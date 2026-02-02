import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';

///  메뉴 섹션 카드
class MenuSection extends StatelessWidget {
  final List<Widget> children;

  const MenuSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(children: children),
      ),
    );
  }
}

///  메뉴 아이템
class MyPageMenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool isDanger;

  const MyPageMenuItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: dark,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: grey04,
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
      subtitle: null,
      trailing: SvgPicture.asset(
        'assets/icons/arrow_right.svg',
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(dark, BlendMode.srcIn),
      ),
      onTap: onTap,
    );
  }
}

class MenuIcon extends StatelessWidget {
  final String assetPath;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const MenuIcon({
    super.key,
    required this.assetPath,
    this.backgroundColor = green,
    this.iconColor = yellow,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: backgroundColor,
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}
