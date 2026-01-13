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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
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
              fontFamily: 'NanumSquareNeo',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: grey04,
                fontSize: 10.5,
                fontFamily: 'NanumSquareNeo',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
      subtitle: null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class MenuIcon extends StatelessWidget {
  final String assetPath;
  final Color backgroundColor;
  final Color iconColor;

  const MenuIcon({
    super.key,
    required this.assetPath,
    this.backgroundColor = green,
    this.iconColor = yellow,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: SvgPicture.asset(
        assetPath,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}
