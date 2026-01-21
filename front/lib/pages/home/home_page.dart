import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/models/user_model.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/widgets/circle_icon_button.dart';

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
                children: const [
                  SizedBox(height: 34),
                  // 나머지 홈 컨텐츠
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
