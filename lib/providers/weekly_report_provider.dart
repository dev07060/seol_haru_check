import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/core/error_handler.dart';
import 'package:seol_haru_check/core/offline_manager.dart';
import 'package:seol_haru_check/helpers/debug_data_helper.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_achievement_service.dart';
import 'package:seol_haru_check/services/visualization_data_service.dart';
import 'package:seol_haru_check/services/weekly_report_service.dart';

/// State class for weekly report management with loading and error states
@immutable
class WeeklyReportState {
  final List<WeeklyReport> reports;
  final WeeklyReport? currentReport;
  final bool isLoading;
  final String? error;
  final bool hasNewReport;
  final bool isLoadingMore;
  final bool isOffline;
  final String? syncStatus;
  final AppException? lastException;
  final bool isGenerating;
  final bool isProcessing;
  final bool isRefreshing;
  final bool hasTimedOut;
  final double? progress;
  final int currentStep;
  final List<String>? progressSteps;
  final List<CategoryAchievement> achievements;
  final List<AchievementProgress> achievementProgress;
  final bool isLoadingAchievements;
  final List<CategoryAchievement> newAchievements;

  const WeeklyReportState({
    this.reports = const [],
    this.currentReport,
    this.isLoading = false,
    this.error,
    this.hasNewReport = false,
    this.isLoadingMore = false,
    this.isOffline = false,
    this.syncStatus,
    this.lastException,
    this.isGenerating = false,
    this.isProcessing = false,
    this.isRefreshing = false,
    this.hasTimedOut = false,
    this.progress,
    this.currentStep = 0,
    this.progressSteps,
    this.achievements = const [],
    this.achievementProgress = const [],
    this.isLoadingAchievements = false,
    this.newAchievements = const [],
  });

  WeeklyReportState copyWith({
    List<WeeklyReport>? reports,
    WeeklyReport? currentReport,
    bool? isLoading,
    String? error,
    bool? hasNewReport,
    bool? isLoadingMore,
    bool? isOffline,
    String? syncStatus,
    AppException? lastException,
    bool? isGenerating,
    bool? isProcessing,
    bool? isRefreshing,
    bool? hasTimedOut,
    double? progress,
    int? currentStep,
    List<String>? progressSteps,
    List<CategoryAchievement>? achievements,
    List<AchievementProgress>? achievementProgress,
    bool? isLoadingAchievements,
    List<CategoryAchievement>? newAchievements,
    bool clearError = false,
    bool clearCurrentReport = false,
    bool clearSyncStatus = false,
    bool clearLastException = false,
    bool clearProgress = false,
    bool clearProgressSteps = false,
    bool clearNewAchievements = false,
  }) {
    return WeeklyReportState(
      reports: reports ?? this.reports,
      currentReport: clearCurrentReport ? null : (currentReport ?? this.currentReport),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasNewReport: hasNewReport ?? this.hasNewReport,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOffline: isOffline ?? this.isOffline,
      syncStatus: clearSyncStatus ? null : (syncStatus ?? this.syncStatus),
      lastException: clearLastException ? null : (lastException ?? this.lastException),
      isGenerating: isGenerating ?? this.isGenerating,
      isProcessing: isProcessing ?? this.isProcessing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasTimedOut: hasTimedOut ?? this.hasTimedOut,
      progress: clearProgress ? null : (progress ?? this.progress),
      currentStep: currentStep ?? this.currentStep,
      progressSteps: clearProgressSteps ? null : (progressSteps ?? this.progressSteps),
      achievements: achievements ?? this.achievements,
      achievementProgress: achievementProgress ?? this.achievementProgress,
      isLoadingAchievements: isLoadingAchievements ?? this.isLoadingAchievements,
      newAchievements: clearNewAchievements ? const [] : (newAchievements ?? this.newAchievements),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyReportState &&
        other.reports.length == reports.length &&
        other.currentReport == currentReport &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.hasNewReport == hasNewReport &&
        other.isLoadingMore == isLoadingMore &&
        other.isOffline == isOffline &&
        other.syncStatus == syncStatus &&
        other.lastException == lastException &&
        other.isGenerating == isGenerating &&
        other.isProcessing == isProcessing &&
        other.isRefreshing == isRefreshing &&
        other.hasTimedOut == hasTimedOut &&
        other.progress == progress &&
        other.currentStep == currentStep &&
        other.progressSteps?.length == progressSteps?.length;
  }

  @override
  int get hashCode {
    return Object.hash(
      reports.length,
      currentReport,
      isLoading,
      error,
      hasNewReport,
      isLoadingMore,
      isOffline,
      syncStatus,
      lastException,
      isGenerating,
      isProcessing,
      isRefreshing,
      hasTimedOut,
      progress,
      currentStep,
      progressSteps?.length,
    );
  }

  @override
  String toString() {
    return 'WeeklyReportState(reports: ${reports.length}, currentReport: $currentReport, isLoading: $isLoading, error: $error, hasNewReport: $hasNewReport, isLoadingMore: $isLoadingMore, isOffline: $isOffline, syncStatus: $syncStatus, lastException: $lastException, isGenerating: $isGenerating, isProcessing: $isProcessing, isRefreshing: $isRefreshing, hasTimedOut: $hasTimedOut, progress: $progress, currentStep: $currentStep, progressSteps: ${progressSteps?.length})';
  }
}

/// StateNotifier for managing weekly report data and operations
class WeeklyReportNotifier extends StateNotifier<WeeklyReportState> {
  final WeeklyReportService _service;
  final CategoryAchievementService _achievementService;
  final Ref _ref;

