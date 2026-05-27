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
      // 1. extendBody를 true로 설정해서 body가 바텀바 영역까지 확장되게 함
      extendBody: true,
      body: Stack(
        children: [
          // 페이지들
          IndexedStack(index: _currentIndex, children: _pages),

          // 2. 네비바를 Stack의 최상단에 배치
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
      // 기존 bottomNavigationBar 속성은 비워둠
    );
  }
}
