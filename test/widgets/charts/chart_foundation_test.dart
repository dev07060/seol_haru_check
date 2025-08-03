import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/services/chart_foundation_service.dart';
import 'package:seol_haru_check/widgets/report/charts/base_chart_widget.dart';
import 'package:seol_haru_check/widgets/report/charts/chart_error_handler.dart';

void main() {
  group('Chart Foundation Tests', () {
    testWidgets('ChartTheme should be created from context', (tester) async {
      late ChartTheme theme;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              theme = ChartTheme.fromContext(context);
              return Container();
            },
          ),
        ),
      );

      expect(theme.primaryColor, isNotNull);
      expect(theme.backgroundColor, isNotNull);
      expect(theme.textColor, isNotNull);
      expect(theme.categoryColors, isNotEmpty);
    });

    testWidgets('AnimationConfig should have correct defaults', (tester) async {
      const config = AnimationConfig();

      expect(config.duration, const Duration(milliseconds: 1000));
      expect(config.curve, Curves.easeInOut);
      expect(config.enableStagger, true);
      expect(config.staggerDelay, const Duration(milliseconds: 100));
    });

    testWidgets('AnimationConfig presets should work', (tester) async {
      final fast = AnimationConfig.fast();
      final slow = AnimationConfig.slow();
      final bouncy = AnimationConfig.bouncy();
      final none = AnimationConfig.none();

      expect(fast.duration, const Duration(milliseconds: 500));
      expect(slow.duration, const Duration(milliseconds: 1500));
      expect(bouncy.enableBounce, true);
      expect(none.duration, Duration.zero);
    });

    test('ChartFoundationService should be singleton', () {
      final service1 = ChartFoundationService.instance;
      final service2 = ChartFoundationService.instance;

      expect(service1, same(service2));
    });

    test('ChartFoundationService should validate data correctly', () {
      final service = ChartFoundationService.instance;

      // Valid data
      final validData = {'key1': 10, 'key2': 20};
      final result = service.validateAndProcessChartData(validData, chartType: 'test', requiredKeys: ['key1', 'key2']);
      expect(result, equals(validData));

      // Invalid data - missing key
      expect(
        () => service.validateAndProcessChartData({'key1': 10}, chartType: 'test', requiredKeys: ['key1', 'key2']),
        throwsA(isA<ChartError>()),
      );

      // Invalid data - empty
      expect(() => service.validateAndProcessChartData({}, chartType: 'test'), throwsA(isA<ChartError>()));
    });

    test('ChartFoundationService should handle NaN values', () {
      final service = ChartFoundationService.instance;

      final dataWithNaN = {'valid': 10, 'invalid': double.nan};
      final result = service.validateAndProcessChartData(dataWithNaN, chartType: 'test');

      expect(result['valid'], 10);
      expect(result['invalid'], 0); // NaN should be converted to 0
    });

    test('ChartFoundationService should get category colors', () {
      final service = ChartFoundationService.instance;
      final theme = ChartTheme.light();

      final exerciseColor = service.getCategoryColor('근력 운동', theme);
      final dietColor = service.getCategoryColor('집밥/도시락', theme);
      final unknownColor = service.getCategoryColor('unknown', theme);

      expect(exerciseColor, isNotNull);
      expect(dietColor, isNotNull);
      expect(unknownColor, isNotNull);
    });

    test('ChartFoundationService should get category emojis', () {
      final service = ChartFoundationService.instance;

      expect(service.getCategoryEmoji('근력 운동'), '💪');
      expect(service.getCategoryEmoji('집밥/도시락'), '🍱');
      expect(service.getCategoryEmoji('unknown'), '📊');
    });

    testWidgets('ExampleChartWidget should render correctly', (tester) async {
      const testData = {'A': 10.0, 'B': 20.0, 'C': 15.0};

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ExampleChartWidget(data: testData, title: 'Test Chart', showTitle: true)),
        ),
      );

      expect(find.text('Test Chart'), findsOneWidget);
      expect(find.text('Chart Foundation Ready!'), findsOneWidget);
      expect(find.text('Data points: 3'), findsOneWidget);
    });

    testWidgets('ExampleChartWidget should show empty state for no data', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ExampleChartWidget(data: {}))));

      expect(find.text('표시할 데이터가 없습니다'), findsOneWidget);
    });

    testWidgets('ChartErrorHandler should create loading placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ChartErrorHandler.createLoadingPlaceholder(message: 'Loading test...'))),
      );

      expect(find.text('Loading test...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ChartErrorHandler should create empty placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartErrorHandler.createEmptyPlaceholder(
              message: 'No data available',
              actionText: 'Refresh',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('ChartErrorHandler should handle specific errors', (tester) async {
      const error = ChartError(type: ChartErrorType.rendering, message: 'Test error');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(body: ChartErrorHandler.handleSpecificError(context, error));
            },
          ),
        ),
      );

      expect(find.text('차트를 그리는 중 오류가 발생했습니다'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    });
  });
}
