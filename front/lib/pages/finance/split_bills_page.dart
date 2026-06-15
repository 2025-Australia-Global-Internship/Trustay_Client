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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep',
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

  /// 올해(현재 연도) 월별 합계(달러). 1=Jan ... 12=Dec.
  Map<int, double> _monthlyTotalsThisYear() {
    final int year = DateTime.now().year;
    final Map<int, double> totals = {for (int i = 1; i <= 12; i++) i: 0.0};
    for (final p in _dutchHistory) {
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
    for (final p in _dutchHistory) {
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
                  fontSize: 17,
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
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: grey03,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fmtMoney(total),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: darkgreen,
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
                  fontWeight: FontWeight.w500,
                  color: grey03,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: darkgreen,
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
    // 막대 9개 (Jan~Sep). 디자인을 충실히 재현.
    final values = List<double>.generate(9, (i) => totals[i + 1] ?? 0);
    final double maxValue =
        values.fold<double>(0, (acc, v) => v > acc ? v : acc);

    return SizedBox(
      height: 130,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 라벨이 항상 막대 위로 올라오도록 강조 막대의 라벨 영역 확보.
          const double labelHeight = 22;
          const double barAreaTop = labelHeight + 6;
          final double barAreaHeight = 110 - barAreaTop;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(9, (i) {
              final v = values[i];
              final bool isCurrent = (i + 1) == currentMonth;
              final double ratio = maxValue == 0 ? 0 : (v / maxValue);
              final double barHeight =
                  (barAreaHeight * ratio).clamp(8.0, barAreaHeight);

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 라벨 (현재 월에만 표시)
                    SizedBox(
                      height: labelHeight,
                      child: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: darkgreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _fmtMoney(v),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 12,
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
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrent ? darkgreen : grey03,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
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
                  fontSize: 14,
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
                    color: darkgreen,
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
    final title = (p.targetAccount != null && p.targetAccount!.isNotEmpty)
        ? p.targetAccount!
        : 'Split bill';

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
              MaterialPageRoute(
                builder: (_) => const CreateSplitBillPage(),
              ),
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
