import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/chat_room_list_model.dart';
import '../models/chat_message_model.dart';
import '../constants/api_endpoints.dart';

/// ============================================================
/// REST API: 채팅방 / 메시지
/// ============================================================
class ChatService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인 정보가 없습니다.');
    }
    return token;
  }

  /// 채팅방 생성/조회 (idempotent).
  ///
  /// 서버 응답 스키마 변경(2026-06-10):
  ///   기존: `data: number` (roomId 만)
  ///   신규: `data: { roomId, houseId }` (`ChatRoomCreateRes`)
  ///
  /// 따라서 본 메서드는 `(roomId, houseId)` 레코드를 그대로 반환한다.
  /// 화면 이동 후에도 별도 룩업 없이 `houseId` 를 보존할 수 있다.
  static Future<({int roomId, int houseId})> createOrGetChatRoom(
    int houseId,
    int senderId,
  ) async {
    final url = Uri.parse(ApiEndpoints.createRoom);

    print("🚀 [ChatService] 전송 데이터: houseId=$houseId, senderId=$senderId");

    try {
      final token = await _getToken();

      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"houseId": houseId, "senderId": senderId}),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        final dynamic data = jsonResponse['data'];

        // 신규 스키마: 객체 { roomId, houseId }
        if (data is Map<String, dynamic>) {
          final int parsedRoomId = (data['roomId'] as num?)?.toInt() ?? 0;
          final int parsedHouseId =
              (data['houseId'] as num?)?.toInt() ?? houseId;
          return (roomId: parsedRoomId, houseId: parsedHouseId);
        }
        // 구 스키마(숫자 단독) 하위 호환: roomId 만 내려옴 → 요청 시 보낸 houseId 사용
        if (data is num) {
          return (roomId: data.toInt(), houseId: houseId);
        }
        throw Exception('채팅방 생성 응답 파싱 실패: $data');
      } else {
        print("❌ 서버 응답 에러: ${response.body}");
        throw Exception('채팅방 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ 통신 에러: $e");
      throw Exception('에러 발생: $e');
    }
  }

  /// 내 채팅방 목록 (lastMessageTime 내림차순, 페이징)
  ///
  /// 백엔드는 PageResponse 로 응답한다 (`data.content[]`).
  /// 호환을 위해 List 응답도 함께 처리한다.
  static Future<List<ChatRoomListModel>> getMyChatRooms(
    int memberId, {
    int page = 0,
    int size = 10,
  }) async {
    final url = Uri.parse(
      ApiEndpoints.myChatRooms(memberId),
    ).replace(queryParameters: {'page': '$page', 'size': '$size'});

    final token = await _getToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('채팅방 목록 조회 실패: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);
    final dynamic data = jsonResponse['data'];
    if (data == null) return [];

    final List<dynamic> dataList = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    final rooms = dataList
        .map((json) => ChatRoomListModel.fromJson(json))
        .toList();

    // 서버 정렬을 신뢰하지 않고 클라이언트에서 한 번 더 정렬
    // (ISO-8601 문자열은 사전식 정렬해도 시간순과 동일하지만, 안전하게 DateTime으로 비교)
    rooms.sort((a, b) {
      final ta = _parseTimeOrNull(a.lastMessageTime);
      final tb = _parseTimeOrNull(b.lastMessageTime);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1; // 시간이 없는 방은 뒤로
      if (tb == null) return -1;
      return tb.compareTo(ta); // 내림차순
    });
    return rooms;
  }

  /// 채팅방 메시지 내역 (페이징)
  ///
  /// 서버는 `regTime DESC` 로 페이지를 잘라준다 (page 0 = 가장 최근 N개).
  /// UI 는 보통 과거→최신 순으로 화면에 쌓으므로, 본 메서드는 페이지 안에서
  /// 한 번 reverse 해서 "오래된→최신" 순서로 반환한다.
  /// 따라서 호출 측은 페이지를 위로 추가 로드할 때 받은 리스트를 기존 리스트
  /// **앞쪽**에 prepend 하면 자연스러운 순서가 유지된다.
  static Future<List<ChatMessageModel>> getChatHistory(
    int roomId,
    int memberId, {
    int page = 0,
    int size = 15,
  }) async {
    final url = Uri.parse(
      ApiEndpoints.chatRoomMessages(roomId, memberId),
    ).replace(queryParameters: {'page': '$page', 'size': '$size'});

    final token = await _getToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('채팅 내역 조회 실패: ${response.statusCode}');
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonResponse = jsonDecode(decodedBody);
    final dynamic data = jsonResponse['data'];
    if (data == null) return [];

    final List<dynamic> dataList = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);

    final messages = dataList
        .map((json) => ChatMessageModel.fromJson(json))
        .toList();
    // 서버는 최신→과거 순이므로 화면 표시용으로 뒤집어 과거→최신으로.
    return messages.reversed.toList();
  }

  /// 채팅방에 이미지 메시지 전송.
  ///
  /// `POST /api/chat/room/{roomId}/image?senderId={senderId}` (multipart/form-data).
  /// - form field: `image` (단일 파일)
  /// - 허용 확장자: jpg / jpeg / png / heic / heif, 최대 20MB
  ///
  /// 서버가 IMAGE 타입 ChatMessage 로 저장한 뒤 STOMP 구독 채널
  /// `/sub/chat/room/{roomId}` 로 자동 브로드캐스트한다. 따라서 호출 측은
  /// 별도의 WebSocket SEND 를 하지 않아도 되며, 동일한 구독 콜백으로
  /// 새 메시지가 수신된다. 응답 payload 도 동일한 `ChatMessageRes` 형식.
  static Future<ChatMessageModel> sendImageMessage({
    required int roomId,
    required int senderId,
    required File imageFile,
  }) async {
    final url = Uri.parse(ApiEndpoints.chatRoomImage(roomId, senderId));
    final token = await _getToken();

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // 명세상 단수
        imageFile.path,
        filename: fileName,
        contentType: _chatImageContentTypeFor(imageFile),
      ),
    );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('이미지 전송 실패: ${streamed.statusCode} $responseBody');
    }

    final decoded = jsonDecode(responseBody);
    final dynamic data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('이미지 전송 응답 파싱 실패: $data');
    }
    return ChatMessageModel.fromJson(data);
  }

  static MediaType _chatImageContentTypeFor(File imageFile) {
    final path = imageFile.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (path.endsWith('.png')) return MediaType('image', 'png');
    if (path.endsWith('.heic')) return MediaType('image', 'heic');
    if (path.endsWith('.heif')) return MediaType('image', 'heif');
    // 서버가 거부할 수도 있으나 기본값 fallback
    return MediaType('application', 'octet-stream');
  }

  /// 채팅방 나가기 (POST /api/chat/room/{roomId}/leave?memberId=)
  static Future<bool> leaveChatRoom(int roomId, int memberId) async {
    final url = Uri.parse(ApiEndpoints.leaveChatRoom(roomId, memberId));
    final token = await _getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('채팅방 나가기 실패: ${response.statusCode}');
    }
    return true;
  }

  /// 채팅방의 안 읽은 메시지를 한 번에 읽음 처리.
  ///
  /// - 채팅방 진입 직후: 서버가 [getChatHistory] 호출 시 자동 처리하므로
  ///   기본 흐름에서는 호출이 필수가 아니다.
  /// - 채팅방을 열어둔 상태에서 STOMP 로 새 메시지가 도착했을 때:
  ///   즉시 호출해 unread 뱃지를 0 으로 유지한다.
  ///
  /// 새로 읽음 처리된 메시지 수를 반환한다 (이미 모두 읽혀 있었으면 0).
  static Future<int> markRoomAsRead(int roomId, int memberId) async {
    final url = Uri.parse(ApiEndpoints.chatRoomRead(roomId, memberId));
    final token = await _getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('채팅 읽음 처리 실패: ${response.statusCode}');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['code'] != 200) {
        throw Exception(decoded['message'] ?? '채팅 읽음 처리 실패');
      }
      final updated =
          ((decoded['data'] as Map<String, dynamic>?)?['updated'] as num?)
                  ?.toInt() ??
              0;
      return updated;
    } catch (_) {
      // 본문 파싱 실패해도 statusCode 200 이면 성공으로 간주.
      return 0;
    }
  }

  static DateTime? _parseTimeOrNull(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      // 서버가 "Z" 없이 보내는 경우가 있어 UTC 처리 보강
      final str = s.endsWith('Z') ? s : '${s}Z';
      return DateTime.parse(str);
    } catch (_) {
      return null;
    }
  }
}

