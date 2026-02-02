import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/models/user_model.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/mypage_menu.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            /// 헤더
            CustomHeader(
              showBack: false,
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),
              trailing: CircleIconButton(
                padding: EdgeInsets.zero,
                svgAsset: 'assets/icons/logout.svg',
                iconSize: 23,
                onPressed: () => _handleLogout(context),
              ),
            ),

            const SizedBox(height: 6),

            /// 프로필 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      user?.profileImageUrl?.isNotEmpty == true
                          ? user!.profileImageUrl!
                          : 'https://i.pravatar.cc/150',
                    ),
                  ),

                  const SizedBox(width: 18),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: grey04,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: grey04,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/edit_profile');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 10,
                          ),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 버튼 크기 최소화
                          children: [
                            SvgPicture.asset(
                              'assets/icons/pencil.svg',
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                darkgreen,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Edit profile',
                              style: TextStyle(
                                fontSize: 11,
                                color: darkgreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 메뉴 섹션들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  MenuSection(
                    children: [
                      MyPageMenuItem(
                        title: 'Personal Details',
                        subtitle:
                            'You must enter your personal information to complete transactions on the platform.',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/profile.svg',
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/person_details');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  MenuSection(
                    children: [
                      MyPageMenuItem(
                        title: 'Current Stay',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/house-user.svg',
                          size: 20,
                        ),
                      ),
                      MyPageMenuItem(
                        title: 'Listings',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/home-edit.svg',
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/listing');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  MenuSection(
                    children: [
                      MyPageMenuItem(
                        title: 'Saved Listings',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/heart.svg',
                        ),
                      ),
                      MyPageMenuItem(
                        title: 'My Reviews',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/review.svg',
                        ),
                      ),
                      MyPageMenuItem(
                        title: 'My Wallet',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/coin-fill.svg',
                          size: 26,
                        ),
                      ),
                      MyPageMenuItem(
                        title: 'My Contracts',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/contract.svg',
                        ),
                      ),
                      MyPageMenuItem(
                        title: 'Recently Viewed',
                        leading: const MenuIcon(
                          assetPath: 'assets/icons/view.svg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
