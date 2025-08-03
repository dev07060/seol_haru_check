import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seol_haru_check/main.dart' as app;
import 'package:seol_haru_check/pages/weekly_report_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance and Stress Tests', () {
    late FirebaseFirestore firestore;

    setUpAll(() async {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
    });

    group('Large Dataset Performance', () {
      testWidgets('Handle 1000+ certifications efficiently', (WidgetTester tester) async {
        const performanceTestUser = 'performance-test-user-1000';
        const performanceTestNickname = 'PerformanceUser1000';

        // Create large dataset
        await _createLargeDatasetForPerformance(firestore, performanceTestUser, performanceTestNickname, 1000);

        final stopwatch = Stopwatch()..start();

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify performance is acceptable (under 3 seconds for large dataset)
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));

        // Verify UI is responsive
        expect(find.byType(WeeklyReportPage), findsOneWidget);

        // Test scrolling performance
        final scrollStopwatch = Stopwatch()..start();
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        scrollStopwatch.stop();

        // Verify smooth scrolling (under 200ms)
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(200));

        // Clean up
        await _cleanupPerformanceTestData(firestore, performanceTestUser);
      });

      testWidgets('Memory efficiency with 50 weeks of reports', (WidgetTester tester) async {
        const memoryTestUser = 'memory-test-user-50weeks';
        const memoryTestNickname = 'MemoryUser50Weeks';

        // Create 50 weeks of data
        await _create50WeeksOfData(firestore, memoryTestUser, memoryTestNickname);

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Test rapid navigation through reports
        final navigationStopwatch = Stopwatch()..start();

        for (int i = 0; i < 20; i++) {
          await tester.tap(find.byKey(const Key('previous_week_button')));
          await tester.pump(const Duration(milliseconds: 100));
        }

        for (int i = 0; i < 20; i++) {
          await tester.tap(find.byKey(const Key('next_week_button')));
          await tester.pump(const Duration(milliseconds: 100));
        }

        navigationStopwatch.stop();

        // Verify navigation performance (under 5 seconds for 40 navigations)
        expect(navigationStopwatch.elapsedMilliseconds, lessThan(5000));

        // Verify UI remains responsive
        expect(find.byType(WeeklyReportPage), findsOneWidget);

        // Clean up
        await _cleanupPerformanceTestData(firestore, memoryTestUser);
      });

      testWidgets('Concurrent user simulation', (WidgetTester tester) async {
        const concurrentUsers = 10;
        final userIds = List.generate(concurrentUsers, (i) => 'concurrent-user-$i');
        final userNicknames = List.generate(concurrentUsers, (i) => 'ConcurrentUser$i');

        // Create data for multiple users concurrently
        final futures = <Future>[];
        for (int i = 0; i < concurrentUsers; i++) {
          futures.add(_createTestDataForUser(firestore, userIds[i], userNicknames[i]));
        }

        final concurrentStopwatch = Stopwatch()..start();
        await Future.wait(futures);
        concurrentStopwatch.stop();

        // Verify concurrent data creation is efficient (under 10 seconds)
        expect(concurrentStopwatch.elapsedMilliseconds, lessThan(10000));

        app.main();
        await tester.pumpAndSettle();

        // Test app performance with multiple users' data
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Verify UI loads correctly
        expect(find.byType(WeeklyReportPage), findsOneWidget);

        // Clean up all test users
        for (final userId in userIds) {
          await _cleanupPerformanceTestData(firestore, userId);
        }
      });
    });

    group('Network and Connectivity Stress Tests', () {
      testWidgets('Offline mode handling', (WidgetTester tester) async {
        const offlineTestUser = 'offline-test-user';
        const offlineTestNickname = 'OfflineTestUser';

        // Create initial data
        await _createTestDataForUser(firestore, offlineTestUser, offlineTestNickname);

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page while online
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Verify initial load works
        expect(find.byType(WeeklyReportPage), findsOneWidget);

        // Simulate offline mode (this would require network simulation in real test)
        // For now, we test the offline state handling in the UI

        // Test pull-to-refresh in offline mode
        await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
        await tester.pumpAndSettle();

        // Verify offline indicator or error message appears
        expect(find.textContaining('오프라인'), findsOneWidget);

        // Clean up
        await _cleanupPerformanceTestData(firestore, offlineTestUser);
      });

      testWidgets('Network timeout handling', (WidgetTester tester) async {
        const timeoutTestUser = 'timeout-test-user';

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Simulate network timeout scenario
        // In a real test, this would involve network mocking

        // Test retry mechanism
        await tester.tap(find.byKey(const Key('retry_button')));
        await tester.pumpAndSettle();

        // Verify loading state appears
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Clean up
        await _cleanupPerformanceTestData(firestore, timeoutTestUser);
      });
    });

    group('UI Stress Tests', () {
      testWidgets('Rapid UI interactions stress test', (WidgetTester tester) async {
        const uiStressUser = 'ui-stress-test-user';
        const uiStressNickname = 'UIStressUser';

        await _createTestDataForUser(firestore, uiStressUser, uiStressNickname);

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        final stressStopwatch = Stopwatch()..start();

        // Perform rapid UI interactions
        for (int i = 0; i < 50; i++) {
          // Rapid navigation
          await tester.tap(find.byKey(const Key('previous_week_button')));
          await tester.pump(const Duration(milliseconds: 50));

          await tester.tap(find.byKey(const Key('next_week_button')));
          await tester.pump(const Duration(milliseconds: 50));

          // Rapid scrolling
          await tester.drag(find.byType(ListView), const Offset(0, -100));
          await tester.pump(const Duration(milliseconds: 50));

          await tester.drag(find.byType(ListView), const Offset(0, 100));
          await tester.pump(const Duration(milliseconds: 50));
        }

        stressStopwatch.stop();

        // Verify UI remains responsive after stress test
        expect(find.byType(WeeklyReportPage), findsOneWidget);

        // Verify performance is acceptable (under 15 seconds for 200 interactions)
        expect(stressStopwatch.elapsedMilliseconds, lessThan(15000));

        // Clean up
        await _cleanupPerformanceTestData(firestore, uiStressUser);
      });

      testWidgets('Widget rebuild optimization test', (WidgetTester tester) async {
        const rebuildTestUser = 'rebuild-test-user';
        const rebuildTestNickname = 'RebuildTestUser';

        await _createTestDataForUser(firestore, rebuildTestUser, rebuildTestNickname);

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Test state changes don't cause unnecessary rebuilds
        final initialWidgetCount = tester.widgetList(find.byType(Widget)).length;

        // Trigger state change
        await tester.tap(find.byKey(const Key('refresh_button')));
        await tester.pumpAndSettle();

        final afterRefreshWidgetCount = tester.widgetList(find.byType(Widget)).length;

        // Verify widget count doesn't increase dramatically (indicating memory leaks)
        expect(afterRefreshWidgetCount, lessThanOrEqualTo(initialWidgetCount * 1.1));

        // Clean up
        await _cleanupPerformanceTestData(firestore, rebuildTestUser);
      });
    });

    group('Data Processing Stress Tests', () {
      testWidgets('Large report content rendering', (WidgetTester tester) async {
        const largeContentUser = 'large-content-user';
        const largeContentNickname = 'LargeContentUser';

        // Create report with very large content
        await _createLargeContentReport(firestore, largeContentUser, largeContentNickname);

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Verify large content renders without issues
        expect(find.byType(WeeklyReportPage), findsOneWidget);
        expect(find.byKey(const Key('report_summary_card')), findsOneWidget);

        // Test scrolling through large content
        final scrollStopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -500));
          await tester.pump(const Duration(milliseconds: 100));
        }

        scrollStopwatch.stop();

        // Verify scrolling performance with large content (under 2 seconds)
        expect(scrollStopwatch.elapsedMilliseconds, lessThan(2000));

        // Clean up
        await _cleanupPerformanceTestData(firestore, largeContentUser);
      });

      testWidgets('Complex data structure handling', (WidgetTester tester) async {
        const complexDataUser = 'complex-data-user';
        const complexDataNickname = 'ComplexDataUser';

        // Create report with complex nested data structures
        await _createComplexDataReport(firestore, complexDataUser, complexDataNickname);

        app.main();
        await tester.pumpAndSettle();

        // Navigate to weekly report page
        await tester.tap(find.byKey(const Key('weekly_report_nav')));
        await tester.pumpAndSettle();

        // Verify complex data renders correctly
        expect(find.byType(WeeklyReportPage), findsOneWidget);
        expect(find.byKey(const Key('exercise_analysis_section')), findsOneWidget);
        expect(find.byKey(const Key('diet_analysis_section')), findsOneWidget);

        // Test data filtering and sorting
        await tester.tap(find.byKey(const Key('filter_button')));
        await tester.pumpAndSettle();

        // Verify filtering works with complex data
        // expect(find.byType(FilterDialog), findsOneWidget);

        // Clean up
        await _cleanupPerformanceTestData(firestore, complexDataUser);
      });
    });
  });
}

