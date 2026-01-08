import 'package:flutter/material.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/common_action_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController passwordController;
  late TextEditingController repasswordController;

  bool isLoading = false;

  // 변수
  String name = '';
  String email = '';
  String password = '';
  String repassword = '';

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    repasswordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    repasswordController.dispose();
    super.dispose();
  }

  /// 회원가입 POST 요청 함수
  Future<Map<String, dynamic>> signup() async {
    final url = Uri.parse(
      'http://54.180.94.203:8080/api/trustay/members/signup',
    );

    final body = jsonEncode({"name": name, "email": email, "passwd": password});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final res = jsonDecode(response.body);

      final code = res['code'] ?? -1;
      final isSuccess =
          (response.statusCode == 200 || response.statusCode == 201) &&
          code == 200;

      return {'success': isSuccess, 'message': res['message'] ?? '알 수 없는 오류'};
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
        titleTextStyle: const TextStyle(
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

          /// 회원가입 UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    CommonTextField(
                      label: 'Name',
                      onSaved: (v) => name = v!,
                      validator: (v) =>
                          v == null || v.isEmpty ? '이름을 입력하세요' : null,
                    ),

                    CommonTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (v) => email = v!,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '이메일을 입력하세요';
                        if (!v.contains('@')) return '유효한 이메일을 입력하세요';
                        return null;
                      },
                    ),

                    CommonTextField(
                      label: 'Password',
                      obscureText: true,
                      controller: passwordController,
                      validator: (v) => v == null || v.length < 8
                          ? '비밀번호는 최소 8자리 이상이어야 합니다'
                          : null,
                    ),

                    CommonTextField(
                      label: 'Repassword',
                      obscureText: true,
                      controller: repasswordController,
                      validator: (v) => v != passwordController.text
                          ? '비밀번호가 일치하지 않습니다'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    CommonActionButton(
                      formKey: _formKey,
                      text: 'Sign Up',
                      isLoading: isLoading, // 로그인처럼 isLoading 추가
                      onAction: () async {
                        if (!_formKey.currentState!.validate()) return false;
                        _formKey.currentState!.save();
                        password = passwordController.text;
                        repassword = repasswordController.text;
                        setState(() => isLoading = true);
                        final result = await signup();
                        setState(() => isLoading = false);

                        if (result['success']) return true;
                        showMessage('회원가입 실패', result['message']);
                        return false;
                      },
                      successMessage: '회원가입 완료',
                      failMessage: '',
                      nextRoute: '/login',
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: const Text(
                            'Login',
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
