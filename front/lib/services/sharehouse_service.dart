import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [중요] 프로젝트에 존재하는 모델 파일들을 모두 import 해주세요.
import '../models/sharehouse_create_model.dart'; // 등록 요청 모델
import '../models/sharehouse_model.dart'; // 홈 화면 목록용 모델
import '../models/listing_model.dart'; // 마이페이지 목록용 모델 (MyListingItem)
import '../models/sharehouse_detail_model.dart'; // 상세 조회용 모델

import '../constants/api_constants.dart';

class SharehouseService {
  // baseUrl is provided by ApiConstants
  static const String _apiBase = '${ApiConstants.baseUrl}/api/trustay';

  // ------------------------------------------------------------------------
  // [공통] 내부 헬퍼 메서드
  // ------------------------------------------------------------------------

  // 토큰 가져오기
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 키 이름이 'token'인지 'accessToken'인지 확인 필요
    final String? token = prefs.getString('token');
    print('토큰: $token');

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

  static MediaType _imageContentTypeFor(File imageFile) {
    final path = imageFile.path.toLowerCase();

    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (path.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (path.endsWith('.heic')) {
      return MediaType('image', 'heic');
    }
    if (path.endsWith('.heif')) {
      return MediaType('image', 'heif');
    }

    throw Exception('지원하지 않는 이미지 형식입니다: ${imageFile.path}');
  }

  // ------------------------------------------------------------------------
  // 1. 이미지 업로드 (Multipart/form-data)
  // ------------------------------------------------------------------------
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$_apiBase/sharehouses/images');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      for (var imageFile in imageFiles) {
        final fileName = imageFile.path.split(Platform.pathSeparator).last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
            filename: fileName,
            contentType: _imageContentTypeFor(imageFile),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final urls = data['data'] as List<dynamic>? ?? [];
        return urls.whereType<String>().toList();
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
      final uri = Uri.parse('$_apiBase/sharehouses');

      final bodyJson = jsonEncode(request.toJson());
      print('📤 URL: $uri');
      print('📤 Body: $bodyJson'); // ← 바디 내용 확인

      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: utf8.encode(bodyJson),
      );

      print('📥 status: ${response.statusCode}');
      print('📥 body: ${response.body}');
      print('📥 headers: ${response.headers}'); // ← 응답 헤더 확인

      return response.statusCode == 200;
    } catch (e, stack) {
      print('❌ 에러: $e');
      print('❌ 스택: $stack');
      throw Exception('매물 등록 중 오류: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 3. 홈 화면: 쉐어하우스 전체 목록 조회 (GET)
  // ------------------------------------------------------------------------
  static Future<List<SharehouseModel>> fetchAllHouses({
    String? houseType,
    String? keyword,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (houseType != null && houseType != 'ALL') {
        queryParams['houseType'] = houseType;
      }
      if (keyword != null && keyword.trim().isNotEmpty) {
        queryParams['keyword'] = keyword.trim();
      }

      final uri = Uri.parse(
        '$_apiBase/sharehouses',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decodedData['data'];

        // data가 List면 바로 사용, Map이면 content 키로 꺼내기
        final List<dynamic> list = data is List
            ? data
            : (data['content'] as List<dynamic>? ?? []);

        return list.map((json) => SharehouseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load houses');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 4. 마이페이지: 내가 등록한 매물 목록 조회 (GET)
  // ------------------------------------------------------------------------
  static Future<List<MyListingItem>> fetchMyListings() async {
    try {
      final token = await _getToken();

      final uri = Uri.parse('$_apiBase/sharehouses/my').replace(
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
      final uri = Uri.parse('$_apiBase/sharehouses/$houseId');

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
      final uri = Uri.parse('$_apiBase/sharehouses/$houseId/wish');

      final response = await http.post(uri, headers: _getHeaders(token));

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
      final uri = Uri.parse('$_apiBase/sharehouses/$houseId');

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
      final uri = Uri.parse('$_apiBase/sharehouses/$houseId');

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
