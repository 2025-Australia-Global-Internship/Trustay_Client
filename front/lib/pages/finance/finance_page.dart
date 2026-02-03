import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/gradient_layout.dart';

class TransactionItem {
  final String title;
  final String subtitle;
  final String date;
  final double amount;

  const TransactionItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
  });
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  int _selectedDay = DateTime.now().day;

  int _selectedFilter = 0;
  final List<String> _filters = ['All splits', 'You paid', 'Mate paid'];

  final Map<String, List<TransactionItem>> _transactionsByMonth = {
    'May': [
      const TransactionItem(
        title: 'Rent Due',
        subtitle: 'My wallet → Stella',
        date: '5/9 · 09:40AM',
        amount: -320,
      ),
      const TransactionItem(
        title: 'Split Bills',
        subtitle: 'Olivia → My wallet',
        date: '5/4 · 03:28PM',
        amount: -320,
      ),
      const TransactionItem(
        title: 'Split Bills',
        subtitle: 'My wallet → Olivia',
        date: '5/2 · 08:07PM',
        amount: -320,
      ),
    ],
    'April': [
      const TransactionItem(
        title: 'Rent Due',
        subtitle: 'My wallet → Stella',
        date: '4/9 · 09:40AM',
        amount: -320,
      ),
      const TransactionItem(
        title: 'Split Bills',
        subtitle: 'Olivia → My wallet',
        date: '4/4 · 03:28PM',
        amount: -320,
      ),
      const TransactionItem(
        title: 'Split Bills',
        subtitle: 'My wallet → Olivia',
        date: '4/2 · 08:07PM',
        amount: -320,
      ),
    ],
  };

  static const int _startDayIndex = 4;
  static const int _totalDays = 31;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CustomHeader(
                showBack: false,
                toolbarHeight: 56,
                leading: Padding(
                  padding: EdgeInsets.only(left: 16),
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
                      onPressed: () {},
                    ),
                    CircleIconButton(
                      svgAsset: 'assets/icons/profile.svg',
                      iconSize: 23,
                      iconColor: dark,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── 본문 ──
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // 달력 카드
                  _buildCalendarCard(),
                  const SizedBox(height: 12),

                  // Split Bills 버튼
                  _buildSplitBillsButton(),
                  const SizedBox(height: 16),

                  // 필터 탭
                  _buildFilterTabs(),
                  const SizedBox(height: 20),

                  // 월별 거래 목록
                  ..._transactionsByMonth.entries.map(
                    (entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthLabel(entry.key),
                        const SizedBox(height: 8),
                        _buildTransactionList(entry.value),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_up,
                    size: 22,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'May',
                    style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 요일 헤더
          _buildDayHeaders(),
          const SizedBox(height: 4),

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
                    color: Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid() {
    const totalCells = 42;
    final prevDayNumbers = List.generate(
      _startDayIndex,
      (i) => 30 - (_startDayIndex - 1 - i),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 36,
      ),
      itemCount: totalCells,
      itemBuilder: (_, index) {
        final dayNumber = index - _startDayIndex + 1;

        // 이전달 날짜 (회색)
        if (index < _startDayIndex) {
          return Align(
            alignment: Alignment.center,
            child: Text(
              '${prevDayNumbers[index]}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
            ),
          );
        }

        // 범위 밖 (빈 셀)
        if (dayNumber > _totalDays) return const SizedBox();

        final isSelected = dayNumber == _selectedDay;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = dayNumber),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 30,
              height: 30,
              decoration: isSelected
                  ? const BoxDecoration(
                      color: Color(0xFFF5F0A0),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF444444),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitBillsButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Split Bills 페이지로 이동
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Splitting bills with roommates made easy.',
                  style: TextStyle(fontSize: 12, color: grey03),
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
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(_filters.length, (i) {
          final isActive = i == _selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: isActive
                    ? BoxDecoration(
                        color: const Color(0xFFF5F0A0),
                        borderRadius: BorderRadius.circular(18),
                      )
                    : null,
                child: Center(
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF888888),
                    ),
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
    return Text(
      month,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              _buildTransactionRow(items[i]),
              if (i < items.length - 1)
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTransactionRow(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF6BCB77),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.attach_money,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- \$${item.amount.abs().toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.date,
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
