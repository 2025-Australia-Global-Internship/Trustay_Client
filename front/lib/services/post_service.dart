import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/post_model.dart';

/// `/api/trustay/posts` REST 호출 모음.
///
/// 백엔드 [PostController] 와 1:1 매핑. (UI 작업은 분리)
class PostService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인 정보가 없습니다.');
    }
    return token;
  }

  static Map<String, String> _authHeaders(String token) => {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // 1. 작성
  static Future<PostModel> createPost({
    int? communityId,
    int? sharehouseId,
    required String title,
    required String content,
    bool isNotice = false,
    List<String>? imageUrls,
  }) async {
    final token = await _getToken();
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'isNotice': isNotice,
    };
    if (communityId != null) body['communityId'] = communityId;
    if (sharehouseId != null) body['sharehouseId'] = sharehouseId;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      body['imageUrls'] = imageUrls;
    }

    final response = await http.post(
      Uri.parse(ApiEndpoints.postsRoot),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode(body)),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '게시글 작성 실패');
    }
    return PostModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // 2. 상세
  static Future<PostModel> getPost(int postId) async {
    final response = await http.get(Uri.parse(ApiEndpoints.postById(postId)));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '게시글 조회 실패');
    }
    return PostModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // 3. 커뮤니티별 / 쉐어하우스별 / 피드 / 내가 쓴 글
  static Future<List<PostModel>> getCommunityPosts(
    int communityId, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet(
        Uri.parse(ApiEndpoints.postsByCommunity(communityId))
            .replace(queryParameters: {'page': '$page', 'size': '$size'}),
      );

  static Future<List<PostModel>> getSharehousePosts(
    int sharehouseId, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet(
        Uri.parse(ApiEndpoints.postsBySharehouse(sharehouseId))
            .replace(queryParameters: {'page': '$page', 'size': '$size'}),
      );

  static Future<List<PostModel>> getFeed({int page = 0, int size = 20}) =>
      _pagedGet(
        Uri.parse(ApiEndpoints.postsFeed)
            .replace(queryParameters: {'page': '$page', 'size': '$size'}),
      );

  static Future<List<PostModel>> getMyPosts({
    int page = 0,
    int size = 20,
  }) async {
    final token = await _getToken();
    return _pagedGet(
      Uri.parse(ApiEndpoints.myPosts)
          .replace(queryParameters: {'page': '$page', 'size': '$size'}),
      headers: _authHeaders(token),
    );
  }

  // 4. 수정 / 삭제
  static Future<void> updatePost({
    required int postId,
    String? title,
    String? content,
    bool? isNotice,
    List<String>? imageUrls,
  }) async {
    final token = await _getToken();
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (isNotice != null) body['isNotice'] = isNotice;
    if (imageUrls != null) body['imageUrls'] = imageUrls;

    final response = await http.put(
      Uri.parse(ApiEndpoints.postById(postId)),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode(body)),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '게시글 수정 실패');
    }
  }

  static Future<void> deletePost(int postId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.postById(postId)),
      headers: _authHeaders(token),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '게시글 삭제 실패');
    }
  }

  // 5. 좋아요 토글 → 새 상태/카운트 반환
  static Future<({bool liked, int likeCount})> toggleLike(int postId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.postLike(postId)),
      headers: _authHeaders(token),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '좋아요 처리 실패');
    }
    final data = (decoded['data'] as Map<String, dynamic>?) ?? const {};
    final liked = (data['liked'] as bool?) ?? false;
    final count = (data['likeCount'] is num)
        ? (data['likeCount'] as num).toInt()
        : 0;
    return (liked: liked, likeCount: count);
  }

  // -------------------------------------------------------------------------
  // 내부 헬퍼: PageResponse<PostRes>를 List로 펴서 반환
  // -------------------------------------------------------------------------
  static Future<List<PostModel>> _pagedGet(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(uri, headers: headers);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '게시글 목록 조회 실패');
    }
    final data = decoded['data'];
    final List<dynamic> content = data is List
        ? data
        : (data['content'] as List<dynamic>? ?? []);
    return content
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
