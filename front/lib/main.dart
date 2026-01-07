import 'package:flutter/material.dart';
import 'package:front/screens/intro.dart';
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

      initialRoute: '/',
      routes: {
        '/': (context) => const IntroPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/index': (context) => const IndexPage(),
        '/sharehouse_create': (context) => const SharehouseCreatePage(),
      },
    );
  }
}
