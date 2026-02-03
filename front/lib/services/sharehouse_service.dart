import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front/models/sharehouse_create_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart'; // MIME 타입 확인
import 'package:http_parser/http_parser.dart'; // MediaType 사용

class SharehouseService {
  static const String baseUrl = 'https://trustay.digitalbasis.com/api/trustay';

  // 이미지 업로드
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('로그인 필요: 토큰 없음');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/sharehouses/images'),
      );

      // 이미지 파일들 추가 (Mime 타입 지정)
      for (var imageFile in imageFiles) {
        final mimeType = lookupMimeType(imageFile.path); // e.g. "image/jpeg"
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ),
        );
      }

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Status: ${response.statusCode}');
      print('Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final images = data['data'] as List<dynamic>?;
        if (images == null) return [];
        return images.map((e) => e.toString()).toList();
      } else {
        throw Exception('이미지 업로드 실패: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 오류 발생: $e');
    }
  }

  // 쉐어하우스 매물 등록
  static Future<bool> createSharehouse(SharehouseCreateRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('로그인 필요: 토큰 없음');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/trustay/sharehouses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('매물 등록 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('매물 등록 중 오류 발생: $e');
    }
  }
}
