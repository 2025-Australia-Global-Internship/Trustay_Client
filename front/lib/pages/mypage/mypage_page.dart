import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/models/user_model.dart';
import 'package:front/widgets/gradient_layout.dart';
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
      backgroundColor: Color(0xFFFAFAFA),
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
                    fontSize: 18,
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
                      const SizedBox(height: 6),

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
                          elevation: 0,
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
                              'assets/icons/edit-note.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                darkgreen,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 7),
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

            /// 메뉴 리스트
            MenuSection(
              children: [
                MyPageMenuItem(
                  title: 'Personal Details',
                  subtitle:
                      'You must enter your info to complete transactions.',
                  leadingPath: 'assets/icons/profile.svg',
                  onTap: () => Navigator.pushNamed(context, '/person_details'),
                ),
                MyPageMenuItem(
                  title: 'Current Stay',
                  leadingPath: 'assets/icons/house-user.svg',
                ),
                MyPageMenuItem(
                  title: 'Listings',
                  leadingPath: 'assets/icons/home-edit.svg',
                  onTap: () => Navigator.pushNamed(context, '/listing'),
                ),
              ],
            ),
            MenuSection(
              children: [
                MyPageMenuItem(
                  title: 'Saved Listings',
                  leadingPath: 'assets/icons/heart.svg',
                ),
                MyPageMenuItem(
                  title: 'My Reviews',
                  leadingPath: 'assets/icons/review.svg',
                ),
                MyPageMenuItem(
                  title: 'My Wallet',
                  leadingPath: 'assets/icons/wallet-line.svg',
                ),
                MyPageMenuItem(
                  title: 'My Contracts',
                  leadingPath: 'assets/icons/contract.svg',
                ),
                MyPageMenuItem(
                  title: 'Recently Viewed',
                  leadingPath: 'assets/icons/view.svg',
                ),
              ],
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class MenuSection extends StatelessWidget {
  final List<Widget> children;
  const MenuSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

/// 메뉴 아이템 디자인
class MyPageMenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String leadingPath;
  final VoidCallback? onTap;

  const MyPageMenuItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.leadingPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(7),
        child: SvgPicture.asset(leadingPath, width: 26, color: dark),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: dark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: grey04))
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: grey01,
      ), // 연한 화살표
    );
  }
}
