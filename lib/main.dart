// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seol_haru_check/firebase_options.dart';
import 'package:seol_haru_check/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // runApp을 ProviderScope로 감싸줍니다.
  runApp(const ProviderScope(child: AuthWrapper()));
}

/// 인증 상태에 따라 앱의 시작점을 관리하는 위젯입니다.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebase 인증 상태 변경을 감지하는 스트림을 사용합니다.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 인증 상태를 확인하는 동안 로딩 화면을 보여줍니다.
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return const MaterialApp(
        //     home: SplashPage(),
        //   );
        // }

        // 인증 상태 확인이 끝나면 GoRouter가 적용된 메인 앱을 실행합니다.
        // 이제 GoRouter의 redirect 로직은 항상 정확한 로그인 상태를 기반으로 동작하게 됩니다.
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '운동 체크',
      routerConfig: AppRouter.router,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
    );
  }
}
