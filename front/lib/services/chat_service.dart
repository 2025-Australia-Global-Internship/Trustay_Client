import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_room_list_model.dart';
import '../models/chat_message_model.dart';

class ChatService {
  static const String baseUrl = 'https://trustay.digitalbasis.com';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인 정보가 없습니다.');
    }
    return token;
  }

  // [수정됨] hostId 파라미터 제거 (CURL 예시 준수)
  static Future<int> createOrGetChatRoom(int houseId, int senderId) async {
    final url = Uri.parse('$baseUrl/api/chat/room');
    
    // 로그로 데이터 확인
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
        body: jsonEncode({
          "houseId": houseId,
          "senderId": senderId, // 현재 로그인한 유저 ID
          // hostId 제거함 (서버 에러 원인 추정)
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        return jsonResponse['data']; // roomId
      } else {
        print("❌ 서버 응답 에러: ${response.body}");
        throw Exception('채팅방 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ 통신 에러: $e");
      throw Exception('에러 발생: $e');
    }
  }

  // ... (나머지 메서드 getMyChatRooms, getChatHistory는 그대로 유지) ...
  static Future<List<ChatRoomListModel>> getMyChatRooms(int memberId) async {
    final url = Uri.parse('$baseUrl/api/chat/rooms/$memberId');
    try {
      String token = await _getToken();
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        if (jsonResponse['data'] != null) {
           final List<dynamic> dataList = jsonResponse['data'];
           return dataList.map((json) => ChatRoomListModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<ChatMessageModel>> getChatHistory(int roomId, int memberId) async {
    final url = Uri.parse('$baseUrl/api/chat/room/$roomId/messages/$memberId');
    try {
      String token = await _getToken();
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        if (jsonResponse['data'] != null) {
          final List<dynamic> dataList = jsonResponse['data'];
          return dataList.map((json) => ChatMessageModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}