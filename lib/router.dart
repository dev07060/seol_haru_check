import 'package:go_router/go_router.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/pages/user_detail_page.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const CertificationTrackerPage()),
    GoRoute(
      path: '/user/:uuid',
      builder: (context, state) {
        final uuid = state.pathParameters['uuid']!;
        return UserDetailPage(uuid: uuid);
      },
    ),
  ],
);
