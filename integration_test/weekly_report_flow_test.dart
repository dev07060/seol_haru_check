import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seol_haru_check/main.dart' as app;
import 'package:seol_haru_check/pages/weekly_report_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Weekly Report Generation E2E Flow', () {
    late FirebaseFirestore firestore;
    late FirebaseAuth auth;
    const testUserUuid = 'test-user-integration-001';
    const testUserNickname = 'TestUser';

    setUpAll(() async {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
      auth = FirebaseAuth.instance;
    });

    setUp(() async {
      // Clean up any existing test data
      await _cleanupTestData(firestore, testUserUuid);

      // Create test user data
      await _setupTestUser(firestore, testUserUuid, testUserNickname);
    });

    tearDown(() async {
      // Clean up test data after each test
      await _cleanupTestData(firestore, testUserUuid);
    });

    testWidgets('Complete weekly report generation workflow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Create sufficient certification data for analysis
      await _createTestCertifications(firestore, testUserUuid, testUserNickname);

      // Step 2: Trigger weekly analysis (simulate Cloud Function trigger)
      await _triggerWeeklyAnalysis(firestore, testUserUuid);

      // Step 3: Wait for report generation
      await tester.pump(const Duration(seconds: 2));

      // Step 4: Navigate to weekly report page
      await tester.tap(find.byKey(const Key('weekly_report_nav')));
      await tester.pumpAndSettle();

      // Step 5: Verify report is displayed
      expect(find.byType(WeeklyReportPage), findsOneWidget);
      expect(find.text('주간 분석 리포트'), findsOneWidget);

      // Step 6: Verify report content sections are present
      expect(find.byKey(const Key('report_summary_card')), findsOneWidget);
      expect(find.byKey(const Key('exercise_analysis_section')), findsOneWidget);
      expect(find.byKey(const Key('diet_analysis_section')), findsOneWidget);
      expect(find.byKey(const Key('recommendations_section')), findsOneWidget);

      // Step 7: Verify statistics are displayed correctly
      expect(find.textContaining('총 인증'), findsOneWidget);
      expect(find.textContaining('운동 일수'), findsOneWidget);
      expect(find.textContaining('식단 일수'), findsOneWidget);

      // Step 8: Verify AI analysis content is present
      expect(find.textContaining('운동 분석'), findsOneWidget);
      expect(find.textContaining('식단 분석'), findsOneWidget);
      expect(find.textContaining('추천사항'), findsOneWidget);
    });

    testWidgets('Historical report browsing functionality', (WidgetTester tester) async {
      // Create multiple weeks of test data
      await _createMultipleWeeksTestData(firestore, testUserUuid, testUserNickname);

      app.main();
      await tester.pumpAndSettle();

      // Navigate to weekly report page
      await tester.tap(find.byKey(const Key('weekly_report_nav')));
      await tester.pumpAndSettle();

      // Test date navigation
      await tester.tap(find.byKey(const Key('previous_week_button')));
      await tester.pumpAndSettle();

      // Verify previous week's report is loaded
      expect(find.byType(WeeklyReportPage), findsOneWidget);

      // Test next week navigation
      await tester.tap(find.byKey(const Key('next_week_button')));
      await tester.pumpAndSettle();

      // Test report list view
      await tester.tap(find.byKey(const Key('report_history_button')));
      await tester.pumpAndSettle();

      // Verify historical reports list
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byKey(const Key('historical_report_item')), findsWidgets);

      // Test selecting a historical report
      await tester.tap(find.byKey(const Key('historical_report_item')).first);
      await tester.pumpAndSettle();

      // Verify selected report is displayed
      expect(find.byType(WeeklyReportPage), findsOneWidget);
    });

    testWidgets('Error handling and retry mechanisms', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to weekly report page without data
      await tester.tap(find.byKey(const Key('weekly_report_nav')));
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.byKey(const Key('empty_state_widget')), findsOneWidget);
      expect(find.textContaining('아직 생성된 리포트가 없습니다'), findsOneWidget);

      // Test retry functionality
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Loading states during report generation', (WidgetTester tester) async {
      // Create test data but don't generate report yet
      await _createTestCertifications(firestore, testUserUuid, testUserNickname);

      app.main();
      await tester.pumpAndSettle();

      // Navigate to weekly report page
      await tester.tap(find.byKey(const Key('weekly_report_nav')));
      await tester.pumpAndSettle();

      // Trigger report generation
      await _triggerWeeklyAnalysis(firestore, testUserUuid);

      // Verify loading state is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('리포트 생성 중'), findsOneWidget);

      // Wait for completion and verify report appears
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(WeeklyReportPage), findsOneWidget);
      expect(find.byKey(const Key('report_summary_card')), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('Large dataset handling performance', (WidgetTester tester) async {
      const largeUserUuid = 'large-dataset-user';
      const largeUserNickname = 'LargeDataUser';

      // Create large dataset (6 months of data)
      await _createLargeDataset(FirebaseFirestore.instance, largeUserUuid, largeUserNickname);

      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      // Navigate to weekly report page
      await tester.tap(find.byKey(const Key('weekly_report_nav')));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Verify performance is acceptable (under 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      // Verify UI is responsive
      expect(find.byType(WeeklyReportPage), findsOneWidget);

      // Test scrolling performance with large dataset
      final scrollStopwatch = Stopwatch()..start();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      scrollStopwatch.stop();

      // Verify scrolling is smooth (under 100ms)
      expect(scrollStopwatch.elapsedMilliseconds, lessThan(100));

      // Clean up large dataset
      await _cleanupTestData(FirebaseFirestore.instance, largeUserUuid);
    });

    testWidgets('Memory usage during report browsing', (WidgetTester tester) async {
      const memoryTestUser = 'memory-test-user';
      const memoryTestNickname = 'MemoryTestUser';

      // Create multiple weeks of data
      await _createMultipleWeeksTestData(FirebaseFirestore.instance, memoryTestUser, memoryTestNickname);

      app.main();
      await tester.pumpAndSettle();

      // Navigate to weekly report page
      await tester.tap(find.byKey(const Key('weekly_report_nav')));
      await tester.pumpAndSettle();

      // Browse through multiple reports rapidly
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const Key('previous_week_button')));
        await tester.pumpAndSettle();

        // Verify UI remains responsive
        expect(find.byType(WeeklyReportPage), findsOneWidget);
      }

      // Navigate back to current week
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const Key('next_week_button')));
        await tester.pumpAndSettle();
      }

      // Verify no memory leaks (UI still responsive)
      expect(find.byType(WeeklyReportPage), findsOneWidget);

      // Clean up
      await _cleanupTestData(FirebaseFirestore.instance, memoryTestUser);
    });
  });
}