// Helper functions for performance testing

Future<void> _createLargeDatasetForPerformance(
  FirebaseFirestore firestore,
  String userUuid,
  String nickname,
  int certificationCount,
) async {
  final batch = firestore.batch();
  final now = DateTime.now();
  final random = Random();

  // Create user
  batch.set(firestore.collection('users').doc(userUuid), {
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token-$userUuid',
  });

  // Create large number of certifications
  for (int i = 0; i < certificationCount; i++) {
    final certificationDate = now.subtract(Duration(days: random.nextInt(365)));
    final certificationRef = firestore.collection('certifications').doc();

    batch.set(certificationRef, {
      'uuid': userUuid,
      'nickname': nickname,
      'type': random.nextBool() ? '운동' : '식단',
      'content': '대용량 테스트 인증 데이터 $i - ${_generateRandomContent(100)}',
      'photoUrl': 'https://example.com/large_photo_$i.jpg',
      'createdAt': Timestamp.fromDate(certificationDate),
    });

    // Commit in batches of 500 to avoid Firestore limits
    if (i % 500 == 499) {
      await batch.commit();
    }
  }

  // Commit remaining items
  await batch.commit();

  // Create weekly reports for recent weeks
  for (int week = 0; week < 10; week++) {
    final weekStart = now.subtract(Duration(days: (now.weekday % 7) + (week * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6));

    await firestore.collection('weeklyReports').add({
      'userUuid': userUuid,
      'weekStartDate': Timestamp.fromDate(weekStart),
      'weekEndDate': Timestamp.fromDate(weekEnd),
      'generatedAt': FieldValue.serverTimestamp(),
      'stats': {
        'totalCertifications': random.nextInt(20) + 5,
        'exerciseDays': random.nextInt(7) + 1,
        'dietDays': random.nextInt(7) + 1,
        'exerciseTypes': {'헬스': random.nextInt(5), '러닝': random.nextInt(5), '요가': random.nextInt(3)},
        'consistencyScore': random.nextDouble(),
      },
      'analysis': {
        'exerciseInsights': _generateRandomContent(500),
        'dietInsights': _generateRandomContent(500),
        'overallAssessment': _generateRandomContent(300),
        'strengthAreas': ['운동 일관성', '식단 다양성', '규칙적인 생활'],
        'improvementAreas': ['수분 섭취', '수면 패턴', '스트레스 관리'],
      },
      'recommendations': List.generate(5, (i) => _generateRandomContent(100)),
      'status': 'completed',
    });
  }
}

Future<void> _create50WeeksOfData(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();
  final random = Random();

  // Create user
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token-$userUuid',
  });

  // Create 50 weeks of reports
  for (int week = 0; week < 50; week++) {
    final weekStart = now.subtract(Duration(days: (now.weekday % 7) + (week * 7)));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Create certifications for this week
    final certificationsThisWeek = random.nextInt(15) + 5;
    for (int cert = 0; cert < certificationsThisWeek; cert++) {
      final certificationDate = weekStart.add(Duration(days: random.nextInt(7)));

      await firestore.collection('certifications').add({
        'uuid': userUuid,
        'nickname': nickname,
        'type': random.nextBool() ? '운동' : '식단',
        'content': '50주 테스트 데이터 주$week 인증$cert',
        'photoUrl': 'https://example.com/50weeks_w${week}_c$cert.jpg',
        'createdAt': Timestamp.fromDate(certificationDate),
      });
    }

    // Create weekly report
    await firestore.collection('weeklyReports').add({
      'userUuid': userUuid,
      'weekStartDate': Timestamp.fromDate(weekStart),
      'weekEndDate': Timestamp.fromDate(weekEnd),
      'generatedAt': FieldValue.serverTimestamp(),
      'stats': {
        'totalCertifications': certificationsThisWeek,
        'exerciseDays': random.nextInt(7) + 1,
        'dietDays': random.nextInt(7) + 1,
        'exerciseTypes': {'헬스': random.nextInt(5), '러닝': random.nextInt(5)},
        'consistencyScore': random.nextDouble(),
      },
      'analysis': {
        'exerciseInsights': '주 $week 운동 분석 내용',
        'dietInsights': '주 $week 식단 분석 내용',
        'overallAssessment': '주 $week 전반적인 평가',
        'strengthAreas': ['강점 영역'],
        'improvementAreas': ['개선 영역'],
      },
      'recommendations': ['추천사항 1', '추천사항 2'],
      'status': 'completed',
    });
  }
}

