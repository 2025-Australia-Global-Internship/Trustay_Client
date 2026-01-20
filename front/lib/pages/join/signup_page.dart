import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/auth_text_field.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/widgets/custom_header.dart';

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

  // 입력값
  String name = '';
  String email = '';
  String password = '';

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomHeader(
                    backButtonStyle: BackButtonStyle.dark,
                    iconSize: 38,
                    center: const Text(
                      'Create New Account',
                      style: TextStyle(
                        color: yellow,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthTextField(
                            label: 'Name',
                            hintText: 'Enter your name',
                            onSaved: (v) => name = v!,
                            validator: (v) =>
                                v == null || v.isEmpty ? '이름을 입력하세요' : null,
                          ),

                          AuthTextField(
                            label: 'Email',
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            onSaved: (v) => email = v!,
                            validator: (v) {
                              if (v == null || v.isEmpty) return '이메일을 입력하세요';
                              if (!v.contains('@')) return '유효한 이메일을 입력하세요';
                              return null;
                            },
                          ),

                          AuthTextField(
                            label: 'Password',
                            hintText: 'Enter your password',
                            obscureText: true,
                            controller: passwordController,
                            validator: (v) => v == null || v.length < 8
                                ? '비밀번호는 최소 8자리 이상이어야 합니다'
                                : null,
                          ),

                          AuthTextField(
                            label: 'Repassword',
                            hintText: 'Enter your password again',
                            obscureText: true,
                            controller: repasswordController,
                            validator: (v) => v != passwordController.text
                                ? '비밀번호가 일치하지 않습니다'
                                : null,
                          ),

                          const SizedBox(height: 20),

                          PrimaryButton(
                            formKey: _formKey,
                            text: 'Sign Up',
                            isLoading: isLoading,
                            onAction: () async {
                              if (!_formKey.currentState!.validate())
                                return false;
                              _formKey.currentState!.save();

                              password = passwordController.text;

                              setState(() => isLoading = true);
                              try {
                                await AuthService.signup(
                                  name: name,
                                  email: email,
                                  password: password,
                                );
                                return true;
                              } catch (e) {
                                showMessage('회원가입 실패', e.toString());
                                return false;
                              } finally {
                                setState(() => isLoading = false);
                              }
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/login'),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: yellow,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.yellow,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
