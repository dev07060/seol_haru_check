import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seol_haru_check/main.dart' as app;
import 'package:seol_haru_check/pages/weekly_report_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Delivery and Handling E2E', () {
    late FirebaseFirestore firestore;
    late FirebaseMessaging messaging;
    const testUserUuid = 'notification-test-user';
    const testUserNickname = 'NotificationTestUser';

    setUpAll(() async {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
      messaging = FirebaseMessaging.instance;
    });

    setUp(() async {
      // Clean up any existing test data
      await _cleanupNotificationTestData(firestore, testUserUuid);

      // Setup test user with FCM token
      await _setupNotificationTestUser(firestore, testUserUuid, testUserNickname);
    });

    tearDown(() async {
      // Clean up test data after each test
      await _cleanupNotificationTestData(firestore, testUserUuid);
    });

    testWidgets('Push notification permission request and handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test notification permission request
      final permissionStatus = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      expect(
        permissionStatus.authorizationStatus,
        isIn([AuthorizationStatus.authorized, AuthorizationStatus.provisional, AuthorizationStatus.denied]),
      );

      // Verify FCM token is generated and stored
      final token = await messaging.getToken();
      expect(token, isNotNull);
      expect(token!.isNotEmpty, isTrue);

      // Verify token is stored in Firestore
      final userDoc = await firestore.collection('users').doc(testUserUuid).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['fcmToken'], isNotNull);
    });

    testWidgets('Weekly report notification delivery', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a weekly report to trigger notification
      await _createWeeklyReportForNotification(firestore, testUserUuid);

      // Wait for notification processing
      await tester.pump(const Duration(seconds: 2));

      // Verify notification was sent (check notification history)
      final notificationQuery =
          await firestore
              .collection('notificationHistory')
              .where('userUuid', isEqualTo: testUserUuid)
              .where('type', isEqualTo: 'weekly_report')
              .get();

      expect(notificationQuery.docs.isNotEmpty, isTrue);

      final notificationDoc = notificationQuery.docs.first;
      expect(notificationDoc.data()['status'], equals('sent'));
      expect(notificationDoc.data()['title'], contains('주간 리포트'));
      expect(notificationDoc.data()['body'], contains('분석이 완료'));
    });

    testWidgets('Notification tap navigation to weekly report', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate notification tap with payload
      const notificationPayload = {'type': 'weekly_report', 'reportId': 'test-report-123', 'userUuid': testUserUuid};

      // Create the report that the notification references
      await _createWeeklyReportForNotification(firestore, testUserUuid, reportId: 'test-report-123');

      // Simulate notification tap (this would normally come from FCM)
      await _simulateNotificationTap(tester, notificationPayload);

      // Verify navigation to weekly report page
      expect(find.byType(WeeklyReportPage), findsOneWidget);
      expect(find.text('주간 분석 리포트'), findsOneWidget);

      // Verify the correct report is displayed
      expect(find.byKey(const Key('report_summary_card')), findsOneWidget);
      expect(find.byKey(const Key('exercise_analysis_section')), findsOneWidget);
      expect(find.byKey(const Key('diet_analysis_section')), findsOneWidget);
    });

    testWidgets('In-app notification indicator when push disabled', (WidgetTester tester) async {
      // Simulate push notifications being disabled
      await _disablePushNotifications(firestore, testUserUuid);

      app.main();
      await tester.pumpAndSettle();

      // Create a new weekly report
      await _createWeeklyReportForNotification(firestore, testUserUuid);

      // Wait for processing
      await tester.pump(const Duration(seconds: 1));

      // Verify in-app notification indicator appears
      expect(find.byKey(const Key('in_app_notification_indicator')), findsOneWidget);
      expect(find.textContaining('새로운 주간 리포트'), findsOneWidget);

      // Test tapping the in-app notification
      await tester.tap(find.byKey(const Key('in_app_notification_indicator')));
      await tester.pumpAndSettle();

      // Verify navigation to weekly report
      expect(find.byType(WeeklyReportPage), findsOneWidget);

      // Verify indicator disappears after viewing
      expect(find.byKey(const Key('in_app_notification_indicator')), findsNothing);
    });

    testWidgets('Notification consolidation for multiple reports', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create multiple weekly reports in quick succession
      await _createWeeklyReportForNotification(firestore, testUserUuid, reportId: 'report-1');
      await _createWeeklyReportForNotification(firestore, testUserUuid, reportId: 'report-2');
      await _createWeeklyReportForNotification(firestore, testUserUuid, reportId: 'report-3');

      // Wait for notification processing
      await tester.pump(const Duration(seconds: 3));

      // Verify only one consolidated notification was sent
      final notificationQuery =
          await firestore
              .collection('notificationHistory')
              .where('userUuid', isEqualTo: testUserUuid)
              .where('type', isEqualTo: 'weekly_report_consolidated')
              .get();

      expect(notificationQuery.docs.length, equals(1));

      final consolidatedNotification = notificationQuery.docs.first;
      expect(consolidatedNotification.data()['title'], contains('주간 리포트'));
      expect(consolidatedNotification.data()['body'], contains('3개의 새로운'));
    });

    testWidgets('Notification settings management', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to notification settings
      await tester.tap(find.byKey(const Key('settings_menu')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_settings')));
      await tester.pumpAndSettle();

      // Verify notification settings page
      expect(find.text('알림 설정'), findsOneWidget);
      expect(find.byKey(const Key('weekly_report_notifications_toggle')), findsOneWidget);

      // Test toggling weekly report notifications
      await tester.tap(find.byKey(const Key('weekly_report_notifications_toggle')));
      await tester.pumpAndSettle();

      // Verify setting is saved
      final userDoc = await firestore.collection('users').doc(testUserUuid).get();
      final notificationSettings = userDoc.data()?['notificationSettings'] as Map<String, dynamic>?;
      expect(notificationSettings?['weeklyReports'], isFalse);

      // Create a report and verify no notification is sent
      await _createWeeklyReportForNotification(firestore, testUserUuid);
      await tester.pump(const Duration(seconds: 2));

      final notificationQuery =
          await firestore.collection('notificationHistory').where('userUuid', isEqualTo: testUserUuid).get();

      expect(notificationQuery.docs.isEmpty, isTrue);
    });

    testWidgets('Notification history tracking', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create multiple reports over time to generate notification history
      await _createWeeklyReportForNotification(firestore, testUserUuid, reportId: 'history-1');
      await tester.pump(const Duration(seconds: 1));

      await _createWeeklyReportForNotification(firestore, testUserUuid, reportId: 'history-2');
      await tester.pump(const Duration(seconds: 1));

      // Navigate to notification history
      await tester.tap(find.byKey(const Key('notification_history_nav')));
      await tester.pumpAndSettle();

      // Verify notification history page
      expect(find.text('알림 기록'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Verify notification items are displayed
      expect(find.byKey(const Key('notification_history_item')), findsWidgets);
      expect(find.textContaining('주간 리포트'), findsWidgets);

      // Test tapping on a notification history item
      await tester.tap(find.byKey(const Key('notification_history_item')).first);
      await tester.pumpAndSettle();

      // Verify navigation to the related report
      expect(find.byType(WeeklyReportPage), findsOneWidget);
    });

    testWidgets('Notification retry mechanism for failures', (WidgetTester tester) async {
      // Simulate FCM service being temporarily unavailable
      await _simulateFCMFailure(firestore, testUserUuid);

      app.main();
      await tester.pumpAndSettle();

      // Create a weekly report
      await _createWeeklyReportForNotification(firestore, testUserUuid);

      // Wait for initial failure and retry attempts
      await tester.pump(const Duration(seconds: 5));

      // Verify retry attempts were made
      final notificationQuery =
          await firestore.collection('notificationQueue').where('userUuid', isEqualTo: testUserUuid).get();

      expect(notificationQuery.docs.isNotEmpty, isTrue);

      final queueItem = notificationQuery.docs.first;
      expect(queueItem.data()['retryCount'], greaterThan(0));
      expect(queueItem.data()['status'], isIn(['retrying', 'failed']));

      // Simulate FCM service recovery
      await _simulateFCMRecovery(firestore, testUserUuid);
      await tester.pump(const Duration(seconds: 2));

      // Verify notification was eventually sent
      final historyQuery =
          await firestore.collection('notificationHistory').where('userUuid', isEqualTo: testUserUuid).get();

      expect(historyQuery.docs.isNotEmpty, isTrue);
      expect(historyQuery.docs.first.data()['status'], equals('sent'));
    });
  });
}

