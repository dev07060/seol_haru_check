import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seol_haru_check/main.dart' as app;
import 'package:seol_haru_check/pages/weekly_report_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Web App Notification System E2E', () {
    late FirebaseFirestore firestore;
    const testUserUuid = 'web-notification-test-user';
    const testUserNickname = 'WebNotificationTestUser';

    setUpAll(() async {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
    });

    setUp(() async {
      // Clean up any existing test data
      await _cleanupWebNotificationTestData(firestore, testUserUuid);

      // Setup test user for web notifications
      await _setupWebNotificationTestUser(firestore, testUserUuid, testUserNickname);
    });

    tearDown(() async {
      // Clean up test data after each test
      await _cleanupWebNotificationTestData(firestore, testUserUuid);
    });

    testWidgets('In-app notification banner display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a weekly report to trigger in-app notification
      await _createWeeklyReportForWebNotification(firestore, testUserUuid);

      // Wait for notification processing
      await tester.pump(const Duration(seconds: 2));

      // Verify in-app notification banner appears
      expect(find.byKey(const Key('in_app_notification_banner')), findsOneWidget);
      expect(find.textContaining('새로운 주간 리포트가 준비되었습니다'), findsOneWidget);

      // Test tapping the notification banner
      await tester.tap(find.byKey(const Key('in_app_notification_banner')));
      await tester.pumpAndSettle();

      // Verify navigation to weekly report page
      expect(find.byType(WeeklyReportPage), findsOneWidget);
      expect(find.text('주간 분석 리포트'), findsOneWidget);
    });

    testWidgets('Toast notification display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a weekly report to trigger toast notification
      await _createWeeklyReportForWebNotification(firestore, testUserUuid);

      // Wait for notification processing
      await tester.pump(const Duration(seconds: 1));

      // Verify toast notification appears
      expect(find.byKey(const Key('toast_notification')), findsOneWidget);
      expect(find.textContaining('AI 분석이 완료되었습니다'), findsOneWidget);

      // Wait for toast to auto-dismiss
      await tester.pump(const Duration(seconds: 4));

      // Verify toast disappears
      expect(find.byKey(const Key('toast_notification')), findsNothing);
    });

    testWidgets('Real-time notification updates via Firestore listener', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a page that listens for notifications
      await tester.tap(find.byKey(const Key('home_nav')));
      await tester.pumpAndSettle();

      // Create a weekly report (simulates real-time update)
      await _createWeeklyReportForWebNotification(firestore, testUserUuid);

      // Wait for Firestore listener to trigger
      await tester.pump(const Duration(seconds: 2));

      // Verify notification indicator appears
      expect(find.byKey(const Key('notification_indicator')), findsOneWidget);
      expect(find.byKey(const Key('notification_badge')), findsOneWidget);

      // Test tapping the notification indicator
      await tester.tap(find.byKey(const Key('notification_indicator')));
      await tester.pumpAndSettle();

      // Verify notification list appears
      expect(find.byKey(const Key('notification_list')), findsOneWidget);
      expect(find.textContaining('주간 리포트'), findsOneWidget);
    });

    testWidgets('Web notification settings management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byKey(const Key('settings_nav')));
      await tester.pumpAndSettle();

      // Navigate to notification settings
      await tester.tap(find.byKey(const Key('notification_settings_tile')));
      await tester.pumpAndSettle();

      // Verify web notification settings page
      expect(find.text('알림 설정'), findsOneWidget);
      expect(find.byKey(const Key('in_app_notifications_toggle')), findsOneWidget);
      expect(find.byKey(const Key('toast_notifications_toggle')), findsOneWidget);
      expect(find.byKey(const Key('sound_notifications_toggle')), findsOneWidget);

      // Test toggling in-app notifications
      await tester.tap(find.byKey(const Key('in_app_notifications_toggle')));
      await tester.pumpAndSettle();

      // Verify setting is saved to Firestore
      final userDoc = await firestore.collection('users').doc(testUserUuid).get();
      final notificationSettings = userDoc.data()?['webNotificationSettings'] as Map<String, dynamic>?;
      expect(notificationSettings?['inAppNotifications'], isFalse);

      // Create a report and verify no in-app notification appears
      await _createWeeklyReportForWebNotification(firestore, testUserUuid);
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key('in_app_notification_banner')), findsNothing);
    });

    testWidgets('Notification history and management', (WidgetTester tester) async {
      // Create multiple reports to generate notification history
      await _createMultipleWebNotifications(firestore, testUserUuid, testUserNickname);

      app.main();
      await tester.pumpAndSettle();

      // Navigate to notification history
      await tester.tap(find.byKey(const Key('notification_history_nav')));
      await tester.pumpAndSettle();

      // Verify notification history page
      expect(find.text('알림 기록'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Verify multiple notification items
      expect(find.byKey(const Key('notification_history_item')), findsWidgets);

      // Test marking notification as read
      await tester.tap(find.byKey(const Key('notification_history_item')).first);
      await tester.pumpAndSettle();

      // Verify navigation to related report
      expect(find.byType(WeeklyReportPage), findsOneWidget);

      // Go back to history
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Test clearing all notifications
      await tester.tap(find.byKey(const Key('clear_all_notifications_button')));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('모든 알림을 삭제하시겠습니까?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.textContaining('삭제'));
      await tester.pumpAndSettle();

      // Verify notifications are cleared
      expect(find.byKey(const Key('notification_history_item')), findsNothing);
      expect(find.textContaining('알림이 없습니다'), findsOneWidget);
    });

    testWidgets('Web notification error handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate network error during notification fetch
      await _simulateNetworkError(firestore, testUserUuid);

      // Try to load notifications
      await tester.tap(find.byKey(const Key('notification_indicator')));
      await tester.pumpAndSettle();

      // Verify error state is handled gracefully
      expect(find.textContaining('알림을 불러올 수 없습니다'), findsOneWidget);
      expect(find.byKey(const Key('retry_notifications_button')), findsOneWidget);

      // Test retry functionality
      await _simulateNetworkRecovery(firestore, testUserUuid);
      await tester.tap(find.byKey(const Key('retry_notifications_button')));
      await tester.pumpAndSettle();

      // Verify notifications load successfully after retry
      expect(find.byKey(const Key('notification_list')), findsOneWidget);
    });

    testWidgets('Real-time notification updates performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Create multiple notifications rapidly
      for (int i = 0; i < 5; i++) {
        await _createWeeklyReportForWebNotification(firestore, testUserUuid, reportId: 'rapid-$i');
        await tester.pump(const Duration(milliseconds: 200));
      }

      stopwatch.stop();

      // Verify all notifications are processed efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      // Verify UI remains responsive
      expect(find.byKey(const Key('notification_indicator')), findsOneWidget);

      // Check notification count
      await tester.tap(find.byKey(const Key('notification_indicator')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_history_item')), findsNWidgets(5));
    });

    testWidgets('Notification accessibility for web', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a notification
      await _createWeeklyReportForWebNotification(firestore, testUserUuid);
      await tester.pump(const Duration(seconds: 1));

      // Verify notification has proper accessibility labels
      final notificationBanner = find.byKey(const Key('in_app_notification_banner'));
      expect(notificationBanner, findsOneWidget);

      // Check semantic properties
      final semantics = tester.getSemantics(notificationBanner);
      expect(semantics.label, contains('새로운 주간 리포트'));
      expect(semantics.hint, contains('탭하여 확인'));

      // Test keyboard navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify focus is on notification
      expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('notification'));

      // Test Enter key activation
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(WeeklyReportPage), findsOneWidget);
    });
  });
}