  // Pagination constants
  static const int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  // Timeout and progress tracking
  Timer? _timeoutTimer;
  Timer? _progressTimer;
  static const Duration _defaultTimeout = Duration(minutes: 2);
  static const Duration _longOperationTimeout = Duration(minutes: 5);

  WeeklyReportNotifier(this._service, this._achievementService, this._ref) : super(const WeeklyReportState()) {
    _initializeRealtimeUpdates();
    _initializeOfflineManager();
    _initializeData();
  }

  /// Initialize real-time updates for new report notifications
  void _initializeRealtimeUpdates() {
    // Listen to auth state changes and reload data when user logs in
    _ref.listen(authStateChangesProvider, (previous, next) {
      final previousUser = previous?.value;
      final currentUser = next.value;

      // User just logged in
      if (previousUser == null && currentUser != null) {
        log('[WeeklyReportNotifier] User logged in, loading data');
        Future.microtask(() async {
          try {
            await Future.wait([fetchCurrentReport(), fetchHistoricalReports(refresh: true)]);
          } catch (e) {
            log('[WeeklyReportNotifier] Error loading data after login: $e');
          }
        });
      }
      // User logged out
      else if (previousUser != null && currentUser == null) {
        log('[WeeklyReportNotifier] User logged out, clearing data');
        state = const WeeklyReportState();
      }
    });

    final currentUser = _ref.read(authStateChangesProvider).value;
    if (currentUser == null) return;

    // Listen for new reports in real-time using service
    _service
        .getNewReportNotificationStream(currentUser.uid)
        .listen(
          (hasNewReport) {
            if (hasNewReport && mounted) {
              // Check if this is actually a new report by comparing with current state
              final shouldNotify = state.reports.isEmpty || !state.hasNewReport;
              if (shouldNotify) {
                state = state.copyWith(hasNewReport: true);
                log('[WeeklyReportNotifier] New report notification received');
              }
            }
          },
          onError: (error) {
            log('[WeeklyReportNotifier] Real-time update error: $error');
            final handledException = ErrorHandler.handleError(
              error,
              context: {'action': 'real_time_updates'},
              userAction: 'Listening to real-time updates',
            );
            state = state.copyWith(lastException: handledException);
          },
        );
  }

  /// Initialize data loading on provider creation
  void _initializeData() {
    // Check if user is authenticated before loading data
    final currentUser = _ref.read(authStateChangesProvider).value;
    if (currentUser != null) {
      log('[WeeklyReportNotifier] User authenticated, loading initial data');
      // Load data asynchronously without blocking the constructor
      Future.microtask(() async {
        try {
          await Future.wait([fetchCurrentReport(), fetchHistoricalReports(refresh: true)]);
        } catch (e) {
          log('[WeeklyReportNotifier] Error during initial data load: $e');
        }
      });
    } else {
      log('[WeeklyReportNotifier] User not authenticated, skipping initial data load');
    }
  }

