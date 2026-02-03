import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/auth_text_field.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/services/auth_service.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/circle_icon_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController passwordController;

  bool isLoading = false;

  // 입력값
  String name = '';
  String email = '';
  String password = '';
  bool isAgree = false;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
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

          /// 그라데이션
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    darkgreen,
                    darkgreen.withOpacity(0.9),
                    darkgreen.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          /// 회원가입 UI (헤더 포함 스크롤 가능)
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
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

                    const SizedBox(height: 10),

                    Padding(
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
                            bottomPadding: 14,
                            controller: passwordController,
                            validator: (v) => v == null || v.length < 8
                                ? '비밀번호는 최소 8자리 이상이어야 합니다'
                                : null,
                          ),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isAgree = !isAgree;
                              });
                            },
                            child: Row(
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
                                const Expanded(
                                  child: Text(
                                    'Agree with Terms & Conditions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 35),

                          PrimaryButton(
                            formKey: _formKey,
                            text: 'Sign Up',
                            enabled: isAgree,
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