// Helper functions for web notification testing

Future<void> _setupWebNotificationTestUser(FirebaseFirestore firestore, String userUuid, String nickname) async {
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'webNotificationSettings': {'inAppNotifications': true, 'toastNotifications': true, 'soundNotifications': false},
    'lastNotificationCheck': FieldValue.serverTimestamp(),
  });
}

Future<void> _createWeeklyReportForWebNotification(
  FirebaseFirestore firestore,
  String userUuid, {
  String? reportId,
}) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday % 7));
  final weekEnd = weekStart.add(const Duration(days: 6));

  final reportData = {
    'userUuid': userUuid,
    'weekStartDate': Timestamp.fromDate(weekStart),
    'weekEndDate': Timestamp.fromDate(weekEnd),
    'generatedAt': FieldValue.serverTimestamp(),
    'stats': {
      'totalCertifications': 8,
      'exerciseDays': 4,
      'dietDays': 4,
      'exerciseTypes': {'헬스': 2, '러닝': 2},
      'consistencyScore': 0.8,
    },
    'analysis': {
      'exerciseInsights': '이번 주 운동 패턴이 좋습니다.',
      'dietInsights': '식단 관리를 잘 하고 계십니다.',
      'overallAssessment': '건강한 라이프스타일을 유지하고 계십니다.',
      'strengthAreas': ['운동 일관성'],
      'improvementAreas': ['수분 섭취'],
    },
    'recommendations': ['하루 2L 이상의 물을 마시세요', '규칙적인 수면 패턴을 유지하세요'],
    'status': 'completed',
    'notificationSent': false,
  };

  if (reportId != null) {
    await firestore.collection('weeklyReports').doc(reportId).set(reportData);
  } else {
    await firestore.collection('weeklyReports').add(reportData);
  }

  // Create web notification entry
  await firestore.collection('webNotifications').add({
    'userUuid': userUuid,
    'type': 'weekly_report',
    'title': '주간 리포트가 준비되었습니다',
    'message': 'AI 분석이 완료되었습니다. 지금 확인해보세요!',
    'reportId': reportId ?? 'auto-generated',
    'createdAt': FieldValue.serverTimestamp(),
    'read': false,
    'dismissed': false,
  });
}

Future<void> _createMultipleWebNotifications(FirebaseFirestore firestore, String userUuid, String nickname) async {
  for (int i = 0; i < 3; i++) {
    await _createWeeklyReportForWebNotification(firestore, userUuid, reportId: 'multi-notification-$i');

    // Add some delay to create different timestamps
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

Future<void> _simulateNetworkError(FirebaseFirestore firestore, String userUuid) async {
  // Create a system status document to simulate network error
  await firestore.collection('systemStatus').doc('notifications').set({
    'status': 'error',
    'lastError': FieldValue.serverTimestamp(),
    'affectedUsers': [userUuid],
  });
}

Future<void> _simulateNetworkRecovery(FirebaseFirestore firestore, String userUuid) async {
  // Update system status to simulate recovery
  await firestore.collection('systemStatus').doc('notifications').set({
    'status': 'operational',
    'lastRecovery': FieldValue.serverTimestamp(),
  });
}

Future<void> _cleanupWebNotificationTestData(FirebaseFirestore firestore, String userUuid) async {
  // Clean up user data
  await firestore.collection('users').doc(userUuid).delete();

  // Clean up weekly reports
  final reportsQuery = await firestore.collection('weeklyReports').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in reportsQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up web notifications
  final notificationsQuery =
      await firestore.collection('webNotifications').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in notificationsQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up system status
  await firestore.collection('systemStatus').doc('notifications').delete();
}
