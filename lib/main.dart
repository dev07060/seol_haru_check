import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seol_haru_check/firebase_options.dart';
import 'package:seol_haru_check/router.dart';

void main() async {
  // Ensure Flutter is initialized for async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Korean locale
  await initializeDateFormatting('ko_KR', null);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run the app with proper MaterialApp wrapper
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '운동 체크',
      routerConfig: router, // go_router 라우터 사용
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
    );
  }
}