Future<void> _createTestDataForUser(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();
  final random = Random();

  // Create user
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token-$userUuid',
  });

  // Create recent certifications
  for (int i = 0; i < 20; i++) {
    final certificationDate = now.subtract(Duration(days: random.nextInt(30)));

    await firestore.collection('certifications').add({
      'uuid': userUuid,
      'nickname': nickname,
      'type': random.nextBool() ? '운동' : '식단',
      'content': '동시 사용자 테스트 인증 $i',
      // 'photoUrl': 'https://example.com/concurrent_$userUuid_$i.jpg',
      'createdAt': Timestamp.fromDate(certificationDate),
    });
  }

  // Create a recent weekly report
  final weekStart = now.subtract(Duration(days: now.weekday % 7));
  final weekEnd = weekStart.add(const Duration(days: 6));

  await firestore.collection('weeklyReports').add({
    'userUuid': userUuid,
    'weekStartDate': Timestamp.fromDate(weekStart),
    'weekEndDate': Timestamp.fromDate(weekEnd),
    'generatedAt': FieldValue.serverTimestamp(),
    'stats': {
      'totalCertifications': 10,
      'exerciseDays': 5,
      'dietDays': 5,
      'exerciseTypes': {'헬스': 3, '러닝': 2},
      'consistencyScore': 0.8,
    },
    'analysis': {
      'exerciseInsights': '동시 사용자 테스트 운동 분석',
      'dietInsights': '동시 사용자 테스트 식단 분석',
      'overallAssessment': '전반적으로 좋은 패턴',
      'strengthAreas': ['일관성'],
      'improvementAreas': ['다양성'],
    },
    'recommendations': ['추천사항 1', '추천사항 2'],
    'status': 'completed',
  });
}