  /// Initialize offline manager and connectivity monitoring
  void _initializeOfflineManager() {
    // Initialize offline manager
    OfflineManager.instance.initialize().catchError((error) {
      log('[WeeklyReportNotifier] Failed to initialize offline manager: $error');
    });

    // Listen to connectivity changes
    OfflineManager.instance.connectivityStream.listen(
      (isOnline) {
        if (mounted) {
          state = state.copyWith(isOffline: !isOnline);

          if (isOnline && state.isOffline) {
            // Just came back online, refresh data
            log('[WeeklyReportNotifier] Device came back online, refreshing data');
            refresh();
          }
        }
      },
      onError: (error) {
        log('[WeeklyReportNotifier] Connectivity stream error: $error');
      },
    );

    // Listen to sync status changes
    OfflineManager.instance.syncStatusStream.listen(
      (syncStatus) {
        if (mounted) {
          state = state.copyWith(syncStatus: syncStatus);
        }
      },
      onError: (error) {
        log('[WeeklyReportNotifier] Sync status stream error: $error');
      },
    );
  }

  /// Simulate report generation for testing loading states
  Future<void> simulateReportGenerationForTesting() async {
    await simulateReportGeneration();
  }

  /// Fetch the current week's report
  Future<void> fetchCurrentReport() async {
    final currentUser = _ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      final authError = AuthException(
        AppStrings.loginRequired,
        code: 'user_not_authenticated',
        context: {'action': 'fetch_current_report'},
      );
      state = state.copyWith(error: ErrorHandler.getUserFriendlyMessage(authError), lastException: authError);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearLastException: true,
      isOffline: OfflineManager.instance.isOffline,
    );

    try {
      log('[WeeklyReportNotifier] Fetching current report');

      final currentReport = await _service.fetchCurrentWeekReport(currentUser.uid);

      state = state.copyWith(
        currentReport: currentReport,
        isLoading: false,
        hasNewReport: false,
        clearSyncStatus: true,
      );

      if (currentReport != null) {
        log('[WeeklyReportNotifier] Current report found: ${currentReport.id}');

        // Detect achievements for the current report
        await _detectAchievements(currentReport);
      } else {
        log('[WeeklyReportNotifier] No current report found');
      }
    } catch (e) {
      log('[WeeklyReportNotifier] Error fetching current report: $e');

      final handledException = ErrorHandler.handleError(
        e,
        context: {'userUuid': currentUser.uid, 'action': 'fetch_current_report'},
        userAction: 'Fetching current week report',
      );

      state = state.copyWith(
        error: handledException.message,
        isLoading: false,
        lastException: handledException,
        isOffline: OfflineManager.instance.isOffline,
      );

      // If it's a retryable error, suggest retry
      if (ErrorHandler.isRetryableError(e)) {
        log('[WeeklyReportNotifier] Error is retryable, user can retry');
      }
    }
  }

  /// Fetch historical reports with pagination and enhanced loading states
  Future<void> fetchHistoricalReports({bool refresh = false}) async {
    final currentUser = _ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      final authError = AuthException(
        AppStrings.loginRequired,
        code: 'user_not_authenticated',
        context: {'action': 'fetch_historical_reports'},
      );
      state = state.copyWith(error: ErrorHandler.getUserFriendlyMessage(authError), lastException: authError);
      return;
    }

