import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/notification_model.dart';

/// `/api/trustay/notifications` REST 호출 모음.
///
/// 서버 컨트롤러: `com.maritel.trustay.controller.NotificationController`
/// - 알림 목록 / 안 읽음 개수 / 읽음 처리 / 삭제 / FCM 토큰 등록·해제
///
/// 다른 서비스(`AuthService`, `CommunityService` …) 와 동일한 패턴으로
/// SharedPreferences 의 `token` 을 Bearer 토큰으로 사용한다.
class NotificationService {
  // ---------------------------------------------------------------------------
  // 안 읽은 알림 개수 전역 캐시
  //
  // 종 아이콘의 빨간 뱃지가 화면 새로고침 없이도 즉시 반영되도록 단순한
  // ValueNotifier 로 노출한다. 알림 페이지에서 mark-as-read / mark-all-read /
  // delete 가 일어나면 그때마다 값을 새로 받아 갱신해주는 것을 권장한다.
  // ---------------------------------------------------------------------------
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  static Future<String?> _tryGetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _authHeaders(String token) => {
    'accept': '*/*',
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // 1) 알림 목록 (페이지네이션)
  //
  // 서버는 PageResponse<NotificationRes> 를 내려주며 page/size/sort 쿼리를
  // 받는다 (기본 sort = regTime,desc).
  // ---------------------------------------------------------------------------
  static Future<NotificationPage> fetchNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.notificationsRoot).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );

    final response = await http.get(uri, headers: _authHeaders(token));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '알림 목록 조회 실패');
    }

    final data = decoded['data'];
    if (data == null) {
      return const NotificationPage(items: [], page: 0, totalPages: 0,
          totalElements: 0, isLast: true);
    }

    if (data is List) {
      final items = data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return NotificationPage(
        items: items,
        page: page,
        totalPages: 1,
        totalElements: items.length,
        isLast: true,
      );
    }

    final map = data as Map<String, dynamic>;
    final List<dynamic> content =
        (map['content'] as List<dynamic>?) ?? const <dynamic>[];
    return NotificationPage(
      items: content
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (map['page'] as num?)?.toInt() ?? page,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (map['totalElements'] as num?)?.toInt() ?? 0,
      isLast: (map['last'] as bool?) ?? (map['isLast'] as bool?) ?? true,
    );
  }

  // ---------------------------------------------------------------------------
  // 2) 안 읽은 알림 개수
  // ---------------------------------------------------------------------------
  static Future<int> fetchUnreadCount() async {
    final token = await _tryGetToken();
    if (token == null || token.isEmpty) {
      unreadCountNotifier.value = 0;
      return 0;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.notificationsUnreadCount),
        headers: _authHeaders(token),
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || decoded['code'] != 200) {
        return unreadCountNotifier.value;
      }
      final count = ((decoded['data'] as Map<String, dynamic>?)?['unreadCount']
              as num?)
          ?.toInt() ??
          0;
      unreadCountNotifier.value = count;
      return count;
    } catch (_) {
      return unreadCountNotifier.value;
    }
  }

  // ---------------------------------------------------------------------------
  // 3) 단건 읽음 처리
  // ---------------------------------------------------------------------------
  static Future<void> markAsRead(int notificationId) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiEndpoints.notificationsRead(notificationId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '알림 읽음 처리 실패');

    // 읽음 처리되면 안 읽은 개수가 줄어들 수 있으므로 캐시 보정 후
    // 서버 값을 다시 조회해 정합성을 맞춘다.
    final current = unreadCountNotifier.value;
    if (current > 0) unreadCountNotifier.value = current - 1;
    await fetchUnreadCount();
  }

  // ---------------------------------------------------------------------------
  // 4) 전체 읽음 처리
  // ---------------------------------------------------------------------------
  static Future<int> markAllRead() async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.notificationsReadAll),
      headers: _authHeaders(token),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '전체 읽음 처리 실패');
    }
    final updated =
        ((decoded['data'] as Map<String, dynamic>?)?['updated'] as num?)
                ?.toInt() ??
            0;
    unreadCountNotifier.value = 0;
    return updated;
  }

  // ---------------------------------------------------------------------------
  // 5) 알림 삭제
  // ---------------------------------------------------------------------------
  static Future<void> deleteNotification(int notificationId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.notificationById(notificationId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '알림 삭제 실패');
    // 삭제한 알림이 안 읽은 상태였을 수도 있으므로 카운트를 재조회.
    await fetchUnreadCount();
  }

  // ---------------------------------------------------------------------------
  // 6) FCM 디바이스 토큰 등록 / 해제
  //
  // 실제 FCM 토큰 발급은 `firebase_messaging` 패키지를 추가한 뒤
  // `FirebaseMessaging.instance.getToken()` 으로 얻는다 (현재 pubspec 미포함).
  // 이 메서드들은 토큰 문자열을 받아 서버에 단순 전송만 담당한다.
  // ---------------------------------------------------------------------------
  static Future<void> registerFcmToken(
    String token, {
    NotificationDeviceType? deviceType,
  }) async {
    if (token.isEmpty) {
      throw ArgumentError('FCM 토큰이 비어 있습니다.');
    }
    final auth = await _getToken();
    final type = deviceType ?? _detectDeviceType();
    final response = await http.post(
      Uri.parse(ApiEndpoints.notificationsFcmToken),
      headers: _authHeaders(auth),
      body: jsonEncode({
        'token': token,
        'deviceType': type.serverValue,
      }),
    );
    _ensureOk(response, 'FCM 토큰 등록 실패');
  }

  static Future<void> removeFcmToken(String token) async {
    if (token.isEmpty) return;
    final auth = await _getToken();
    final uri = Uri.parse(ApiEndpoints.notificationsFcmToken)
        .replace(queryParameters: {'token': token});
    final response = await http.delete(uri, headers: _authHeaders(auth));
    _ensureOk(response, 'FCM 토큰 제거 실패');
  }

  // ---------------------------------------------------------------------------
  // 내부 헬퍼
  // ---------------------------------------------------------------------------
  static NotificationDeviceType _detectDeviceType() {
    if (kIsWeb) return NotificationDeviceType.web;
    try {
      if (Platform.isAndroid) return NotificationDeviceType.android;
      if (Platform.isIOS) return NotificationDeviceType.ios;
    } catch (_) {
      // dart:io 가 동작하지 않는 환경 (ex. 일부 테스트) → web 으로 폴백
    }
    return NotificationDeviceType.web;
  }

  static void _ensureOk(http.Response response, String failMessage) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw Exception('$failMessage (응답 파싱 실패)');
    }
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? failMessage);
    }
  }
}

/// 알림 목록 페이지 조회 결과.
class NotificationPage {
  final List<NotificationModel> items;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  const NotificationPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
  });
}
