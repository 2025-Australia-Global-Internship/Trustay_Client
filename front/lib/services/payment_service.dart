import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../models/payment_model.dart';

/// `/api/trustay/payments` REST 호출 모음.
///
/// 토스 결제위젯 자체는 별도 SDK / WebView로 처리하고, 이 클래스는
/// 백엔드 API 호출만 담당한다.
class PaymentService {
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

  // -------------------------------------------------------------------------
  // 1. 토스 클라이언트키 조회
  // -------------------------------------------------------------------------
  static Future<TossClientConfig> getTossClientConfig() async {
    final response = await http.get(Uri.parse(ApiEndpoints.tossClientConfig));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '토스 클라이언트키 조회 실패');
    }
    return TossClientConfig.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 2. 월세 결제 준비
  // -------------------------------------------------------------------------
  static Future<PaymentPrepareModel> prepareRentPayment({
    required int contractId,
    required int amount,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.rentPrepare),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode({
        'contractId': contractId,
        'amount': amount,
      })),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '월세 결제 준비 실패');
    }
    return PaymentPrepareModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 3. 더치페이 생성
  // -------------------------------------------------------------------------
  static Future<DutchPayCreateModel> createDutchPay({
    required int totalAmount,
    required List<int> memberIds,
    required int payeeMemberId,
    String? title,
    int? contractId,
  }) async {
    final token = await _getToken();
    final body = <String, dynamic>{
      'totalAmount': totalAmount,
      'memberIds': memberIds,
      'payeeMemberId': payeeMemberId,
    };
    if (title != null) body['title'] = title;
    if (contractId != null) body['contractId'] = contractId;

    final response = await http.post(
      Uri.parse(ApiEndpoints.dutchCreate),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode(body)),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '더치페이 생성 실패');
    }
    return DutchPayCreateModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 4. 토스 결제 승인
  // -------------------------------------------------------------------------
  static Future<PaymentConfirmModel> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiEndpoints.paymentConfirm),
      headers: _authHeaders(token),
      body: utf8.encode(jsonEncode({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      })),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '결제 승인 실패');
    }
    return PaymentConfirmModel.fromJson(decoded['data'] as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------------
  // 5. 내 미완료 결제 목록 (페이징)
  // -------------------------------------------------------------------------
  static Future<List<PendingPayment>> getMyPending({
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiEndpoints.myPendingPayments).replace(
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final response = await http.get(uri, headers: _authHeaders(token));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '미완료 결제 조회 실패');
    }
    final dynamic data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    return list
        .map((e) => PendingPayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------------------
  // 6. 내 결제 이력 (기간/타입 필터, 페이징)
  //    백엔드 [GET /api/trustay/payments/me/history]
  // -------------------------------------------------------------------------
  static Future<List<PaymentHistoryItem>> getMyHistory({
    DateTime? from,
    DateTime? to,
    String? type, // RENT / UTILITY / DUTCH
    int page = 0,
    int size = 10,
  }) async {
    final token = await _getToken();
    final qp = <String, String>{};
    if (from != null) qp['from'] = _yyyyMmDd(from);
    if (to != null) qp['to'] = _yyyyMmDd(to);
    if (type != null && type.isNotEmpty) qp['type'] = type;
    qp['page'] = '$page';
    qp['size'] = '$size';

    final uri = Uri.parse(ApiEndpoints.myPaymentHistory).replace(
      queryParameters: qp,
    );
    final response = await http.get(uri, headers: _authHeaders(token));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded['code'] != 200) {
      throw Exception(decoded['message'] ?? '결제 이력 조회 실패');
    }
    final dynamic data = decoded['data'];
    final List<dynamic> list = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['content'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    return list
        .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String _yyyyMmDd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
