import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/community.dart';
import 'screens/map.dart';
import 'screens/finance.dart';
import 'screens/mypage.dart';
import 'widgets/common_bottom_navbar.dart';

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
      bottomNavigationBar: CommonBottomNavbar(
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
