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
    this.elevation = 4,
    this.padding = EdgeInsets.zero,
    this.applySvgColor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: backgroundColor,
          shape: CircleBorder(
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: borderWidth)
                : BorderSide.none,
          ),
          elevation: elevation,
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
      ),
    );
  }
}
