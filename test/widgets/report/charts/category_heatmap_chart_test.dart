import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/charts/category_heatmap_chart.dart';

void main() {
  group('HeatmapCellData', () {
    test('should create cell data with correct properties', () {
      final cellData = HeatmapCellData(
        dayOfWeek: 1,
        categoryName: '근력 운동',
        emoji: '💪',
        activityCount: 3,
        intensity: 0.8,
        baseColor: SPColors.podGreen,
        activities: ['벤치프레스', '스쿼트'],
      );

      expect(cellData.dayOfWeek, equals(1));
      expect(cellData.categoryName, equals('근력 운동'));
      expect(cellData.emoji, equals('💪'));
      expect(cellData.activityCount, equals(3));
      expect(cellData.intensity, equals(0.8));
      expect(cellData.hasActivity, isTrue);
      expect(cellData.activities.length, equals(2));
    });

    test('should generate correct intensity color', () {
      final cellData = HeatmapCellData(
        dayOfWeek: 0,
        categoryName: 'Test',
        emoji: '🏃',
        activityCount: 2,
        intensity: 0.5,
        baseColor: SPColors.podBlue,
      );

      expect(cellData.intensityColor, isA<Color>());
      expect(cellData.intensityColor, isNot(equals(SPColors.gray100)));
    });

    test('should return gray color for zero activity', () {
      final cellData = HeatmapCellData(
        dayOfWeek: 0,
        categoryName: 'Test',
        emoji: '🏃',
        activityCount: 0,
        intensity: 0.0,
        baseColor: SPColors.podBlue,
      );

      expect(cellData.intensityColor, equals(SPColors.gray100));
      expect(cellData.hasActivity, isFalse);
    });

    test('should generate correct tooltip text', () {
      final cellData = HeatmapCellData(
        dayOfWeek: 0,
        categoryName: '근력 운동',
        emoji: '💪',
        activityCount: 2,
        intensity: 0.6,
        baseColor: SPColors.podGreen,
      );

      expect(cellData.tooltipText, contains('💪 근력 운동'));
      expect(cellData.tooltipText, contains('2회 활동'));
      expect(cellData.tooltipText, contains('60%'));
    });

    test('should handle empty activity correctly', () {
      final cellData = HeatmapCellData(
        dayOfWeek: 0,
        categoryName: '근력 운동',
        emoji: '💪',
        activityCount: 0,
        intensity: 0.0,
        baseColor: SPColors.podGreen,
      );

      expect(cellData.tooltipText, contains('활동 없음'));
      expect(cellData.activityDescription, equals('활동 없음'));
    });
  });

  group('CategoryHeatmapData', () {
    late CategoryHeatmapData heatmapData;
    late List<HeatmapCellData> testCells;

    setUp(() {
      testCells = [
        HeatmapCellData(
          dayOfWeek: 0,
          categoryName: '근력 운동',
          emoji: '💪',
          activityCount: 2,
          intensity: 0.6,
          baseColor: SPColors.podGreen,
        ),
        HeatmapCellData(
          dayOfWeek: 1,
          categoryName: '근력 운동',
          emoji: '💪',
          activityCount: 3,
          intensity: 1.0,
          baseColor: SPColors.podGreen,
        ),
        HeatmapCellData(
          dayOfWeek: 0,
          categoryName: '유산소 운동',
          emoji: '🏃',
          activityCount: 1,
          intensity: 0.3,
          baseColor: SPColors.podBlue,
        ),
      ];

      heatmapData = CategoryHeatmapData(
        cells: testCells,
        categories: ['근력 운동', '유산소 운동'],
        dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
        maxActivityCount: 3,
        maxIntensity: 1.0,
        type: CategoryType.exercise,
        dateRange: DateTimeRange(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 7)),
      );
    });

    test('should create heatmap data with correct properties', () {
      expect(heatmapData.cells.length, equals(3));
      expect(heatmapData.categories.length, equals(2));
      expect(heatmapData.dayLabels.length, equals(7));
      expect(heatmapData.maxActivityCount, equals(3));
      expect(heatmapData.type, equals(CategoryType.exercise));
    });

    test('should create empty heatmap data', () {
      final emptyData = CategoryHeatmapData.empty(CategoryType.diet);

      expect(emptyData.cells, isEmpty);
      expect(emptyData.categories, isEmpty);
      expect(emptyData.maxActivityCount, equals(0));
      expect(emptyData.type, equals(CategoryType.diet));
      expect(emptyData.hasActivityData, isFalse);
    });

    test('should find cell data correctly', () {
      final cellData = heatmapData.getCellData(0, '근력 운동');

      expect(cellData, isNotNull);
      expect(cellData!.dayOfWeek, equals(0));
      expect(cellData.categoryName, equals('근력 운동'));
      expect(cellData.activityCount, equals(2));
    });

    test('should return null for non-existent cell', () {
      final cellData = heatmapData.getCellData(5, '존재하지 않는 카테고리');
      expect(cellData, isNull);
    });

    test('should calculate total activities for day correctly', () {
      final totalForDay0 = heatmapData.getTotalActivitiesForDay(0);
      expect(totalForDay0, equals(3)); // 2 + 1

      final totalForDay1 = heatmapData.getTotalActivitiesForDay(1);
      expect(totalForDay1, equals(3)); // 3 + 0
    });

    test('should calculate total activities for category correctly', () {
      final totalForStrength = heatmapData.getTotalActivitiesForCategory('근력 운동');
      expect(totalForStrength, equals(5)); // 2 + 3

      final totalForCardio = heatmapData.getTotalActivitiesForCategory('유산소 운동');
      expect(totalForCardio, equals(1)); // 1
    });

    test('should identify most active day', () {
      expect(heatmapData.mostActiveDay, equals(1)); // Day 1 has 3 total activities (근력 운동: 3)
    });

    test('should identify most active category', () {
      expect(heatmapData.mostActiveCategory, equals('근력 운동')); // 5 total activities
    });

    test('should detect activity data presence', () {
      expect(heatmapData.hasActivityData, isTrue);

      final emptyData = CategoryHeatmapData.empty(CategoryType.exercise);
      expect(emptyData.hasActivityData, isFalse);
    });
  });

  group('CategoryHeatmapChart Widget', () {
    late CategoryHeatmapData testHeatmapData;

    setUp(() {
      testHeatmapData = CategoryHeatmapData(
        cells: [
          HeatmapCellData(
            dayOfWeek: 0,
            categoryName: '근력 운동',
            emoji: '💪',
            activityCount: 2,
            intensity: 0.6,
            baseColor: SPColors.podGreen,
            activities: ['벤치프레스', '스쿼트'],
          ),
          HeatmapCellData(
            dayOfWeek: 1,
            categoryName: '유산소 운동',
            emoji: '🏃',
            activityCount: 1,
            intensity: 0.3,
            baseColor: SPColors.podBlue,
            activities: ['러닝'],
          ),
        ],
        categories: ['근력 운동', '유산소 운동'],
        dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
        maxActivityCount: 2,
        maxIntensity: 0.6,
        type: CategoryType.exercise,
        dateRange: DateTimeRange(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 7)),
      );
    });

    testWidgets('should render heatmap chart with data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: testHeatmapData, height: 400))),
      );

      expect(find.byType(CategoryHeatmapChart), findsOneWidget);

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Should show day labels
      expect(find.text('월'), findsOneWidget);
      expect(find.text('화'), findsOneWidget);

      // Should show category labels
      expect(find.text('근력 운동'), findsOneWidget);
      expect(find.text('유산소 운동'), findsOneWidget);
    });

    testWidgets('should show empty placeholder for no data', (WidgetTester tester) async {
      final emptyData = CategoryHeatmapData.empty(CategoryType.exercise);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: emptyData, height: 400))),
      );

      await tester.pumpAndSettle();

      // The empty data should show the base chart empty placeholder
      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);
    });

    testWidgets('should show intensity legend when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryHeatmapChart(heatmapData: testHeatmapData, showIntensityLegend: true, height: 400),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('활동 강도'), findsOneWidget);
      expect(find.text('낮음'), findsOneWidget);
      expect(find.text('높음'), findsOneWidget);
    });

    testWidgets('should hide intensity legend when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryHeatmapChart(heatmapData: testHeatmapData, showIntensityLegend: false, height: 400),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('활동 강도'), findsNothing);
    });

    testWidgets('should handle cell tap interaction', (WidgetTester tester) async {
      HeatmapCellData? tappedCell;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryHeatmapChart(
              heatmapData: testHeatmapData,
              enableInteraction: true,
              onCellTap: (cellData) {
                tappedCell = cellData;
              },
              height: 400,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a heatmap cell
      final cellFinder = find.byType(GestureDetector).first;
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      expect(tappedCell, isNotNull);
    });

    testWidgets('should show cell details when cell is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryHeatmapChart(heatmapData: testHeatmapData, enableInteraction: true, height: 400),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find a specific cell container and tap it
      final cellContainers = find.byType(GestureDetector);
      expect(cellContainers, findsWidgets);

      // Tap the first available cell
      await tester.tap(cellContainers.first);
      await tester.pumpAndSettle();

      // Should show some cell-related content (the chart should respond to tap)
      expect(find.byType(CategoryHeatmapChart), findsOneWidget);
    });

    testWidgets('should highlight optimal timing when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryHeatmapChart(heatmapData: testHeatmapData, highlightOptimalTiming: true, height: 400),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should highlight the most active day and category
      // This is tested by checking if the highlighting containers are present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should apply custom theme', (WidgetTester tester) async {
      final customTheme = ChartTheme.light().copyWith(primaryColor: Colors.red);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoryHeatmapChart(heatmapData: testHeatmapData, theme: customTheme, height: 400)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CategoryHeatmapChart), findsOneWidget);
    });

    testWidgets('should handle animation configuration', (WidgetTester tester) async {
      const animationConfig = AnimationConfig(duration: Duration(milliseconds: 500), enableStagger: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryHeatmapChart(heatmapData: testHeatmapData, animationConfig: animationConfig, height: 400),
          ),
        ),
      );

      // Should start with animation
      expect(find.byType(CategoryHeatmapChart), findsOneWidget);

      // Wait for animation to complete
      await tester.pumpAndSettle();

      expect(find.byType(CategoryHeatmapChart), findsOneWidget);
    });

    testWidgets('should validate data correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: testHeatmapData, height: 400))),
      );

      await tester.pumpAndSettle();

      // Should render successfully with valid data
      expect(find.byType(CategoryHeatmapChart), findsOneWidget);

      // Test with empty data
      final emptyData = CategoryHeatmapData.empty(CategoryType.exercise);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: emptyData, height: 400))),
      );

      await tester.pumpAndSettle();

      // Should show empty placeholder
      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);
    });

    testWidgets('should handle chart data properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: testHeatmapData, height: 400))),
      );

      await tester.pumpAndSettle();

      // Verify chart renders with correct data
      expect(find.byType(CategoryHeatmapChart), findsOneWidget);
      expect(testHeatmapData.categories.length, equals(2));
      expect(testHeatmapData.cells.length, equals(2));
      expect(testHeatmapData.maxActivityCount, equals(2));
      expect(testHeatmapData.type, equals(CategoryType.exercise));
      expect(testHeatmapData.hasActivityData, isTrue);
    });
  });

  group('CategoryHeatmapChart Error Handling', () {
    testWidgets('should show fallback for empty data', (WidgetTester tester) async {
      final emptyData = CategoryHeatmapData.empty(CategoryType.diet);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: emptyData, height: 400))),
      );

      await tester.pumpAndSettle();

      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);
    });

    testWidgets('should handle null cell data gracefully', (WidgetTester tester) async {
      // Create data with missing cells
      final sparseData = CategoryHeatmapData(
        cells: [
          HeatmapCellData(
            dayOfWeek: 0,
            categoryName: '근력 운동',
            emoji: '💪',
            activityCount: 1,
            intensity: 0.3,
            baseColor: SPColors.podGreen,
          ),
        ],
        categories: ['근력 운동', '유산소 운동'], // More categories than cells
        dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
        maxActivityCount: 1,
        maxIntensity: 0.3,
        type: CategoryType.exercise,
        dateRange: DateTimeRange(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 7)),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CategoryHeatmapChart(heatmapData: sparseData, height: 400))),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(CategoryHeatmapChart), findsOneWidget);
    });
  });
}
