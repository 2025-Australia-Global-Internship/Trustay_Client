import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/services/auth_service.dart';

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

  /// 로그인 버튼 클릭 시 처리
  Future<bool> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return false;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      final success = await AuthService.login(email: email, password: password);
      return success;
    } catch (e) {
      showMessage('로그인 실패', e.toString());
      return false;
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Back'),
        titleTextStyle: const TextStyle(
          color: yellow,
          fontFamily: 'NanumSquareNeo',
          fontWeight: FontWeight.w800,
          fontSize: 20,
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

                    PrimaryButton(
                      formKey: _formKey,
                      text: 'Login',
                      isLoading: isLoading,
                      onAction: _handleLogin,
                      successMessage: '로그인 성공',
                      failMessage: '',
                      nextRoute: '/index',
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NanumSquareNeo',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Register now',
                            style: TextStyle(
                              color: yellow,
                              fontFamily: 'NanumSquareNeo',
                              fontWeight: FontWeight.w800,
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
