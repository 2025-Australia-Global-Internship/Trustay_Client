import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:front/constants/colors.dart';
import 'package:front/models/payment_model.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';

import 'create_split_bill_page.dart';

/// "Split Bills" 페이지 (Finance_04 디자인).
///
/// 표시 내용:
///  - 이번 달 Split Bill 총액(=내가 지불한 DUTCH 결제의 합)
///  - 월별 막대 차트 (Jan ~ Sep)
///  - Split Bill History 카드 (최근 1건 미리보기 + See all)
///  - "Create Split Bill" CTA
///
/// 통화는 호주달러(AUD) — `$` 기호 + 천 단위 구분.
class SplitBillsPage extends StatefulWidget {
  const SplitBillsPage({super.key});

  @override
  State<SplitBillsPage> createState() => _SplitBillsPageState();
}

class _SplitBillsPageState extends State<SplitBillsPage> {
  static const List<String> _shortMonths = [
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

  // 가져올 결제 이력 (DUTCH 전용으로 충분히 큰 페이지).
  // 백엔드가 정렬을 최신순으로 내려주는 것으로 가정한다.
  bool _isLoading = true;
  List<PaymentHistoryItem> _dutchHistory = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await PaymentService.getMyHistory(
        type: 'DUTCH',
        page: 0,
        size: 100,
      );
      if (!mounted) return;
      setState(() {
        _dutchHistory = all;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load split bills.';
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 통계 계산
  // ---------------------------------------------------------------------------

  /// 차트/총합에 사용할 항목만 필터링.
  ///
  /// - "내가 지불한" 더치페이만 포함 (OUT, CONFIRMED).
  ///   - PENDING 은 아직 결제 전이라 합산하면 사용자 입장에서 잘못된 금액이 노출됨.
  ///   - IN 은 내가 받은 돈이라 "이번 달 사용 금액"엔 들어가면 안 됨.
  Iterable<PaymentHistoryItem> get _confirmedOutgoing => _dutchHistory.where(
        (p) => !p.isIncoming && p.status == 'CONFIRMED',
      );

  /// 올해(현재 연도) 월별 합계(달러). 1=Jan ... 12=Dec.
  Map<int, double> _monthlyTotalsThisYear() {
    final int year = DateTime.now().year;
    final Map<int, double> totals = {for (int i = 1; i <= 12; i++) i: 0.0};
    for (final p in _confirmedOutgoing) {
      final d = p.transactionDate;
      if (d == null) continue;
      if (d.year != year) continue;
      totals[d.month] = (totals[d.month] ?? 0) + p.amount;
    }
    return totals;
  }

  double _totalThisMonth() {
    final now = DateTime.now();
    double sum = 0;
    for (final p in _confirmedOutgoing) {
      final d = p.transactionDate;
      if (d == null) continue;
      if (d.year != now.year || d.month != now.month) continue;
      sum += p.amount;
    }
    return sum;
  }

  // ---------------------------------------------------------------------------
  // 포맷팅
  // ---------------------------------------------------------------------------

  String _fmtMoney(num v) {
    final f = NumberFormat.currency(
      locale: 'en_AU',
      symbol: '\$',
      decimalDigits: 2,
    );
    return f.format(v);
  }

  String _fmtTxDate(DateTime d) {
    return DateFormat('dd MMM, yyyy · HH:mm').format(d);
  }

  // ---------------------------------------------------------------------------
  // 빌드
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: GradientLayout(
        child: Column(
          children: [
            const CustomHeader(
              showBack: true,
              toolbarHeight: 56,
              center: Text(
                'Split Bills',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: green))
                  : RefreshIndicator(
                      color: green,
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildHistoryCard(),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: grey03,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ---------------------------------------------------------------------------
  // Summary 카드 (Total + bar chart)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard() {
    final totals = _monthlyTotalsThisYear();
    final double total = _totalThisMonth();
    final int year = DateTime.now().year;
    final int currentMonth = DateTime.now().month;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Split Bill This Month',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _fmtMoney(total),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: green,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expenses in $year',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: grey02,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildBarChart(totals: totals, currentMonth: currentMonth),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required Map<int, double> totals,
    required int currentMonth,
  }) {
    final values = List<double>.generate(12, (i) => totals[i + 1] ?? 0);
    final double maxValue = values.fold<double>(
      0,
      (acc, v) => v > acc ? v : acc,
    );

    return SizedBox(
      height: 120,
      // 💡 1. 가로 스크롤을 가능하게 해주는 좌우 스크롤 뷰 배치
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double labelHeight = 24;
            const double barAreaTop = labelHeight + 6;
            final double barAreaHeight = 110 - barAreaTop;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              // 💡 2. Expanded 대신 고정 너비를 가질 수 있도록 변경
              children: List.generate(12, (i) {
                final v = values[i];
                final bool isCurrent = (i + 1) == currentMonth;
                final double ratio = maxValue == 0 ? 0 : (v / maxValue);
                final double barHeight = (barAreaHeight * ratio).clamp(
                  8.0,
                  barAreaHeight,
                );

                // 💡 3. 각 한 달 영역의 총 가로 할당 너비를 고정(42px)합니다.
                // 이 값이 커질수록 막대 사이의 간격이 넓어집니다.
                return SizedBox(
                  width: 42,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 💬 가로로 긴 말풍선 모양 가격 라벨
                      SizedBox(
                        height: labelHeight,
                        child: isCurrent
                            ? OverflowBox(
                                minWidth: 0,
                                maxWidth: 100, // 양옆으로 넉넉하게 펼쳐질 수 있는 공간 보장
                                minHeight: 0,
                                maxHeight: labelHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 말풍선 본체 (가로로 긴 라운드 렉트)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: green,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _fmtMoney(v),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    // 말풍선 아래 꼬리 역삼각형 모양 힌트
                                    Transform.translate(
                                      offset: const Offset(0, -1),
                                      child: ClipPath(
                                        clipper: _TriangleClipper(),
                                        child: Container(
                                          width: 6,
                                          height: 4,
                                          color: green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 6),
                      // 막대 기둥
                      Container(
                        width: 23,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isCurrent ? yellow : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _shortMonths[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isCurrent ? green : grey03,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // History 카드
  // ---------------------------------------------------------------------------
  Widget _buildHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Split Bill History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_dutchHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No split bills yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: grey03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ..._dutchHistory.take(3).map(_buildHistoryRow),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(PaymentHistoryItem p) {
    final d = p.transactionDate;
    final dateStr = d != null ? _fmtTxDate(d) : '';
    // 행 제목: 1순위 카운터파티 이름, 2순위 계좌 라벨(짧을 때만), 그 외 'Split bill'.
    //   targetAccount 는 계좌 등록 안내 같은 긴 문장이 들어올 수 있으므로
    //   그대로 노출하면 안 된다(=서버 PaymentService.ACCOUNT_NOT_SET 메시지).
    String resolvedTitle = 'Split bill';
    if (p.counterpartyName != null && p.counterpartyName!.isNotEmpty) {
      resolvedTitle = p.counterpartyName!;
    } else if (p.targetAccount != null &&
        p.targetAccount!.isNotEmpty &&
        !p.targetAccount!.startsWith('(')) {
      resolvedTitle = p.targetAccount!;
    }
    final title = resolvedTitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: darkgreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              title.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: grey03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _fmtMoney(p.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: darkgreen,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CTA — Create Split Bill
  // ---------------------------------------------------------------------------
  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CreateSplitBillPage()),
            );
            if (created == true && mounted) _load();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            foregroundColor: dark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/plus.svg',
                width: 14,
                height: 14,
                color: dark,
              ),
              const SizedBox(width: 8),
              const Text(
                'Create Split Bill',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 💡 말풍선 아래 꼬리 삼각형을 그리기 위한 클리퍼 클래스
class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