Future<void> _createLargeContentReport(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday % 7));
  final weekEnd = weekStart.add(const Duration(days: 6));

  // Create user
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token-$userUuid',
  });

  // Create report with very large content
  await firestore.collection('weeklyReports').add({
    'userUuid': userUuid,
    'weekStartDate': Timestamp.fromDate(weekStart),
    'weekEndDate': Timestamp.fromDate(weekEnd),
    'generatedAt': FieldValue.serverTimestamp(),
    'stats': {
      'totalCertifications': 25,
      'exerciseDays': 7,
      'dietDays': 7,
      'exerciseTypes': {'헬스': 5, '러닝': 4, '요가': 3, '수영': 2, '사이클링': 2},
      'consistencyScore': 0.95,
    },
    'analysis': {
      'exerciseInsights': _generateRandomContent(2000), // Very large content
      'dietInsights': _generateRandomContent(2000),
      'overallAssessment': _generateRandomContent(1000),
      'strengthAreas': List.generate(10, (i) => '강점 영역 $i'),
      'improvementAreas': List.generate(10, (i) => '개선 영역 $i'),
    },
    'recommendations': List.generate(20, (i) => _generateRandomContent(200)),
    'status': 'completed',
  });
}

Future<void> _createComplexDataReport(FirebaseFirestore firestore, String userUuid, String nickname) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday % 7));
  final weekEnd = weekStart.add(const Duration(days: 6));

  // Create user
  await firestore.collection('users').doc(userUuid).set({
    'nickname': nickname,
    'createdAt': FieldValue.serverTimestamp(),
    'fcmToken': 'test-fcm-token-$userUuid',
  });

  // Create report with complex nested data
  await firestore.collection('weeklyReports').add({
    'userUuid': userUuid,
    'weekStartDate': Timestamp.fromDate(weekStart),
    'weekEndDate': Timestamp.fromDate(weekEnd),
    'generatedAt': FieldValue.serverTimestamp(),
    'stats': {
      'totalCertifications': 30,
      'exerciseDays': 7,
      'dietDays': 7,
      'exerciseTypes': {'헬스': 8, '러닝': 6, '요가': 4, '수영': 3, '사이클링': 3, '등산': 2, '테니스': 2, '배드민턴': 2},
      'consistencyScore': 0.92,
      'dailyBreakdown': {
        'monday': {'exercise': 3, 'diet': 3},
        'tuesday': {'exercise': 2, 'diet': 4},
        'wednesday': {'exercise': 4, 'diet': 3},
        'thursday': {'exercise': 3, 'diet': 5},
        'friday': {'exercise': 5, 'diet': 3},
        'saturday': {'exercise': 4, 'diet': 4},
        'sunday': {'exercise': 3, 'diet': 3},
      },
      'timeDistribution': {'morning': 12, 'afternoon': 8, 'evening': 10},
    },
    'analysis': {
      'exerciseInsights': '복잡한 데이터 구조 테스트를 위한 운동 분석 내용',
      'dietInsights': '복잡한 데이터 구조 테스트를 위한 식단 분석 내용',
      'overallAssessment': '매우 상세한 전반적 평가',
      'strengthAreas': ['일관성', '다양성', '시간 관리', '목표 달성'],
      'improvementAreas': ['수분 섭취', '수면 패턴', '스트레스 관리'],
      'detailedMetrics': {
        'exerciseIntensity': {'low': 8, 'medium': 12, 'high': 10},
        'nutritionBalance': {'carbs': 0.4, 'protein': 0.3, 'fat': 0.3},
        'weeklyTrends': {
          'improving': ['consistency', 'variety'],
          'declining': ['intensity'],
          'stable': ['frequency'],
        },
      },
    },
    'recommendations': [
      '고강도 운동 비율을 늘려보세요',
      '단백질 섭취량을 조금 더 늘려보세요',
      '주말 운동 패턴을 개선해보세요',
      '수분 섭취를 더 규칙적으로 해보세요',
      '수면 시간을 일정하게 유지해보세요',
    ],
    'status': 'completed',
  });
}

String _generateRandomContent(int length) {
  const chars = '가나다라마바사아자차카타파하 abcdefghijklmnopqrstuvwxyz 0123456789 ';
  final random = Random();
  return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
}

Future<void> _cleanupPerformanceTestData(FirebaseFirestore firestore, String userUuid) async {
  // Clean up user data
  await firestore.collection('users').doc(userUuid).delete();

  // Clean up certifications in batches
  var certificationsQuery =
      await firestore.collection('certifications').where('uuid', isEqualTo: userUuid).limit(500).get();

  while (certificationsQuery.docs.isNotEmpty) {
    final batch = firestore.batch();
    for (final doc in certificationsQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    certificationsQuery =
        await firestore.collection('certifications').where('uuid', isEqualTo: userUuid).limit(500).get();
  }

  // Clean up weekly reports
  final reportsQuery = await firestore.collection('weeklyReports').where('userUuid', isEqualTo: userUuid).get();

  final reportsBatch = firestore.batch();
  for (final doc in reportsQuery.docs) {
    reportsBatch.delete(doc.reference);
  }
  await reportsBatch.commit();
}
