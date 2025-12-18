import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/widgets/common_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController birthController;
  late TextEditingController passwordController;
  late TextEditingController repasswordController;

  // 변수
  String name = '';
  String birth = '';
  String tel = '';
  String email = '';
  String password = '';
  String repassword = '';

  @override
  void initState() {
    super.initState();
    birthController = TextEditingController();
    passwordController = TextEditingController();
    repasswordController = TextEditingController();
  }

  @override
  void dispose() {
    birthController.dispose();
    passwordController.dispose();
    repasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 이름
              CommonTextField(
                label: '이름',
                onSaved: (v) => name = v!,
                validator: (v) => v == null || v.isEmpty ? '이름을 입력하세요' : null,
              ),

              /// 생년월일
              CommonTextField(
                label: '생년월일',
                readOnly: true,
                controller: birthController,
                suffixIcon: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );

                  if (pickedDate != null) {
                    birth =
                        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                    setState(() {
                      birthController.text = birth;
                    });
                  }
                },
                validator: (v) => v == null || v.isEmpty ? '생년월일을 선택하세요' : null,
              ),

              /// 전화번호
              CommonTextField(
                label: '전화번호',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSaved: (v) => tel = v!,
                validator: (v) => v == null || v.isEmpty ? '전화번호를 입력하세요' : null,
              ),

              /// 이메일
              CommonTextField(
                label: '이메일',
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => email = v!,
                validator: (v) {
                  if (v == null || v.isEmpty) return '이메일을 입력하세요';
                  if (!v.contains('@')) return '유효한 이메일을 입력하세요';
                  return null;
                },
              ),

              /// 비밀번호
              CommonTextField(
                label: '비밀번호',
                obscureText: true,
                controller: passwordController,
                validator: (v) =>
                    v == null || v.length < 6 ? '비밀번호는 6자리 이상이어야 합니다' : null,
              ),

              /// 비밀번호 재입력
              CommonTextField(
                label: '비밀번호 재입력',
                obscureText: true,
                controller: repasswordController,
                validator: (v) =>
                    v != passwordController.text ? '비밀번호가 일치하지 않습니다' : null,
              ),

              const SizedBox(height: 24),

              /// 회원가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      password = passwordController.text;
                      repassword = repasswordController.text;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('회원가입이 완료되었습니다')),
                      );

                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: const Text('회원가입'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
