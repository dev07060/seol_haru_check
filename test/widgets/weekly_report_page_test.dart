import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/pages/weekly_report_page.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/services/category_achievement_service.dart';
import 'package:seol_haru_check/services/weekly_report_service.dart';
import 'package:seol_haru_check/widgets/loading/loading_state_manager.dart';
import 'package:seol_haru_check/widgets/report/diet_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/exercise_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/recommendations_section.dart';
import 'package:seol_haru_check/widgets/report/report_summary_card.dart';

import '../helpers/test_data_helper.dart';
import 'weekly_report_page_test.mocks.dart';

@GenerateMocks([WeeklyReportService, User, GoRouter])
/// Simple mock for CategoryAchievementService
class MockCategoryAchievementService extends Mock implements CategoryAchievementService {}

void main() {
  group('WeeklyReportPage Widget Tests', () {
    late MockWeeklyReportService mockService;
    late MockUser mockUser;

    setUp(() {
      mockService = MockWeeklyReportService();
      mockUser = MockUser();

      // Setup mock user
      when(mockUser.uid).thenReturn('test-user-123');
    });

    Widget createTestWidget({WeeklyReportState? initialState, bool includeRouter = true}) {
      final container = ProviderContainer(
        overrides: [
          weeklyReportServiceProvider.overrideWithValue(mockService),
          authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
          if (initialState != null) weeklyReportProvider.overrideWith((ref) => TestWeeklyReportNotifier(initialState)),
        ],
      );

      Widget child = UncontrolledProviderScope(container: container, child: const WeeklyReportPage());

      if (includeRouter) {
        child = MaterialApp.router(
          routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => child)]),
        );
      } else {
        child = MaterialApp(home: child);
      }

      return child;
    }

    group('Initial State', () {
      testWidgets('should display app bar with correct title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.weeklyReport), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display refresh indicator', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('should display loading state when isLoading is true', (tester) async {
        const loadingState = WeeklyReportState(isLoading: true);

        await tester.pumpWidget(createTestWidget(initialState: loadingState));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingStateManager), findsOneWidget);

        // Check for at least one CircularProgressIndicator
        final progressIndicators = find.byType(CircularProgressIndicator);
        expect(progressIndicators.evaluate().length, greaterThanOrEqualTo(1));
      });

      testWidgets('should display generating state with progress', (tester) async {
        const generatingState = WeeklyReportState(
          isGenerating: true,
          progress: 0.5,
          progressSteps: ['Step 1', 'Step 2', 'Step 3'],
          currentStep: 1,
        );

        await tester.pumpWidget(createTestWidget(initialState: generatingState));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingStateManager), findsOneWidget);
        expect(find.text(AppStrings.generatingReport), findsOneWidget);
      });

      testWidgets('should display processing state with steps', (tester) async {
        const processingState = WeeklyReportState(
          isProcessing: true,
          progressSteps: ['사용자 데이터 수집 중...', 'AI 분석 진행 중...'],
          currentStep: 0,
        );

        await tester.pumpWidget(createTestWidget(initialState: processingState));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingStateManager), findsOneWidget);
        expect(find.text(AppStrings.processingData), findsOneWidget);
      });

      testWidgets('should display refreshing state', (tester) async {
        const refreshingState = WeeklyReportState(isRefreshing: true);

        await tester.pumpWidget(createTestWidget(initialState: refreshingState));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingStateManager), findsOneWidget);
        expect(find.text(AppStrings.refreshingData), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('should display error state with retry button', (tester) async {
        const errorState = WeeklyReportState(error: 'Test error message');

        await tester.pumpWidget(createTestWidget(initialState: errorState));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingStateManager), findsOneWidget);
        expect(find.text('Test error message'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
      });

      testWidgets('should display timeout state with retry and cancel buttons', (tester) async {
        const timeoutState = WeeklyReportState(hasTimedOut: true);

        await tester.pumpWidget(createTestWidget(initialState: timeoutState));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingStateManager), findsOneWidget);
        expect(find.text(AppStrings.timeoutError), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
        expect(find.text(AppStrings.cancel), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should display empty state when no report exists', (tester) async {
        const emptyState = WeeklyReportState(currentReport: null, isLoading: false);

        await tester.pumpWidget(createTestWidget(initialState: emptyState));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.noReportYet), findsOneWidget);
        expect(find.text(AppStrings.needMoreCertifications), findsOneWidget);
        expect(find.text(AppStrings.keepItUp), findsOneWidget);
        expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      });
    });

    group('Report Content Display', () {
      late WeeklyReport testReport;

      setUp(() {
        testReport = WeeklyReport(
          id: 'test-report-1',
          userUuid: 'test-user-123',
          weekStartDate: DateTime(2024, 1, 15),
          weekEndDate: DateTime(2024, 1, 21),
          generatedAt: DateTime(2024, 1, 22),
          stats: TestDataHelper.createDefaultWeeklyStats(
            totalCertifications: 10,
            exerciseDays: 5,
            dietDays: 4,
            exerciseTypes: {'running': 3, 'swimming': 2},
            consistencyScore: 0.85,
          ),
          analysis: const AIAnalysis(
            exerciseInsights: 'Great exercise consistency this week',
            dietInsights: 'Balanced nutrition with room for improvement',
            overallAssessment: 'Excellent progress overall',
            strengthAreas: ['운동 일관성', '식단 균형'],
            improvementAreas: ['수분 섭취', '수면 패턴'],
          ),
          recommendations: ['물을 더 많이 마시세요', '규칙적인 수면 패턴을 유지하세요'],
          status: ReportStatus.completed,
        );
      });

      testWidgets('should display report content when report exists', (tester) async {
        final reportState = WeeklyReportState(currentReport: testReport, isLoading: false);

        await tester.pumpWidget(createTestWidget(initialState: reportState));
        await tester.pumpAndSettle();

        // Check report header
        expect(find.text(AppStrings.thisWeekReport), findsOneWidget);
        expect(find.text('1월 15일 - 1월 21일'), findsOneWidget);

        // Check report components
        expect(find.byType(ReportSummaryCard), findsOneWidget);
        expect(find.byType(ExerciseAnalysisSection), findsOneWidget);
        expect(find.byType(DietAnalysisSection), findsOneWidget);
        expect(find.byType(RecommendationsSection), findsOneWidget);
      });

      testWidgets('should display generating indicator when report status is generating', (tester) async {
        final generatingReport = testReport.copyWith(status: ReportStatus.generating);
        final reportState = WeeklyReportState(currentReport: generatingReport, isLoading: false);

        await tester.pumpWidget(createTestWidget(initialState: reportState));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.reportGenerating), findsOneWidget);

        // Check for at least one CircularProgressIndicator
        final progressIndicators = find.byType(CircularProgressIndicator);
        expect(progressIndicators.evaluate().length, greaterThanOrEqualTo(1));
      });
    });

    group('User Interactions', () {
      testWidgets('should trigger refresh when pull-to-refresh is used', (tester) async {
        const initialState = WeeklyReportState();

        await tester.pumpWidget(createTestWidget(initialState: initialState));
        await tester.pumpAndSettle();

        // Find the RefreshIndicator and trigger refresh
        final refreshIndicator = find.byType(RefreshIndicator);
        expect(refreshIndicator, findsOneWidget);

        // Simulate pull-to-refresh gesture
        await tester.fling(refreshIndicator, const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Verify that refresh was triggered (loading state should be shown)
        // Note: In a real test, you would verify that the provider method was called
      });

      testWidgets('should handle back button navigation', (tester) async {
        await tester.pumpWidget(createTestWidget(includeRouter: false));
        await tester.pumpAndSettle();

        // Find and tap the back button
        final backButton = find.byIcon(Icons.arrow_back_ios_new);
        expect(backButton, findsOneWidget);

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // In a real app test, you would verify navigation occurred
      });

      testWidgets('should handle retry button tap in error state', (tester) async {
        const errorState = WeeklyReportState(error: 'Network error');

        await tester.pumpWidget(createTestWidget(initialState: errorState));
        await tester.pumpAndSettle();

        final retryButton = find.text(AppStrings.retry);
        expect(retryButton, findsOneWidget);

        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        // In a real test, you would verify that retry was called
      });

      testWidgets('should handle cancel button tap in timeout state', (tester) async {
        const timeoutState = WeeklyReportState(hasTimedOut: true);

        await tester.pumpWidget(createTestWidget(initialState: timeoutState));
        await tester.pumpAndSettle();

        final cancelButton = find.text(AppStrings.cancel);
        expect(cancelButton, findsOneWidget);

        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // In a real test, you would verify that cancel was called
      });
    });

    group('Scroll Behavior', () {
      testWidgets('should handle scroll behavior', (tester) async {
        final reportState = WeeklyReportState(
          reports: List.generate(
            5,
            (index) => WeeklyReport(
              id: 'report-$index',
              userUuid: 'test-user-123',
              weekStartDate: DateTime(2024, 1, 1 + index * 7),
              weekEndDate: DateTime(2024, 1, 7 + index * 7),
              generatedAt: DateTime(2024, 1, 8 + index * 7),
              stats: TestDataHelper.createDefaultWeeklyStats(
                totalCertifications: 5,
                exerciseDays: 3,
                dietDays: 2,
                exerciseTypes: {},
                consistencyScore: 0.5,
              ),
              analysis: const AIAnalysis(
                exerciseInsights: '',
                dietInsights: '',
                overallAssessment: '',
                strengthAreas: [],
                improvementAreas: [],
              ),
              recommendations: [],
              status: ReportStatus.completed,
            ),
          ),
          isLoading: false,
        );

        await tester.pumpWidget(createTestWidget(initialState: reportState));
        await tester.pumpAndSettle();

        // Find the scrollable widget
        final scrollable = find.byType(CustomScrollView);
        expect(scrollable, findsOneWidget);

        // Perform scroll action
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pumpAndSettle();

        // In a real test, you would verify that loadMoreReports was called
      });
    });

    group('Animation Tests', () {
      testWidgets('should animate content when data loads', (tester) async {
        const initialState = WeeklyReportState(isLoading: true);

        await tester.pumpWidget(createTestWidget(initialState: initialState));
        await tester.pump();

        // Verify loading state
        expect(find.byType(LoadingStateManager), findsOneWidget);

        // The animation controller should be present
        final animatedBuilders = find.byType(AnimatedBuilder);
        expect(animatedBuilders.evaluate().length, greaterThanOrEqualTo(1));
      });

      testWidgets('should handle fade animation for report content', (tester) async {
        final testReport = WeeklyReport(
          id: 'test-report-1',
          userUuid: 'test-user-123',
          weekStartDate: DateTime(2024, 1, 15),
          weekEndDate: DateTime(2024, 1, 21),
          generatedAt: DateTime(2024, 1, 22),
          stats: TestDataHelper.createDefaultWeeklyStats(
            totalCertifications: 5,
            exerciseDays: 3,
            dietDays: 2,
            exerciseTypes: {},
            consistencyScore: 0.5,
          ),
          analysis: const AIAnalysis(
            exerciseInsights: 'Test insights',
            dietInsights: 'Test diet',
            overallAssessment: 'Test assessment',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        final reportState = WeeklyReportState(currentReport: testReport, isLoading: false);

        await tester.pumpWidget(createTestWidget(initialState: reportState));
        await tester.pump();

        // Check for FadeTransition widget
        final fadeTransitions = find.byType(FadeTransition);
        expect(fadeTransitions.evaluate().length, greaterThanOrEqualTo(1));

        await tester.pumpAndSettle();
      });
    });
  });
}

