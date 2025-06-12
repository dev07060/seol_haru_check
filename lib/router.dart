import 'dart:async'; // [추가]

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // [추가]
import 'package:go_router/go_router.dart';
import 'package:seol_haru_check/certification_tracker_page.dart' hide User;
import 'package:seol_haru_check/pages/login_page.dart';
import 'package:seol_haru_check/pages/my_feed_page.dart';
import 'package:seol_haru_check/pages/other_user_feed_page.dart'; // Import the new page
import 'package:seol_haru_check/pages/user_detail_page.dart';

// [추가] FirebaseAuth의 인증 상태 변경(Stream)을 GoRouter에 알려주는(ChangeNotifier) 클래스
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  GoRouterRefreshStream(Stream<User?> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((user) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  routes: [
    // 기본 경로를 MyFeedPage로 변경
    GoRoute(path: '/', builder: (context, state) => const MyFeedPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/user/:uuid',
      builder: (context, state) {
        final uuid = state.pathParameters['uuid']!;
        return UserDetailPage(uuid: uuid);
      },
    ),
    GoRoute(
      // New route for other users' feeds
      path: '/user/:uuid/feed',
      builder: (context, state) => OtherUserFeedPage(uuid: state.pathParameters['uuid']!),
    ),
    // 기존 테이블 페이지를 관리자용으로 남겨둘 경우
    GoRoute(path: '/admin/tracker', builder: (context, state) => const CertificationTrackerPage()),
  ],
  // [수정] refreshListenable을 사용하여 인증 상태 변경을 실시간으로 감지
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.matchedLocation == '/login';

    if (!loggedIn && !loggingIn) {
      return '/login';
    }
    if (loggedIn && loggingIn) {
      return '/';
    }

    return null;
  },
);