    // Reset pagination if refreshing
    if (refresh) {
      _lastDocument = null;
      _hasMoreData = true;
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearLastException: true,
        isOffline: OfflineManager.instance.isOffline,
      );
    } else if (!_hasMoreData) {
      return; // No more data to load
    } else {
      state = state.copyWith(
        isLoadingMore: true,
        clearError: true,
        clearLastException: true,
        isOffline: OfflineManager.instance.isOffline,
      );
    }

    try {
      log('[WeeklyReportNotifier] Fetching historical reports for user: ${currentUser.uid}');

      // Add artificial delay for smooth loading animation
      if (refresh) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final newReports = await _service.fetchUserReports(
        userUuid: currentUser.uid,
        limit: _pageSize,
        startAfter: refresh ? null : _lastDocument,
      );

      log('[WeeklyReportNotifier] Fetched ${newReports.length} historical reports');

      // Update pagination state
      _hasMoreData = newReports.length == _pageSize;
      if (newReports.isNotEmpty) {
        // We need to get the last document for pagination, but service doesn't return it
        // For now, we'll use a simpler approach without cursor-based pagination
        _hasMoreData = newReports.length == _pageSize;
      }

      // Update state
      final updatedReports = refresh ? newReports : [...state.reports, ...newReports];

      // Remove duplicates based on ID
      final uniqueReports = <String, WeeklyReport>{};
      for (final report in updatedReports) {
        uniqueReports[report.id] = report;
      }

      // Add smooth transition delay
      await Future.delayed(const Duration(milliseconds: 100));

      state = state.copyWith(
        reports: uniqueReports.values.toList()..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate)),
        isLoading: false,
        isLoadingMore: false,
        hasNewReport: false,
        clearSyncStatus: true,
      );
    } catch (e) {
      log('[WeeklyReportNotifier] Error fetching historical reports: $e');

      final handledException = ErrorHandler.handleError(
        e,
        context: {'userUuid': currentUser.uid, 'refresh': refresh, 'action': 'fetch_historical_reports'},
        userAction: 'Fetching historical reports',
      );

      state = state.copyWith(
        error: handledException.message,
        isLoading: false,
        isLoadingMore: false,
        lastException: handledException,
        isOffline: OfflineManager.instance.isOffline,
      );

      // If it's a network error and we're offline, show appropriate message
      if (ErrorHandler.isNetworkError(e) && OfflineManager.instance.isOffline) {
        state = state.copyWith(error: AppStrings.offlineModeDescription, syncStatus: AppStrings.offlineMode);
      }
    }
  }

  /// Fetch a specific report by week start date with smooth loading
  Future<WeeklyReport?> fetchReportByWeek(DateTime weekStart) async {
    final currentUser = _ref.read(authStateChangesProvider).value;
    if (currentUser == null) {
      final authError = AuthException(
        AppStrings.loginRequired,
        code: 'user_not_authenticated',
        context: {'action': 'fetch_report_by_week', 'weekStart': weekStart.toIso8601String()},
      );
      state = state.copyWith(error: ErrorHandler.getUserFriendlyMessage(authError), lastException: authError);
      throw authError;
    }

    try {
      log('[WeeklyReportNotifier] Fetching report for week: $weekStart');

      // Update offline status
      state = state.copyWith(isOffline: OfflineManager.instance.isOffline);

      // Add loading delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 500));

      final report = await _service.fetchReportByWeek(userUuid: currentUser.uid, weekStart: weekStart);

      if (report != null) {
        log('[WeeklyReportNotifier] Report found for week: ${report.id}');

        // Update the reports list if this report isn't already included
        final existingReports = state.reports;
        final reportExists = existingReports.any((r) => r.id == report.id);

        if (!reportExists) {
          final updatedReports = [...existingReports, report]
            ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

          state = state.copyWith(reports: updatedReports, clearError: true, clearLastException: true);
        }
      } else {
        log('[WeeklyReportNotifier] No report found for week: $weekStart');
      }

      return report;
    } catch (e) {
      log('[WeeklyReportNotifier] Error fetching report by week: $e');

      final handledException = ErrorHandler.handleError(
        e,
        context: {
          'userUuid': currentUser.uid,
          'weekStart': weekStart.toIso8601String(),
          'action': 'fetch_report_by_week',
        },
        userAction: 'Fetching report by week',
      );

      state = state.copyWith(
        error: handledException.message,
        lastException: handledException,
        isOffline: OfflineManager.instance.isOffline,
      );

      throw handledException;
    }
  }

  /// Mark new report notification as read
  void markNewReportAsRead() {
    if (state.hasNewReport) {
      state = state.copyWith(hasNewReport: false);
      log('[WeeklyReportNotifier] New report notification marked as read');

      // Also update the FCM provider to mark the notification as read
      // _ref.read(newReportNotificationProvider.notifier).markAsRead();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    log('[WeeklyReportNotifier] Refreshing all data');
    await Future.wait([fetchCurrentReport(), fetchHistoricalReports(refresh: true)]);
  }

  /// Load more historical reports (pagination)
  Future<void> loadMoreReports() async {
    if (!state.isLoadingMore && _hasMoreData) {
      await fetchHistoricalReports(refresh: false);
    }
  }

  /// Check if there are more reports to load
  bool get hasMoreReports => _hasMoreData;

  /// Clear cache for better memory management
  void clearCache() {
    _service.clearCache();
    OfflineManager.instance.clearAllCache();
    log('[WeeklyReportNotifier] Cache cleared');
  }

  /// Retry last failed operation
  Future<void> retryLastOperation() async {
    if (state.lastException == null) return;

    final context = state.lastException!.context;
    if (context == null) return;

    final action = context['action'] as String?;
    if (action == null) return;

    log('[WeeklyReportNotifier] Retrying last operation: $action');

    try {
      switch (action) {
        case 'fetch_current_report':
          await fetchCurrentReport();
          break;
        case 'fetch_historical_reports':
          final refresh = context['refresh'] as bool? ?? false;
          await fetchHistoricalReports(refresh: refresh);
          break;
        case 'fetch_report_by_week':
          final weekStartStr = context['weekStart'] as String?;
          if (weekStartStr != null) {
            final weekStart = DateTime.parse(weekStartStr);
            await fetchReportByWeek(weekStart);
          }
          break;
        default:
          log('[WeeklyReportNotifier] Unknown action for retry: $action');
      }
    } catch (e) {
      log('[WeeklyReportNotifier] Retry failed: $e');
      // Error is already handled in the individual methods
    }
  }

  /// Check if current error is retryable
  bool get canRetry {
    return state.lastException != null && ErrorHandler.isRetryableError(state.lastException!.originalError);
  }

  /// Get user-friendly error message with retry suggestion
  String get errorMessageWithRetry {
    if (state.error == null) return '';

    if (canRetry) {
      return '${state.error}\n\n${AppStrings.tryAgainLater}';
    }

    return state.error!;
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true, clearLastException: true, clearSyncStatus: true);
  }

  /// Report error to support (placeholder for error reporting)
  Future<void> reportError() async {
    if (state.lastException == null) return;

    try {
      final errorReport = ErrorHandler.createErrorReport(state.lastException!);

      // TODO: Implement actual error reporting to backend or crash reporting service
      log('[WeeklyReportNotifier] Error report created: $errorReport');

      // For now, just log the report
      // In production, you would send this to your error reporting service

      // Show success message to user
      state = state.copyWith(syncStatus: AppStrings.errorReported);

      // Clear the status after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(clearSyncStatus: true);
        }
      });
    } catch (e) {
      log('[WeeklyReportNotifier] Failed to report error: $e');
      state = state.copyWith(syncStatus: AppStrings.errorReportFailed);
    }
  }

  /// Force sync with server (when coming back online)
  Future<void> forceSync() async {
    if (OfflineManager.instance.isOffline) {
      state = state.copyWith(error: AppStrings.connectionError, syncStatus: AppStrings.offlineMode);
      return;
    }

    state = state.copyWith(syncStatus: AppStrings.syncingData, isRefreshing: true);

    try {
      // Force refresh all data
      await refresh();
      state = state.copyWith(
        syncStatus: AppStrings.syncCompleted,
        isRefreshing: false,
        clearError: true,
        clearLastException: true,
      );

      // Clear sync status after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(clearSyncStatus: true);
        }
      });
    } catch (e) {
      log('[WeeklyReportNotifier] Force sync failed: $e');
      state = state.copyWith(syncStatus: AppStrings.syncFailed, isRefreshing: false);
    }
  }

  /// Start timeout timer for operations
  void _startTimeoutTimer({Duration? timeout, VoidCallback? onTimeout}) {
    _cancelTimeoutTimer();

    final timeoutDuration = timeout ?? _defaultTimeout;
    _timeoutTimer = Timer(timeoutDuration, () {
      if (mounted) {
        log('[WeeklyReportNotifier] Operation timed out after ${timeoutDuration.inSeconds} seconds');
        state = state.copyWith(
          hasTimedOut: true,
          isLoading: false,
          isGenerating: false,
          isProcessing: false,
          clearProgress: true,
          clearProgressSteps: true,
        );
        onTimeout?.call();
      }
    });
  }

  /// Cancel timeout timer
  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Start progress simulation for long-running operations
  void _startProgressSimulation({List<String>? steps}) {
    _cancelProgressTimer();

    if (steps != null) {
      state = state.copyWith(progressSteps: steps, currentStep: 0);

      _progressTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final currentStep = state.currentStep;
        if (currentStep < steps.length - 1) {
          state = state.copyWith(currentStep: currentStep + 1);
        } else {
          timer.cancel();
        }
      });
    } else {
      // Continuous progress simulation
      state = state.copyWith(progress: 0.0);

      _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final currentProgress = state.progress ?? 0.0;
        if (currentProgress < 0.9) {
          state = state.copyWith(progress: currentProgress + 0.05);
        } else {
          timer.cancel();
        }
      });
    }
  }

  /// Cancel progress timer
  void _cancelProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// Handle timeout for current operation
  void handleTimeout() {
    log('[WeeklyReportNotifier] Handling timeout');
    _cancelTimeoutTimer();
    _cancelProgressTimer();

    state = state.copyWith(
      hasTimedOut: true,
      isLoading: false,
      isGenerating: false,
      isProcessing: false,
      isRefreshing: false,
      clearProgress: true,
      clearProgressSteps: true,
      error: AppStrings.timeoutError,
    );
  }

  /// Reset timeout state and retry operation
  void resetTimeoutAndRetry() {
    log('[WeeklyReportNotifier] Resetting timeout and retrying');
    state = state.copyWith(
      hasTimedOut: false,
      clearError: true,
      clearLastException: true,
      clearProgress: true,
      clearProgressSteps: true,
    );
  }

  /// Simulate report generation with progress updates
  Future<void> simulateReportGeneration() async {
    if (state.isGenerating) return;

    log('[WeeklyReportNotifier] Starting report generation simulation');

    final steps = ['사용자 데이터 수집 중...', 'AI 분석 진행 중...', '리포트 생성 중...', '최종 검토 중...'];

    state = state.copyWith(isGenerating: true, hasTimedOut: false, clearError: true, clearLastException: true);

    _startTimeoutTimer(timeout: _longOperationTimeout, onTimeout: handleTimeout);

    _startProgressSimulation(steps: steps);

    try {
      // Simulate long-running operation
      for (int i = 0; i < steps.length; i++) {
        await Future.delayed(const Duration(seconds: 4));
        if (!mounted || state.hasTimedOut) break;

        state = state.copyWith(currentStep: i);
      }

      if (!state.hasTimedOut && mounted) {
        // Complete the generation
        await Future.delayed(const Duration(seconds: 2));

        _cancelTimeoutTimer();
        _cancelProgressTimer();

        state = state.copyWith(isGenerating: false, clearProgress: true, clearProgressSteps: true);

        // Refresh data to get the new report
        await fetchCurrentReport();
      }
    } catch (e) {
      log('[WeeklyReportNotifier] Report generation simulation failed: $e');

      _cancelTimeoutTimer();
      _cancelProgressTimer();

      final handledException = ErrorHandler.handleError(
        e,
        context: {'action': 'simulate_report_generation'},
        userAction: 'Simulating report generation',
      );

      state = state.copyWith(
        isGenerating: false,
        error: handledException.message,
        lastException: handledException,
        clearProgress: true,
        clearProgressSteps: true,
      );
    }
  }

  /// Cancel any ongoing operations
  void cancelOperations() {
    log('[WeeklyReportNotifier] Cancelling all operations');

    _cancelTimeoutTimer();
    _cancelProgressTimer();

    state = state.copyWith(
      isLoading: false,
      isGenerating: false,
      isProcessing: false,
      isRefreshing: false,
      isLoadingMore: false,
      hasTimedOut: false,
      clearProgress: true,
      clearProgressSteps: true,
      clearError: true,
      clearLastException: true,
    );
  }

  /// Detect achievements for the current report
  Future<void> _detectAchievements(WeeklyReport currentReport) async {
    try {
      state = state.copyWith(isLoadingAchievements: true);

      log('[WeeklyReportNotifier] Detecting achievements for report: ${currentReport.id}');

      // Get historical reports for comparison
      final historicalReports = state.reports.where((r) => r.id != currentReport.id).toList();

      // Detect achievements
      final achievements = await _achievementService.detectAchievements(currentReport, historicalReports);

      // Get achievement progress
      final progress = await _achievementService.getAchievementProgress(currentReport, historicalReports);

      // Find new achievements (not in current state)
      final existingAchievementIds = state.achievements.map((a) => a.id).toSet();
      final newAchievements = achievements.where((a) => !existingAchievementIds.contains(a.id)).toList();

      state = state.copyWith(
        achievements: achievements,
        achievementProgress: progress,
        newAchievements: newAchievements,
        isLoadingAchievements: false,
      );

      log('[WeeklyReportNotifier] Detected ${achievements.length} achievements, ${newAchievements.length} new');
    } catch (e) {
      log('[WeeklyReportNotifier] Error detecting achievements: $e');
      state = state.copyWith(isLoadingAchievements: false);
    }
  }

  /// Get achievements for the current report
  List<CategoryAchievement> get currentAchievements => state.achievements;

  /// Get achievement progress
  List<AchievementProgress> get currentAchievementProgress => state.achievementProgress;

  /// Get new achievements that haven't been seen yet
  List<CategoryAchievement> get newAchievements => state.newAchievements;

  /// Mark new achievements as seen
  void markNewAchievementsAsSeen() {
    if (state.newAchievements.isNotEmpty) {
      // Mark achievements as not new
      final updatedAchievements =
          state.achievements.map((achievement) {
            if (state.newAchievements.any((newAch) => newAch.id == achievement.id)) {
              return achievement.copyWith(isNew: false);
            }
            return achievement;
          }).toList();

      state = state.copyWith(achievements: updatedAchievements, clearNewAchievements: true);

      log('[WeeklyReportNotifier] Marked ${state.newAchievements.length} achievements as seen');
    }
  }

  /// Refresh achievements for current report
  Future<void> refreshAchievements() async {
    if (state.currentReport != null) {
      await _detectAchievements(state.currentReport!);
    }
  }

  /// Get total achievement points
  int get totalAchievementPoints {
    return state.achievements.fold<int>(0, (total, achievement) => total + achievement.points);
  }

  /// Get achievements by type
  List<CategoryAchievement> getAchievementsByType(AchievementType type) {
    return state.achievements.where((achievement) => achievement.type == type).toList();
  }

  /// Get achievements by rarity
  List<CategoryAchievement> getAchievementsByRarity(AchievementRarity rarity) {
    return state.achievements.where((achievement) => achievement.rarity == rarity).toList();
  }

  /// Check if user has specific achievement
  bool hasAchievement(String achievementId) {
    return state.achievements.any((achievement) => achievement.id == achievementId);
  }

  /// 디버깅 모드에서 가짜 데이터로 현재 주간 리포트 로드
  Future<void> loadDebugCurrentWeekReport() async {
    if (!kDebugMode) {
      log('[WeeklyReportNotifier] Debug data loading is only available in debug mode');
      return;
    }

    log('[WeeklyReportNotifier] Loading debug current week report');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 가짜 현재 주간 리포트 생성
      final fakeReport = DebugDataHelper.generateFakeWeeklyReport();

      // 가짜 성취 데이터를 별도로 생성
      final fakeAchievements = DebugDataHelper.generateFakeAchievements();

      await Future.delayed(const Duration(milliseconds: 500)); // 로딩 시뮬레이션

      state = state.copyWith(
        currentReport: fakeReport,
        achievements: fakeAchievements,
        isLoading: false,
        hasNewReport: true,
      );

      log('[WeeklyReportNotifier] Debug current week report loaded successfully');
    } catch (error) {
      log('[WeeklyReportNotifier] Error loading debug current week report: $error');
      state = state.copyWith(isLoading: false, error: 'Debug 데이터 로딩 중 오류가 발생했습니다: $error');
    }
  }

  /// 디버깅 모드에서 가짜 데이터로 히스토리 리포트들 로드
  Future<void> loadDebugReports() async {
    if (!kDebugMode) {
      log('[WeeklyReportNotifier] Debug data loading is only available in debug mode');
      return;
    }

    log('[WeeklyReportNotifier] Loading debug reports');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 가짜 히스토리 리포트들 생성 (현재 주 포함 5주)
      final fakeReports = DebugDataHelper.generateFakeWeeklyReports(count: 5);

      // 가짜 성취 데이터를 별도로 생성
      final fakeAchievements = DebugDataHelper.generateFakeAchievements();

      await Future.delayed(const Duration(milliseconds: 800)); // 로딩 시뮬레이션

      state = state.copyWith(
        reports: fakeReports,
        currentReport: fakeReports.first, // 가장 최근 리포트를 현재 리포트로
        achievements: fakeAchievements,
        isLoading: false,
        hasNewReport: true,
      );

      log('[WeeklyReportNotifier] Debug reports loaded successfully: ${fakeReports.length} reports');
    } catch (error) {
      log('[WeeklyReportNotifier] Error loading debug reports: $error');
      state = state.copyWith(isLoading: false, error: 'Debug 리포트 로딩 중 오류가 발생했습니다: $error');
    }
  }

  /// 디버깅 모드에서 가짜 리포트 생성 시뮬레이션
  Future<void> generateDebugReport() async {
    if (!kDebugMode) {
      log('[WeeklyReportNotifier] Debug report generation is only available in debug mode');
      return;
    }

    log('[WeeklyReportNotifier] Generating debug report');
    state = state.copyWith(
      isGenerating: true,
      isProcessing: true,
      progress: 0.0,
      currentStep: 0,
      progressSteps: ['인증 데이터 수집 중...', '카테고리 분석 중...', '패턴 인식 중...', '인사이트 생성 중...', '추천사항 작성 중...', '리포트 완성 중...'],
      clearError: true,
    );

    try {
      // 단계별 진행 시뮬레이션
      for (int step = 0; step < 6; step++) {
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        state = state.copyWith(progress: (step + 1) / 6, currentStep: step);
      }

      // 가짜 리포트 생성
      final fakeReport = DebugDataHelper.generateFakeWeeklyReport();
      final fakeAchievements = DebugDataHelper.generateFakeAchievements();

      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        currentReport: fakeReport,
        achievements: fakeAchievements,
        reports: [fakeReport, ...state.reports],
        isGenerating: false,
        isProcessing: false,
        hasNewReport: true,
        clearProgress: true,
        clearProgressSteps: true,
      );

      log('[WeeklyReportNotifier] Debug report generated successfully');
    } catch (error) {
      log('[WeeklyReportNotifier] Error generating debug report: $error');
      state = state.copyWith(
        isGenerating: false,
        isProcessing: false,
        error: 'Debug 리포트 생성 중 오류가 발생했습니다: $error',
        clearProgress: true,
        clearProgressSteps: true,
      );
    }
  }

  /// 디버깅 모드 상태 확인
  bool get isDebugMode => kDebugMode;

  @override
  void dispose() {
    _cancelTimeoutTimer();
    _cancelProgressTimer();
    super.dispose();
  }
}

