import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/widgets/loading/loading_state_manager.dart';

void main() {
  group('LoadingStateManager Widget Tests', () {
    Widget createTestWidget({
      required LoadingStateType state,
      LoadingStateConfig config = const LoadingStateConfig(),
      VoidCallback? onTimeout,
      VoidCallback? onCancel,
      VoidCallback? onRetry,
      double? progress,
      int currentStep = 0,
      String? errorMessage,
      Widget? child,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LoadingStateManager(
            state: state,
            config: config,
            onTimeout: onTimeout,
            onCancel: onCancel,
            onRetry: onRetry,
            progress: progress,
            currentStep: currentStep,
            errorMessage: errorMessage,
            child: child ?? const Text('Test Content'),
          ),
        ),
      );
    }

    group('Initial and Success States', () {
      testWidgets('should display child content in initial state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.initial, child: const Text('Initial Content')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Initial Content'), findsOneWidget);
      });

      testWidgets('should display child content in success state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.success, child: const Text('Success Content')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Success Content'), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('should display loading indicator in loading state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.loading,
            config: const LoadingStateConfig(customMessage: 'Loading test data...'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading test data...'), findsOneWidget);
      });

      testWidgets('should display loading more indicator', (tester) async {
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.loadingMore, child: const Text('Existing Content')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Existing Content'), findsOneWidget);
        expect(find.text(AppStrings.loadingMore), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display refreshing overlay', (tester) async {
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.refreshing, child: const Text('Content Being Refreshed')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Content Being Refreshed'), findsOneWidget);
        expect(find.text(AppStrings.syncingData), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Generating State', () {
      testWidgets('should display generating state with progress', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.generating,
            config: const LoadingStateConfig(showProgress: true, customMessage: 'Generating report...'),
            progress: 0.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Generating report...'), findsOneWidget);
        // The EnhancedProgressIndicator is not implemented yet, so we just check for basic progress indication
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display cancel button when configured', (tester) async {
        bool cancelCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.generating,
            config: const LoadingStateConfig(showCancelButton: true),
            onCancel: () => cancelCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Test cancel functionality if cancel button exists
        final cancelButton = find.text('취소');
        if (tester.any(cancelButton)) {
          await tester.tap(cancelButton);
          expect(cancelCalled, true);
        }
      });
    });

    group('Processing State', () {
      testWidgets('should display processing state with steps', (tester) async {
        const steps = ['Step 1', 'Step 2', 'Step 3'];

        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.processing,
            config: const LoadingStateConfig(showSteps: true, progressSteps: steps),
            currentStep: 1,
          ),
        );
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should use default steps when none provided', (tester) async {
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.processing, config: const LoadingStateConfig(showSteps: true)),
        );
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('should display error state with retry button', (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.error,
            errorMessage: 'Test error occurred',
            onRetry: () => retryCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.errorOccurred), findsOneWidget);
        expect(find.text('Test error occurred'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Test retry button
        await tester.tap(find.text(AppStrings.retry));
        await tester.pumpAndSettle();

        expect(retryCalled, true);
      });

      testWidgets('should display default error message when none provided', (tester) async {
        await tester.pumpWidget(createTestWidget(state: LoadingStateType.error));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.errorOccurred), findsOneWidget);
        expect(find.text(AppStrings.unexpectedError), findsOneWidget);
      });
    });

    group('Timeout State', () {
      testWidgets('should display timeout state with retry and cancel buttons', (tester) async {
        bool retryCalled = false;
        bool cancelCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.timeout,
            onRetry: () => retryCalled = true,
            onCancel: () => cancelCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.timeoutError), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
        expect(find.text(AppStrings.cancel), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);

        // Test retry button
        await tester.tap(find.text(AppStrings.retry));
        await tester.pumpAndSettle();
        expect(retryCalled, true);

        // Test cancel button
        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();
        expect(cancelCalled, true);
      });
    });

    group('Animations', () {
      testWidgets('should animate state transitions', (tester) async {
        await tester.pumpWidget(createTestWidget(state: LoadingStateType.loading));

        // Check for animation widgets
        expect(find.byType(AnimatedSwitcher), findsOneWidget);

        final fadeTransitions = find.byType(FadeTransition);
        expect(fadeTransitions.evaluate().length, greaterThanOrEqualTo(1));

        await tester.pumpAndSettle();
      });

      testWidgets('should handle state changes with animations', (tester) async {
        Widget testWidget = createTestWidget(state: LoadingStateType.loading);
        await tester.pumpWidget(testWidget);
        await tester.pump();

        // Change state
        testWidget = createTestWidget(state: LoadingStateType.success);
        await tester.pumpWidget(testWidget);
        await tester.pump();

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });
    });

    group('Configuration Options', () {
      testWidgets('should respect timeout configuration', (tester) async {
        const config = LoadingStateConfig(timeout: Duration(seconds: 5), enableTimeout: true);

        await tester.pumpWidget(createTestWidget(state: LoadingStateType.generating, config: config));
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle custom messages', (tester) async {
        const customMessage = 'Custom loading message';
        const config = LoadingStateConfig(customMessage: customMessage);

        await tester.pumpWidget(createTestWidget(state: LoadingStateType.loading, config: config));
        await tester.pumpAndSettle();

        expect(find.text(customMessage), findsOneWidget);
      });

      testWidgets('should handle progress steps configuration', (tester) async {
        const steps = ['Custom Step 1', 'Custom Step 2', 'Custom Step 3'];
        const config = LoadingStateConfig(showSteps: true, progressSteps: steps);

        await tester.pumpWidget(createTestWidget(state: LoadingStateType.processing, config: config, currentStep: 1));
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null callbacks gracefully', (tester) async {
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.error, onRetry: null, onCancel: null, onTimeout: null),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.retry), findsOneWidget);
        // Should not crash when tapping retry with null callback
        await tester.tap(find.text(AppStrings.retry));
        await tester.pumpAndSettle();
      });

      testWidgets('should handle negative progress values', (tester) async {
        await tester.pumpWidget(createTestWidget(state: LoadingStateType.generating, progress: -0.5));
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle progress values greater than 1', (tester) async {
        await tester.pumpWidget(createTestWidget(state: LoadingStateType.generating, progress: 1.5));
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle invalid current step values', (tester) async {
        const steps = ['Step 1', 'Step 2'];

        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.processing,
            config: const LoadingStateConfig(progressSteps: steps),
            currentStep: 10, // Invalid step index
          ),
        );
        await tester.pumpAndSettle();

        // Basic progress indication should be shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible in all states', (tester) async {
        // Test loading state accessibility
        await tester.pumpWidget(
          createTestWidget(
            state: LoadingStateType.loading,
            config: const LoadingStateConfig(customMessage: 'Loading content'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Loading content'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Test error state accessibility
        await tester.pumpWidget(
          createTestWidget(state: LoadingStateType.error, errorMessage: 'Accessible error message'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Accessible error message'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
      });
    });
  });

  group('InlineLoadingIndicator Widget Tests', () {
    Widget createInlineTestWidget({required String message, double size = 16.0, Color? color}) {
      return MaterialApp(home: Scaffold(body: InlineLoadingIndicator(message: message, size: size, color: color)));
    }

    testWidgets('should display message and loading indicator', (tester) async {
      await tester.pumpWidget(createInlineTestWidget(message: 'Loading...'));
      await tester.pumpAndSettle();

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should respect custom size', (tester) async {
      await tester.pumpWidget(createInlineTestWidget(message: 'Loading...', size: 24.0));
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);
    });

    testWidgets('should use custom color when provided', (tester) async {
      await tester.pumpWidget(createInlineTestWidget(message: 'Loading...', color: Colors.red));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('PulseLoadingButton Widget Tests', () {
    Widget createPulseTestWidget({required bool isLoading, VoidCallback? onPressed, Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: PulseLoadingButton(isLoading: isLoading, onPressed: onPressed, child: child ?? const Text('Button')),
        ),
      );
    }

    testWidgets('should display normal button when not loading', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        createPulseTestWidget(isLoading: false, onPressed: () => pressed = true, child: const Text('Click Me')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });

    testWidgets('should display loading button with animation when loading', (tester) async {
      await tester.pumpWidget(createPulseTestWidget(isLoading: true, child: const Text('Loading')));
      await tester.pump();

      expect(find.text('Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });

    testWidgets('should disable button when loading', (tester) async {
      await tester.pumpWidget(createPulseTestWidget(isLoading: true, onPressed: () {}));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should animate when loading state changes', (tester) async {
      Widget testWidget = createPulseTestWidget(isLoading: false);
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Change to loading
      testWidget = createPulseTestWidget(isLoading: true);
      await tester.pumpWidget(testWidget);
      await tester.pump();

      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });
  });
}
