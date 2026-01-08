import 'package:flutter/material.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/common_action_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  /// 서버 메시지 AlertDialog
  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 로그인 API
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('http://54.180.94.203:8080/api/trustay/auth/login');

    final body = jsonEncode({"email": email, "passwd": password});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final res = jsonDecode(response.body);

      // 서버 성공 코드 확인
      final code = res['code'] ?? -1;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          code == 200) {
        // 성공
        final token = res['data']?['token'];
        print('로그인 성공, 토큰: $token');
        return true;
      } else {
        showMessage('로그인 실패', res['message'] ?? '이메일 또는 비밀번호가 틀렸습니다');
        return false;
      }
    } catch (e) {
      showMessage('로그인 실패', '서버 연결 실패: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Back'),
        titleTextStyle: TextStyle(
          color: Color(0xFFFFF27B),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,

      body: Stack(
        children: [
          /// 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro_back.png',
              fit: BoxFit.cover,
            ),
          ),

          /// 어두운 오버레이
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          /// 로그인 UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    CommonTextField(
                      label: 'Email',
                      validator: (v) =>
                          v == null || v.isEmpty ? '이메일을 입력하세요' : null,
                      onSaved: (v) => email = v!,
                    ),

                    CommonTextField(
                      label: 'Password',
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? '비밀번호를 입력하세요' : null,
                      onSaved: (v) => password = v!,
                    ),

                    const SizedBox(height: 20),

                    CommonActionButton(
                      formKey: _formKey,
                      text: 'Login',
                      isLoading: isLoading,
                      onAction: () async {
                        if (!_formKey.currentState!.validate()) return false;
                        _formKey.currentState!.save();
                        setState(() => isLoading = true);
                        final result = await login(email, password);
                        setState(() => isLoading = false);
                        return result;
                      },
                      successMessage: '로그인 성공',
                      failMessage: '', // 실패는 AlertDialog로 처리
                      nextRoute: '/index',
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Register now',
                            style: TextStyle(color: Color(0xFFFFF27B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