// Helper functions for test setup and cleanup

Future<void> _setupTestUser(FirebaseFirestore firestore, String userUuid, String nickname) async {
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token',
  });
}

Future<void> _createTestCertifications(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday % 7));

  // Create certifications for 5 days of the week
  for (int i = 0; i < 5; i++) {
    final certificationDate = weekStart.add(Duration(days: i));

    // Exercise certification
    await firestore.collection('certifications').add({
      'uuid': userUuid,
      'nickname': nickname,
      'type': '운동',
      'content': '테스트 운동 인증 $i',
      'photoUrl': 'https://example.com/photo$i.jpg',
      'createdAt': Timestamp.fromDate(certificationDate),
    });

    // Diet certification
    await firestore.collection('certifications').add({
      'uuid': userUuid,
      'nickname': nickname,
      'type': '식단',
      'content': '테스트 식단 인증 $i',
      'photoUrl': 'https://example.com/diet$i.jpg',
      'createdAt': Timestamp.fromDate(certificationDate),
    });
  }
}

Future<void> _triggerWeeklyAnalysis(FirebaseFirestore firestore, String userUuid) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday % 7));
  final weekEnd = weekStart.add(const Duration(days: 6));

  // Create analysis queue item (simulates Cloud Function trigger)
  await firestore.collection('analysisQueue').add({
    'userUuid': userUuid,
    'weekStartDate': Timestamp.fromDate(weekStart),
    'weekEndDate': Timestamp.fromDate(weekEnd),
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'retryCount': 0,
  });

  // Simulate report generation (in real scenario, this would be done by Cloud Function)
  await _generateMockReport(firestore, userUuid, weekStart, weekEnd);
}

