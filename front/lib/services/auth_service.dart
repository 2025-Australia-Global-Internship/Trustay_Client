import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://54.180.94.203:8080/api/trustay';

  /// 로그인
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "passwd": password}),
    );

    final res = jsonDecode(response.body);
    final code = res['code'] ?? -1;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        code == 200) {
      final token = res['data']?['token'];
      if (token == null) {
        throw Exception('로그인 응답에 토큰 없음');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token); // 토큰 저장

      return true;
    } else {
      throw Exception(res['message'] ?? '로그인 실패');
    }
  }

  /// 회원가입
  static Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/members/signup');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "passwd": password}),
    );

    final res = jsonDecode(response.body);
    final code = res['code'] ?? -1;

    if (!((response.statusCode == 200 || response.statusCode == 201) &&
        code == 200)) {
      throw Exception(res['message'] ?? '회원가입 실패');
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse('$baseUrl/auth/logout');

    await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({}),
    );

    // 서버 성공/실패 상관없이 토큰 삭제
    await prefs.remove('token');
  }

  // 프로필 조회
  static Future<User> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('토큰 없음');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/members/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('프로필 조회 실패');
    }

    final body = jsonDecode(res.body);
    return User.fromJson(body['data']);
  }
}