// Helper functions for notification testing

Future<void> _setupNotificationTestUser(FirebaseFirestore firestore, String userUuid, String nickname) async {
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token-$userUuid',
    'notificationSettings': {'weeklyReports': true, 'generalUpdates': true},
  });
}

Future<void> _createWeeklyReportForNotification(
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
  };

  if (reportId != null) {
    await firestore.collection('weeklyReports').doc(reportId).set(reportData);
  } else {
    await firestore.collection('weeklyReports').add(reportData);
  }

  // Simulate notification queue creation (normally done by Cloud Function)
  await firestore.collection('notificationQueue').add({
    'userUuid': userUuid,
    'type': 'weekly_report',
    'reportId': reportId ?? 'auto-generated',
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'retryCount': 0,
  });
}

Future<void> _simulateNotificationTap(WidgetTester tester, Map<String, dynamic> payload) async {
  // This simulates the app being opened from a notification tap
  // In a real scenario, this would be handled by the FCM message handler

  // Navigate to the appropriate screen based on payload
  if (payload['type'] == 'weekly_report') {
    await tester.tap(find.byKey(const Key('weekly_report_nav')));
    await tester.pumpAndSettle();
  }
}

Future<void> _disablePushNotifications(FirebaseFirestore firestore, String userUuid) async {
  await firestore.collection('users').doc(userUuid).update({
    'notificationSettings.weeklyReports': false,
    'pushNotificationsEnabled': false,
  });
}

