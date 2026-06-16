import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/notification_service.dart';
import 'circle_icon_button.dart';

/// 종 아이콘 + 안 읽은 알림 개수 빨간 뱃지를 그리는 공통 위젯.
///
/// - 뱃지는 [NotificationService.unreadCountNotifier] 를 구독하므로
///   페이지 새로고침 없이도 즉시 반영된다.
/// - 기본 동작: 탭 시 [AppRoutes.notifications] 로 이동.
///   필요 시 [onPressed] 를 넘겨 동작을 덮어쓸 수 있다.
///
/// 호출 측은 home / community / 그 외 헤더에서 동일한 모양으로 재사용한다.
class NotificationBellButton extends StatelessWidget {
  /// 탭 동작 커스텀이 필요할 때 사용. 기본값은 알림 페이지로 push.
  final VoidCallback? onPressed;

  /// 종 SVG 아이콘 크기 (기본 22). 페이지 헤더 디자인에 맞춰 조정 가능.
  final double iconSize;

  /// 헤더 우측 정렬 여백 등에서 활용할 외부 패딩.
  final EdgeInsetsGeometry padding;

  const NotificationBellButton({
    super.key,
    this.onPressed,
    this.iconSize = 22,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCountNotifier,
      builder: (context, unread, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              svgAsset: 'assets/icons/bell.svg',
              iconSize: iconSize,
              padding: padding,
              onPressed: onPressed ??
                  () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            if (unread > 0)
              Positioned(
                right: padding is EdgeInsets
                    ? (padding as EdgeInsets).right + 2
                    : 2,
                top: 2,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
