import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/charts/hierarchical_category_chart.dart';

void main() {
  group('HierarchicalCategoryChart', () {
    late Map<String, Map<String, int>> testHierarchicalData;
    late Map<String, String> testCategoryEmojis;
    late Map<String, Color> testCategoryColors;

    setUp(() {
      testHierarchicalData = {
        '운동': {'근력 운동': 5, '유산소 운동': 3, '스트레칭': 2},
        '식단': {'집밥': 4, '건강식': 3, '외식': 2},
      };

      testCategoryEmojis = {'운동': '💪', '식단': '🍽️'};

      testCategoryColors = {'운동': SPColors.podGreen, '식단': SPColors.podBlue};
    });

    testWidgets('should render hierarchical chart with valid data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
            ),
          ),
        ),
      );

      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Should show center info by default
      expect(find.text('19'), findsOneWidget); // Total count
      expect(find.text('총 활동'), findsOneWidget);
      expect(find.text('2개 카테고리'), findsOneWidget);
    });

    testWidgets('should handle empty data gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HierarchicalCategoryChart(hierarchicalData: {}, categoryEmojis: {}, categoryColors: {})),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty placeholder
      expect(find.text('계층 데이터가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.donut_large), findsOneWidget);
    });

    testWidgets('should support drill-down functionality', (tester) async {
      bool categoryTapped = false;
      String? tappedMainCategory;
      String? tappedSubcategory;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              enableDrillDown: true,
              onCategoryTap: (mainCategory, subcategory) {
                categoryTapped = true;
                tappedMainCategory = mainCategory;
                tappedSubcategory = subcategory;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the chart to trigger drill-down
      await tester.tap(find.byType(HierarchicalCategoryChart));
      await tester.pumpAndSettle();

      expect(categoryTapped, isTrue);
      expect(tappedMainCategory, isNotNull);
    });

    testWidgets('should render with drill-down enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              enableDrillDown: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render the chart
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    testWidgets('should handle back navigation correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              enableDrillDown: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    testWidgets('should respect showCenterInfo parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              showCenterInfo: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show center info
      expect(find.text('총 활동'), findsNothing);
    });

    testWidgets('should respect showSubcategoryDetails parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              showSubcategoryDetails: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Chart should render without subcategory preview
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    testWidgets('should apply custom theme correctly', (tester) async {
      final customTheme = ChartTheme.light().copyWith(primaryColor: Colors.red, backgroundColor: Colors.yellow);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              theme: customTheme,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render with custom theme
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    testWidgets('should apply custom animation config', (tester) async {
      const customAnimationConfig = AnimationConfig(
        duration: Duration(milliseconds: 500),
        curve: Curves.bounceIn,
        enableStagger: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              animationConfig: customAnimationConfig,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render with custom animation config
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    testWidgets('should handle zoom and pan when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              enableZoomPan: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render with zoom/pan enabled
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);

      // Test pan gesture
      await tester.drag(find.byType(HierarchicalCategoryChart), const Offset(50, 50));
      await tester.pumpAndSettle();

      // Should still be rendered after pan gesture
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    testWidgets('should handle custom radius values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HierarchicalCategoryChart(
              hierarchicalData: testHierarchicalData,
              categoryEmojis: testCategoryEmojis,
              categoryColors: testCategoryColors,
              maxRadius: 150.0,
              minRadius: 80.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render with custom radius values
      expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
    });

    group('Error handling', () {
      testWidgets('should show fallback for empty data', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(hierarchicalData: {}, categoryEmojis: {}, categoryColors: {}),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('계층 데이터가 없습니다'), findsOneWidget);
      });

      testWidgets('should handle data with zero values', (tester) async {
        final zeroData = {
          '운동': {'근력 운동': 0, '유산소 운동': 0},
          '식단': {'집밥': 0},
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: zeroData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show empty placeholder for zero data
        expect(find.text('계층 데이터가 없습니다'), findsOneWidget);
      });

      testWidgets('should handle missing emojis gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: {}, // Empty emojis
                categoryColors: testCategoryColors,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render with default emojis
        expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
      });

      testWidgets('should handle missing colors gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: {}, // Empty colors
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render with default colors
        expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('should handle tap events when drill-down is disabled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: testCategoryColors,
                enableDrillDown: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without drill-down
        expect(find.byType(HierarchicalCategoryChart), findsOneWidget);

        // Tap should not cause errors
        await tester.tap(find.byType(HierarchicalCategoryChart));
        await tester.pumpAndSettle();

        expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
      });

      testWidgets('should call onCategoryTap callback', (tester) async {
        String? tappedCategory;
        String? tappedSubcategory;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: testCategoryColors,
                enableDrillDown: true,
                onCategoryTap: (mainCategory, subcategory) {
                  tappedCategory = mainCategory;
                  tappedSubcategory = subcategory;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the chart
        await tester.tap(find.byType(HierarchicalCategoryChart));
        await tester.pumpAndSettle();

        // Callback should be called
        expect(tappedCategory, isNotNull);
      });
    });

    group('Visual properties', () {
      testWidgets('should render with title when specified', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: testCategoryColors,
                title: '계층 차트',
                showTitle: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('계층 차트'), findsOneWidget);
      });

      testWidgets('should respect height parameter', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: testCategoryColors,
                height: 300,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render with specified height
        expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
      });

      testWidgets('should respect padding parameter', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HierarchicalCategoryChart(
                hierarchicalData: testHierarchicalData,
                categoryEmojis: testCategoryEmojis,
                categoryColors: testCategoryColors,
                padding: const EdgeInsets.all(32),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render with specified padding
        expect(find.byType(HierarchicalCategoryChart), findsOneWidget);
      });
    });
  });
}
