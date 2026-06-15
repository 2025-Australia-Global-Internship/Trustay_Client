import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/review_model.dart';

/// `/api/trustay/reviews` 호출 모음.
///
/// - createReview         : 매물 거주 이력(ACTIVE/EXPIRED 계약) 보유자만 작성
/// - getHouseReviews      : 매물의 리뷰 페이지 (최신순)
/// - getTopHouseReviews   : 매물 상세 페이지 미리보기용 (별점 높은 순, 기본 3건)
/// - getHouseRatingSummary: 평균 평점/개수
/// - deleteReview         : 본인 리뷰 삭제
class ReviewService {
  static Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('token');
    if (t == null) throw Exception('Not signed in.');
    return t;
  }

  /// 리뷰 작성. content 는 nullable(미입력 가능)이지만 보통은 함께 보낸다.
  static Future<ReviewModel> createReview({
    required int houseId,
    required int rating,
    String? content,
  }) async {
    final token = await _token();
    final response = await http.post(
      Uri.parse(ApiEndpoints.reviewsRoot),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: utf8.encode(jsonEncode({
        'houseId': houseId,
        'rating': rating,
        if (content != null) 'content': content,
      })),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final code = decoded['code'];
    if (response.statusCode != 200 || code != 200) {
      throw Exception(decoded['message'] ?? 'Failed to create review');
    }
    return ReviewModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// 매물 리뷰 목록 (페이징, 최신순).
  static Future<List<ReviewModel>> getHouseReviews(
    int houseId, {
    int page = 0,
    int size = 10,
  }) async {
    final token = await _token();
    final uri = Uri.parse(ApiEndpoints.houseReviews(houseId)).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to load reviews');
    }
    final data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
            ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
            : const <dynamic>[]);
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 매물 상세 페이지 미리보기용 top-N (별점 높은 순). 기본 3건.
  /// 미로그인 등 실패 시 빈 리스트를 반환해 화면이 끊기지 않게 한다.
  static Future<List<ReviewModel>> getTopHouseReviews(
    int houseId, {
    int limit = 3,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse(ApiEndpoints.houseTopReviews(houseId, limit: limit)),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) return const <ReviewModel>[];
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded['code'] != 200) return const <ReviewModel>[];
      final List<dynamic> list = (decoded['data'] as List<dynamic>?) ?? const <dynamic>[];
      return list
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <ReviewModel>[];
    }
  }

  /// 평균 평점/리뷰 개수. 실패 시 0/0 폴백.
  static Future<RatingSummary> getHouseRatingSummary(int houseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse(ApiEndpoints.houseReviewSummary(houseId)),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) return RatingSummary.empty;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded['code'] != 200) return RatingSummary.empty;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return RatingSummary.empty;
      return RatingSummary.fromJson(data);
    } catch (_) {
      return RatingSummary.empty;
    }
  }

  /// 내가 작성한 리뷰 목록 (최신순, 페이징).
  ///
  /// `/api/trustay/reviews/me` 응답은 `PageResponse<ReviewRes>` 형태이므로
  /// `data.content[]` 로 접근. 호환을 위해 list 응답도 함께 처리.
  static Future<List<ReviewModel>> getMyReviews({
    int page = 0,
    int size = 20,
  }) async {
    final token = await _token();
    final uri = Uri.parse(ApiEndpoints.myReviews).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to load my reviews');
    }
    final dynamic data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
            ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
            : const <dynamic>[]);
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 본인 리뷰 삭제.
  static Future<void> deleteReview(int reviewId) async {
    final token = await _token();
    final response = await http.delete(
      Uri.parse(ApiEndpoints.reviewById(reviewId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to delete review');
    }
  }
}
