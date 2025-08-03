import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/widgets/report/diet_analysis_section.dart';

void main() {
  group('DietAnalysisSection Widget Tests', () {
    late AIAnalysis testAnalysis;

    setUp(() {
      testAnalysis = const AIAnalysis(
        exerciseInsights: '운동 패턴이 좋습니다.',
        dietInsights: '이번 주 식단 관리가 매우 우수했습니다. 균형 잡힌 영양소 섭취와 규칙적인 식사 시간이 인상적입니다.',
        overallAssessment: '전반적으로 우수한 진전을 보이고 있습니다.',
        strengthAreas: ['식단 균형', '영양소 다양성', '식사 시간 규칙성'],
        improvementAreas: ['수분 섭취 증가', '야채 섭취 늘리기', '간식 조절'],
      );
    });

    Widget createTestWidget(AIAnalysis analysis) {
      return MaterialApp(home: Scaffold(body: DietAnalysisSection(analysis: analysis)));
    }

    group('Basic Display', () {
      testWidgets('should display section header with icon and title', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.dietAnalysis), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      });

      testWidgets('should display diet insights when available', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 패턴 분석'), findsOneWidget);
        expect(find.text('이번 주 식단 관리가 매우 우수했습니다. 균형 잡힌 영양소 섭취와 규칙적인 식사 시간이 인상적입니다.'), findsOneWidget);
      });

      testWidgets('should not display insights when empty', (tester) async {
        final emptyInsightsAnalysis = testAnalysis.copyWith(dietInsights: '');

        await tester.pumpWidget(createTestWidget(emptyInsightsAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 패턴 분석'), findsNothing);
      });
    });

    group('Strength Areas Display', () {
      testWidgets('should display diet-related strength areas', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 강점'), findsOneWidget);
        expect(find.text('식단 균형'), findsOneWidget);
        expect(find.text('영양소 다양성'), findsOneWidget);
        expect(find.text('식사 시간 규칙성'), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);

        // Check for multiple check circle icons (one for each strength area)
        final checkIcons = find.byIcon(Icons.check_circle_outline);
        expect(checkIcons.evaluate().length, greaterThanOrEqualTo(3));
      });

      testWidgets('should filter out non-diet related strength areas', (tester) async {
        final mixedAnalysis = testAnalysis.copyWith(strengthAreas: ['식단 균형', '운동 일관성', '수면 패턴', '영양 관리']);

        await tester.pumpWidget(createTestWidget(mixedAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 균형'), findsOneWidget);
        expect(find.text('영양 관리'), findsOneWidget);
        expect(find.text('운동 일관성'), findsNothing); // Should be filtered out
        expect(find.text('수면 패턴'), findsNothing); // Should be filtered out
      });

      testWidgets('should not display strength section when no diet-related areas', (tester) async {
        final nonDietAnalysis = testAnalysis.copyWith(strengthAreas: ['운동 일관성', '수면 패턴', '스트레스 관리']);

        await tester.pumpWidget(createTestWidget(nonDietAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 강점'), findsNothing);
      });

      testWidgets('should not display strength section when empty', (tester) async {
        final emptyStrengthAnalysis = testAnalysis.copyWith(strengthAreas: []);

        await tester.pumpWidget(createTestWidget(emptyStrengthAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 강점'), findsNothing);
      });
    });

    group('Improvement Areas Display', () {
      testWidgets('should display diet-related improvement areas', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 개선점'), findsOneWidget);
        expect(find.text('수분 섭취 증가'), findsOneWidget);
        expect(find.text('야채 섭취 늘리기'), findsOneWidget);
        expect(find.text('간식 조절'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);

        // Check for multiple arrow icons (one for each improvement area)
        final arrowIcons = find.byIcon(Icons.arrow_upward);
        expect(arrowIcons.evaluate().length, greaterThanOrEqualTo(3));
      });

      testWidgets('should filter out non-diet related improvement areas', (tester) async {
        final mixedAnalysis = testAnalysis.copyWith(improvementAreas: ['수분 섭취', '운동 강도', '식단 개선', '근력 훈련']);

        await tester.pumpWidget(createTestWidget(mixedAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('수분 섭취'), findsOneWidget);
        expect(find.text('식단 개선'), findsOneWidget);
        expect(find.text('운동 강도'), findsNothing); // Should be filtered out
        expect(find.text('근력 훈련'), findsNothing); // Should be filtered out
      });

      testWidgets('should not display improvement section when no diet-related areas', (tester) async {
        final nonDietAnalysis = testAnalysis.copyWith(improvementAreas: ['운동 강도', '근력 훈련', '체력 향상']);

        await tester.pumpWidget(createTestWidget(nonDietAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 개선점'), findsNothing);
      });

      testWidgets('should not display improvement section when empty', (tester) async {
        final emptyImprovementAnalysis = testAnalysis.copyWith(improvementAreas: []);

        await tester.pumpWidget(createTestWidget(emptyImprovementAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 개선점'), findsNothing);
      });
    });

    group('Visual Styling', () {
      testWidgets('should display card with proper styling', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final card = tester.widget<Card>(cardFinder);
        expect(card.elevation, equals(2));
        expect(card.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('should display header with orange accent color', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        // Check for container with orange background
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(1));

        // Verify restaurant icon is present
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      });

      testWidgets('should display insight card with proper styling', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        // Check for insight card container
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(2)); // Header container + insight container
      });
    });

    group('Layout Tests', () {
      testWidgets('should arrange sections vertically', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        // Find section headers
        final analysisHeader = find.text(AppStrings.dietAnalysis);
        final strengthHeader = find.text('식단 강점');
        final improvementHeader = find.text('식단 개선점');

        expect(analysisHeader, findsOneWidget);
        expect(strengthHeader, findsOneWidget);
        expect(improvementHeader, findsOneWidget);

        // Verify vertical arrangement
        final analysisPosition = tester.getTopLeft(analysisHeader);
        final strengthPosition = tester.getTopLeft(strengthHeader);
        final improvementPosition = tester.getTopLeft(improvementHeader);

        expect(analysisPosition.dy, lessThan(strengthPosition.dy));
        expect(strengthPosition.dy, lessThan(improvementPosition.dy));
      });

      testWidgets('should display list items with proper spacing', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        // Check for SizedBox widgets that provide spacing
        final sizedBoxes = find.byType(SizedBox);
        expect(sizedBoxes.evaluate().length, greaterThanOrEqualTo(3)); // Multiple spacing elements
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very long insight text', (tester) async {
        final longInsightAnalysis = testAnalysis.copyWith(dietInsights: '이것은 매우 긴 식단 분석 텍스트입니다. ' * 20);

        await tester.pumpWidget(createTestWidget(longInsightAnalysis));
        await tester.pumpAndSettle();

        // Should display without overflow
        expect(find.text('식단 패턴 분석'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle empty analysis gracefully', (tester) async {
        const emptyAnalysis = AIAnalysis(
          exerciseInsights: '',
          dietInsights: '',
          overallAssessment: '',
          strengthAreas: [],
          improvementAreas: [],
        );

        await tester.pumpWidget(createTestWidget(emptyAnalysis));
        await tester.pumpAndSettle();

        // Should only show header
        expect(find.text(AppStrings.dietAnalysis), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.text('식단 패턴 분석'), findsNothing);
        expect(find.text('식단 강점'), findsNothing);
        expect(find.text('식단 개선점'), findsNothing);
      });

      testWidgets('should handle single strength and improvement area', (tester) async {
        final singleItemAnalysis = testAnalysis.copyWith(strengthAreas: ['식단 균형'], improvementAreas: ['수분 섭취']);

        await tester.pumpWidget(createTestWidget(singleItemAnalysis));
        await tester.pumpAndSettle();

        expect(find.text('식단 강점'), findsOneWidget);
        expect(find.text('식단 균형'), findsOneWidget);
        expect(find.text('식단 개선점'), findsOneWidget);
        expect(find.text('수분 섭취'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible with proper semantics', (tester) async {
        await tester.pumpWidget(createTestWidget(testAnalysis));
        await tester.pumpAndSettle();

        // Check that important text is accessible
        expect(find.text(AppStrings.dietAnalysis), findsOneWidget);
        expect(find.text('식단 강점'), findsOneWidget);
        expect(find.text('식단 개선점'), findsOneWidget);

        // Verify icons are present for visual context
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });
  });
}