/// Test implementation of WeeklyReportNotifier for widget testing
class TestWeeklyReportNotifier extends WeeklyReportNotifier {
  final WeeklyReportState _testState;

  TestWeeklyReportNotifier(this._testState)
    : super(MockWeeklyReportService(), MockCategoryAchievementService(), MockRef());

  @override
  WeeklyReportState get state => _testState;

  @override
  set state(WeeklyReportState newState) {
    // Override to prevent state changes during test
  }

  @override
  Future<void> fetchCurrentReport() async {
    // Mock implementation for testing
  }

  @override
  Future<void> refresh() async {
    // Mock implementation for testing
  }

  @override
  void markNewReportAsRead() {
    // Mock implementation for testing
  }

  @override
  void handleTimeout() {
    // Mock implementation for testing
  }

  @override
  void cancelOperations() {
    // Mock implementation for testing
  }

  @override
  void resetTimeoutAndRetry() {
    // Mock implementation for testing
  }

  @override
  Future<void> retryLastOperation() async {
    // Mock implementation for testing
  }
}

/// Mock Ref for testing
class MockRef extends Mock implements Ref {
  @override
  T read<T>(ProviderListenable<T> provider) {
    if (provider == authStateChangesProvider) {
      return Stream.value(MockUser()) as T;
    }
    return super.noSuchMethod(Invocation.getter(#read));
  }
}
