import 'package:flutter/material.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/widgets/mypage_menu.dart';
import 'package:front/widgets/icon_primary_button.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ===== 프로필 영역 =====
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  /// 프로필 사진
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
                  ),

                  const SizedBox(width: 16),

                  /// 이름 / 이메일 / 버튼
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emma',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'NanumSquareNeo',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'd2421@e-mirim.hs.kr',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'NanumSquareNeo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconPrimaryButton(
                        text: 'Edit profile',
                        icon: Icons.edit,
                        height: 36,
                        fontSize: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile/edit');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 34),

          /// ===== 메뉴 섹션 =====
          MenuSection(
            children: [
              MyPageMenuItem(
                title: 'Personal Details',
                subtitle:
                    'You must enter your personal information to complete transactions on the platform.',
                leading: const MenuIcon(assetPath: 'assets/icons/profile.svg'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          MenuSection(
            children: [
              MyPageMenuItem(
                title: 'Current Stay',
                leading: const MenuIcon(
                  assetPath: 'assets/icons/house-user.svg',
                ),
              ),
              MyPageMenuItem(
                title: 'Listings',
                leading: const MenuIcon(
                  assetPath: 'assets/icons/home-edit.svg',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          MenuSection(
            children: [
              MyPageMenuItem(
                title: 'Saved Listings',
                leading: const MenuIcon(assetPath: 'assets/icons/heart.svg'),
              ),
              MyPageMenuItem(
                title: 'My Reviews',
                leading: const MenuIcon(assetPath: 'assets/icons/review.svg'),
              ),
              MyPageMenuItem(
                title: 'My Contracts',
                leading: const MenuIcon(assetPath: 'assets/icons/contract.svg'),
              ),
              MyPageMenuItem(
                title: 'Recently Viewed',
                leading: const MenuIcon(assetPath: 'assets/icons/view.svg'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
