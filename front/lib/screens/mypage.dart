import 'package:flutter/material.dart';
import '../widgets/common_section_title.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class _MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isDanger;

  const _MenuItem({
    required this.title,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: isDanger ? Colors.red : Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      // 토큰 없으면 그냥 로그인 페이지로
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://54.180.94.203:8080/api/trustay/auth/logout');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // JWT 토큰 인증
        },
        body: jsonEncode({}), // 로그아웃 요청 body가 필요 없으면 빈 객체
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 토큰 삭제
        await prefs.remove('token');

        // 화면 이동
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // 실패 시 메시지
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('로그아웃 실패'),
            content: Text(res['message'] ?? '알 수 없는 오류'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 서버 연결 실패
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('로그아웃 실패'),
          content: Text('서버 연결 실패: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auth
          const CommonSectionTitle(title: 'Auth'),
          _MenuItem(
            title: '로그인 / 회원가입',
            onTap: () {
              // Navigator.pushNamed(context, '/login');
            },
          ),
          _MenuItem(
            title: '로그아웃',
            onTap: () {
              logout(context);
            },
          ),

          const SizedBox(height: 24),

          // 계약 관리
          const CommonSectionTitle(title: '계약 관리'),
          _MenuItem(title: '보관된 계약서 확인', onTap: () {}),

          const SizedBox(height: 24),

          // 프로필
          const CommonSectionTitle(title: '프로필'),
          _MenuItem(title: '프로필 수정', onTap: () {}),
          _MenuItem(title: '개인정보 확인 / 수정', onTap: () {}),
          _MenuItem(title: '나의 후기', onTap: () {}),
          _MenuItem(title: '찜', onTap: () {}),
          _MenuItem(title: '최근 본 글', onTap: () {}),

          const SizedBox(height: 24),

          // 쉐어하우스
          const CommonSectionTitle(title: '쉐어하우스'),
          _MenuItem(title: '내 쉐어하우스', onTap: () {}),
          _MenuItem(title: '살았던 쉐어하우스 목록', onTap: () {}),
          _MenuItem(title: '현 쉐어하우스 정보 / 탈퇴', isDanger: true, onTap: () {}),
        ],
      ),
    );
  }
}
