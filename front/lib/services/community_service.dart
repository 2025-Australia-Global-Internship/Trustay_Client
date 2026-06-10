import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/community_model.dart';

/// `/api/trustay/communities` REST 호출 모음.
///
/// 백엔드 [CommunityController]와 1:1 매핑된다. 화면(UI)은 별도로 작업해야 하며
/// 이 클래스는 데이터 호출 책임만 진다.
class CommunityService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  static Map<String, String> _authHeaders(String token) => {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // -------------------------------------------------------------------------
  // 1. 커뮤니티 생성
  // -------------------------------------------------------------------------
  static Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.communitiesRoot),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
      })),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '커뮤니티 생성 실패');
    }
    return CommunityModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 2. 커뮤니티 목록 (검색)
  // -------------------------------------------------------------------------
  static Future<List<CommunityModel>> fetchCommunities({
    String? keyword,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    final Map<String, String> qp = {
      'page': '$page',
      'size': '$size',
    };
    if (keyword != null && keyword.trim().isNotEmpty) {
      qp['keyword'] = keyword.trim();
    }
    if (sort != null && sort.isNotEmpty) qp['sort'] = sort;

    final uri =
        Uri.parse(ApiEndpoints.communitiesRoot).replace(queryParameters: qp);
    final response = await http.get(uri);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '커뮤니티 목록 조회 실패');
    }
    final data = decoded['data'];
    final List<dynamic> content = data is List
        ? data
        : (data['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // 3. 인기 커뮤니티
  // -------------------------------------------------------------------------
  static Future<List<CommunityModel>> fetchTrending({
    int page = 0,
    int size = 10,
  }) async {
    final uri = Uri.parse(ApiEndpoints.communitiesTrending).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '인기 커뮤니티 조회 실패');
    }
    final data = decoded['data'];
    final List<dynamic> content = data is List
        ? data
        : (data['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // 4. 내가 만든 / 내가 가입한 커뮤니티
  // -------------------------------------------------------------------------
  static Future<List<CommunityModel>> fetchCreated() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.communitiesCreated),
      headers: _authHeaders(token),
    );
    return _parseList(response, '내가 만든 커뮤니티 조회 실패');
  }

  static Future<List<CommunityModel>> fetchJoined() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.communitiesJoined),
      headers: _authHeaders(token),
    );
    return _parseList(response, '가입 커뮤니티 조회 실패');
  }

  // -------------------------------------------------------------------------
  // 5. 단일 커뮤니티 상세
  // -------------------------------------------------------------------------
  static Future<CommunityModel> fetchCommunity(int communityId) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.communityById(communityId)),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '커뮤니티 상세 조회 실패');
    }
    return CommunityModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 6. 가입 / 탈퇴
  // -------------------------------------------------------------------------
  static Future<void> join(int communityId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.communityJoin(communityId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '커뮤니티 가입 실패');
  }

  static Future<void> leave(int communityId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.communityLeave(communityId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '커뮤니티 탈퇴 실패');
  }

  // -------------------------------------------------------------------------
  // 7. 수정 / 삭제
  // -------------------------------------------------------------------------
  static Future<void> updateCommunity({
    required int communityId,
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(ApiEndpoints.communityUpdate(communityId)),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
      })),
    );
    _ensureOk(response, '커뮤니티 수정 실패');
  }

  static Future<void> deleteCommunity(int communityId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.communityDelete(communityId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '커뮤니티 삭제 실패');
  }

  // -------------------------------------------------------------------------
  // 내부 헬퍼
  // -------------------------------------------------------------------------
  static List<CommunityModel> _parseList(
    http.Response response,
    String failMessage,
  ) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? failMessage);
    }
    final data = decoded['data'];
    final List<dynamic> list = data is List ? data : <dynamic>[];
    return list
        .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static void _ensureOk(http.Response response, String failMessage) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? failMessage);
    }
  }
}
