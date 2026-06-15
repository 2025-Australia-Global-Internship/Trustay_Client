import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/contract_model.dart';

/// `/api/contracts` REST 호출 모음.
///
/// - propose : 한쪽이 계약 조건 + 본인 서명 이미지로 제안 (multipart)
/// - sign    : 상대방이 본인 서명 이미지로 서명 (multipart). 양측 서명되면 ACTIVE
/// - getById : 단건 조회
/// - getMy   : 내가 참여한 계약 목록
class ContractService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Not signed in.');
    }
    return token;
  }

  /// 계약 제안. `signaturePng` 는 캔버스에서 캡쳐한 PNG 바이트.
  ///
  /// `iAm` 은 `LANDLORD` 또는 `TENANT` 만 허용. 일반적으로 sharehouse 의 host 면
  /// LANDLORD 를, 입주를 원하는 쪽이면 TENANT 를 보낸다.
  static Future<ContractModel> propose({
    required int roomId,
    int? paperContractDocumentId,
    required String iAm, // 'LANDLORD' | 'TENANT'
    required int deposit,
    required int monthlyRent,
    required String startDate, // yyyy-MM-dd
    required String endDate,
    required Uint8List signaturePng,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.contractPropose);

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';

    // 백엔드의 ContractController.propose 는 ContractProposeReq 를 @ModelAttribute
    // 로 받기 때문에 (JSON 파트가 아니라) multipart form **fields** 로 보내야 한다.
    // 빠진 필드가 있으면 @NotNull 검증에서 모두 거부되고 code=4000, data={} 로 떨어진다.
    request.fields['roomId'] = roomId.toString();
    request.fields['iAm'] = iAm;
    request.fields['deposit'] = deposit.toString();
    request.fields['monthlyRent'] = monthlyRent.toString();
    request.fields['startDate'] = startDate;
    request.fields['endDate'] = endDate;
    if (paperContractDocumentId != null) {
      request.fields['paperContractDocumentId'] =
          paperContractDocumentId.toString();
    }

    request.files.add(http.MultipartFile.fromBytes(
      'signature',
      signaturePng,
      filename: 'signature.png',
      contentType: MediaType('image', 'png'),
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Failed to send proposal (${streamed.statusCode}): $body');
    }
    final decoded = jsonDecode(body);
    if (decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to send proposal');
    }
    return ContractModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// 상대방 서명. PNG 바이트 업로드.
  static Future<ContractModel> sign({
    required int contractId,
    required Uint8List signaturePng,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.contractSign(contractId));

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';
    request.files.add(http.MultipartFile.fromBytes(
      'signature',
      signaturePng,
      filename: 'signature.png',
      contentType: MediaType('image', 'png'),
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Failed to sign contract (${streamed.statusCode}): $body');
    }
    final decoded = jsonDecode(body);
    if (decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to sign contract');
    }
    return ContractModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// 계약 단건 조회 (당사자만).
  static Future<ContractModel> getById(int contractId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.contractById(contractId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to load contract');
    }
    return ContractModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// 홈스테이 나가기 — 세입자(tenant) 가 ACTIVE 계약을 EXPIRED 로 종료.
  ///
  /// 성공 시 갱신된 계약(상태가 EXPIRED 가 된) 응답을 돌려준다.
  /// 권한이 없거나 ACTIVE 가 아닐 때는 백엔드가 code != 200 (FORBIDDEN) 으로
  /// 응답하므로 메시지를 그대로 예외로 전환한다.
  static Future<ContractModel> leave(int contractId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.contractLeave(contractId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to leave homestay');
    }
    return ContractModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  /// 내가 참여한 계약 목록 (페이징).
  ///
  /// 백엔드는 `PageResponse<ContractRes>` 로 응답한다 (`data.content[]`).
  /// 호환을 위해 List 응답도 함께 처리한다.
  static Future<List<ContractModel>> getMyContracts({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.myContracts).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? 'Failed to load my contracts');
    }
    final dynamic data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    return list
        .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
