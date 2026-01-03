import 'package:flutter/material.dart';

class CommonBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CommonBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _BottomNavItem(Icons.home_outlined, 'Home'),
    _BottomNavItem(Icons.chat_bubble_outline, 'Comms'),
    _BottomNavItem(Icons.location_on_outlined, 'Map'),
    _BottomNavItem(Icons.attach_money, 'Finance'),
    _BottomNavItem(Icons.person_outline, 'My'),
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
                    color: isSelected
                        ? const Color(0xFFFFF3A0)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_items[index].icon, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  _items[index].label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
  final IconData icon;
  final String label;

  const _BottomNavItem(this.icon, this.label);
}
