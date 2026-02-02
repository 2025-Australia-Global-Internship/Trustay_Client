import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front/models/sharehouse_create_model.dart';

class SharehouseService {
  static const String baseUrl = 'YOUR_API_BASE_URL'; // API base URL로 변경하세요

  // 이미지 업로드
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/trustay/sharehouses/images'),
      );

      // 이미지 파일들 추가
      for (var imageFile in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('images', imageFile.path),
        );
      }

      // TODO: 인증 토큰 추가
      // request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return List<String>.from(data['data']);
      } else {
        throw Exception('이미지 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 오류 발생: $e');
    }
  }

  // 쉐어하우스 매물 등록
  static Future<bool> createSharehouse(SharehouseCreateRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trustay/sharehouses'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: 인증 토큰 추가
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('매물 등록 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('매물 등록 중 오류 발생: $e');
    }
  }
}
