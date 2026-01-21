import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'routes/app_router.dart';
import 'constants/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.appTheme,
      initialRoute: AppRoutes.intro,
      routes: appRouter,
    );
  }
}
