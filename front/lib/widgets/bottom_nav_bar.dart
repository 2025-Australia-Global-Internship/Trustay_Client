import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static final List<Map<String, String>> _items = [
    {
      'default': 'assets/icons/home.svg',
      'selected': 'assets/icons/home-fill.svg',
    },
    {
      'default': 'assets/icons/community.svg',
      'selected': 'assets/icons/community-fill.svg',
    },
    {
      'default': 'assets/icons/map.svg',
      'selected': 'assets/icons/map-fill.svg',
    },
    {
      'default': 'assets/icons/coin.svg',
      'selected': 'assets/icons/coin-fill.svg',
    },
    {
      'default': 'assets/icons/profile.svg',
      'selected': 'assets/icons/profile-fill.svg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const double navbarHeight = 74;
    const double circleSize = 58;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: navbarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (index) {
                    final isSelected = index == currentIndex;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? green : Colors.white,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            isSelected
                                ? _items[index]['selected']!
                                : _items[index]['default']!,
                            width: index == 4 ? 26 : 24,
                            height: index == 4 ? 26 : 24,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
