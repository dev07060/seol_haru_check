import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/core/error_handler.dart';
import 'package:seol_haru_check/core/offline_manager.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import '../helpers/test_data_helper.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/services/weekly_report_service.dart';

import 'weekly_report_provider_test.mocks.dart';

@GenerateMocks([WeeklyReportService, User, OfflineManager])
void main() {
  group('WeeklyReportState', () {
    test('should create default state correctly', () {
      const state = WeeklyReportState();

      expect(state.reports, isEmpty);
      expect(state.currentReport, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasNewReport, false);
      expect(state.isLoadingMore, false);
      expect(state.isOffline, false);
      expect(state.syncStatus, isNull);
      expect(state.lastException, isNull);
      expect(state.isGenerating, false);
      expect(state.isProcessing, false);
      expect(state.isRefreshing, false);
      expect(state.hasTimedOut, false);
      expect(state.progress, isNull);
      expect(state.currentStep, 0);
      expect(state.progressSteps, isNull);
    });

    test('should create copy with updated values', () {
      const original = WeeklyReportState();
      final updated = original.copyWith(isLoading: true, error: 'Test error', hasNewReport: true);

      expect(updated.isLoading, true);
      expect(updated.error, 'Test error');
      expect(updated.hasNewReport, true);
      // Unchanged values
      expect(updated.reports, isEmpty);
      expect(updated.currentReport, isNull);
      expect(updated.isLoadingMore, false);
    });

    test('should clear values when specified', () {
      final original = WeeklyReportState(
        error: 'Test error',
        syncStatus: 'Syncing',
        lastException: AppException('Test'),
        progress: 0.5,
        progressSteps: ['Step 1'],
      );

      final updated = original.copyWith(
        clearError: true,
        clearSyncStatus: true,
        clearLastException: true,
        clearProgress: true,
        clearProgressSteps: true,
      );

      expect(updated.error, isNull);
      expect(updated.syncStatus, isNull);
      expect(updated.lastException, isNull);
      expect(updated.progress, isNull);
      expect(updated.progressSteps, isNull);
    });

    test('should implement equality correctly', () {
      const state1 = WeeklyReportState(isLoading: true, error: 'Test error', hasNewReport: true);

      const state2 = WeeklyReportState(isLoading: true, error: 'Test error', hasNewReport: true);

      const state3 = WeeklyReportState(isLoading: false, error: 'Different error', hasNewReport: false);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('should have meaningful toString', () {
      const state = WeeklyReportState(isLoading: true, error: 'Test error', hasNewReport: true);

      final string = state.toString();
      expect(string, contains('WeeklyReportState'));
      expect(string, contains('isLoading: true'));
      expect(string, contains('error: Test error'));
      expect(string, contains('hasNewReport: true'));
    });
  });

  group('WeeklyReportNotifier', () {
    late MockWeeklyReportService mockService;
    late MockUser mockUser;
    late ProviderContainer container;
    late WeeklyReportNotifier notifier;

    setUp(() {
      mockService = MockWeeklyReportService();
      mockUser = MockUser();

      // Setup mock user
      when(mockUser.uid).thenReturn('test-user-123');

      container = ProviderContainer(
        overrides: [
          weeklyReportServiceProvider.overrideWithValue(mockService),
          authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
        ],
      );

      notifier = container.read(weeklyReportProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('fetchCurrentReport', () {
      test('should fetch current report successfully', () async {
        // Arrange
        final testReport = WeeklyReport(
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
            exerciseInsights: 'Great consistency',
            dietInsights: 'Balanced nutrition',
            overallAssessment: 'Excellent progress',
            strengthAreas: ['Consistency'],
            improvementAreas: ['Hydration'],
          ),
          recommendations: ['Drink more water'],
          status: ReportStatus.completed,
        );

        when(mockService.fetchCurrentWeekReport('test-user-123')).thenAnswer((_) async => testReport);

        // Act
        await notifier.fetchCurrentReport();

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.currentReport, equals(testReport));
        expect(state.isLoading, false);
        expect(state.error, isNull);
        expect(state.hasNewReport, false);

        verify(mockService.fetchCurrentWeekReport('test-user-123')).called(1);
      });

      test('should handle no current report found', () async {
        // Arrange
        when(mockService.fetchCurrentWeekReport('test-user-123')).thenAnswer((_) async => null);

        // Act
        await notifier.fetchCurrentReport();

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.currentReport, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNull);

        verify(mockService.fetchCurrentWeekReport('test-user-123')).called(1);
      });

      test('should handle service error', () async {
        // Arrange
        final testError = Exception('Network error');
        when(mockService.fetchCurrentWeekReport('test-user-123')).thenThrow(testError);

        // Act
        await notifier.fetchCurrentReport();

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.currentReport, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
        expect(state.lastException, isNotNull);

        verify(mockService.fetchCurrentWeekReport('test-user-123')).called(1);
      });

      test('should handle unauthenticated user', () async {
        // Arrange
        final unauthenticatedContainer = ProviderContainer(
          overrides: [
            weeklyReportServiceProvider.overrideWithValue(mockService),
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );

        final unauthenticatedNotifier = unauthenticatedContainer.read(weeklyReportProvider.notifier);

        // Act
        await unauthenticatedNotifier.fetchCurrentReport();

        // Assert
        final state = unauthenticatedContainer.read(weeklyReportProvider);
        expect(state.error, AppStrings.loginRequired);
        expect(state.lastException, isA<AuthException>());

        verifyNever(mockService.fetchCurrentWeekReport(any));

        unauthenticatedContainer.dispose();
      });
    });

    group('fetchHistoricalReports', () {
      test('should fetch historical reports successfully', () async {
        // Arrange
        final testReports = [
          WeeklyReport(
            id: 'report-1',
            userUuid: 'test-user-123',
            weekStartDate: DateTime(2024, 1, 8),
            weekEndDate: DateTime(2024, 1, 14),
            generatedAt: DateTime(2024, 1, 15),
            stats: TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 8,
        exerciseDays: 4,
        dietDays: 3,
        exerciseTypes: {'yoga': 2, 'cardio': 2},
        consistencyScore: 0.75,
      ),
            analysis: const AIAnalysis(
              exerciseInsights: 'Good variety',
              dietInsights: 'Needs improvement',
              overallAssessment: 'Making progress',
              strengthAreas: ['Variety'],
              improvementAreas: ['Consistency'],
            ),
            recommendations: ['Be more consistent'],
            status: ReportStatus.completed,
          ),
          WeeklyReport(
            id: 'report-2',
            userUuid: 'test-user-123',
            weekStartDate: DateTime(2024, 1, 1),
            weekEndDate: DateTime(2024, 1, 7),
            generatedAt: DateTime(2024, 1, 8),
            stats: TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 6,
        exerciseDays: 3,
        dietDays: 2,
        exerciseTypes: {'running': 3},
        consistencyScore: 0.6,
      ),
            analysis: const AIAnalysis(
              exerciseInsights: 'Good start',
              dietInsights: 'Room for improvement',
              overallAssessment: 'Getting started',
              strengthAreas: ['Motivation'],
              improvementAreas: ['Frequency'],
            ),
            recommendations: ['Increase frequency'],
            status: ReportStatus.completed,
          ),
        ];

        when(
          mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null),
        ).thenAnswer((_) async => testReports);

        // Act
        await notifier.fetchHistoricalReports(refresh: true);

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.reports, hasLength(2));
        expect(state.reports.first.id, 'report-1'); // Should be sorted by date descending
        expect(state.reports.last.id, 'report-2');
        expect(state.isLoading, false);
        expect(state.error, isNull);

        verify(mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null)).called(1);
      });

      test('should handle empty historical reports', () async {
        // Arrange
        when(
          mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null),
        ).thenAnswer((_) async => []);

        // Act
        await notifier.fetchHistoricalReports(refresh: true);

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.reports, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNull);

        verify(mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null)).called(1);
      });

      test('should handle service error', () async {
        // Arrange
        final testError = Exception('Network error');
        when(mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null)).thenThrow(testError);

        // Act
        await notifier.fetchHistoricalReports(refresh: true);

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.reports, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
        expect(state.lastException, isNotNull);

        verify(mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null)).called(1);
      });

      test('should handle pagination correctly', () async {
        // Arrange - First call returns full page
        final firstPageReports = List.generate(
          10,
          (index) => WeeklyReport(
            id: 'report-$index',
            userUuid: 'test-user-123',
            weekStartDate: DateTime(2024, 1, 1 + index),
            weekEndDate: DateTime(2024, 1, 7 + index),
            generatedAt: DateTime(2024, 1, 8 + index),
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
        );

        when(
          mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null),
        ).thenAnswer((_) async => firstPageReports);

        // Act
        await notifier.fetchHistoricalReports(refresh: true);

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.reports, hasLength(10));
        expect(notifier.hasMoreReports, true); // Should have more data since we got a full page

        verify(mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null)).called(1);
      });
    });

    group('fetchReportByWeek', () {
      test('should fetch report by week successfully', () async {
        // Arrange
        final weekStart = DateTime(2024, 1, 15);
        final testReport = WeeklyReport(
          id: 'test-report-week',
          userUuid: 'test-user-123',
          weekStartDate: weekStart,
          weekEndDate: weekStart.add(const Duration(days: 6)),
          generatedAt: weekStart.add(const Duration(days: 7)),
          stats: TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 7,
        exerciseDays: 4,
        dietDays: 3,
        exerciseTypes: {'swimming': 2, 'yoga': 2},
        consistencyScore: 0.7,
      ),
          analysis: const AIAnalysis(
            exerciseInsights: 'Good week',
            dietInsights: 'Balanced',
            overallAssessment: 'Solid progress',
            strengthAreas: ['Balance'],
            improvementAreas: ['Intensity'],
          ),
          recommendations: ['Increase intensity'],
          status: ReportStatus.completed,
        );

        when(
          mockService.fetchReportByWeek(userUuid: 'test-user-123', weekStart: weekStart),
        ).thenAnswer((_) async => testReport);

        // Act
        final result = await notifier.fetchReportByWeek(weekStart);

        // Assert
        expect(result, equals(testReport));
        final state = container.read(weeklyReportProvider);
        expect(state.reports, contains(testReport));
        expect(state.error, isNull);

        verify(mockService.fetchReportByWeek(userUuid: 'test-user-123', weekStart: weekStart)).called(1);
      });

      test('should handle no report found for week', () async {
        // Arrange
        final weekStart = DateTime(2024, 1, 15);
        when(
          mockService.fetchReportByWeek(userUuid: 'test-user-123', weekStart: weekStart),
        ).thenAnswer((_) async => null);

        // Act
        final result = await notifier.fetchReportByWeek(weekStart);

        // Assert
        expect(result, isNull);
        final state = container.read(weeklyReportProvider);
        expect(state.error, isNull);

        verify(mockService.fetchReportByWeek(userUuid: 'test-user-123', weekStart: weekStart)).called(1);
      });

      test('should handle service error', () async {
        // Arrange
        final weekStart = DateTime(2024, 1, 15);
        final testError = Exception('Network error');
        when(mockService.fetchReportByWeek(userUuid: 'test-user-123', weekStart: weekStart)).thenThrow(testError);

        // Act & Assert
        try {
          await notifier.fetchReportByWeek(weekStart);
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<AppException>());
        }

        final state = container.read(weeklyReportProvider);
        expect(state.error, isNotNull);
        expect(state.lastException, isNotNull);

        verify(mockService.fetchReportByWeek(userUuid: 'test-user-123', weekStart: weekStart)).called(1);
      });
    });

    group('markNewReportAsRead', () {
      test('should mark new report as read', () {
        // Arrange
        notifier.state = notifier.state.copyWith(hasNewReport: true);

        // Act
        notifier.markNewReportAsRead();

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.hasNewReport, false);
      });

      test('should do nothing if no new report', () {
        // Arrange
        notifier.state = notifier.state.copyWith(hasNewReport: false);

        // Act
        notifier.markNewReportAsRead();

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.hasNewReport, false);
      });
    });

    group('refresh', () {
      test('should refresh all data', () async {
        // Arrange
        when(mockService.fetchCurrentWeekReport('test-user-123')).thenAnswer((_) async => null);
        when(
          mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null),
        ).thenAnswer((_) async => []);

        // Act
        await notifier.refresh();

        // Assert
        verify(mockService.fetchCurrentWeekReport('test-user-123')).called(1);
        verify(mockService.fetchUserReports(userUuid: 'test-user-123', limit: 10, startAfter: null)).called(1);
      });
    });

    group('clearError', () {
      test('should clear error state', () {
        // Arrange
        notifier.state = notifier.state.copyWith(
          error: 'Test error',
          lastException: AppException('Test'),
          syncStatus: 'Syncing',
        );

        // Act
        notifier.clearError();

        // Assert
        final state = container.read(weeklyReportProvider);
        expect(state.error, isNull);
        expect(state.lastException, isNull);
        expect(state.syncStatus, isNull);
      });
    });

    group('canRetry', () {
      test('should return true for retryable errors', () {
        // Arrange
        final originalError = const SocketException('Network error');
        final networkError = NetworkException('Network error', originalError: originalError);
        notifier.state = notifier.state.copyWith(lastException: networkError);

        // Act & Assert
        expect(notifier.canRetry, true);
      });

      test('should return false for non-retryable errors', () {
        // Arrange
        final authError = AuthException('Auth error');
        notifier.state = notifier.state.copyWith(lastException: authError);

        // Act & Assert
        expect(notifier.canRetry, false);
      });

      test('should return false when no exception', () {
        // Arrange
        notifier.state = notifier.state.copyWith(lastException: null);

        // Act & Assert
        expect(notifier.canRetry, false);
      });
    });

    group('errorMessageWithRetry', () {
      test('should include retry message for retryable errors', () {
        // Arrange
        final originalError = const SocketException('Network error');
        final networkError = NetworkException('Network error', originalError: originalError);
        notifier.state = notifier.state.copyWith(error: 'Network error', lastException: networkError);

        // Act
        final message = notifier.errorMessageWithRetry;

        // Assert
        expect(message, contains('Network error'));
        expect(message, contains(AppStrings.tryAgainLater));
      });

      test('should not include retry message for non-retryable errors', () {
        // Arrange
        final authError = AuthException('Auth error');
        notifier.state = notifier.state.copyWith(error: 'Auth error', lastException: authError);

        // Act
        final message = notifier.errorMessageWithRetry;

        // Assert
        expect(message, equals('Auth error'));
        expect(message, isNot(contains(AppStrings.tryAgainLater)));
      });

      test('should return empty string when no error', () {
        // Arrange
        notifier.state = notifier.state.copyWith(error: null);

        // Act
        final message = notifier.errorMessageWithRetry;

        // Assert
        expect(message, isEmpty);
      });
    });

    group('simulateReportGeneration', () {
      test('should simulate report generation with progress', () async {
        // Act
        final future = notifier.simulateReportGeneration();

        // Assert initial state
        expect(notifier.state.isGenerating, true);
        expect(notifier.state.progressSteps, isNotNull);
        expect(notifier.state.progressSteps!.length, 4);

        // Wait for completion (but not the full duration to avoid slow tests)
        await Future.delayed(const Duration(milliseconds: 100));

        // Cancel the operation to avoid waiting for the full simulation
        notifier.cancelOperations();

        // Wait for the future to complete
        await future.catchError((_) => null);
      });

      test('should not start if already generating', () async {
        // Arrange
        notifier.state = notifier.state.copyWith(isGenerating: true);

        // Act
        await notifier.simulateReportGeneration();

        // Assert - should not change state if already generating
        expect(notifier.state.isGenerating, true);
      });
    });

    group('cancelOperations', () {
      test('should cancel all operations and reset state', () {
        // Arrange
        notifier.state = notifier.state.copyWith(
          isLoading: true,
          isGenerating: true,
          isProcessing: true,
          isRefreshing: true,
          isLoadingMore: true,
          hasTimedOut: true,
          progress: 0.5,
          progressSteps: ['Step 1'],
          error: 'Test error',
          lastException: AppException('Test'),
        );

        // Act
        notifier.cancelOperations();

        // Assert
        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.isGenerating, false);
        expect(state.isProcessing, false);
        expect(state.isRefreshing, false);
        expect(state.isLoadingMore, false);
        expect(state.hasTimedOut, false);
        expect(state.progress, isNull);
        expect(state.progressSteps, isNull);
        expect(state.error, isNull);
        expect(state.lastException, isNull);
      });
    });

    group('handleTimeout', () {
      test('should handle timeout correctly', () {
        // Arrange
        notifier.state = notifier.state.copyWith(
          isLoading: true,
          isGenerating: true,
          progress: 0.5,
          progressSteps: ['Step 1'],
        );

        // Act
        notifier.handleTimeout();

        // Assert
        final state = notifier.state;
        expect(state.hasTimedOut, true);
        expect(state.isLoading, false);
        expect(state.isGenerating, false);
        expect(state.progress, isNull);
        expect(state.progressSteps, isNull);
        expect(state.error, AppStrings.timeoutError);
      });
    });

    group('resetTimeoutAndRetry', () {
      test('should reset timeout state', () {
        // Arrange
        notifier.state = notifier.state.copyWith(
          hasTimedOut: true,
          error: AppStrings.timeoutError,
          lastException: AppException('Timeout'),
          progress: 0.5,
          progressSteps: ['Step 1'],
        );

        // Act
        notifier.resetTimeoutAndRetry();

        // Assert
        final state = notifier.state;
        expect(state.hasTimedOut, false);
        expect(state.error, isNull);
        expect(state.lastException, isNull);
        expect(state.progress, isNull);
        expect(state.progressSteps, isNull);
      });
    });
  });
}
