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
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 0, 27, 30),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2).withOpacity(0.8),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (index) {
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 67,
                height: 67,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? green : Colors.white,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    isSelected
                        ? _items[index]['selected']!
                        : _items[index]['default']!,
                    width: index == 4 ? 29 : 27,
                    height: index == 4 ? 29 : 27,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
