import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase import
import 'routes/app_routes.dart';
import 'routes/app_router.dart';
import 'constants/theme.dart';
import 'firebase_options.dart'; // FlutterFire CLI로 생성

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // FlutterFire CLI에서 자동 생성
  );

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
