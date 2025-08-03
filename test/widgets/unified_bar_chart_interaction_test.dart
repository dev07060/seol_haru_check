import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/unified_bar_chart.dart';

void main() {
  group('UnifiedBarChart Touch Interaction Tests', () {
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

    testWidgets('should render chart with touch interaction enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, enableInteraction: true),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify chart is rendered
      expect(find.byType(UnifiedBarChart), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.byType(MouseRegion), findsWidgets);
    });

    testWidgets('should handle tap interaction', (WidgetTester tester) async {
      CategoryVisualizationData? tappedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              enableInteraction: true,
              onCategoryTap: (category) {
                tappedCategory = category;
              },
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Find the chart widget
      final chartFinder = find.byType(UnifiedBarChart);
      expect(chartFinder, findsOneWidget);

      // Tap on the chart (should hit the first segment)
      await tester.tap(chartFinder);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(tappedCategory, isNotNull);
      expect(tappedCategory?.categoryName, isNotEmpty);
    });

    testWidgets('should handle hover interaction on web/desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, enableInteraction: true),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Find the chart widget for hover testing
      final chartFinder = find.byType(UnifiedBarChart);
      expect(chartFinder, findsOneWidget);

      // Simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(chartFinder));
      await tester.pump();

      // Verify no errors occurred during hover
      expect(tester.takeException(), isNull);
    });

    testWidgets('should disable interaction when enableInteraction is false', (WidgetTester tester) async {
      CategoryVisualizationData? tappedCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(
              exerciseData: exerciseData,
              dietData: dietData,
              enableInteraction: false,
              onCategoryTap: (category) {
                tappedCategory = category;
              },
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Tap on the chart
      await tester.tap(find.byType(UnifiedBarChart));
      await tester.pumpAndSettle();

      // Verify callback was not called
      expect(tappedCategory, isNull);
    });

    testWidgets('should show proper cursor when interaction is enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, enableInteraction: true),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Find the MouseRegion widget with click cursor (our chart's MouseRegion)
      final mouseRegions = tester.widgetList<MouseRegion>(find.byType(MouseRegion));
      final chartMouseRegion = mouseRegions.firstWhere((region) => region.cursor == SystemMouseCursors.click);
      expect(chartMouseRegion.cursor, equals(SystemMouseCursors.click));
    });

    testWidgets('should show basic cursor when interaction is disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, enableInteraction: false),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Find the MouseRegion widget with basic cursor (our chart's MouseRegion when disabled)
      final mouseRegions = tester.widgetList<MouseRegion>(find.byType(MouseRegion));
      final chartMouseRegion = mouseRegions.firstWhere((region) => region.cursor == SystemMouseCursors.basic);
      expect(chartMouseRegion.cursor, equals(SystemMouseCursors.basic));
    });

    testWidgets('should handle empty data gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: UnifiedBarChart(exerciseData: [], dietData: [], enableInteraction: true))),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify chart renders empty state
      expect(find.byType(UnifiedBarChart), findsOneWidget);
      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);

      // Tap should not cause errors
      await tester.tap(find.byType(UnifiedBarChart));
      await tester.pumpAndSettle();

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should animate highlight effects', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnifiedBarChart(exerciseData: exerciseData, dietData: dietData, enableInteraction: true),
          ),
        ),
      );

      // Wait for initial animations to complete
      await tester.pumpAndSettle();

      // Tap on the chart to trigger highlight animation
      await tester.tap(find.byType(UnifiedBarChart));

      // Pump a few frames to see animation in progress
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      // Wait for all animations to complete
      await tester.pumpAndSettle();

      // Verify no exceptions during animation
      expect(tester.takeException(), isNull);
    });
  });
}
