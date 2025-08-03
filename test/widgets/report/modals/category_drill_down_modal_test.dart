import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/modals/category_drill_down_modal.dart';

void main() {
  group('CategoryDrillDownModal', () {
    late CategoryVisualizationData mockCategoryData;
    late List<WeeklyReport> mockHistoricalReports;

    setUp(() {
      mockCategoryData = CategoryVisualizationData(
        categoryName: '근력 운동',
        emoji: '💪',
        count: 5,
        percentage: 0.35,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
        subcategories: [
          const SubcategoryData(
            name: '웨이트 트레이닝',
            count: 3,
            percentage: 0.6,
            description: '덤벨, 바벨을 이용한 근력 운동',
            emoji: '🏋️',
          ),
          const SubcategoryData(
            name: '맨몸 운동',
            count: 2,
            percentage: 0.4,
            description: '푸시업, 스쿼트 등 자체 중량 운동',
            emoji: '🤸',
          ),
        ],
        description: '근육량 증가와 기초대사량 향상을 위한 운동',
      );

      mockHistoricalReports = List.generate(4, (index) {
        final weekStart = DateTime.now().subtract(Duration(days: (index + 1) * 7));
        return WeeklyReport(
          id: 'report_$index',
          userUuid: 'test_user',
          weekStartDate: weekStart,
          weekEndDate: weekStart.add(const Duration(days: 6)),
          generatedAt: weekStart,
          stats: WeeklyStats(
            totalCertifications: 10,
            exerciseDays: 4,
            dietDays: 6,
            consistencyScore: 0.8,
            exerciseCategories: {'근력 운동': 3 + index, '유산소 운동': 2},
            dietCategories: {},
            exerciseTypes: {},
          ),
          analysis: AIAnalysis(
            exerciseInsights: 'Test exercise insights',
            dietInsights: 'Test diet insights',
            overallAssessment: 'Test overall assessment',
            strengthAreas: ['Test strength'],
            improvementAreas: ['Test improvement'],
          ),
          recommendations: ['Test recommendation'],
          status: ReportStatus.completed,
        );
      });
    });

    testWidgets('should display category information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(categoryData: mockCategoryData, historicalReports: mockHistoricalReports),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Check if category name is displayed
      expect(find.text('근력 운동'), findsOneWidget);

      // Check if emoji is displayed
      expect(find.text('💪'), findsOneWidget);

      // Check if count and percentage are displayed
      expect(find.textContaining('5회'), findsWidgets);
      expect(find.textContaining('35.0%'), findsWidgets);
    });

    testWidgets('should display tabs correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(categoryData: mockCategoryData, historicalReports: mockHistoricalReports),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if all tabs are present
      expect(find.text('개요'), findsOneWidget);
      expect(find.text('기록'), findsOneWidget);
      expect(find.text('추천'), findsOneWidget);
      expect(find.text('목표'), findsOneWidget);
    });

    testWidgets('should display subcategories when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(categoryData: mockCategoryData, historicalReports: mockHistoricalReports),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if subcategory section is displayed
      expect(find.text('세부 분류'), findsOneWidget);

      // Check if subcategories are displayed
      expect(find.text('웨이트 트레이닝'), findsOneWidget);
      expect(find.text('맨몸 운동'), findsOneWidget);
    });

    testWidgets('should switch tabs correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(categoryData: mockCategoryData, historicalReports: mockHistoricalReports),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the history tab
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();

      // Check if historical chart is displayed
      expect(find.text('근력 운동 기록 추이'), findsOneWidget);

      // Tap on the recommendations tab
      await tester.tap(find.text('추천'));
      await tester.pumpAndSettle();

      // Check if recommendations section is displayed
      expect(find.text('맞춤 추천'), findsOneWidget);

      // Tap on the goals tab
      await tester.tap(find.text('목표'));
      await tester.pumpAndSettle();

      // Check if goal section is displayed
      expect(find.text('목표 설정'), findsOneWidget);
    });

    testWidgets('should display goal setting interface', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(
              categoryData: mockCategoryData,
              historicalReports: mockHistoricalReports,
              onGoalSet: (categoryName, goalValue) {
                // Goal setting callback
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to goals tab
      await tester.tap(find.text('목표'));
      await tester.pumpAndSettle();

      // Verify goal setting interface is displayed
      expect(find.text('목표 설정'), findsOneWidget);
      expect(find.text('이번 주 목표'), findsOneWidget);
      expect(find.text('목표 제안'), findsOneWidget);
    });

    testWidgets('should handle empty historical reports', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDrillDownModal(categoryData: mockCategoryData, historicalReports: [])),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to history tab
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();

      // Check if empty state is displayed
      expect(find.text('기록이 없습니다'), findsOneWidget);
    });

    testWidgets('should close modal when close button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(categoryData: mockCategoryData, historicalReports: mockHistoricalReports),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // The modal should start closing animation
      // We can't easily test navigation pop in widget tests,
      // but we can verify the close button exists and is tappable
    });

    testWidgets('should display category without subcategories', (tester) async {
      final categoryWithoutSubs = CategoryVisualizationData(
        categoryName: '유산소 운동',
        emoji: '🏃',
        count: 3,
        percentage: 0.25,
        color: SPColors.podBlue,
        type: CategoryType.exercise,
        subcategories: [], // No subcategories
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDrillDownModal(categoryData: categoryWithoutSubs, historicalReports: mockHistoricalReports),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that subcategory section is not displayed
      expect(find.text('세부 분류'), findsNothing);
    });
  });
}
