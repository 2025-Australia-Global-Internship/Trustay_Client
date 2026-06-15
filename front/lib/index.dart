import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';
import 'pages/community/community_page.dart';
import 'pages/map/map_page.dart';
import 'pages/finance/finance_page.dart';
import 'pages/mypage/mypage_page.dart';
import 'widgets/bottom_nav_bar.dart';

/// 다른 페이지(예: 헤더의 프로필 아이콘 버튼)에서 IndexPage 의
/// 하단 탭을 프로그래매틱하게 전환할 때 사용하는 전역 노티파이어.
/// 0: Home, 1: Community, 2: Map, 3: Finance, 4: MyPage
final ValueNotifier<int> indexTabNotifier = ValueNotifier<int>(0);

/// MyPage 탭(=4)으로 이동시키는 헬퍼.
void goToMyPageTab() {
  indexTabNotifier.value = 4;
}

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
  void initState() {
    super.initState();
    // 초기 진입 시점의 노티파이어 값이 0이 아니라면 동기화 (방어적)
    _currentIndex = indexTabNotifier.value;
    indexTabNotifier.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    indexTabNotifier.removeListener(_onExternalTabChange);
    super.dispose();
  }

  void _onExternalTabChange() {
    if (!mounted) return;
    final next = indexTabNotifier.value;
    if (next < 0 || next >= _pages.length) return;
    if (next == _currentIndex) return;
    setState(() => _currentIndex = next);
  }

  void _setTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // 외부 listener 들에게도 알리되, 같은 값이면 알림 발생 X
    if (indexTabNotifier.value != index) {
      indexTabNotifier.value = index;
    }
  }

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
              onTap: _setTab,
            ),
          ),
        ],
      ),
      // 기존 bottomNavigationBar 속성은 비워둠
    );
  }
}
