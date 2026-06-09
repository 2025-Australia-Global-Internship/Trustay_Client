import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // 서버 모델 User
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constants/api_endpoints.dart';

class AuthService {
  // Use ApiEndpoints for endpoint URLs
  static final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  /// 기본 프로필 이미지 자산 경로 (이미지가 없는 신규 회원에게 업로드)
  static const String _defaultProfileAsset = 'assets/icons/default.png';

  /// 동시 호출 시 default 이미지가 여러 번 업로드되지 않도록 단일 Future로 메모이즈
  static Future<void>? _ensureDefaultImageFuture;

  /// 현재 로그인한 사용자 정보를 앱 전역에 공유하는 노티파이어.
  /// `fetchProfile()` 호출로 최신 값이 자동 반영되며, 다른 화면은 이를 구독해
  /// 새로고침 없이 프로필(이미지 포함) 변경을 즉시 받아볼 수 있다.
  static final ValueNotifier<User?> currentUserNotifier = ValueNotifier<User?>(
    null,
  );

  /// 로그인
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiEndpoints.authLogin);

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
      final url = Uri.parse(ApiEndpoints.authOauth);
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
    final url = Uri.parse(ApiEndpoints.signup);

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

    final url = Uri.parse(ApiEndpoints.authLogout);

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
  ///
  /// 이미지가 없는 신규 회원이라면 클라이언트 번들의 `assets/icons/default.png`를
  /// 한 번 업로드한 뒤 다시 프로필을 조회해서 최신 URL을 돌려준다.
  /// (이후 호출부터는 서버가 갖고 있는 이미지 URL을 그대로 사용)
  static Future<User> fetchProfile() async {
    User user = await _fetchProfileRaw();

    if (user.profileImageUrl == null || user.profileImageUrl!.isEmpty) {
      try {
        await _ensureDefaultProfileImageUploaded();
        user = await _fetchProfileRaw();
      } catch (e) {
        // 기본 이미지 업로드 실패는 치명적이지 않음 → 원본 프로필 그대로 반환
        // (다음 fetchProfile 호출 시 다시 시도)
        debugPrint('⚠️ 기본 프로필 이미지 업로드 실패: $e');
      }
    }

    // 전역 사용자 정보 갱신 → 다른 화면이 새로고침 없이 즉시 반영
    currentUserNotifier.value = user;

    return user;
  }

  /// 서버에서 프로필을 그대로 받아오는 내부 헬퍼 (default 업로드 로직 없음)
  static Future<User> _fetchProfileRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('토큰 없음');
    }

    final res = await http.get(
      Uri.parse(ApiEndpoints.profile),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('프로필 조회 실패');
    }

    final body = jsonDecode(res.body);
    return User.fromJson(body['data']);
  }

  /// `assets/icons/default.png`를 임시 파일로 풀어 multipart 업로드.
  /// 동시 호출이 발생해도 단일 Future로 메모이즈해 중복 업로드를 막는다.
  static Future<void> _ensureDefaultProfileImageUploaded() {
    return _ensureDefaultImageFuture ??= _uploadDefaultProfileImageAsset()
        .whenComplete(() {
      _ensureDefaultImageFuture = null;
    });
  }

  static Future<void> _uploadDefaultProfileImageAsset() async {
    final ByteData byteData = await rootBundle.load(_defaultProfileAsset);
    final Uint8List bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    // 시스템 임시 디렉터리에 default.png 풀기
    final tempPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}default_profile_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = await File(tempPath).writeAsBytes(bytes, flush: true);

    try {
      await updateProfileImage(tempFile);
    } finally {
      // 업로드 후 임시 파일 정리 (실패해도 무시)
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  /// 프로필 이미지 업로드
  /// POST /api/trustay/members/profile/image
  /// multipart/form-data, 필드명: profileImage
  static Future<void> updateProfileImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('토큰 없음');
    }

    final uri = Uri.parse(ApiEndpoints.profileImage);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['accept'] = '*/*';

    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    request.files.add(
      await http.MultipartFile.fromPath(
        'profileImage',
        imageFile.path,
        filename: fileName,
        contentType: _imageContentTypeFor(imageFile),
      ),
    );

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      throw Exception('프로필 이미지 업로드 실패 (${streamed.statusCode}): $responseBody');
    }

    try {
      final decoded = jsonDecode(responseBody);
      final code = decoded['code'] ?? 200;
      if (code != 200) {
        throw Exception(decoded['message'] ?? '프로필 이미지 업로드 실패');
      }
    } catch (_) {
      // 응답 본문이 JSON이 아니어도 statusCode가 200이면 성공으로 간주
    }
  }

  /// 이미지 파일 확장자별 ContentType 추론
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
    if (path.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    throw Exception('지원하지 않는 이미지 형식입니다: ${imageFile.path}');
  }
}
