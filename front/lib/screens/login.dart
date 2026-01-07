import 'package:flutter/material.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/common_action_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro_back.png',
              fit: BoxFit.cover,
            ),
          ),

          /// 어두운 오버레이 (글자 안 보일 때 필수)
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
                    const SizedBox(height: 80),

                    CommonTextField(
                      label: '이메일',
                      validator: (v) =>
                          v == null || v.isEmpty ? '이메일을 입력하세요' : null,
                      onSaved: (v) => email = v!,
                    ),

                    CommonTextField(
                      label: '비밀번호',
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? '비밀번호를 입력하세요' : null,
                      onSaved: (v) => password = v!,
                    ),

                    const SizedBox(height: 20),

                    CommonActionButton(
                      formKey: _formKey,
                      text: '로그인',
                      isLoading: isLoading,
                      onAction: () async {
                        setState(() => isLoading = true);
                        final result = await login(email, password);
                        setState(() => isLoading = false);
                        return result;
                      },
                      successMessage: '로그인 성공',
                      failMessage: '이메일 또는 비밀번호가 틀렸습니다',
                      nextRoute: '/index',
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '회원이 아니신가요? ',
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              color: Color(0xFFFFF27B),
                              fontWeight: FontWeight.bold,
                            ),
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

// 임시
Future<bool> login(String email, String password) async {
  await Future.delayed(const Duration(seconds: 1));

  return email == 'test@test.com' && password == '123456';
}
