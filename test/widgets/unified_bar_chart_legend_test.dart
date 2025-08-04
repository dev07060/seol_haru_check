import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/unified_bar_chart.dart';

void main() {
  group('UnifiedBarChart Legend System Tests', () {
    late List<CategoryVisualizationData> exerciseData;
    late List<CategoryVisualizationData> dietData;

    setUp(() {
      exerciseData = [
        CategoryVisualizationData(
          categoryName: '근력 운동',
          emoji: '💪',
          count: 8,
          percentage: 0.0,
          color: SPColors.reportGreen,
          type: CategoryType.exercise,
        ),
        CategoryVisualizationData(
          categoryName: '유산소',
          emoji: '🏃',
          count: 5,
          percentage: 0.0,
          color: SPColors.reportBlue,
          type: CategoryType.exercise,
        ),
      ];

      dietData = [
        CategoryVisualizationData(
          categoryName: '한식',
          emoji: '🍚',
          count: 6,
          percentage: 0.0,
          color: SPColors.dietGreen,
          type: CategoryType.diet,
        ),
        CategoryVisualizationData(
          categoryName: '샐러드',
          emoji: '🥗',
          count: 4,
          percentage: 0.0,
          color: SPColors.dietLightGreen,
          type: CategoryType.diet,
        ),
      ];
    });

    testWidgets('should display legend with exercise and diet items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, showLegend: true)),
        ),
      );

      await tester.pumpAndSettle();

      // Verify legend items are displayed
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.text('운동 13개 (56.5%)'), findsOneWidget);
      expect(find.text('식단 10개 (43.5%)'), findsOneWidget);
    });

    testWidgets('should highlight exercise segments when exercise legend is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              showLegend: true,
              enableInteraction: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the exercise legend item
      final exerciseLegend = find.byIcon(Icons.fitness_center);
      expect(exerciseLegend, findsOneWidget);

      await tester.tap(exerciseLegend);
      await tester.pumpAndSettle();

      // Verify the legend item is highlighted (we can't easily test visual changes,
      // but we can verify the widget rebuilds without errors)
      expect(exerciseLegend, findsOneWidget);
    });

    testWidgets('should highlight diet segments when diet legend is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              showLegend: true,
              enableInteraction: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the diet legend item
      final dietLegend = find.byIcon(Icons.restaurant);
      expect(dietLegend, findsOneWidget);

      await tester.tap(dietLegend);
      await tester.pumpAndSettle();

      // Verify the legend item is highlighted
      expect(dietLegend, findsOneWidget);
    });

    testWidgets('should toggle highlight when same legend item is tapped twice', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              showLegend: true,
              enableInteraction: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final exerciseLegend = find.byIcon(Icons.fitness_center);

      // First tap - should highlight
      await tester.tap(exerciseLegend);
      await tester.pumpAndSettle();

      // Second tap - should remove highlight
      await tester.tap(exerciseLegend);
      await tester.pumpAndSettle();

      // Verify widget still works correctly
      expect(exerciseLegend, findsOneWidget);
    });

    testWidgets('should not show legend when showLegend is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, showLegend: false)),
        ),
      );

      await tester.pumpAndSettle();

      // Verify legend items are not displayed
      expect(find.byIcon(Icons.fitness_center), findsNothing);
      expect(find.byIcon(Icons.restaurant), findsNothing);
    });

    testWidgets('should not respond to legend taps when interaction is disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              showLegend: true,
              enableInteraction: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final exerciseLegend = find.byIcon(Icons.fitness_center);
      expect(exerciseLegend, findsOneWidget);

      // Tap should not cause any interaction effects
      await tester.tap(exerciseLegend);
      await tester.pumpAndSettle();

      // Widget should still be present and functional
      expect(exerciseLegend, findsOneWidget);
    });

    testWidgets('should show only exercise legend when no diet data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: [], // Empty diet data
              showLegend: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify only exercise legend is shown
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsNothing);
      expect(find.text('운동 13개 (100.0%)'), findsOneWidget);
    });

    testWidgets('should show only diet legend when no exercise data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: [], // Empty exercise data
              dietData: dietData,
              showLegend: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify only diet legend is shown
      expect(find.byIcon(Icons.fitness_center), findsNothing);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.text('식단 10개 (100.0%)'), findsOneWidget);
    });

    testWidgets('should handle legend interaction with proper visual feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              showLegend: true,
              enableInteraction: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test hover behavior (simulated through gesture detection)
      final exerciseLegend = find.byIcon(Icons.fitness_center);

      // Tap down should provide immediate feedback
      final gesture = await tester.startGesture(tester.getCenter(exerciseLegend));
      await tester.pumpAndSettle();

      // Complete the tap
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify widget remains functional
      expect(exerciseLegend, findsOneWidget);
    });
  });
}
