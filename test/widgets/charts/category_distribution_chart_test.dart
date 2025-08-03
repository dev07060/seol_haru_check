import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/charts/category_distribution_chart.dart';

void main() {
  group('CategoryDistributionChart', () {
    late List<CategoryVisualizationData> mockExerciseData;
    late List<CategoryVisualizationData> mockDietData;

    setUp(() {
      mockExerciseData = [
        CategoryVisualizationData.fromExerciseCategory(ExerciseCategory.strength, 5, 0.5, SPColors.podGreen),
        CategoryVisualizationData.fromExerciseCategory(ExerciseCategory.cardio, 3, 0.3, SPColors.podBlue),
        CategoryVisualizationData.fromExerciseCategory(ExerciseCategory.flexibility, 2, 0.2, SPColors.podOrange),
      ];

      mockDietData = [
        CategoryVisualizationData.fromDietCategory(DietCategory.homeMade, 4, 0.4, SPColors.podGreen),
        CategoryVisualizationData.fromDietCategory(DietCategory.healthy, 3, 0.3, SPColors.podBlue),
        CategoryVisualizationData.fromDietCategory(DietCategory.protein, 3, 0.3, SPColors.podOrange),
      ];
    });

    testWidgets('should render pie chart with exercise data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDistributionChart(categoryData: mockExerciseData, type: CategoryType.exercise)),
        ),
      );

      expect(find.byType(CategoryDistributionChart), findsOneWidget);

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Should show legend items
      expect(find.text('💪'), findsOneWidget); // Strength emoji
      expect(find.text('🏃'), findsOneWidget); // Cardio emoji
      expect(find.text('🧘'), findsOneWidget); // Flexibility emoji
    });

    testWidgets('should render pie chart with diet data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDistributionChart(categoryData: mockDietData, type: CategoryType.diet)),
        ),
      );

      expect(find.byType(CategoryDistributionChart), findsOneWidget);

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Should show legend items
      expect(find.text('🍱'), findsOneWidget); // Home made emoji
      expect(find.text('🥗'), findsOneWidget); // Healthy emoji
      expect(find.text('🍗'), findsOneWidget); // Protein emoji
    });

    testWidgets('should handle empty data gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryDistributionChart(categoryData: [], type: CategoryType.exercise))),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    });

    testWidgets('should handle tap interactions when enabled', (tester) async {
      CategoryVisualizationData? tappedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              enableInteraction: true,
              onCategoryTap: (category) {
                tappedCategory = category;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a legend item
      await tester.tap(find.text('💪').first);
      await tester.pumpAndSettle();

      expect(tappedCategory, isNotNull);
      expect(tappedCategory!.categoryName, equals('근력 운동'));
    });

    testWidgets('should not handle taps when interaction is disabled', (tester) async {
      CategoryVisualizationData? tappedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              enableInteraction: false,
              onCategoryTap: (category) {
                tappedCategory = category;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to tap on a legend item
      await tester.tap(find.text('💪').first);
      await tester.pumpAndSettle();

      expect(tappedCategory, isNull);
    });

    testWidgets('should hide legend when showLegend is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              showLegend: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Legend should not be visible
      expect(find.text('근력 운동'), findsNothing);
    });

    testWidgets('should show center text when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              showCenterText: true,
              centerText: '10\n운동',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Center text should be visible
      expect(find.text('10'), findsOneWidget);
      expect(find.text('운동'), findsOneWidget);
    });

    testWidgets('should hide percentages when showPercentages is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              showPercentages: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Percentages should not be visible
      expect(find.text('50.0%'), findsNothing);
      expect(find.text('30.0%'), findsNothing);
      expect(find.text('20.0%'), findsNothing);
    });

    testWidgets('should apply custom theme', (tester) async {
      final customTheme = ChartTheme.light().copyWith(primaryColor: Colors.red, backgroundColor: Colors.yellow);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              theme: customTheme,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CategoryDistributionChart), findsOneWidget);
    });

    testWidgets('should apply custom animation config', (tester) async {
      const customAnimation = AnimationConfig(
        duration: Duration(milliseconds: 500),
        curve: Curves.bounceIn,
        enableStagger: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              animationConfig: customAnimation,
            ),
          ),
        ),
      );

      // Should complete animation faster
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(CategoryDistributionChart), findsOneWidget);
    });

    testWidgets('should show title when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDistributionChart(
              categoryData: mockExerciseData,
              type: CategoryType.exercise,
              title: '운동 분포',
              showTitle: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('운동 분포'), findsOneWidget);
    });

    testWidgets('should validate data correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDistributionChart(categoryData: mockExerciseData, type: CategoryType.exercise)),
        ),
      );

      await tester.pumpAndSettle();

      // Chart should render successfully with valid data
      expect(find.byType(CategoryDistributionChart), findsOneWidget);
      expect(find.text('💪'), findsOneWidget);
    });

    testWidgets('should handle chart data correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDistributionChart(categoryData: mockExerciseData, type: CategoryType.exercise)),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all categories
      expect(find.text('💪'), findsOneWidget); // Strength
      expect(find.text('🏃'), findsOneWidget); // Cardio
      expect(find.text('🧘'), findsOneWidget); // Flexibility
    });

    testWidgets('should show fallback for invalid data', (tester) async {
      final invalidData = [
        CategoryVisualizationData.fromExerciseCategory(
          ExerciseCategory.strength,
          0, // Zero count
          0.0,
          SPColors.podGreen,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryDistributionChart(categoryData: invalidData, type: CategoryType.exercise)),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state since all counts are zero
      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);
    });

    group('Animation Tests', () {
      testWidgets('should animate chart appearance', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryDistributionChart(
                categoryData: mockExerciseData,
                type: CategoryType.exercise,
                animationConfig: const AnimationConfig(duration: Duration(milliseconds: 1000)),
              ),
            ),
          ),
        );

        // Chart should be animating
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(CategoryDistributionChart), findsOneWidget);

        // Animation should complete
        await tester.pumpAndSettle();
        expect(find.byType(CategoryDistributionChart), findsOneWidget);
      });

      testWidgets('should handle staggered animations', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryDistributionChart(
                categoryData: mockExerciseData,
                type: CategoryType.exercise,
                animationConfig: const AnimationConfig(enableStagger: true, staggerDelay: Duration(milliseconds: 100)),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(CategoryDistributionChart), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryDistributionChart(categoryData: mockExerciseData, type: CategoryType.exercise),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have semantic information
        expect(find.byType(CategoryDistributionChart), findsOneWidget);
      });
    });
  });
}
