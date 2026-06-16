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

/// 같은 탭을 다시 눌렀을 때(=재선택) 페이지에 새로고침 신호를 보내는 노티파이어.
///
/// 값 자체는 의미가 없고 `notifyListeners()` 가 호출되었다는 사실만 사용한다.
/// 어떤 탭이 재선택되었는지는 [lastReselectedTabIndex] 로 확인한다.
/// (ValueNotifier 는 같은 값을 다시 set 하면 알림이 발생하지 않으므로,
///  매번 카운터를 증가시켜 같은 탭을 연속으로 눌러도 매번 알림이 발생하도록 한다.)
final ValueNotifier<int> tabReselectTick = ValueNotifier<int>(0);

/// 가장 최근에 재선택된 탭 인덱스. [tabReselectTick] 이 트리거되었을 때
/// 호출 측에서 자기 탭이 재선택된 것인지 비교하는 용도.
int lastReselectedTabIndex = -1;

/// 같은 탭을 다시 눌렀을 때 IndexPage 가 호출하는 전역 시그널 발신기.
/// 페이지들은 [tabReselectTick] 을 listen 해서 자기 탭이 재선택되면
/// 페이지 상태를 새로고침할 수 있다.
void signalTabReselect(int tabIndex) {
  lastReselectedTabIndex = tabIndex;
  tabReselectTick.value = tabReselectTick.value + 1;
}

/// MyPage 탭(=4)으로 이동시키는 헬퍼.
void goToMyPageTab() {
  indexTabNotifier.value = 4;
}

/// Finance 탭(=3)으로 이동시키는 헬퍼.
/// 마이페이지의 My Wallet → "See all activity" 등에서 사용한다.
void goToFinanceTab() {
  indexTabNotifier.value = 3;
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
    if (index == _currentIndex) {
      // 같은 탭을 다시 눌렀을 때 → 그 탭의 페이지에 새로고침 신호.
      // (지도 탭에서는 검색/카메라 초기화로 사용된다.)
      signalTabReselect(index);
      return;
    }
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
