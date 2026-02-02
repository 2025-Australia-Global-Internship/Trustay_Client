import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'circle_icon_button.dart';

enum BackButtonStyle { light, dark }

class CustomHeader extends StatelessWidget {
  /// 기본 옵션
  final bool showBack;
  final BackButtonStyle backButtonStyle;
  final double toolbarHeight;
  final double iconSize;

  /// 슬롯
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;
  final Widget? bottom;

  const CustomHeader({
    super.key,
    this.showBack = true,
    this.backButtonStyle = BackButtonStyle.light,
    this.toolbarHeight = kToolbarHeight,
    this.iconSize = 48,
    this.leading,
    this.center,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    final isDark = backButtonStyle == BackButtonStyle.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 상단 툴바 영역
          SizedBox(
            height: toolbarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Leading
                Positioned(
                  left: 0,
                  child:
                      leading ??
                      (showBack && canGoBack
                          ? CircleIconButton(
                              padding: EdgeInsets.only(left: 16),
                              icon: Icons.arrow_back_ios_rounded,
                              iconColor: isDark ? Colors.white : dark,
                              backgroundColor: isDark
                                  ? Colors.transparent
                                  : Colors.white,
                              borderColor: isDark ? Colors.white : null,
                              elevation: isDark ? 0 : 4,
                              size: iconSize,
                              onPressed: () => Navigator.pop(context),
                            )
                          : const SizedBox()),
                ),

                // Center
                if (center != null) Center(child: center!),

                // Trailing
                if (trailing != null) Positioned(right: 16, child: trailing!),
              ],
            ),
          ),

          /// 확장 영역 (프로필 / 검색 / 탭 등)
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
