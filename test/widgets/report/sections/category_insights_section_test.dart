import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/sections/category_insights_section.dart';

void main() {
  group('CategoryInsightsSection', () {
    late List<CategoryVisualizationData> exerciseCategories;
    late List<CategoryVisualizationData> dietCategories;
    late List<WeeklyReport> historicalReports;

    setUp(() {
      exerciseCategories = [
        const CategoryVisualizationData(
          categoryName: '근력 운동',
          emoji: '💪',
          count: 3,
          percentage: 0.5,
          color: SPColors.reportGreen,
          type: CategoryType.exercise,
        ),
        const CategoryVisualizationData(
          categoryName: '유산소 운동',
          emoji: '🏃',
          count: 0,
          percentage: 0.0,
          color: SPColors.reportBlue,
          type: CategoryType.exercise,
        ),
      ];

      dietCategories = [
        const CategoryVisualizationData(
          categoryName: '집밥/도시락',
          emoji: '🍱',
          count: 5,
          percentage: 0.7,
          color: SPColors.dietGreen,
          type: CategoryType.diet,
        ),
        const CategoryVisualizationData(
          categoryName: '건강식/샐러드',
          emoji: '🥗',
          count: 1,
          percentage: 0.1,
          color: SPColors.dietLightGreen,
          type: CategoryType.diet,
        ),
      ];

      historicalReports = [];
    });

    testWidgets('should render category insights section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryInsightsSection(
                exerciseCategories: exerciseCategories,
                dietCategories: dietCategories,
                historicalReports: historicalReports,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CategoryInsightsSection), findsOneWidget);
      expect(find.text('AI 맞춤 인사이트'), findsOneWidget);
    });

    testWidgets('should show insights for categories with zero count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryInsightsSection(
                exerciseCategories: exerciseCategories,
                dietCategories: dietCategories,
                historicalReports: historicalReports,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show insight for starting cardio exercise (count = 0)
      expect(find.textContaining('🏃 유산소 운동 시작해보기'), findsOneWidget);
    });

    testWidgets('should show empty state when no insights available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryInsightsSection(exerciseCategories: [], dietCategories: [], historicalReports: []),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('인사이트 준비 중'), findsOneWidget);
      expect(find.text('더 많은 데이터가 쌓이면\n맞춤 인사이트를 제공해드릴게요'), findsOneWidget);
    });

    testWidgets('should display actionable steps for insights', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryInsightsSection(
                exerciseCategories: exerciseCategories,
                dietCategories: dietCategories,
                historicalReports: historicalReports,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show actionable steps section
      expect(find.text('실천 방법'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show AI generated badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryInsightsSection(
                exerciseCategories: exerciseCategories,
                dietCategories: dietCategories,
                historicalReports: historicalReports,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show AI generated badges
      expect(find.text('AI 생성'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show priority badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryInsightsSection(
                exerciseCategories: exerciseCategories,
                dietCategories: dietCategories,
                historicalReports: historicalReports,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show priority badges (중요, 보통, 참고)
      final priorityBadges = find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data == '중요' || widget.data == '보통' || widget.data == '참고'),
      );
      expect(priorityBadges, findsAtLeastNWidgets(1));
    });
  });
}
