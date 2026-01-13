import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';

class IconPrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  final double height;
  final double fontSize;
  final EdgeInsets padding;

  const IconPrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.height = 40,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: dark,
          elevation: 0,
          padding: padding,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'NanumSquareNeo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
