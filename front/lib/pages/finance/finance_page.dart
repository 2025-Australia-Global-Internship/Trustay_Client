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
  late DateTime _currentMonth;
  int? _selectedDay;
  int _selectedFilter = 0;
  final List<String> _filters = ['All splits', 'You paid', 'Mate paid'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDay = DateTime.now().day;
  }

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
        mainAxisSpacing: 10, // 행 간격
      ),
      itemCount: totalCells,
      itemBuilder: (_, index) {
        // 이전 달 날짜
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

        // 다음 달 날짜
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

  Widget _buildSplitBillsButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Split Bills 페이지로 이동
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                ),
                SizedBox(height: 7),
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
    return Text(
      month,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: dark,
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
