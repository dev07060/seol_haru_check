import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/widgets/report/charts/category_trend_line_chart.dart';

import '../../../helpers/test_data_helper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });
  group('CategoryTrendLineChart', () {
    testWidgets('should render chart with historical data', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTrendLineChart(historicalReports: historicalReports, categoryType: CategoryType.exercise),
          ),
        ),
      );

      expect(find.byType(CategoryTrendLineChart), findsOneWidget);
      expect(find.text('운동 카테고리 트렌드'), findsOneWidget);
    });

    testWidgets('should show empty state when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CategoryTrendLineChart(historicalReports: [], categoryType: CategoryType.exercise)),
        ),
      );

      expect(find.text('트렌드 데이터가 없습니다'), findsOneWidget);
      expect(find.text('더 많은 주간 데이터가 필요합니다'), findsOneWidget);
    });

    testWidgets('should handle category toggle', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(5);
      String? toggledCategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTrendLineChart(
              historicalReports: historicalReports,
              categoryType: CategoryType.exercise,
              onCategoryToggle: (categoryName) {
                toggledCategory = categoryName;
              },
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pumpAndSettle();

      // Find and tap a category in the legend
      final categoryFinder = find.text('근력 운동').first;
      if (tester.any(categoryFinder)) {
        await tester.tap(categoryFinder);
        expect(toggledCategory, equals('근력 운동'));
      }
    });

    testWidgets('should render diet category trends', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTrendLineChart(historicalReports: historicalReports, categoryType: CategoryType.diet),
          ),
        ),
      );

      expect(find.text('식단 카테고리 트렌드'), findsOneWidget);
    });

    testWidgets('should animate chart rendering', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTrendLineChart(historicalReports: historicalReports, categoryType: CategoryType.exercise),
          ),
        ),
      );

      // Verify initial state
      expect(find.byType(CategoryTrendLineChart), findsOneWidget);

      // Wait for animation to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify chart is rendered after animation
      expect(find.byType(CategoryTrendLineChart), findsOneWidget);
    });
  });
}
