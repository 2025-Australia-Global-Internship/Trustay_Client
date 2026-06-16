import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/index.dart' show goToMyPageTab;
import 'package:front/services/notification_service.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/notification_bell_button.dart';
import 'community_search_page.dart';
import 'house_comm_page.dart';
import 'social_comm_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/main.dart'; // routeObserver import

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with RouteAware {
  int _topTabIndex = 0; // 0: House, 1: Social

  @override
  void initState() {
    super.initState();
    // 종 아이콘 빨간 뱃지를 위한 unread 개수 갱신.
    NotificationService.fetchUnreadCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 알림 페이지에서 돌아왔을 때 뱃지를 다시 동기화한다.
  @override
  void didPopNext() {
    NotificationService.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientLayout(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopSwitchHeader(),
              Expanded(
                child: _topTabIndex == 0 ? HouseCommPage() : SocialCommPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 House / Social 스위치
  Widget _buildTopSwitchHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: CustomHeader(
        toolbarHeight: 60, // 원하는 높이
        leading: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopTab('House', 'assets/icons/house.svg', 0),
              SizedBox(width: 4),
              _buildTopTab('Social', 'assets/icons/social.svg', 1),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_topTabIndex == 1)
              CircleIconButton(
                svgAsset: 'assets/icons/search.svg',
                iconSize: 23,
                iconColor: dark,
                padding: const EdgeInsets.only(right: 8),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommunitySearchPage(),
                    ),
                  );
                },
              ),
            const NotificationBellButton(
              iconSize: 21.5,
              padding: EdgeInsets.only(right: 8),
            ),
            CircleIconButton(
              svgAsset: 'assets/icons/profile.svg',
              iconColor: dark,
              iconSize: 23,
              onPressed: goToMyPageTab,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTab(String label, String svgPath, int index) {
    final isSelected = _topTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _topTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? yellow : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(svgPath, width: 18, height: 18),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
