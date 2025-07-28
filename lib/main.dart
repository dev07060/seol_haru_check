// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/firebase_options.dart';
import 'package:seol_haru_check/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // runApp을 ProviderScope로 감싸줍니다.
  runApp(const ProviderScope(child: AuthWrapper()));
}

/// Firebase 인증 상태 변경 스트림을 제공하는 Provider입니다.
/// 앱의 어느 곳에서든 ref.watch(authStateChangesProvider)를 통해 인증 상태를 알 수 있습니다.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 인증 상태에 따라 앱의 시작점을 관리하는 위젯입니다.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // StreamProvider를 사용하여 인증 상태를 감지합니다.
    final authState = ref.watch(authStateChangesProvider);

    // AsyncValue.when을 사용하여 로딩, 에러, 데이터 상태를 명확하게 처리합니다.
    return authState.when(
      data: (user) {
        // 데이터가 도착하면 (로그인 상태 확인 완료) GoRouter가 적용된 메인 앱을 실행합니다.
        // GoRouter의 redirect 로직은 이 시점부터 정확한 로그인 상태를 기반으로 동작합니다.
        return const MyApp();
      },
      loading: () {
        // Firebase가 인증 상태를 확인하는 동안 보여줄 스플래시 화면입니다.
        return const MaterialApp(home: Scaffold(body: Center(child: CupertinoActivityIndicator())));
      },
      error: (err, stack) {
        // 스트림에서 에러가 발생한 경우 보여줄 화면입니다.
        return MaterialApp(home: Scaffold(body: Center(child: Text('${AppStrings.errorOccurred}: $err'))));
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appTitleKorean,
      routerConfig: AppRouter.router,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
    );
  }
}
