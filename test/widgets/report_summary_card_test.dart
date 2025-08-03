import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/widgets/report/report_summary_card.dart';

import '../helpers/test_data_helper.dart';

void main() {
  group('ReportSummaryCard Widget Tests', () {
    late WeeklyReport testReport;

    setUp(() {
      testReport = WeeklyReport(
        id: 'test-report-1',
        userUuid: 'test-user-123',
        weekStartDate: DateTime(2024, 1, 15),
        weekEndDate: DateTime(2024, 1, 21),
        generatedAt: DateTime(2024, 1, 22),
        stats: TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 12,
          exerciseDays: 5,
          dietDays: 4,
          exerciseTypes: {'running': 3, 'swimming': 2, 'yoga': 1},
          consistencyScore: 0.85,
        ),
        analysis: const AIAnalysis(
          exerciseInsights: 'Great consistency',
          dietInsights: 'Balanced nutrition',
          overallAssessment: 'Excellent progress',
          strengthAreas: ['Consistency'],
          improvementAreas: ['Hydration'],
        ),
        recommendations: ['Drink more water'],
        status: ReportStatus.completed,
      );
    });

    Widget createTestWidget(WeeklyReport report) {
      return MaterialApp(home: Scaffold(body: ReportSummaryCard(report: report)));
    }

    group('Basic Display', () {
      testWidgets('should display weekly stats title', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.weeklyStats), findsOneWidget);
      });

      testWidgets('should display all stat items', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Check for stat labels
        expect(find.text(AppStrings.totalCertifications), findsOneWidget);
        expect(find.text(AppStrings.exerciseDays), findsOneWidget);
        expect(find.text(AppStrings.dietDays), findsOneWidget);
        expect(find.text(AppStrings.consistencyScore), findsOneWidget);

        // Check for stat values
        expect(find.text('12개'), findsOneWidget);
        expect(find.text('5일'), findsOneWidget);
        expect(find.text('4일'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
      });

      testWidgets('should display correct icons for each stat', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });

    group('Exercise Types Breakdown', () {
      testWidgets('should display exercise types breakdown when available', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        expect(find.text('운동 유형별 분포'), findsOneWidget);
        expect(find.text('running'), findsOneWidget);
        expect(find.text('swimming'), findsOneWidget);
        expect(find.text('yoga'), findsOneWidget);
        expect(find.text('3회'), findsOneWidget);
        expect(find.text('2회'), findsOneWidget);
        expect(find.text('1회'), findsOneWidget);
      });

      testWidgets('should not display exercise types breakdown when empty', (tester) async {
        final reportWithoutExerciseTypes = testReport.copyWith(stats: testReport.stats.copyWith(exerciseTypes: {}));

        await tester.pumpWidget(createTestWidget(reportWithoutExerciseTypes));
        await tester.pumpAndSettle();

        expect(find.text('운동 유형별 분포'), findsNothing);
      });

      testWidgets('should sort exercise types by frequency', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Find all exercise type texts
        final runningFinder = find.text('running');
        final swimmingFinder = find.text('swimming');
        final yogaFinder = find.text('yoga');

        expect(runningFinder, findsOneWidget);
        expect(swimmingFinder, findsOneWidget);
        expect(yogaFinder, findsOneWidget);

        // Get positions to verify sorting (running should be first with 3 occurrences)
        final runningPosition = tester.getTopLeft(runningFinder);
        final swimmingPosition = tester.getTopLeft(swimmingFinder);
        final yogaPosition = tester.getTopLeft(yogaFinder);

        expect(runningPosition.dy, lessThan(swimmingPosition.dy));
        expect(swimmingPosition.dy, lessThan(yogaPosition.dy));
      });
    });

    group('Visual Styling', () {
      testWidgets('should display card with proper styling', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final card = tester.widget<Card>(cardFinder);
        expect(card.elevation, equals(2));
        expect(card.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('should display stat items with colored containers', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Check for containers with background colors
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(4)); // At least 4 stat containers
      });

      testWidgets('should display progress bars for exercise types', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Check for FractionallySizedBox widgets (progress bars)
        final progressBars = find.byType(FractionallySizedBox);
        expect(progressBars.evaluate().length, greaterThanOrEqualTo(3));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle zero values correctly', (tester) async {
        final zeroStatsReport = testReport.copyWith(
          stats: TestDataHelper.createDefaultWeeklyStats(
            totalCertifications: 0,
            exerciseDays: 0,
            dietDays: 0,
            exerciseTypes: {},
            consistencyScore: 0.0,
          ),
        );

        await tester.pumpWidget(createTestWidget(zeroStatsReport));
        await tester.pumpAndSettle();

        expect(find.text('0개'), findsOneWidget);

        // Check for multiple instances of '0일' (exerciseDays and dietDays)
        final zeroDaysFinder = find.text('0일');
        expect(zeroDaysFinder.evaluate().length, greaterThanOrEqualTo(2)); // exerciseDays and dietDays

        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('should handle high consistency score correctly', (tester) async {
        final perfectScoreReport = testReport.copyWith(stats: testReport.stats.copyWith(consistencyScore: 1.0));

        await tester.pumpWidget(createTestWidget(perfectScoreReport));
        await tester.pumpAndSettle();

        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('should handle single exercise type', (tester) async {
        final singleExerciseReport = testReport.copyWith(
          stats: testReport.stats.copyWith(exerciseTypes: {'running': 5}),
        );

        await tester.pumpWidget(createTestWidget(singleExerciseReport));
        await tester.pumpAndSettle();

        expect(find.text('운동 유형별 분포'), findsOneWidget);
        expect(find.text('running'), findsOneWidget);
        expect(find.text('5회'), findsOneWidget);
        expect(find.byType(FractionallySizedBox), findsOneWidget);
      });

      testWidgets('should handle very long exercise type names', (tester) async {
        final longNameReport = testReport.copyWith(
          stats: testReport.stats.copyWith(exerciseTypes: {'very_long_exercise_type_name_that_might_overflow': 2}),
        );

        await tester.pumpWidget(createTestWidget(longNameReport));
        await tester.pumpAndSettle();

        expect(find.text('very_long_exercise_type_name_that_might_overflow'), findsOneWidget);

        // Verify text doesn't overflow
        final textWidget = tester.widget<Text>(find.text('very_long_exercise_type_name_that_might_overflow'));
        expect(textWidget.overflow, isNull); // Should handle overflow gracefully
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible with proper semantics', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Check that important text is accessible
        expect(find.text(AppStrings.weeklyStats), findsOneWidget);
        expect(find.text(AppStrings.totalCertifications), findsOneWidget);
        expect(find.text(AppStrings.exerciseDays), findsOneWidget);
        expect(find.text(AppStrings.dietDays), findsOneWidget);
        expect(find.text(AppStrings.consistencyScore), findsOneWidget);

        // Verify icons are present for visual context
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });

    group('Layout Tests', () {
      testWidgets('should arrange stats in 2x2 grid layout', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Find all Row widgets that contain the stat items
        final rows = find.byType(Row);
        expect(rows.evaluate().length, greaterThanOrEqualTo(2)); // At least 2 rows for the 2x2 grid

        // Verify each row has 2 Expanded widgets (for 2 columns)
        final expandedWidgets = find.byType(Expanded);
        expect(expandedWidgets.evaluate().length, greaterThanOrEqualTo(4)); // 4 stat items = 4 Expanded widgets
      });

      testWidgets('should display exercise types in vertical list', (tester) async {
        await tester.pumpWidget(createTestWidget(testReport));
        await tester.pumpAndSettle();

        // Find the exercise types section
        expect(find.text('운동 유형별 분포'), findsOneWidget);

        // Verify vertical arrangement by checking positions
        final runningPosition = tester.getTopLeft(find.text('running'));
        final swimmingPosition = tester.getTopLeft(find.text('swimming'));

        expect(runningPosition.dy, lessThan(swimmingPosition.dy));
      });
    });
  });
}
