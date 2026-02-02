import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/auth_text_field.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/routes/navigation_type.dart';
import 'package:front/widgets/circle_icon_button.dart';
import 'package:front/widgets/custom_header.dart';

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
  bool isAgree = false;

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
      print(e.toString());
      return false;
    } finally {
      setState(() => isLoading = false);
    }
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

          /// 그라데이션
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    darkgreen, // 아래 단색
                    darkgreen.withOpacity(0.9), // 여기까지는 단색
                    darkgreen.withOpacity(0.0), // 위에서만 투명
                  ],
                  stops: const [0.0, 0.55, 1.0], // 그라데이션 범위 조절
                ),
              ),
            ),
          ),

          /// UI 영역
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(
                  backButtonStyle: BackButtonStyle.dark,
                  iconSize: 38,
                  center: const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        AuthTextField(
                          label: 'Email',
                          hintText: 'Enter your email',
                          validator: (v) =>
                              v == null || v.isEmpty ? '이메일을 입력하세요' : null,
                          onSaved: (v) => email = v!,
                        ),

                        AuthTextField(
                          label: 'Password',
                          hintText: 'Enter your password',
                          bottomPadding: 14,
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? '비밀번호를 입력하세요' : null,
                          onSaved: (v) => password = v!,
                        ),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isAgree = !isAgree;
                            });
                          },
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white),
                                      color: isAgree
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    child: isAgree
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  // TODO: 비밀번호 찾기 이동
                                },
                                child: const Text(
                                  'Forgot your password?',
                                  style: TextStyle(
                                    color: yellow,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 35),

                        PrimaryButton(
                          formKey: _formKey,
                          text: 'Login',
                          isLoading: isLoading,
                          onAction: _handleLogin,
                          successMessage: '로그인 성공',
                          failMessage: '',
                          nextRoute: '/index',
                          navigationType: NavigationType.clearStack,
                        ),

                        const SizedBox(height: 35),

                        Row(
                          children: const [
                            Expanded(
                              child: Divider(
                                color: Colors.white54,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'or sign up with',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white54,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleIconButton(
                              svgAsset: 'assets/icons/apple.svg',
                              iconColor: Colors.white,
                              backgroundColor: Colors.transparent,
                              size: 52,
                              iconSize: 24,
                              borderWidth: 1,
                              borderColor: Colors.white,
                              applySvgColor: false,
                              onPressed: () {},
                            ),
                            const SizedBox(width: 25),
                            CircleIconButton(
                              svgAsset: 'assets/icons/google.svg',
                              backgroundColor: Colors.transparent,
                              size: 52,
                              iconSize: 20,
                              borderWidth: 1,
                              borderColor: Colors.white,
                              applySvgColor: false,
                              onPressed: () {},
                            ),
                            const SizedBox(width: 25),
                            CircleIconButton(
                              svgAsset: 'assets/icons/facebook.svg',
                              backgroundColor: Colors.transparent,
                              size: 52,
                              iconSize: 26,
                              borderWidth: 1,
                              borderColor: Colors.white,
                              applySvgColor: false,
                              onPressed: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationColor: yellow,
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
        ],
      ),
    );
  }
}
