import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 패키지 추가
import '../../models/chat_room_list_model.dart';

class ChatService {
  static const String baseUrl = 'https://trustay.digitalbasis.com';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // 로그인 시 저장한 키값 (SharehouseService와 동일하게 'token' 사용)
    final String? token = prefs.getString('token'); 

    if (token == null) {
      throw Exception('로그인 정보가 없습니다.');
    }
    return token;
  }

  // 2. 채팅방 목록 조회 (헤더에 토큰 추가)
  Future<List<ChatRoomListModel>> getMyChatRooms(int memberId) async {
    final url = Uri.parse('$baseUrl/api/chat/rooms/$memberId');
    
    try {
      // 토큰 가져오기
      String token = await _getToken();

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // [중요] JWT 토큰 추가
        },
      );

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);

        if (jsonResponse['data'] != null) {
          final List<dynamic> dataList = jsonResponse['data'];
          return dataList.map((json) => ChatRoomListModel.fromJson(json)).toList();
        }
        return [];
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception in getMyChatRooms: $e");
      return []; // 에러 발생 시 빈 리스트 반환
    }
  }
}
