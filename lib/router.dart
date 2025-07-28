import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seol_haru_check/certification_tracker_page.dart' hide User;
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/pages/login_page.dart';
import 'package:seol_haru_check/pages/my_feed_page.dart';
import 'package:seol_haru_check/pages/other_user_feed_page.dart';

enum AppRoutePath {
  myFeed,
  login,
  otherUserFeed,
  adminTracker;

  String get relativePath {
    switch (this) {
      case myFeed:
        return '/';
      case login:
        return '/login';
      case otherUserFeed:
        return '/user/:${AppStrings.uuidField}/feed';
      case adminTracker:
        return '/admin/tracker';
    }
  }
}

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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutePath.myFeed.relativePath,
    routes: [
      GoRoute(
        path: AppRoutePath.myFeed.relativePath,
        name: AppRoutePath.myFeed.name,
        builder: (context, state) => const MyFeedPage(),
      ),
      GoRoute(
        path: AppRoutePath.otherUserFeed.relativePath,
        name: AppRoutePath.otherUserFeed.name,
        builder: (context, state) {
          final uuid = state.pathParameters[AppStrings.uuidField]!;
          return OtherUserFeedPage(uuid: uuid);
        },
      ),
      GoRoute(
        path: AppRoutePath.login.relativePath,
        name: AppRoutePath.login.name,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePath.adminTracker.relativePath,
        name: AppRoutePath.adminTracker.name,
        builder: (context, state) => const CertificationTrackerPage(),
      ),
    ],
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.matchedLocation == AppRoutePath.login.relativePath;

      if (!loggedIn && !loggingIn) {
        return AppRoutePath.login.relativePath;
      }
      if (loggedIn && loggingIn) {
        return AppRoutePath.myFeed.relativePath;
      }

      // No redirection needed.
      return null;
    },
  );
}
