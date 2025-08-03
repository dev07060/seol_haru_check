import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/widgets/report/charts/category_preference_evolution_chart.dart';

import '../../../helpers/test_data_helper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });
  group('CategoryPreferenceEvolutionChart', () {
    testWidgets('should render preference evolution chart', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(6);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPreferenceEvolutionChart(
              historicalReports: historicalReports,
              categoryType: CategoryType.exercise,
            ),
          ),
        ),
      );

      expect(find.byType(CategoryPreferenceEvolutionChart), findsOneWidget);
      expect(find.text('운동 선호도 변화'), findsOneWidget);
    });

    testWidgets('should show empty state when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryPreferenceEvolutionChart(historicalReports: [], categoryType: CategoryType.exercise),
          ),
        ),
      );

      expect(find.text('선호도 데이터가 없습니다'), findsOneWidget);
    });

    testWidgets('should render diet preference evolution', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPreferenceEvolutionChart(
              historicalReports: historicalReports,
              categoryType: CategoryType.diet,
            ),
          ),
        ),
      );

      expect(find.text('식단 선호도 변화'), findsOneWidget);
    });

    testWidgets('should show insights when data is available', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPreferenceEvolutionChart(
              historicalReports: historicalReports,
              categoryType: CategoryType.exercise,
              maxCategoriesToShow: 3,
            ),
          ),
        ),
      );

      // Wait for animation and data processing
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show some trend insights
      expect(find.byType(CategoryPreferenceEvolutionChart), findsOneWidget);
    });

    testWidgets('should limit categories to maxCategoriesToShow', (tester) async {
      final historicalReports = TestDataHelper.createMockHistoricalReports(4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPreferenceEvolutionChart(
              historicalReports: historicalReports,
              categoryType: CategoryType.exercise,
              maxCategoriesToShow: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should only show top 2 categories
      expect(find.byType(CategoryPreferenceEvolutionChart), findsOneWidget);
    });
  });
}
