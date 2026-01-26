import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // 서버 모델 User
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl = 'https://trustay.digitalbasis.com/api/trustay';
  static final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

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

  /// Google OAuth 로그인
  static Future<bool> loginWithGoogle() async {
    try {
      // Google Sign-In 시작
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase Credential 생성 및 로그인
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await fb.FirebaseAuth.instance
          .signInWithCredential(credential);
      final fb.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Firebase User 없음');

      // Firebase 토큰 가져오기
      final firebaseToken = await firebaseUser.getIdToken();

      // 서버에 사용자 정보 전송
      final url = Uri.parse('$baseUrl/members/oauth-login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": firebaseUser.displayName ?? "Unknown", // 이름
          "email": firebaseUser.email ?? "", // 이메일
          "oauth_provider": "google", // 구글임을 명시
          "firebase_token": firebaseToken, // 서버에서 검증용
        }),
      );

      final res = jsonDecode(response.body);
      final code = res['code'] ?? -1;

      if (!((response.statusCode == 200 || response.statusCode == 201) &&
          code == 200)) {
        throw Exception(res['message'] ?? '서버 OAuth 로그인 실패');
      }

      // 서버 토큰 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      final serverToken = res['data']?['token'];
      if (serverToken == null) {
        throw Exception('서버에서 토큰을 받지 못함');
      }
      await prefs.setString('token', serverToken);

      return true;
    } catch (e) {
      throw Exception('Google 로그인 실패: ${e.toString()}');
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
    await _auth.signOut(); // Firebase 로그아웃

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

  /// 프로필 조회
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
