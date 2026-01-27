import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // 서버 모델 User
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

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
  static Future<bool> loginWithGoogle(BuildContext context) async {
    GoogleSignInAccount? googleUser;

    // 1️⃣ Google 로그인 화면 띄우기
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      // 로그인 화면 띄우기 실패
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google 로그인 화면을 열 수 없습니다: $e')));
      return false;
    }

    if (googleUser == null) {
      // 사용자가 취소했을 때
      return false;
    }

    // 2️⃣ Firebase 로그인 & 서버 호출은 여기서 처리
    try {
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await fb.FirebaseAuth.instance
          .signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) throw Exception('Firebase User 없음');

      final firebaseToken = await firebaseUser.getIdToken();
      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw Exception('Firebase Token 없음');
      }

      // 서버 호출
      final url = Uri.parse('$baseUrl/auth/oauth');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"firebaseToken": firebaseToken}),
      );

      final res = jsonDecode(response.body);
      final code = res['code'] ?? -1;

      if (response.statusCode != 200 || code != 200) {
        final msg = res['message'] ?? '서버 OAuth 로그인 실패';
        if (msg.contains('존재하지 않는 계정') || msg.contains('not found')) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('회원가입 필요'),
              content: Text('서버에 등록된 계정이 없습니다.\n회원가입 후 다시 시도해주세요.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text('회원가입'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소'),
                ),
              ],
            ),
          );
          return false;
        } else {
          throw Exception(msg);
        }
      }

      // 서버 JWT 저장
      final serverToken = res['data']?['token'];
      if (serverToken == null) throw Exception('서버 JWT 없음');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', serverToken);

      return true; // 로그인 성공
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 중 오류 발생: $e')));
      return false;
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
