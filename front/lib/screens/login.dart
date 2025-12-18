import 'package:flutter/material.dart';
import 'package:front/widgets/common_text_field.dart';

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
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonTextField(
                label: '이메일',
                validator: (v) => v == null || v.isEmpty ? '이메일을 입력하세요' : null,
                onSaved: (v) => email = v!,
              ),

              CommonTextField(
                label: '비밀번호',
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? '비밀번호를 입력하세요' : null,
                onSaved: (v) => password = v!,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          setState(() => isLoading = true);

                          final success = await login(email, password);

                          setState(() => isLoading = false);

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success ? '로그인 성공' : '이메일 또는 비밀번호가 틀렸습니다',
                              ),
                            ),
                          );

                          Navigator.pushReplacementNamed(
                            context,
                            '/sharehouse_create',
                          );
                        }
                      },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('로그인'),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('회원이 아니신가요? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.blue,
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
    );
  }
}

// 임시
Future<bool> login(String email, String password) async {
  await Future.delayed(const Duration(seconds: 1));

  return email == 'test@test.com' && password == '123456';
}
