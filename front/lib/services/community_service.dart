import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/community_member_model.dart';
import '../models/community_model.dart';
import '../models/search_model.dart';

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

  /// 토큰이 있으면 반환, 없으면 null. 비로그인 상태에서도 호출 가능한 API에 사용.
  static Future<String?> _tryGetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _authHeaders(String token) => {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// 토큰이 있으면 Bearer 헤더, 없으면 빈 헤더 (비로그인 허용 API에 사용).
  static Map<String, String> _maybeAuthHeaders(String? token) {
    if (token == null || token.isEmpty) {
      return const {'accept': '*/*'};
    }
    return {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    };
  }

  // -------------------------------------------------------------------------
  // 1. 커뮤니티 생성
  // -------------------------------------------------------------------------
  static Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? imageUrl,
    CommunityCategory? category,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.communitiesRoot),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode({
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (category != null) 'category': category.serverValue,
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
  //
  // - 로그인 상태에서 keyword 와 함께 호출하면 서버가 자동으로 최근 검색어에 기록.
  //   (그러므로 검색 화면에서는 반드시 인증 토큰을 함께 보낸다)
  // - 비로그인 / keyword 없는 호출도 그대로 동작한다 (단순 목록).
  // -------------------------------------------------------------------------
  static Future<List<CommunityModel>> fetchCommunities({
    String? keyword,
    int page = 0,
    int size = 10,
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
    final token = await _tryGetToken();
    final response = await http.get(uri, headers: _maybeAuthHeaders(token));
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
  //
  // 백엔드는 토큰이 있으면 **이미 가입한 커뮤니티는 제외**하고 멤버 수 내림차순으로
  // 반환한다. 비로그인 시에는 전체 커뮤니티를 멤버 수 내림차순으로 반환한다.
  // -------------------------------------------------------------------------
  static Future<List<CommunityModel>> fetchTrending({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _tryGetToken();
    final uri = Uri.parse(ApiEndpoints.communitiesTrending).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri, headers: _maybeAuthHeaders(token));
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
  // 4. 내가 만든 / 내가 가입한 커뮤니티 (페이징)
  // -------------------------------------------------------------------------
  static Future<List<CommunityModel>> fetchCreated({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.communitiesCreated).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri, headers: _authHeaders(token));
    return _parseList(response, '내가 만든 커뮤니티 조회 실패');
  }

  static Future<List<CommunityModel>> fetchJoined({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.communitiesJoined).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri, headers: _authHeaders(token));
    return _parseList(response, '가입 커뮤니티 조회 실패');
  }

  // -------------------------------------------------------------------------
  // 5. 단일 커뮤니티 상세
  //
  // 인증 토큰이 있으면 서버가 자동으로 "최근 본 커뮤니티"에 기록한다.
  // 비로그인 호출도 허용한다(기록만 생략).
  // -------------------------------------------------------------------------
  static Future<CommunityModel> fetchCommunity(int communityId) async {
    final token = await _tryGetToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.communityById(communityId)),
      headers: _maybeAuthHeaders(token),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '커뮤니티 상세 조회 실패');
    }
    return CommunityModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 5-1. 커뮤니티 멤버 목록 (페이징)
  // -------------------------------------------------------------------------
  static Future<List<CommunityMemberModel>> fetchMembers(
    int communityId, {
    int page = 0,
    int size = 10,
  }) async {
    final uri = Uri.parse(ApiEndpoints.communityMembers(communityId)).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final token = await _tryGetToken();
    final response = await http.get(uri, headers: _maybeAuthHeaders(token));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '커뮤니티 멤버 조회 실패');
    }
    final data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    return list
        .map((e) => CommunityMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
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

  /// 오너 전용: 멤버 강퇴.
  /// DELETE /api/trustay/communities/{communityId}/members/{memberId}
  static Future<void> kickMember(int communityId, int memberId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(
        '${ApiEndpoints.communityMembers(communityId)}/$memberId',
      ),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '멤버 강퇴 실패');
  }

  /// 오너 전용: 커뮤니티 정보 수정.
  ///
  /// 서버는 imageUrl 이 비어 있을 때 기존 이미지를 유지하고, 값이 있으면 새로 저장한다.
  /// 따라서 "이미지만 변경" 하려면 현재 [name], [description], [category] 를 그대로
  /// 넘기고 새 [imageUrl] 만 넣어 호출하면 된다.
  static Future<void> updateCommunity({
    required int communityId,
    required String name,
    String? description,
    String? imageUrl,
    CommunityCategory? category,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(ApiEndpoints.communityUpdate(communityId)),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode({
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (category != null) 'category': category.serverValue,
      })),
    );
    _ensureOk(response, '커뮤니티 수정 실패');
  }

  // -------------------------------------------------------------------------
  // 7. 삭제
  // -------------------------------------------------------------------------
  static Future<void> deleteCommunity(int communityId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.communityDelete(communityId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '커뮤니티 삭제 실패');
  }

  // -------------------------------------------------------------------------
  // 8. 최근 검색어 / 최근 본 커뮤니티 (검색 화면용)
  //
  // 백엔드 패턴: SharehouseRecentSearch 와 동일하게 검색(GET /communities?keyword=...)
  // 호출 시 자동 기록되고, 상세(GET /communities/{id}) 호출 시 최근본이 자동 기록된다.
  // 등록용 API 는 따로 없고, 조회/삭제만 있다.
  // -------------------------------------------------------------------------

  /// 최근 검색어 목록 (최신순). 미로그인/오류 시 빈 리스트로 폴백.
  static Future<List<SearchHistory>> fetchRecentSearches() async {
    final token = await _tryGetToken();
    if (token == null || token.isEmpty) return const <SearchHistory>[];
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.communitiesRecentSearches),
        headers: _maybeAuthHeaders(token),
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || decoded['code'] != 200) {
        return const <SearchHistory>[];
      }
      final data = decoded['data'];
      final List<dynamic> list = data is List ? data : const <dynamic>[];
      return list
          .map((e) => SearchHistory.fromApi(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <SearchHistory>[];
    }
  }

  /// 최근 검색어 1건 삭제 (칩의 X 버튼).
  static Future<void> deleteRecentSearch(int searchId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.communitiesRecentSearchById(searchId)),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '최근 검색어 삭제 실패');
  }

  /// 최근 검색어 전체 삭제 ("Delete all").
  static Future<void> deleteAllRecentSearches() async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.communitiesRecentSearches),
      headers: _authHeaders(token),
    );
    _ensureOk(response, '최근 검색어 일괄 삭제 실패');
  }

  /// 최근 본 커뮤니티 목록 (서버 자동 집계, 최신 5개). 미로그인/오류 시 빈 리스트.
  static Future<List<CommunityModel>> fetchRecentCommunities() async {
    final token = await _tryGetToken();
    if (token == null || token.isEmpty) return const <CommunityModel>[];
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.communitiesRecent),
        headers: _maybeAuthHeaders(token),
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || decoded['code'] != 200) {
        return const <CommunityModel>[];
      }
      final data = decoded['data'];
      final List<dynamic> list = data is List ? data : const <dynamic>[];
      return list
          .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <CommunityModel>[];
    }
  }

  // -------------------------------------------------------------------------
  // 내부 헬퍼
  // -------------------------------------------------------------------------
  /// 응답을 List 형태로 풀어 반환. 백엔드가 List<T> 또는 PageResponse<T>
  /// (`{ content: [...], ... }`) 어느 쪽으로 내려와도 안전하게 처리한다.
  static List<CommunityModel> _parseList(
    http.Response response,
    String failMessage,
  ) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? failMessage);
    }
    final data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
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
