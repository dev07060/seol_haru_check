// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/firebase_options.dart';
import 'package:seol_haru_check/providers/fcm_provider.dart';
import 'package:seol_haru_check/router.dart';
import 'package:seol_haru_check/services/fcm_service.dart';
import 'package:seol_haru_check/widgets/in_app_notification_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: "assets/env/.dev.env");

  // 웹 플랫폼에서 폰트 로딩 최적화
  if (kIsWeb) {
    await _preloadFonts();
  }

  // FCM 백그라운드 메시지 핸들러 설정
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // runApp을 ProviderScope로 감싸줍니다.
  runApp(const ProviderScope(child: AuthWrapper()));
}

/// 웹에서 폰트를 미리 로드하여 FOUC(Flash of Unstyled Content) 방지
Future<void> _preloadFonts() async {
  try {
    // 주요 폰트 웨이트들을 미리 로드
    final fontFutures = [
      rootBundle.load('assets/fonts/pretendard/Pretendard-Regular.otf'),
      rootBundle.load('assets/fonts/pretendard/Pretendard-Medium.otf'),
      rootBundle.load('assets/fonts/pretendard/Pretendard-Bold.otf'),
      rootBundle.load('assets/fonts/pretendard/Pretendard-Light.otf'),
      rootBundle.load('assets/fonts/pretendard/Pretendard-SemiBold.otf'),
    ];

    await Future.wait(fontFutures);

    // 폰트 로딩 완료 후 약간의 지연을 두어 렌더링 안정화
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint('All Pretendard fonts preloaded successfully');
  } catch (e) {
    // 폰트 로딩 실패 시에도 앱이 계속 실행되도록 함
    debugPrint('Font preloading failed: $e');
  }
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
        // 사용자가 로그인한 경우 FCM 초기화
        if (user != null) {
          // FCM 초기화를 비동기로 실행 (UI 블로킹 방지)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final fcmService = ref.read(fcmServiceProvider);
            fcmService.initialize(
              onForegroundMessage: (message) {
                // 포그라운드에서 알림을 받았을 때 인앱 알림 표시
                ref.read(inAppNotificationProvider.notifier).showNotification(message);
                // 알림 히스토리 새로고침
                ref.read(notificationHistoryProvider.notifier).refresh();
              },
            );
          });
        }

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appTitleKorean,
      routerConfig: AppRouter.router,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      builder: (context, child) {
        // FCM 서비스에 네비게이션 컨텍스트 설정
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(fcmServiceProvider).setNavigationContext(context);
        });

        // 인앱 알림 오버레이로 감싸기
        return InAppNotificationOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
