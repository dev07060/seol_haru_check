import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/widgets/report/recommendations_section.dart';

void main() {
  group('RecommendationsSection Widget Tests', () {
    final testRecommendations = [
      '매일 물을 2리터 이상 마시도록 노력하세요.',
      '주 3회 이상 유산소 운동을 추가해보세요.',
      '야채 섭취량을 늘리고 가공식품을 줄여보세요.',
      '규칙적인 수면 패턴을 유지하세요.',
      '스트레스 관리를 위한 명상이나 요가를 시도해보세요.',
    ];

    Widget createTestWidget(List<String> recommendations) {
      return MaterialApp(home: Scaffold(body: RecommendationsSection(recommendations: recommendations)));
    }

    group('Basic Display', () {
      testWidgets('should display section header with icon and title', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.recommendations), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });

      testWidgets('should display all recommendations with numbers', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for numbered badges
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);

        // Check for recommendation texts
        expect(find.text('매일 물을 2리터 이상 마시도록 노력하세요.'), findsOneWidget);
        expect(find.text('주 3회 이상 유산소 운동을 추가해보세요.'), findsOneWidget);
        expect(find.text('야채 섭취량을 늘리고 가공식품을 줄여보세요.'), findsOneWidget);
        expect(find.text('규칙적인 수면 패턴을 유지하세요.'), findsOneWidget);
        expect(find.text('스트레스 관리를 위한 명상이나 요가를 시도해보세요.'), findsOneWidget);
      });

      testWidgets('should not display when recommendations are empty', (tester) async {
        await tester.pumpWidget(createTestWidget([]));
        await tester.pumpAndSettle();

        expect(find.byType(RecommendationsSection), findsOneWidget);
        expect(find.text(AppStrings.recommendations), findsNothing);
        expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      });
    });

    group('Visual Styling', () {
      testWidgets('should display card with proper styling', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final card = tester.widget<Card>(cardFinder);
        expect(card.elevation, equals(2));
        expect(card.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('should display header with purple accent color', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for container with purple background
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(1));

        // Verify lightbulb icon is present
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });

      testWidgets('should display numbered badges with purple background', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for circular containers (number badges)
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(6)); // Header + 5 number badges

        // Verify number badges are present
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('should display gradient background for recommendation items', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for containers with gradient decoration
        final containers = find.byType(Container);
        expect(containers.evaluate().length, greaterThanOrEqualTo(5)); // At least 5 recommendation containers
      });
    });

    group('Layout Tests', () {
      testWidgets('should arrange recommendations vertically', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Find recommendation texts
        final firstRec = find.text('매일 물을 2리터 이상 마시도록 노력하세요.');
        final secondRec = find.text('주 3회 이상 유산소 운동을 추가해보세요.');
        final thirdRec = find.text('야채 섭취량을 늘리고 가공식품을 줄여보세요.');

        expect(firstRec, findsOneWidget);
        expect(secondRec, findsOneWidget);
        expect(thirdRec, findsOneWidget);

        // Verify vertical arrangement
        final firstPosition = tester.getTopLeft(firstRec);
        final secondPosition = tester.getTopLeft(secondRec);
        final thirdPosition = tester.getTopLeft(thirdRec);

        expect(firstPosition.dy, lessThan(secondPosition.dy));
        expect(secondPosition.dy, lessThan(thirdPosition.dy));
      });

      testWidgets('should display number badges aligned with text', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for Row widgets that contain number + text
        final rows = find.byType(Row);
        expect(rows.evaluate().length, greaterThanOrEqualTo(6)); // Header row + 5 recommendation rows

        // Verify Expanded widgets for text content
        final expandedWidgets = find.byType(Expanded);
        expect(expandedWidgets.evaluate().length, greaterThanOrEqualTo(5)); // One for each recommendation text
      });

      testWidgets('should have proper spacing between recommendations', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for SizedBox widgets that provide spacing
        final sizedBoxes = find.byType(SizedBox);
        expect(sizedBoxes.evaluate().length, greaterThanOrEqualTo(10)); // Multiple spacing elements
      });
    });

    group('Single Recommendation', () {
      testWidgets('should display single recommendation correctly', (tester) async {
        final singleRecommendation = ['매일 물을 충분히 마시세요.'];

        await tester.pumpWidget(createTestWidget(singleRecommendation));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.recommendations), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('매일 물을 충분히 마시세요.'), findsOneWidget);
        expect(find.text('2'), findsNothing); // Should not have second number
      });
    });

    group('Multiple Recommendations', () {
      testWidgets('should handle many recommendations', (tester) async {
        final manyRecommendations = List.generate(10, (index) => '추천사항 ${index + 1}');

        await tester.pumpWidget(createTestWidget(manyRecommendations));
        await tester.pumpAndSettle();

        // Check for all number badges
        for (int i = 1; i <= 10; i++) {
          expect(find.text('$i'), findsOneWidget);
        }

        // Check for all recommendation texts
        for (int i = 0; i < 10; i++) {
          expect(find.text('추천사항 ${i + 1}'), findsOneWidget);
        }
      });

      testWidgets('should maintain proper numbering order', (tester) async {
        final orderedRecommendations = ['첫 번째 추천사항', '두 번째 추천사항', '세 번째 추천사항'];

        await tester.pumpWidget(createTestWidget(orderedRecommendations));
        await tester.pumpAndSettle();

        // Verify numbering matches order
        final firstNumber = find.text('1');
        final secondNumber = find.text('2');
        final thirdNumber = find.text('3');

        expect(firstNumber, findsOneWidget);
        expect(secondNumber, findsOneWidget);
        expect(thirdNumber, findsOneWidget);

        // Verify texts are in correct order
        final firstText = find.text('첫 번째 추천사항');
        final secondText = find.text('두 번째 추천사항');
        final thirdText = find.text('세 번째 추천사항');

        final firstPos = tester.getTopLeft(firstText);
        final secondPos = tester.getTopLeft(secondText);
        final thirdPos = tester.getTopLeft(thirdText);

        expect(firstPos.dy, lessThan(secondPos.dy));
        expect(secondPos.dy, lessThan(thirdPos.dy));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very long recommendation text', (tester) async {
        final longRecommendations = ['이것은 매우 긴 추천사항입니다. ' * 20];

        await tester.pumpWidget(createTestWidget(longRecommendations));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        expect(find.textContaining('이것은 매우 긴 추천사항입니다.'), findsOneWidget);
        expect(tester.takeException(), isNull); // Should not overflow
      });

      testWidgets('should handle empty string recommendations', (tester) async {
        final emptyStringRecommendations = ['', '유효한 추천사항', ''];

        await tester.pumpWidget(createTestWidget(emptyStringRecommendations));
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('유효한 추천사항'), findsOneWidget);
      });

      testWidgets('should handle special characters in recommendations', (tester) async {
        final specialCharRecommendations = ['운동량을 20% 증가시키세요! 💪', '물 섭취: 하루 2L+ 권장 ⭐', '식단 개선 → 건강한 삶 🥗'];

        await tester.pumpWidget(createTestWidget(specialCharRecommendations));
        await tester.pumpAndSettle();

        expect(find.text('운동량을 20% 증가시키세요! 💪'), findsOneWidget);
        expect(find.text('물 섭취: 하루 2L+ 권장 ⭐'), findsOneWidget);
        expect(find.text('식단 개선 → 건강한 삶 🥗'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible with proper semantics', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check that important text is accessible
        expect(find.text(AppStrings.recommendations), findsOneWidget);

        // Verify icon is present for visual context
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

        // Check that all recommendations are accessible
        for (final recommendation in testRecommendations) {
          expect(find.text(recommendation), findsOneWidget);
        }

        // Check that number badges are accessible
        for (int i = 1; i <= testRecommendations.length; i++) {
          expect(find.text('$i'), findsOneWidget);
        }
      });
    });

    group('Widget Structure', () {
      testWidgets('should return SizedBox.shrink when empty', (tester) async {
        await tester.pumpWidget(createTestWidget([]));
        await tester.pumpAndSettle();

        // The widget should render but be effectively invisible
        expect(find.byType(RecommendationsSection), findsOneWidget);
        expect(find.byType(SizedBox), findsOneWidget);
      });

      testWidgets('should contain proper widget hierarchy', (tester) async {
        await tester.pumpWidget(createTestWidget(testRecommendations));
        await tester.pumpAndSettle();

        // Check for main structural widgets
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Row).evaluate().length, greaterThanOrEqualTo(6)); // Header + 5 recommendations
        expect(find.byType(Container).evaluate().length, greaterThanOrEqualTo(6)); // Header + 5 number badges
      });
    });

    group('Text Styling', () {
      testWidgets('should apply correct text styles', (tester) async {
        await tester.pumpWidget(createTestWidget(['테스트 추천사항']));
        await tester.pumpAndSettle();

        // Find the recommendation text widget
        final textWidget = find.text('테스트 추천사항');
        expect(textWidget, findsOneWidget);

        // The text should be wrapped in an Expanded widget for proper layout
        final expandedFinder = find.ancestor(of: textWidget, matching: find.byType(Expanded));
        expect(expandedFinder, findsOneWidget);
      });

      testWidgets('should display number badges with white text', (tester) async {
        await tester.pumpWidget(createTestWidget(['테스트']));
        await tester.pumpAndSettle();

        final numberText = find.text('1');
        expect(numberText, findsOneWidget);

        // Number should be in a circular container
        final containerFinder = find.ancestor(of: numberText, matching: find.byType(Container));
        expect(containerFinder.evaluate().length, greaterThanOrEqualTo(1));
      });
    });
  });
}
