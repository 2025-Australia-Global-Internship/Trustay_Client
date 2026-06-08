import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'routes/app_routes.dart';
import 'routes/app_router.dart';
import 'constants/theme.dart';
import 'firebase_options.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // env 로드
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.appTheme,
      initialRoute: AppRoutes.intro,
      debugShowCheckedModeBanner: false,
      routes: appRouter,
      navigatorObservers: [routeObserver],
    );
  }
}
