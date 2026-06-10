import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/paper_contract_model.dart';

/// `/api/paper-contracts` REST 호출 모음.
///
/// 종이 계약서 사진을 업로드하면 서버에서 OCR + PDF 변환 후 채팅방에
/// CONTRACT 메시지를 자동 broadcast 한다. (백엔드 [PaperContractController])
class PaperContractService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('로그인 정보가 없습니다.');
    }
    return token;
  }

  // -------------------------------------------------------------------------
  // 1. 계약서 스캔 업로드 (multipart, images[])
  //    POST /api/paper-contracts/scan?roomId=&memberId=
  // -------------------------------------------------------------------------
  static Future<PaperContractScanResult> scan({
    required int roomId,
    required int memberId,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('이미지가 1장 이상 필요합니다.');
    }
    final token = await _getToken();
    final uri = Uri.parse(
      '${ApiEndpoints.paperScan}?roomId=$roomId&memberId=$memberId',
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';

    for (final imageFile in images) {
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

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      throw Exception('계약서 업로드 실패 (${streamed.statusCode}): $responseBody');
    }
    final decoded = jsonDecode(responseBody);
    if (decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '계약서 업로드 실패');
    }
    return PaperContractScanResult.fromJson(
      decoded['data'] as Map<String, dynamic>,
    );
  }

  // -------------------------------------------------------------------------
  // 2. 문서 단건 조회
  //    GET /api/paper-contracts/{documentId}?memberId=
  // -------------------------------------------------------------------------
  static Future<PaperContractDocumentModel> getDocument({
    required int documentId,
    required int memberId,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '${ApiEndpoints.paperDocument(documentId.toString())}?memberId=$memberId',
    );
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '계약서 조회 실패');
    }
    return PaperContractDocumentModel.fromJson(
      decoded['data'] as Map<String, dynamic>,
    );
  }

  // -------------------------------------------------------------------------
  // 3. 내 계약서 목록 (GET /api/paper-contracts/me)
  // -------------------------------------------------------------------------
  static Future<List<PaperContractDocumentModel>> getMyDocuments() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.myPaperContracts),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '내 계약서 목록 조회 실패');
    }
    final list = decoded['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            PaperContractDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // 내부 헬퍼
  // -------------------------------------------------------------------------
  static MediaType _imageContentTypeFor(File imageFile) {
    final path = imageFile.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (path.endsWith('.png')) return MediaType('image', 'png');
    if (path.endsWith('.heic')) return MediaType('image', 'heic');
    if (path.endsWith('.heif')) return MediaType('image', 'heif');
    if (path.endsWith('.webp')) return MediaType('image', 'webp');
    throw Exception('지원하지 않는 이미지 형식입니다: ${imageFile.path}');
  }
}
