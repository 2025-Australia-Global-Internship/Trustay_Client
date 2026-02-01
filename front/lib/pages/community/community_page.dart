import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'house_comm_page.dart';
import 'social_comm_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _topTabIndex = 0; // 0: House, 1: Social

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
        child: Column(
          children: [
            // 상단 스위치 헤더
            _buildTopSwitchHeader(),
            // 모드별 페이지
            Expanded(
              child: _topTabIndex == 0
                  ? HouseCommPage() // House 모드
                  : SocialCommPage(), // Social 모드
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 House / Social 스위치
  Widget _buildTopSwitchHeader() {
    return CustomHeader(
      toolbarHeight: 60, // 원하는 높이
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopTab('House', 'assets/icons/house.svg', 0),
          SizedBox(width: 8),
          _buildTopTab('Social', 'assets/icons/social.svg', 1),
        ],
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
              onPressed: () {},
            ),
          CircleIconButton(
            svgAsset: 'assets/icons/bell.svg',
            iconSize: 19,
            iconColor: dark,
            padding: const EdgeInsets.only(right: 8),
            onPressed: () {},
          ),
          CircleIconButton(
            svgAsset: 'assets/icons/profile.svg',
            iconColor: dark,
            iconSize: 24,
            onPressed: () {},
          ),
        ],
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? yellow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? dark : grey02, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgPath,
              width: 16,
              height: 16, // 색상 적용 가능
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
