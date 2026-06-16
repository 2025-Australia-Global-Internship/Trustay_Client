/// 서버 [NotificationType] 와 1:1 매핑.
///
/// - CHAT      : 새 채팅 메시지
/// - PAYMENT   : 결제 완료 / 입금 확인
/// - APPROVAL  : 매물 승인 / 거절
/// - COMMUNITY : 커뮤니티 가입 / 공지
/// - SYSTEM    : 일반 시스템 알림
enum NotificationType {
  chat,
  payment,
  approval,
  community,
  system;

  static NotificationType fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'CHAT':
        return NotificationType.chat;
      case 'PAYMENT':
        return NotificationType.payment;
      case 'APPROVAL':
        return NotificationType.approval;
      case 'COMMUNITY':
        return NotificationType.community;
      case 'SYSTEM':
      default:
        return NotificationType.system;
    }
  }

  /// 서버에 다시 보낼 때 쓰는 대문자 표현.
  String get serverValue {
    switch (this) {
      case NotificationType.chat:
        return 'CHAT';
      case NotificationType.payment:
        return 'PAYMENT';
      case NotificationType.approval:
        return 'APPROVAL';
      case NotificationType.community:
        return 'COMMUNITY';
      case NotificationType.system:
        return 'SYSTEM';
    }
  }
}

/// 서버 [NotificationRes] 와 1:1 매핑되는 클라이언트 모델.
class NotificationModel {
  final int id;
  final NotificationType type;
  final String title;
  final String? body;

  /// 클릭 시 이동할 in-app 라우트 (예: "/sharehouse/12", "/chat/room/3")
  final String? linkUrl;
  final bool isRead;

  /// 서버가 내려주는 ISO 8601 문자열 그대로 보관.
  /// (예: "2025-12-01T10:32:11")
  final String regTime;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.linkUrl,
    required this.isRead,
    required this.regTime,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      type: NotificationType.fromString(json['type'] as String?),
      title: (json['title'] as String?) ?? '',
      body: json['body'] as String?,
      linkUrl: json['linkUrl'] as String?,
      isRead: (json['isRead'] as bool?) ?? false,
      regTime: (json['regTime'] as String?) ?? '',
    );
  }

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      linkUrl: linkUrl,
      isRead: isRead ?? this.isRead,
      regTime: regTime,
    );
  }
}

/// 서버 [DeviceType] 와 1:1 매핑.
enum NotificationDeviceType {
  android,
  ios,
  web;

  String get serverValue {
    switch (this) {
      case NotificationDeviceType.android:
        return 'ANDROID';
      case NotificationDeviceType.ios:
        return 'IOS';
      case NotificationDeviceType.web:
        return 'WEB';
    }
  }
}
