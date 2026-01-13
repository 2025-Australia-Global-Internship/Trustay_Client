import 'package:flutter/material.dart';
import '../pages/join/intro_page.dart';
import '../pages/join/login_page.dart';
import '../pages/join/signup_page.dart';
import '../index.dart';
import '../pages/mypage/sharehouse_create.dart';
import 'app_routes.dart';

final Map<String, WidgetBuilder> appRouter = {
  AppRoutes.intro: (_) => const IntroPage(),
  AppRoutes.login: (_) => const LoginPage(),
  AppRoutes.signup: (_) => const SignupPage(),
  AppRoutes.index: (_) => const IndexPage(),
  AppRoutes.sharehouseCreate: (_) => const SharehouseCreatePage(),
};