Future<void> _generateMockReport(
  FirebaseFirestore firestore,
  String userUuid,
  DateTime weekStart,
  DateTime weekEnd,
) async {
  final reportData = {
    'userUuid': userUuid,
    'weekStartDate': Timestamp.fromDate(weekStart),
    'weekEndDate': Timestamp.fromDate(weekEnd),
    'generatedAt': FieldValue.serverTimestamp(),
    'stats': {
      'totalCertifications': 10,
      'exerciseDays': 5,
      'dietDays': 5,
      'exerciseTypes': {'헬스': 3, '러닝': 2},
      'consistencyScore': 0.85,
    },
    'analysis': {
      'exerciseInsights': '이번 주 운동 패턴이 매우 좋습니다. 꾸준한 헬스와 러닝으로 균형잡힌 운동을 하고 계시네요.',
      'dietInsights': '식단 관리도 잘 하고 계십니다. 다양한 영양소를 골고루 섭취하고 있어 보입니다.',
      'overallAssessment': '전반적으로 건강한 라이프스타일을 유지하고 계십니다.',
      'strengthAreas': ['운동 일관성', '식단 다양성'],
      'improvementAreas': ['수분 섭취', '수면 패턴'],
    },
    'recommendations': ['하루 2L 이상의 물을 마시세요', '규칙적인 수면 패턴을 유지하세요', '주 1회 이상 새로운 운동을 시도해보세요'],
    'status': 'completed',
  };

  await firestore.collection('weeklyReports').add(reportData);
}

Future<void> _createMultipleWeeksTestData(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();

  // Create data for 4 weeks
  for (int week = 0; week < 4; week++) {
    final weekStart = now.subtract(Duration(days: (now.weekday % 7) + (week * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Create certifications for this week
    for (int day = 0; day < 5; day++) {
      final certificationDate = weekStart.add(Duration(days: day));

      await firestore.collection('certifications').add({
        'uuid': userUuid,
        'nickname': nickname,
        'type': '운동',
        'content': '주 $week 운동 인증 $day',
        'photoUrl': 'https://example.com/week${week}_exercise$day.jpg',
        'createdAt': Timestamp.fromDate(certificationDate),
      });

      await firestore.collection('certifications').add({
        'uuid': userUuid,
        'nickname': nickname,
        'type': '식단',
        'content': '주 $week 식단 인증 $day',
        'photoUrl': 'https://example.com/week${week}_diet$day.jpg',
        'createdAt': Timestamp.fromDate(certificationDate),
      });
    }

    // Generate report for this week
    await _generateMockReport(firestore, userUuid, weekStart, weekEnd);
  }
}

Future<void> _createLargeDataset(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();

  // Create 6 months of data (26 weeks)
  for (int week = 0; week < 26; week++) {
    final weekStart = now.subtract(Duration(days: (now.weekday % 7) + (week * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Create certifications for this week (3-7 days randomly)
    final daysWithCertifications = 3 + (week % 5); // 3-7 days

    for (int day = 0; day < daysWithCertifications; day++) {
      final certificationDate = weekStart.add(Duration(days: day));

      // Multiple certifications per day
      for (int cert = 0; cert < 2; cert++) {
        await firestore.collection('certifications').add({
          'uuid': userUuid,
          'nickname': nickname,
          'type': cert == 0 ? '운동' : '식단',
          'content': '주 $week 일 $day ${cert == 0 ? '운동' : '식단'} 인증',
          'photoUrl': 'https://example.com/large_week${week}_day${day}_cert$cert.jpg',
          'createdAt': Timestamp.fromDate(certificationDate.add(Duration(hours: cert * 6))),
        });
      }
    }

    // Generate report for this week
    await _generateMockReport(firestore, userUuid, weekStart, weekEnd);
  }
}

Future<void> _cleanupTestData(FirebaseFirestore firestore, String userUuid) async {
  // Clean up user data
  await firestore.collection('users').doc(userUuid).delete();

  // Clean up certifications
  final certificationsQuery = await firestore.collection('certifications').where('uuid', isEqualTo: userUuid).get();

  for (final doc in certificationsQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up weekly reports
  final reportsQuery = await firestore.collection('weeklyReports').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in reportsQuery.docs) {
    await doc.reference.delete();
  }

  // Clean up analysis queue
  final queueQuery = await firestore.collection('analysisQueue').where('userUuid', isEqualTo: userUuid).get();

  for (final doc in queueQuery.docs) {
    await doc.reference.delete();
  }
}
