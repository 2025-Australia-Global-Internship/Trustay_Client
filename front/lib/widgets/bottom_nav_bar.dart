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

  static final _items = [
    _BottomNavItem('assets/icons/home.svg', 'Home'),
    _BottomNavItem('assets/icons/community.svg', 'Comms'),
    _BottomNavItem('assets/icons/map.svg', 'Map'),
    _BottomNavItem('assets/icons/coin.svg', 'Finance'),
    _BottomNavItem('assets/icons/profile.svg', 'My'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? yellow : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    _items[index].iconPath,
                    width: 24,
                    height: 24,
                    color: darkgreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _items[index].label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'NanumSquareNeo',
                    fontWeight: FontWeight.w700,
                    color: darkgreen,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNavItem {
  final String iconPath;
  final String label;

  const _BottomNavItem(this.iconPath, this.label);
}
