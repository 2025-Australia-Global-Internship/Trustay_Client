import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';
import 'pages/community/community_page.dart';
import 'pages/map/map_page.dart';
import 'pages/finance/finance_page.dart';
import 'pages/mypage/mypage_page.dart';
import 'widgets/bottom_nav_bar.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    CommunityPage(),
    MapPage(),
    FinancePage(),
    MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
