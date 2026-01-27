import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/models/user_model.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/data/home_dummy_data.dart';
import 'package:front/widgets/house_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService.fetchProfile();
    setState(() {
      user = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(
              showBack: false,
              toolbarHeight: 64,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        user?.profileImageUrl?.isNotEmpty == true
                            ? user!.profileImageUrl!
                            : 'https://i.pravatar.cc/150',
                      ),
                    ),
                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/pin.svg',
                              width: 14,
                              height: 14,
                              color: green,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Location',
                              style: const TextStyle(
                                color: grey04,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Welcome, ${user?.name ?? ''}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ],
                ),
              ),

              trailing: Row(
                children: [
                  CircleIconButton(
                    svgAsset: 'assets/icons/search.svg',
                    iconSize: 23,
                    padding: EdgeInsetsGeometry.only(right: 8),
                    onPressed: () {},
                  ),
                  CircleIconButton(
                    svgAsset: 'assets/icons/bell.svg',
                    iconSize: 20,
                    iconColor: dark,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            /// 나머지 콘텐츠
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 34),

                  /// 메인 카피
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Explore Your Place to Stay,',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Built on Trust.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// 필터 버튼
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _filterChip('Filter', icon: 'assets/icons/filter.svg'),
                        _filterChip('All', selected: true),
                        _filterChip('House'),
                        _filterChip('Apartment'),
                      ],
                    ),
                  ),

                  /// 타이틀
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Popular listings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          color: green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// 가로 스크롤 카드
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularHousesDummy.length,
                      itemBuilder: (context, index) {
                        return HouseCard(house: popularHousesDummy[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String text, {bool selected = false, String? icon}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: selected ? green : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? green : grey02),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            SvgPicture.asset(
              icon,
              width: 16,
              height: 16,
              color: selected ? Colors.white : dark,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : dark,
            ),
          ),
        ],
      ),
    );
  }
}