Future<void> _simulateFCMFailure(FirebaseFirestore firestore, String userUuid) async {
  // Create a mock FCM failure scenario
  await firestore.collection('systemStatus').doc('fcm').set({
    'status': 'unavailable',
    'lastFailure': FieldValue.serverTimestamp(),
    'affectedUsers': [userUuid],
  });
}

Future<void> _simulateFCMRecovery(FirebaseFirestore firestore, String userUuid) async {
  // Simulate FCM service recovery
  await firestore.collection('systemStatus').doc('fcm').set({
    'status': 'available',
    'lastRecovery': FieldValue.serverTimestamp(),
  });

  // Process pending notifications
  final pendingQuery =
      await firestore
          .collection('notificationQueue')
          .where('userUuid', isEqualTo: userUuid)
          .where('status', isEqualTo: 'retrying')
          .get();

  for (final doc in pendingQuery.docs) {
    // Simulate successful notification send
    await firestore.collection('notificationHistory').add({
      'userUuid': userUuid,
      'type': doc.data()['type'],
      'title': '주간 리포트가 준비되었습니다',
      'body': 'AI 분석이 완료되었습니다. 지금 확인해보세요!',
      'status': 'sent',
      'sentAt': FieldValue.serverTimestamp(),
      'originalQueueId': doc.id,
    });

    // Remove from queue
    await doc.reference.delete();
  }
}

Future<void> _cleanupNotificationTestData(FirebaseFirestore firestore, String userUuid) async {
  // Clean up user data
  await firestore.collection('users').doc(userUuid).delete();

  // Clean up weekly reports
  final reportsQuery = await firestore.collection('weeklyReports').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in reportsQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up notification history
  final historyQuery = await firestore.collection('notificationHistory').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in historyQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up notification queue
  final queueQuery = await firestore.collection('notificationQueue').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in queueQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up system status
  await firestore.collection('systemStatus').doc('fcm').delete();
}
