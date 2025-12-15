import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final repasswordController = TextEditingController();
  String name = '';
  String birth = '';
  String tel = '';
  String email = '';
  String password = '';
  String repassword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '이름'),
                onSaved: (value) => name = value!,
                validator: (value) => value!.isEmpty ? '이름을 입력하세요' : null,
              ),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '생년월일',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(text: birth),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      birth =
                          "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                    });
                  }
                },
                validator: (value) => value!.isEmpty ? '생년월일을 선택하세요' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '전화번호'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => tel = value!,
                validator: (value) => value!.isEmpty ? '전화번호를 입력하세요' : null,
              ),
              TextFormField(
                // 중복 이메일 체크 필요
                decoration: const InputDecoration(labelText: '이메일'),
                onSaved: (value) => email = value!,
                validator: (value) =>
                    value!.contains('@') ? null : '유효한 이메일을 입력하세요',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                controller: passwordController,
                validator: (value) => value!.length < 6 ? '6자리 이상 입력하세요' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '비밀번호 재입력'),
                obscureText: true,
                controller: repasswordController,
                validator: (value) =>
                    value != passwordController.text ? '비밀번호가 동일하지 않습니다' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    password = passwordController.text;
                    repassword = repasswordController.text;

                    _formKey.currentState!.save();

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('회원가입이 완료되었습니다.')));

                    // 로그인 페이지로 이동
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
