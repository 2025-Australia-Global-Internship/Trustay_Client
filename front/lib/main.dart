import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'index.dart';
import 'screens/sharehouse_create.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(primarySwatch: Colors.blue),

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/index': (context) => const IndexPage(),
        '/sharehouse_create': (context) => const SharehouseCreatePage(),
      },
    );
  }
}