/// ============================================================
/// WebSocket(STOMP) 라이프사이클 서비스
/// connect / disconnect / reconnect / subscribe / unsubscribe / sendMessage
/// ============================================================
class ChatSocketService {
  StompClient? _client;
  String? _token;

  /// roomId → unsubscribe 함수 (stomp_dart_client subscribe 반환값)
  final Map<int, void Function({Map<String, String>? unsubscribeHeaders})>
  _subscriptions = {};

  /// onConnected: 연결 성공 후 호출 (구독 재설정 등)
  /// onError    : 연결/STOMP 에러 발생 시 호출
  /// autoReconnect: 끊김 시 자동 재연결 여부
  void Function()? _onConnected;
  void Function(String message)? _onError;
  bool _autoReconnect = true;
  bool _manualDisconnect = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool get isConnected => _client?.connected ?? false;

  /// WebSocket 연결
  Future<void> connect({
    required String token,
    void Function()? onConnected,
    void Function(String message)? onError,
    bool autoReconnect = true,
  }) async {
    _token = token;
    _onConnected = onConnected;
    _onError = onError;
    _autoReconnect = autoReconnect;
    _manualDisconnect = false;
    _reconnectAttempts = 0;

    // 백엔드가 SockJS이므로 StompConfig.sockJS 팩토리를 사용한다.
    // (raw WebSocket 모드인 StompConfig(url: 'ws://...')로는 400을 받는다)
    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiEndpoints.websocketEndpoint, // http(s)://host/ws-stomp
        onConnect: _handleConnect,
        onWebSocketError: (dynamic error) {
          final msg = '소켓 연결 에러: $error';
          print('❌ $msg');
          _onError?.call(msg);
          _scheduleReconnect();
        },
        onStompError: (StompFrame frame) {
          final msg = 'STOMP 에러: ${frame.body}';
          print('❌ $msg');
          _onError?.call(msg);
        },
        onDisconnect: (StompFrame frame) {
          print('⚠️ 소켓 연결 끊김');
          _scheduleReconnect();
        },
        // STOMP CONNECT 프레임에 토큰 포함 (SecurityConfig에서 STOMP 단계 인증)
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        // SockJS HTTP 핸드셰이크에 함께 보낼 헤더가 필요하면 webSocketConnectHeaders 사용
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
      ),
    );

    _client!.activate();
  }

  void _handleConnect(StompFrame frame) {
    _reconnectAttempts = 0;
    print('✅ 소켓 연결 성공');
    _onConnected?.call();
  }

  /// 수동 종료가 아니면 backoff로 재연결 시도
  void _scheduleReconnect() {
    if (_manualDisconnect || !_autoReconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _onError?.call('재연결 시도 한도 초과');
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    print(
      '🔁 ${delay.inSeconds}s 후 재연결 시도($_reconnectAttempts/$_maxReconnectAttempts)',
    );
    Future.delayed(delay, () {
      if (_manualDisconnect) return;
      reconnect();
    });
  }

  /// 명시적 재연결 (현재 연결을 끊고 새로 연결)
  Future<void> reconnect() async {
    if (_token == null) return;
    try {
      _client?.deactivate();
    } catch (_) {}
    _subscriptions.clear();
    await connect(
      token: _token!,
      onConnected: _onConnected,
      onError: _onError,
      autoReconnect: _autoReconnect,
    );
  }

  /// 방 구독 — 새 메시지 수신 시 onMessage 호출
  void subscribeRoom({
    required int roomId,
    required void Function(ChatMessageModel message) onMessage,
  }) {
    if (_client == null || !isConnected) {
      print('⚠️ 구독 실패: 소켓이 연결되어 있지 않음');
      return;
    }
    // 이미 구독 중이면 중복 방지
    unsubscribeRoom(roomId);

    final unsub = _client!.subscribe(
      destination: ApiEndpoints.stompSubscribeRoom(roomId),
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        try {
          final Map<String, dynamic> jsonBody = jsonDecode(frame.body!);
          final msg = ChatMessageModel.fromJson(jsonBody);
          onMessage(msg);
        } catch (e) {
          print('❌ 메시지 파싱 에러: $e');
        }
      },
    );
    _subscriptions[roomId] = unsub;
  }

  /// 방 구독 해제
  void unsubscribeRoom(int roomId) {
    final unsub = _subscriptions.remove(roomId);
    try {
      unsub?.call();
    } catch (_) {}
  }

  /// 메시지 전송: /pub/chat/send
  ///
  /// `messageType` 은 서버 Enum 과 일치해야 한다.
  ///   - `TEXT`     : 일반 텍스트
  ///   - `IMAGE`    : 이미지 업로드 후 받은 URL 을 `message` 에 담아 전송
  ///   - `CONTRACT` : 종이 계약서 스캔 후 받은 PDF URL 을 `message` 에 담아 전송
  bool sendMessage({
    required int roomId,
    required int senderId,
    required String message,
    String messageType = 'TEXT',
  }) {
    if (_client == null || !isConnected) {
      print('⚠️ 전송 실패: 소켓이 연결되어 있지 않음');
      return false;
    }
    if (message.trim().isEmpty) return false;

    _client!.send(
      destination: ApiEndpoints.stompPublishSend,
      body: jsonEncode({
        'roomId': roomId,
        'senderId': senderId,
        'message': message,
        'messageType': messageType,
      }),
      headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
    );
    return true;
  }

  /// 연결 종료 (자동 재연결 중지)
  void disconnect() {
    _manualDisconnect = true;
    for (final id in _subscriptions.keys.toList()) {
      unsubscribeRoom(id);
    }
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
  }
}
