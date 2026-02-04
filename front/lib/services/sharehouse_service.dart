import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// [중요] 프로젝트에 존재하는 모델 파일들을 모두 import 해주세요.
import '../models/sharehouse_create_model.dart'; // 등록 요청 모델
import '../models/sharehouse_model.dart'; // 홈 화면 목록용 모델
import '../models/listing_model.dart'; // 마이페이지 목록용 모델 (MyListingItem)
import '../models/sharehouse_detail_model.dart'; // 상세 조회용 모델

class SharehouseService {
  // API 기본 주소
  static const String _baseUrl = 'https://trustay.digitalbasis.com';

  // ------------------------------------------------------------------------
  // [공통] 내부 헬퍼 메서드
  // ------------------------------------------------------------------------

  // 토큰 가져오기
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 키 이름이 'token'인지 'accessToken'인지 확인 필요
    final String? token = prefs.getString('token');

    if (token == null) {
      throw Exception('로그인 정보가 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  // 기본 헤더 생성 (JSON Content-Type + Auth Token)
  static Map<String, String> _getHeaders(String token) {
    return {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ------------------------------------------------------------------------
  // 1. 이미지 업로드 (Multipart/form-data)
  // ------------------------------------------------------------------------
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/images');
      var request = http.MultipartRequest('POST', uri);

      // 이미지 파일 추가
      for (var imageFile in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('images', imageFile.path),
        );
      }

      // 필요한 경우 토큰 추가 (보안 설정에 따라 다름)
      final token = await _getToken();
      request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        // null 체크 후 안전하게 변환
        final urls = data['data'] as List<dynamic>? ?? [];
        return urls.whereType<String>().toList(); // null 제거 후 String만 변환
      } else {
        throw Exception('이미지 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 오류: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 2. 쉐어하우스 매물 등록 (POST)
  // ------------------------------------------------------------------------
  static Future<bool> createSharehouse(SharehouseCreateRequest request) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses');

      final response = await http.post(
        uri,
        headers: _getHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        throw Exception('매물 등록 실패: $decodedBody');
      }
    } catch (e) {
      throw Exception('매물 등록 중 오류: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 3. 홈 화면: 쉐어하우스 전체 목록 조회 (GET)
  // ------------------------------------------------------------------------
  static Future<List<SharehouseModel>> getSharehouseList(
    String filterType,
  ) async {
    try {
      final token = await _getToken();

      // 쿼리 파라미터 설정
      Map<String, String> queryParams = {'page': '0', 'size': '10'};

      // 필터 적용 ('ALL'이 아닐 경우 houseType 추가)
      if (filterType != 'ALL') {
        queryParams['houseType'] = filterType;
      }

      final uri = Uri.parse(
        '$_baseUrl/api/trustay/sharehouses',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        // 응답 구조: { "data": { "content": [...] } }
        final List<dynamic> content = jsonResponse['data']['content'];
        return content.map((e) => SharehouseModel.fromJson(e)).toList();
      } else {
        throw Exception('목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('홈 데이터 로드 중 오류: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 4. 마이페이지: 내가 등록한 매물 목록 조회 (GET)
  // ------------------------------------------------------------------------
  static Future<List<MyListingItem>> fetchMyListings() async {
    try {
      final token = await _getToken();

      final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/my').replace(
        queryParameters: {'page': '0', 'size': '10', 'sort': 'createdAt,desc'},
      );

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        final List<dynamic> content = jsonResponse['data']['content'];
        return content.map((e) => MyListingItem.fromJson(e)).toList();
      } else {
        throw Exception('내 매물 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('내 매물 로드 중 오류: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 5. 쉐어하우스 상세 정보 조회 (GET)
  // ------------------------------------------------------------------------
  static Future<SharehouseDetailModel> getSharehouseDetail(int houseId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/$houseId');

      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(decodedBody);

        // 응답 구조: { "data": { ...상세 정보... } }
        return SharehouseDetailModel.fromJson(jsonResponse['data']);
      } else {
        throw Exception('상세 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('상세 정보 로드 중 오류: $e');
    }
  }


 static Future<bool> toggleWish(int houseId) async {
  try {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/$houseId/wish');

    final response = await http.post(
      uri,
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);
      // 보내주신 JSON 구조: { "data": { "wished": true ... } }
      // 따라서 ['data']['wished']를 리턴해야 합니다.
      return decodedData['data']['wished'] ?? false;
    } else {
      throw Exception('찜하기 요청 실패');
    }
  } catch (e) {
    throw Exception('찜하기 오류: $e');
  }
}
  // ------------------------------------------------------------------------
  // 6. 쉐어하우스 정보 수정 (PUT)
  // ------------------------------------------------------------------------
  static Future<bool> updateListing(
    int houseId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/$houseId');

      final response = await http.put(
        uri,
        headers: _getHeaders(token),
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('수정 중 오류: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 7. 쉐어하우스 삭제 (DELETE)
  // ------------------------------------------------------------------------
  static Future<bool> deleteListing(int houseId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_baseUrl/api/trustay/sharehouses/$houseId');

      final response = await http.delete(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('삭제 중 오류: $e');
    }
  }
}
