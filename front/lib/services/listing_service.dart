import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sharehouse_detail_model.dart'; 
import '../models/listing_model.dart';

class ListingService {
  // [주의] 실제 서버 주소로 변경 필요 (에뮬레이터: 10.0.2.2, 실기기: PC IP)
  static const String _baseUrl = "https://trustay.digitalbasis.com";

  // 1. 매물 목록 조회 (GET)
  Future<List<MyListingItem>> fetchMyListings() async {
    final token = await _getToken();
    
    final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/my')
        .replace(queryParameters: {'page': '0', 'size': '10'});

    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);
      final List<dynamic> content = jsonResponse['data']['content'];
      return content.map((e) => MyListingItem.fromJson(e)).toList();
    } else {
      throw Exception('목록 조회 실패: ${response.body}');
    }
  }

  // 2. 매물 삭제 (DELETE)
  Future<bool> deleteListing(int houseId) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/trustay/sharehouses/$houseId');

    print('DEBUG: DELETE Request -> $url');

    final response = await http.delete(
      url,
      headers: _getHeaders(token),
    );

    print('DEBUG: DELETE Response Code -> ${response.statusCode}');

    if (response.statusCode == 200) {
      return true;
    } else {
      print('ERROR: 삭제 실패 -> ${response.body}');
      throw Exception('삭제에 실패했습니다.');
    }
  }

  // 3. 매물 수정 (PUT)
  // updateData는 수정할 필드들을 담은 Map입니다 (SharehouseUpdateReq DTO 대응)
  Future<bool> updateListing(int houseId, Map<String, dynamic> updateData) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/trustay/sharehouses/$houseId');

    final response = await http.put(
      url,
      headers: _getHeaders(token),
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('ERROR: 수정 실패 -> ${response.body}');
      throw Exception('수정에 실패했습니다.');
    }
  }

  Future<SharehouseDetail> getSharehouseDetail(int houseId) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/trustay/sharehouses/my/$houseId');

    final response = await http.get(
      url,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final jsonResponse = json.decode(decodedBody);
      
      // JSON 구조: { "data": { ...상세정보... } }
      return SharehouseDetail.fromJson(jsonResponse['data']);
    } else {
      throw Exception('상세 정보 조회 실패');
    }
  }

  // 내부 유틸: 토큰 가져오기
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) throw Exception('로그인이 필요합니다.');
    return token;
  }

  // 내부 유틸: 헤더 생성
  Map<String, String> _getHeaders(String token) {
    return {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}