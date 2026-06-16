import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:front/constants/colors.dart';
import 'package:front/index.dart' show goToMyPageTab;
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/models/payment_model.dart';
import 'create_split_bill_page.dart';
import 'split_bills_page.dart';
import 'toss_payment_webview.dart';

class TransactionItem {
  final String title;
  final String subtitle;
  final String date;
  final double amount;
  final String paymentType; // RENT / UTILITY / DUTCH
  /// true 면 "Mate paid" (양수, 초록색), false 면 "You paid" (음수)
  final bool isIncoming;

  /// PENDING 결제 행이면 본인이 직접 결제할 수 있도록 진입점에 사용할 정보.
  /// CONFIRMED 또는 다른 사람이 결제할 건이라면 null.
  final PendingPayment? pending;

  /// IN 거래 중 아직 메이트가 결제 완료하지 않은 항목(=대기 중).
  /// UI 에서 "Awaiting" 같은 보조 라벨을 보여주기 위함.
  final bool isAwaiting;

  const TransactionItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.paymentType,
    required this.isIncoming,
    this.pending,
    this.isAwaiting = false,
  });

  bool get isPayable => pending != null;
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late DateTime _currentMonth;
  int? _selectedDay;
  int _selectedFilter = 0;
  final List<String> _filters = ['All splits', 'You paid', 'Mate paid'];

  /// 서버에서 받아온 결제 이력을 월별로 그룹핑한 결과.
  /// API 호출 실패 또는 데이터가 없을 때는 빈 맵으로 둔다(=빈 상태 표시).
  Map<String, List<TransactionItem>> _transactionsByMonth = {};
  bool _isLoading = true;
  String? _loadError;

  // ── 결제 이력 페이징 ──
  // 누적해 들어온 모든 페이지의 raw 항목을 보관한다(중복 합쳐진 뒤 다시 월별 그룹핑).
  static const int _historyPageSize = 20;
  final List<PaymentHistoryItem> _allHistoryItems = [];
  // PENDING 결제 (탭 → 토스 결제창) 진입을 위해 함께 보관.
  List<PendingPayment> _pendingPayments = const [];
  int _historyNextPage = 0;
  bool _historyHasMore = true;
  bool _isLoadingMoreHistory = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDay = DateTime.now().day;
    _scrollController.addListener(_onScroll);
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 화면 끝 200px 근처에 닿으면 다음 페이지를 prefetch.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreHistory();
    }
  }

  // ---------------------------------------------------------------------------
  // 결제 이력 조회 (백엔드 GET /api/trustay/payments/me/history)
  //   서버 응답을 화면용 TransactionItem 으로 매핑한다.
  //   부호 규칙: 내가 송금자(=PaymentStatus.CONFIRMED 결제) → 음수 / 수취 → 양수
  //   targetAccount 또는 paymentType 으로 표시할 subtitle 을 구성한다.
  // ---------------------------------------------------------------------------
  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      // 거래 이력과 미완료 결제(Pending) 를 한 번에 가져온다.
      final results = await Future.wait([
        PaymentService.getMyHistory(page: 0, size: _historyPageSize),
        PaymentService.getMyPending(size: 30),
      ]);
      if (!mounted) return;
      final history = results[0] as List<PaymentHistoryItem>;
      final pending = results[1] as List<PendingPayment>;
      setState(() {
        _allHistoryItems
          ..clear()
          ..addAll(history);
        _pendingPayments = pending;
        _transactionsByMonth = _groupByMonth(
          _allHistoryItems,
          _pendingPayments,
        );
        _historyNextPage = 1;
        _historyHasMore = history.length >= _historyPageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // 로그인 만료 등 인증 실패는 안내만 표시.
      setState(() {
        _allHistoryItems.clear();
        _pendingPayments = const [];
        _transactionsByMonth = {};
        _historyHasMore = false;
        _isLoading = false;
        _loadError = 'Could not load transactions. Pull down to retry.';
      });
    }
  }

  /// 다음 페이지를 가져와 누적 리스트에 추가하고 월별 그룹핑을 다시 계산.
  Future<void> _loadMoreHistory() async {
    if (_isLoadingMoreHistory || !_historyHasMore || _isLoading) return;
    setState(() => _isLoadingMoreHistory = true);
    try {
      final next = await PaymentService.getMyHistory(
        page: _historyNextPage,
        size: _historyPageSize,
      );
      if (!mounted) return;
      setState(() {
        _allHistoryItems.addAll(next);
        _transactionsByMonth = _groupByMonth(
          _allHistoryItems,
          _pendingPayments,
        );
        _historyNextPage += 1;
        _historyHasMore = next.length >= _historyPageSize;
        _isLoadingMoreHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMoreHistory = false);
    }
  }

  /// PENDING 결제 행을 누르면 토스 결제 위젯을 띄우고 성공 시 새로고침.
  Future<void> _payPending(PendingPayment p) async {
    final user = AuthService.currentUserNotifier.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile is not loaded yet.')),
      );
      return;
    }
    final orderName = (p.title != null && p.title!.isNotEmpty)
        ? p.title!
        : _titleFor(p.paymentType);
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TossPaymentWebView(
          amount: p.amount,
          orderId: p.orderId,
          orderName: orderName,
          customerKey: 'MEMBER_${user.memberId}',
          customerName: user.name,
        ),
      ),
    );
    if (paid == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment confirmed.')));
      _loadHistory();
    }
  }

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Map<String, List<TransactionItem>> _groupByMonth(
    List<PaymentHistoryItem> items,
    List<PendingPayment> pendings,
  ) {
    final result = <String, List<TransactionItem>>{};

    // (1) 미완료 결제 → 별도 "Pending" 섹션으로 묶어 가장 위에 노출.
    if (pendings.isNotEmpty) {
      result['Pending'] = pendings
          .map(
            (p) => TransactionItem(
              title: (p.title != null && p.title!.isNotEmpty)
                  ? p.title!
                  : _titleFor(p.paymentType),
              subtitle: (p.payeeName != null && p.payeeName!.isNotEmpty)
                  ? 'My wallet → ${p.payeeName}'
                  : ((p.targetAccount != null && p.targetAccount!.isNotEmpty)
                        ? 'My wallet → ${p.targetAccount}'
                        : 'My wallet'),
              date: 'Tap to pay',
              amount: -p.amount.toDouble(),
              paymentType: p.paymentType,
              isIncoming: false,
              pending: p,
            ),
          )
          .toList();
    }

    // (2) 거래 이력: 최신순 → 월별 그룹핑.
    //
    // OUT 거래의 PENDING 은 이미 위 "Pending" 섹션에서 노출되므로 월별 거래 내역에는
    // 포함시키지 않는다(중복 표시 방지). IN 거래의 PENDING 은 "Awaiting" 라벨로
    // 받을 예정 금액을 표시해야 하므로 그대로 둔다.
    final sorted = [...items]
      ..sort((a, b) {
        final ad = a.transactionDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.transactionDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    for (final p in sorted) {
      final date = p.transactionDate;
      if (date == null) continue;
      // OUT 거래의 PENDING / FAILED 는 거래 내역에서 제외.
      //   - PENDING: 위 Pending 섹션과 중복.
      //   - FAILED : 사용자에게 노이즈 (재시도하면 새 레코드가 생성).
      if (!p.isIncoming && p.status != 'CONFIRMED') continue;
      final monthLabel = _monthLabels[date.month - 1];
      final dateStr = _formatTxDate(date);
      final title = _titleFor(p.paymentType);
      final subtitle = _subtitleFor(p);
      // 백엔드 direction 필드 사용:
      // - IN  : 내가 받음 (Mate paid) → 양수
      // - OUT : 내가 보냄 (You paid) → 음수
      final double signed = p.isIncoming
          ? p.amount.toDouble()
          : -p.amount.toDouble();

      // IN 인데 아직 메이트가 결제 안 한 경우 = 받을 예정.
      final bool awaiting = p.isIncoming && p.status == 'PENDING';

      result
          .putIfAbsent(monthLabel, () => [])
          .add(
            TransactionItem(
              title: title,
              subtitle: subtitle,
              date: dateStr,
              amount: signed,
              paymentType: p.paymentType,
              isIncoming: p.isIncoming,
              isAwaiting: awaiting,
            ),
          );
    }

    return result;
  }

  String _titleFor(String paymentType) {
    switch (paymentType) {
      case 'RENT':
        return 'Rent Due';
      case 'UTILITY':
        return 'Utility';
      case 'DUTCH':
        return 'Split Bills';
      default:
        return paymentType;
    }
  }

  String _subtitleFor(PaymentHistoryItem p) {
    // 디자인:
    //   - You paid : "My wallet → {상대방}"
    //   - Mate paid: "{상대방} → My wallet"
    final counterparty =
        (p.counterpartyName != null && p.counterpartyName!.isNotEmpty)
        ? p.counterpartyName!
        : ((p.targetAccount != null && p.targetAccount!.isNotEmpty)
              ? p.targetAccount!
              : 'Counterparty');
    if (p.isIncoming) {
      return '$counterparty → My wallet';
    }
    return 'My wallet → $counterparty';
  }

  String _formatTxDate(DateTime d) {
    // 디자인: "09 May · 09:40AM"
    return DateFormat('dd MMM · hh:mma').format(d);
  }

  String _fmtAud(num v) {
    return NumberFormat.currency(
      locale: 'en_AU',
      symbol: '\$',
      decimalDigits: 0,
    ).format(v);
  }

  // 필터링된 거래 내역 가져오기
  Map<String, List<TransactionItem>> _getFilteredTransactions() {
    // "Pending" 섹션은 항상 그대로 노출하고, 거래 내역에만 필터를 적용.
    final pending = _transactionsByMonth['Pending'];
    if (_selectedFilter == 0) {
      // All splits - 전체 표시
      return _transactionsByMonth;
    }

    Map<String, List<TransactionItem>> filtered = {};
    if (pending != null && pending.isNotEmpty) {
      filtered['Pending'] = pending;
    }

    _transactionsByMonth.forEach((month, transactions) {
      if (month == 'Pending') return;
      List<TransactionItem> filteredList = transactions.where((item) {
        if (_selectedFilter == 1) {
          // You paid - 음수 (내가 지불)
          return item.amount < 0;
        } else {
          // Mate paid - 양수 (메이트가 지불)
          return item.amount > 0;
        }
      }).toList();

      if (filteredList.isNotEmpty) {
        filtered[month] = filteredList;
      }
    });

    return filtered;
  }

  // 해당 월의 첫 번째 날의 요일 인덱스 (0=일요일)
  int _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  // 해당 월의 총 일수
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // 이전 달의 총 일수
  int _getDaysInPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month, 0).day;
  }

  // 월 이름 가져오기
  String _getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[date.month - 1];
  }

  // 이전 달로 이동
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
    });
  }

  // 다음 달로 이동
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: GradientLayout(
        child: RefreshIndicator(
          color: green,
          onRefresh: _loadHistory,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: CustomHeader(
                  showBack: false,
                  toolbarHeight: 56,
                  leading: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: const Text(
                      'House Finances',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  trailing: Row(
                    children: [
                      CircleIconButton(
                        svgAsset: 'assets/icons/plus.svg',
                        iconSize: 17,
                        iconColor: dark,
                        padding: const EdgeInsets.only(right: 8),
                        onPressed: _openCreateSplitBill,
                      ),
                      CircleIconButton(
                        svgAsset: 'assets/icons/profile.svg',
                        iconSize: 23,
                        iconColor: dark,
                        onPressed: goToMyPageTab,
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),

                    // 달력 카드
                    _buildCalendarCard(),
                    const SizedBox(height: 28),

                    // Split Bills 버튼
                    _buildSplitBillsButton(),
                    const SizedBox(height: 28),

                    // 필터 탭
                    _buildFilterTabs(),
                    const SizedBox(height: 24),

                    // 로딩 / 에러 / 빈 상태 / 데이터 표시
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: green),
                        ),
                      )
                    else if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                color: grey02,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: grey03,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filteredTransactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/wallet.svg',
                                width: 48,
                                height: 48,
                                color: grey01,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: grey03,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Create a split bill to get started.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: grey03,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredTransactions.entries.map(
                        (entry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMonthLabel(entry.key),
                            const SizedBox(height: 16),
                            _buildTransactionList(entry.value),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                    // 추가 페이지 로드 인디케이터 / 끝 안내
                    if (_isLoadingMoreHistory)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: green,
                            ),
                          ),
                        ),
                      )
                    else if (!_historyHasMore && _allHistoryItems.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'No more transactions',
                            style: TextStyle(fontSize: 12, color: grey03),
                          ),
                        ),
                      ),

                    const SizedBox(height: 70),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),

              Row(
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_back.svg',
                        width: 14,
                        height: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _getMonthName(_currentMonth),
                    style: const TextStyle(
                      fontSize: 13,
                      color: dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_right.svg',
                        width: 14,
                        height: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 요일 헤더
          _buildDayHeaders(),
          const SizedBox(height: 24),

          // 날짜 그리드
          _buildDayGrid(),
        ],
      ),
    );
  }

  Widget _buildDayHeaders() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: days
          .map(
            (d) => Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 12,
                    color: green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    const totalCells = 38;
    final firstDayIndex = _getFirstDayOfMonth(_currentMonth);
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final daysInPrevMonth = _getDaysInPreviousMonth(_currentMonth);

    final today = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == today.year && _currentMonth.month == today.month;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 36,
        mainAxisSpacing: 10,
      ),
      itemCount: totalCells,
      itemBuilder: (_, index) {
        if (index < firstDayIndex) {
          final prevMonthDay = daysInPrevMonth - (firstDayIndex - index - 1);
          return Align(
            alignment: Alignment.center,
            child: Text(
              '$prevMonthDay',
              style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
            ),
          );
        }

        final dayNumber = index - firstDayIndex + 1;

        if (dayNumber > daysInMonth) {
          final nextMonthDay = dayNumber - daysInMonth;
          return Align(
            alignment: Alignment.center,
            child: Text(
              '$nextMonthDay',
              style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
            ),
          );
        }

        final isSelected = dayNumber == _selectedDay;
        final isToday = isCurrentMonth && dayNumber == today.day;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = dayNumber),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? yellow : null,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: grey01, width: 1)
                    : null,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    color: dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSplitBills() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SplitBillsPage()),
    );
    if (!mounted) return;
    _loadHistory();
  }

  Future<void> _openCreateSplitBill() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateSplitBillPage()),
    );
    if (created == true && mounted) _loadHistory();
  }

  Widget _buildSplitBillsButton() {
    return GestureDetector(
      onTap: _openSplitBills,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: green,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/wallet.svg',
                width: 9,
                height: 9,
                fit: BoxFit.none,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split Bills',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Splitting bills with roommates made easy.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: grey04,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final isSelected = _selectedFilter == i;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? yellow : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthLabel(String month) {
    return Padding(
      padding: EdgeInsets.only(left: 6),
      child: Text(
        month,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: dark,
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionItem> items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              _buildTransactionRow(items[i]),
              if (i < items.length - 1) const SizedBox(height: 2),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTransactionRow(TransactionItem item) {
    final isRent = item.paymentType == 'RENT';
    final String leadingIcon = isRent
        ? 'assets/icons/coin-fill.svg'
        : 'assets/icons/wallet.svg';
    final Color amountColor = item.isIncoming ? darkgreen : dark;
    final String sign = item.amount >= 0 ? '' : '- ';
    final String moneyText = '$sign${_fmtAud(item.amount.abs().toInt())}';

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      onTap: item.isPayable ? () => _payPending(item.pending!) : null,
      leading: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          leadingIcon,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          color: yellow,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: dark,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: const TextStyle(
          fontSize: 10.5,
          color: grey03,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            moneyText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          const SizedBox(height: 6),
          if (item.isPayable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pay',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            )
          else if (item.isAwaiting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Awaiting',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: darkgreen,
                ),
              ),
            )
          else
            Text(
              item.date,
              style: const TextStyle(
                fontSize: 9.5,
                color: grey03,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      dense: true,
    );
    return tile;
  }
}
