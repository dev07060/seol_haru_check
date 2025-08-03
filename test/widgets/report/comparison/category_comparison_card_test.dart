import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/widgets/report/comparison/category_comparison_card.dart';

void main() {
  group('CategoryComparisonCard', () {
    late WeeklyReport currentWeekReport;
    late WeeklyReport previousWeekReport;

    setUp(() {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));
      final previousWeekEnd = previousWeekStart.add(const Duration(days: 6));

      currentWeekReport = WeeklyReport(
        id: 'current_week',
        userUuid: 'test_user',
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        generatedAt: now,
        stats: const WeeklyStats(
          totalCertifications: 10,
          exerciseDays: 5,
          dietDays: 5,
          exerciseTypes: {},
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2, '스트레칭/요가': 1},
          dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 2, '단백질 위주': 1},
          consistencyScore: 0.8,
        ),
        analysis: const AIAnalysis(
          exerciseInsights: 'Test insights',
          dietInsights: 'Test insights',
          overallAssessment: 'Test assessment',
          strengthAreas: [],
          improvementAreas: [],
        ),
        recommendations: [],
        status: ReportStatus.completed,
      );

      previousWeekReport = WeeklyReport(
        id: 'previous_week',
        userUuid: 'test_user',
        weekStartDate: previousWeekStart,
        weekEndDate: previousWeekEnd,
        generatedAt: now.subtract(const Duration(days: 7)),
        stats: const WeeklyStats(
          totalCertifications: 8,
          exerciseDays: 4,
          dietDays: 4,
          exerciseTypes: {},
          exerciseCategories: {'근력 운동': 2, '유산소 운동': 3, '구기/스포츠': 1},
          dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 1, '외식/배달': 2},
          consistencyScore: 0.7,
        ),
        analysis: const AIAnalysis(
          exerciseInsights: 'Previous insights',
          dietInsights: 'Previous insights',
          overallAssessment: 'Previous assessment',
          strengthAreas: [],
          improvementAreas: [],
        ),
        recommendations: [],
        status: ReportStatus.completed,
      );
    });

    testWidgets('should render exercise category comparison card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('운동 카테고리 비교'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);

      // Verify comparison headers
      expect(find.text('이번 주'), findsOneWidget);
      expect(find.text('지난 주'), findsOneWidget);

      // Verify category rows are displayed
      expect(find.text('💪'), findsOneWidget); // 근력 운동 emoji
      expect(find.text('🏃'), findsOneWidget); // 유산소 운동 emoji

      // Verify diversity score section
      expect(find.text('다양성 점수'), findsOneWidget);
      expect(find.byIcon(Icons.diversity_3), findsOneWidget);
    });

    testWidgets('should render diet category comparison card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.diet,
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('식단 카테고리 비교'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);

      // Verify diet category emojis
      expect(find.text('🍱'), findsOneWidget); // 집밥/도시락 emoji
      expect(find.text('🥗'), findsOneWidget); // 건강식/샐러드 emoji
    });

    testWidgets('should show no comparison data when previous week is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: null,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      // Verify no comparison message
      expect(find.text('비교할 이전 주 데이터가 없습니다'), findsOneWidget);
      expect(find.text('다음 주부터 비교 분석을 제공합니다'), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
    });

    testWidgets('should handle tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(CategoryComparisonCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('should display change indicators correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      // Should show trending up for 근력 운동 (2 -> 3)
      expect(find.byIcon(Icons.trending_up), findsWidgets);

      // Should show trending down for 유산소 운동 (3 -> 2)
      expect(find.byIcon(Icons.trending_down), findsWidgets);

      // Should show new category indicator for 스트레칭/요가 (0 -> 1)
      expect(find.byIcon(Icons.fiber_new), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('should calculate and display diversity score', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      // Verify diversity score is displayed
      expect(find.text('다양성 점수'), findsOneWidget);
      expect(find.textContaining('점').last, findsOneWidget);

      // Verify diversity change indicator is shown
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.trending_up ||
                  widget.icon == Icons.trending_down ||
                  widget.icon == Icons.trending_flat),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should show disappeared category indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.diet,
            ),
          ),
        ),
      );

      // Should show disappeared indicator for 외식/배달 (2 -> 0)
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.text('중단'), findsOneWidget);
    });

    testWidgets('should limit displayed categories to 5', (tester) async {
      // Create a report with many categories
      final manyCategories = WeeklyReport(
        id: 'many_categories',
        userUuid: 'test_user',
        weekStartDate: DateTime.now(),
        weekEndDate: DateTime.now().add(const Duration(days: 6)),
        generatedAt: DateTime.now(),
        stats: const WeeklyStats(
          totalCertifications: 20,
          exerciseDays: 7,
          dietDays: 7,
          exerciseTypes: {},
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2, '스트레칭/요가': 1, '구기/스포츠': 2, '야외 활동': 1, '댄스/무용': 1, '기타 운동': 1},
          dietCategories: {},
          consistencyScore: 0.9,
        ),
        analysis: const AIAnalysis(
          exerciseInsights: 'Test insights',
          dietInsights: 'Test insights',
          overallAssessment: 'Test assessment',
          strengthAreas: [],
          improvementAreas: [],
        ),
        recommendations: [],
        status: ReportStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: manyCategories,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      // Should show "외 N개 카테고리" text when more than 5 categories
      expect(find.text('외 2개 카테고리'), findsOneWidget);
    });

    group('CategoryComparisonData', () {
      test('should create comparison data correctly', () {
        const data = CategoryComparisonData(
          categoryName: '근력 운동',
          emoji: '💪',
          currentCount: 3,
          previousCount: 2,
          changeType: CategoryChangeType.increased,
          changePercentage: 50.0,
        );

        expect(data.categoryName, equals('근력 운동'));
        expect(data.emoji, equals('💪'));
        expect(data.currentCount, equals(3));
        expect(data.previousCount, equals(2));
        expect(data.changeType, equals(CategoryChangeType.increased));
        expect(data.changePercentage, equals(50.0));
      });
    });

    group('CategoryChangeType', () {
      test('should have correct display names', () {
        expect(CategoryChangeType.increased.displayName, equals('증가'));
        expect(CategoryChangeType.decreased.displayName, equals('감소'));
        expect(CategoryChangeType.stable.displayName, equals('유지'));
        expect(CategoryChangeType.emerged.displayName, equals('신규'));
        expect(CategoryChangeType.disappeared.displayName, equals('중단'));
      });

      test('should have correct descriptions', () {
        expect(CategoryChangeType.increased.description, equals('이전 주보다 증가했습니다'));
        expect(CategoryChangeType.decreased.description, equals('이전 주보다 감소했습니다'));
        expect(CategoryChangeType.stable.description, equals('이전 주와 동일합니다'));
        expect(CategoryChangeType.emerged.description, equals('새롭게 시작된 카테고리입니다'));
        expect(CategoryChangeType.disappeared.description, equals('이번 주에는 활동하지 않았습니다'));
      });
    });

    testWidgets('should show chevron icon when onTap is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should not show chevron icon when onTap is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: currentWeekReport,
              previousWeek: previousWeekReport,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('should handle empty categories gracefully', (tester) async {
      final emptyReport = WeeklyReport(
        id: 'empty_report',
        userUuid: 'test_user',
        weekStartDate: DateTime.now(),
        weekEndDate: DateTime.now().add(const Duration(days: 6)),
        generatedAt: DateTime.now(),
        stats: const WeeklyStats(
          totalCertifications: 0,
          exerciseDays: 0,
          dietDays: 0,
          exerciseTypes: {},
          exerciseCategories: {},
          dietCategories: {},
          consistencyScore: 0.0,
        ),
        analysis: const AIAnalysis(
          exerciseInsights: '',
          dietInsights: '',
          overallAssessment: '',
          strengthAreas: [],
          improvementAreas: [],
        ),
        recommendations: [],
        status: ReportStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryComparisonCard(
              currentWeek: emptyReport,
              previousWeek: emptyReport,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      // Should show no comparison data message
      expect(find.text('비교할 카테고리 데이터가 없습니다'), findsOneWidget);
    });
  });
}