/// Provider for weekly report service
final weeklyReportServiceProvider = Provider<WeeklyReportService>((ref) {
  return WeeklyReportService(FirebaseFirestore.instance);
});

/// Provider for visualization data service
final visualizationDataServiceProvider = Provider<VisualizationDataService>((ref) {
  return VisualizationDataService();
});

/// Provider for category achievement service
final categoryAchievementServiceProvider = Provider<CategoryAchievementService>((ref) {
  return CategoryAchievementService();
});

/// Provider for weekly report state management
final weeklyReportProvider = StateNotifierProvider<WeeklyReportNotifier, WeeklyReportState>((ref) {
  final service = ref.read(weeklyReportServiceProvider);
  final achievementService = ref.read(categoryAchievementServiceProvider);
  return WeeklyReportNotifier(service, achievementService, ref);
});

/// Stream provider for real-time current week report updates
final currentWeekReportStreamProvider = StreamProvider<WeeklyReport?>((ref) {
  final currentUser = ref.watch(authStateChangesProvider).value;
  if (currentUser == null) {
    return Stream.value(null);
  }

  final service = ref.read(weeklyReportServiceProvider);
  return service.getCurrentWeekReportStream(currentUser.uid);
});

/// Stream provider for real-time report updates by user UUID
final weeklyReportStreamProvider = StreamProvider.family<WeeklyReport?, String>((ref, userUuid) {
  final service = ref.read(weeklyReportServiceProvider);
  return service.getCurrentWeekReportStream(userUuid);
});

/// Provider for checking if user has any weekly reports
final hasWeeklyReportsProvider = StreamProvider<bool>((ref) {
  final currentUser = ref.watch(authStateChangesProvider).value;
  if (currentUser == null) {
    return Stream.value(false);
  }

  return FirebaseFirestore.instance
      .collection('weeklyReports')
      .where('userUuid', isEqualTo: currentUser.uid)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty);
});

/// Provider for auth state changes (imported from feed_provider)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
