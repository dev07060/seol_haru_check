import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/widgets/report/historical_reports_section.dart';

import '../../helpers/test_data_helper.dart';
import '../../providers/weekly_report_provider_test.mocks.dart';

void main() {
  group('HistoricalReportsSection Enhanced Features', () {
    late MockWeeklyReportService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockWeeklyReportService();
      container = ProviderContainer(overrides: [weeklyReportServiceProvider.overrideWithValue(mockService)]);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should show category trends toggle when enough data', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(5);

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Should show category trends toggle
      expect(find.text('카테고리 트렌드 분석'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should not show category trends toggle with insufficient data', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(2);

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show category trends toggle
      expect(find.text('카테고리 트렌드 분석'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('should show category trend visualizations when toggle is enabled', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(8);

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the toggle switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should show category trend section
      expect(find.text('카테고리 트렌드 분석'), findsAtLeastNWidgets(1));
      expect(find.text('시간에 따른 운동과 식단 카테고리의 변화를 분석합니다'), findsOneWidget);
    });

    testWidgets('should show seasonality charts with enough monthly data', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(24); // 6 months of data

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Enable category trends
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should show seasonality charts
      expect(find.text('운동 월별 패턴'), findsOneWidget);
      expect(find.text('식단 월별 패턴'), findsOneWidget);
    });

    testWidgets('should show progress tracker with enough weekly data', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(10); // 10 weeks of data

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Enable category trends
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should show progress tracker
      expect(find.text('운동 카테고리별 월간 진행도'), findsOneWidget);
      expect(find.text('식단 카테고리별 월간 진행도'), findsOneWidget);
    });

    testWidgets('should handle category selection in trend charts', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(6);

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Enable category trends
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should be able to interact with category trend charts
      expect(find.text('운동 카테고리 트렌드'), findsOneWidget);
      expect(find.text('식단 카테고리 트렌드'), findsOneWidget);
    });

    testWidgets('should maintain existing historical report functionality', (tester) async {
      final mockReports = TestDataHelper.createMockHistoricalReports(5);

      when(
        mockService.fetchUserReports(userUuid: anyNamed('userUuid'), limit: anyNamed('limit')),
      ).thenAnswer((_) async => mockReports);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HistoricalReportsSection())),
        ),
      );

      await tester.pumpAndSettle();

      // Should still show historical reports list
      expect(find.text('이전 주차'), findsOneWidget);
      expect(find.text('날짜 선택'), findsOneWidget);

      // Should show historical report cards
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });
  });
}
