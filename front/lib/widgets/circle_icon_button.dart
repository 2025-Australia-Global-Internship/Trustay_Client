import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/constants/colors.dart';

class CircleIconButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  final Color iconColor;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double elevation;
  final EdgeInsetsGeometry padding;

  final bool applySvgColor;

  const CircleIconButton({
    super.key,
    this.icon,
    this.svgAsset,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 20,
    this.iconColor = darkgreen,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.borderWidth = 1,
    this.elevation = 0,
    this.padding = EdgeInsets.zero,
    this.applySvgColor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: applySvgColor
                      ? ColorFilter.mode(iconColor, BlendMode.srcIn)
                      : null,
                )
              : Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}
