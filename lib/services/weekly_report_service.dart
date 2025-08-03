import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/core/error_handler.dart';
import 'package:seol_haru_check/core/offline_manager.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';

/// Service class for weekly report Firestore operations
class WeeklyReportService {
  final FirebaseFirestore _firestore;

  // Cache for improved performance
  final Map<String, WeeklyReport> _reportCache = {};
  static const int _cacheExpirationMinutes = 5;
  final Map<String, DateTime> _cacheTimestamps = {};

  WeeklyReportService(this._firestore);

  /// Fetch user reports with pagination support
  Future<List<WeeklyReport>> fetchUserReports({
    required String userUuid,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      log('[WeeklyReportService] Fetching reports for user: $userUuid, limit: $limit');

      // Check if offline and return cached data
      if (OfflineManager.instance.isOffline) {
        log('[WeeklyReportService] Device is offline, returning cached data');
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        if (cachedReports != null) {
          return cachedReports.take(limit).toList();
        }
        throw NetworkException(
          AppStrings.connectionError,
          code: 'offline_no_cache',
          context: {'userUuid': userUuid, 'action': 'fetch_user_reports'},
        );
      }

      Query query = _firestore
          .collection('weeklyReports')
          .where('userUuid', isEqualTo: userUuid)
          .orderBy('weekStartDate', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final reports = querySnapshot.docs.map((doc) => WeeklyReport.fromFirestore(doc)).toList();

      // Update cache
      for (final report in reports) {
        _updateCache(report);
      }

      // Cache all reports for offline access
      if (reports.isNotEmpty) {
        await OfflineManager.instance.cacheWeeklyReports(userUuid, reports);
      }

      log('[WeeklyReportService] Fetched ${reports.length} reports');
      return reports;
    } catch (e) {
      log('[WeeklyReportService] Error fetching user reports: $e');

      // If network error and we have cached data, return it
      if (ErrorHandler.isNetworkError(e)) {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        if (cachedReports != null) {
          log('[WeeklyReportService] Returning cached data due to network error');
          return cachedReports.take(limit).toList();
        }
      }

      throw ErrorHandler.handleError(
        e,
        context: {'userUuid': userUuid, 'limit': limit, 'action': 'fetch_user_reports'},
        userAction: 'Fetching weekly reports',
      );
    }
  }

  /// Fetch current week report for user
  Future<WeeklyReport?> fetchCurrentWeekReport(String userUuid) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekEnd = _getWeekEnd(weekStart);

      // Check cache first
      final cacheKey = '${userUuid}_${weekStart.millisecondsSinceEpoch}';
      if (_isValidCache(cacheKey)) {
        log('[WeeklyReportService] Returning cached current week report');
        return _reportCache[cacheKey];
      }

      // Check offline cache
      if (OfflineManager.instance.isOffline) {
        log('[WeeklyReportService] Device is offline, checking offline cache');
        final cachedReport = await OfflineManager.instance.getCachedCurrentWeekReport(userUuid);
        if (cachedReport != null) {
          _updateCache(cachedReport, cacheKey);
          return cachedReport;
        }
        throw NetworkException(
          AppStrings.connectionError,
          code: 'offline_no_cache',
          context: {'userUuid': userUuid, 'action': 'fetch_current_week_report'},
        );
      }

      log('[WeeklyReportService] Fetching current week report for user: $userUuid');

      final query =
          await _firestore
              .collection('weeklyReports')
              .where('userUuid', isEqualTo: userUuid)
              .where('weekStartDate', isEqualTo: Timestamp.fromDate(weekStart))
              .where('weekEndDate', isEqualTo: Timestamp.fromDate(weekEnd))
              .limit(1)
              .get();

      WeeklyReport? report;
      if (query.docs.isNotEmpty) {
        report = WeeklyReport.fromFirestore(query.docs.first);
        _updateCache(report, cacheKey);
        log('[WeeklyReportService] Current week report found: ${report.id}');
      } else {
        log('[WeeklyReportService] No current week report found');
      }

      // Cache the result (even if null) for offline access
      await OfflineManager.instance.cacheCurrentWeekReport(userUuid, report);

      return report;
    } catch (e) {
      log('[WeeklyReportService] Error fetching current week report: $e');

      // If network error and we have cached data, return it
      if (ErrorHandler.isNetworkError(e)) {
        final cachedReport = await OfflineManager.instance.getCachedCurrentWeekReport(userUuid);
        if (cachedReport != null) {
          log('[WeeklyReportService] Returning cached current week report due to network error');
          final cacheKey = '${userUuid}_${_getWeekStart(DateTime.now()).millisecondsSinceEpoch}';
          _updateCache(cachedReport, cacheKey);
          return cachedReport;
        }
      }

      throw ErrorHandler.handleError(
        e,
        context: {'userUuid': userUuid, 'action': 'fetch_current_week_report'},
        userAction: 'Fetching current week report',
      );
    }
  }

  /// Fetch report by specific week start date
  Future<WeeklyReport?> fetchReportByWeek({required String userUuid, required DateTime weekStart}) async {
    try {
      final weekEnd = _getWeekEnd(weekStart);

      // Check cache first
      final cacheKey = '${userUuid}_${weekStart.millisecondsSinceEpoch}';
      if (_isValidCache(cacheKey)) {
        log('[WeeklyReportService] Returning cached report for week');
        return _reportCache[cacheKey];
      }

      // Check offline cache
      if (OfflineManager.instance.isOffline) {
        log('[WeeklyReportService] Device is offline, checking cached reports');
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        if (cachedReports != null) {
          final report = cachedReports.firstWhere(
            (r) => r.weekStartDate.isAtSameMomentAs(weekStart),
            orElse: () => throw StateError('Report not found in cache'),
          );
          _updateCache(report, cacheKey);
          return report;
        }
        throw NetworkException(
          AppStrings.connectionError,
          code: 'offline_no_cache',
          context: {'userUuid': userUuid, 'weekStart': weekStart.toIso8601String(), 'action': 'fetch_report_by_week'},
        );
      }

      log('[WeeklyReportService] Fetching report for week: $weekStart to $weekEnd');

      final query =
          await _firestore
              .collection('weeklyReports')
              .where('userUuid', isEqualTo: userUuid)
              .where('weekStartDate', isEqualTo: Timestamp.fromDate(weekStart))
              .where('weekEndDate', isEqualTo: Timestamp.fromDate(weekEnd))
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final report = WeeklyReport.fromFirestore(query.docs.first);
        _updateCache(report, cacheKey);
        log('[WeeklyReportService] Report found for week: ${report.id}');
        return report;
      }

      log('[WeeklyReportService] No report found for week: $weekStart');
      return null;
    } catch (e) {
      log('[WeeklyReportService] Error fetching report by week: $e');

      // If network error and we have cached data, try to find it
      if (ErrorHandler.isNetworkError(e)) {
        try {
          final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
          if (cachedReports != null) {
            final report = cachedReports.firstWhere(
              (r) => r.weekStartDate.isAtSameMomentAs(weekStart),
              orElse: () => throw StateError('Report not found in cache'),
            );
            log('[WeeklyReportService] Returning cached report for week due to network error');
            final cacheKey = '${userUuid}_${weekStart.millisecondsSinceEpoch}';
            _updateCache(report, cacheKey);
            return report;
          }
        } catch (cacheError) {
          log('[WeeklyReportService] No cached report found for week: $cacheError');
        }
      }

      throw ErrorHandler.handleError(
        e,
        context: {'userUuid': userUuid, 'weekStart': weekStart.toIso8601String(), 'action': 'fetch_report_by_week'},
        userAction: 'Fetching report by week',
      );
    }
  }

  /// Get real-time stream for current week report
  Stream<WeeklyReport?> getCurrentWeekReportStream(String userUuid) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = _getWeekEnd(weekStart);

    log('[WeeklyReportService] Creating stream for current week report');

    return _firestore
        .collection('weeklyReports')
        .where('userUuid', isEqualTo: userUuid)
        .where('weekStartDate', isEqualTo: Timestamp.fromDate(weekStart))
        .where('weekEndDate', isEqualTo: Timestamp.fromDate(weekEnd))
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final report = WeeklyReport.fromFirestore(snapshot.docs.first);
            _updateCache(report);
            // Cache for offline access
            OfflineManager.instance.cacheCurrentWeekReport(userUuid, report);
            return report;
          }
          return null;
        })
        .handleError((error) {
          log('[WeeklyReportService] Stream error: $error');

          // If it's a network error, try to return cached data
          if (ErrorHandler.isNetworkError(error)) {
            return OfflineManager.instance.getCachedCurrentWeekReport(userUuid);
          }

          throw ErrorHandler.handleError(
            error,
            context: {
              'userUuid': userUuid,
              'weekStart': weekStart.toIso8601String(),
              'action': 'get_current_week_report_stream',
            },
            userAction: 'Listening to current week report updates',
          );
        });
  }

  /// Get stream for new report notifications
  Stream<bool> getNewReportNotificationStream(String userUuid) {
    log('[WeeklyReportService] Creating new report notification stream');

    return _firestore
        .collection('weeklyReports')
        .where('userUuid', isEqualTo: userUuid)
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty)
        .handleError((error) {
          log('[WeeklyReportService] Notification stream error: $error');
          return false;
        });
  }

  /// Check if user has any weekly reports
  Future<bool> hasAnyReports(String userUuid) async {
    try {
      log('[WeeklyReportService] Checking if user has any reports: $userUuid');

      // If offline, check cached data
      if (OfflineManager.instance.isOffline) {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        return cachedReports != null && cachedReports.isNotEmpty;
      }

      final query = await _firestore.collection('weeklyReports').where('userUuid', isEqualTo: userUuid).limit(1).get();

      final hasReports = query.docs.isNotEmpty;
      log('[WeeklyReportService] User has reports: $hasReports');
      return hasReports;
    } catch (e) {
      log('[WeeklyReportService] Error checking for reports: $e');

      // Try cached data on error
      try {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        return cachedReports != null && cachedReports.isNotEmpty;
      } catch (cacheError) {
        log('[WeeklyReportService] Cache check also failed: $cacheError');
      }

      // Don't throw error for this method, just return false
      return false;
    }
  }

  /// Get reports count for user
  Future<int> getReportsCount(String userUuid) async {
    try {
      log('[WeeklyReportService] Getting reports count for user: $userUuid');

      // If offline, check cached data
      if (OfflineManager.instance.isOffline) {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        return cachedReports?.length ?? 0;
      }

      final query = await _firestore.collection('weeklyReports').where('userUuid', isEqualTo: userUuid).get();

      final count = query.docs.length;
      log('[WeeklyReportService] Reports count: $count');
      return count;
    } catch (e) {
      log('[WeeklyReportService] Error getting reports count: $e');

      // Try cached data on error
      try {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        return cachedReports?.length ?? 0;
      } catch (cacheError) {
        log('[WeeklyReportService] Cache count check also failed: $cacheError');
      }

      // Don't throw error for this method, just return 0
      return 0;
    }
  }

  /// Get available weeks that have reports for user
  Future<List<DateTime>> getAvailableWeeks(String userUuid) async {
    try {
      log('[WeeklyReportService] Getting available weeks for user: $userUuid');

      // If offline, check cached data
      if (OfflineManager.instance.isOffline) {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        if (cachedReports != null) {
          return cachedReports.map((report) => report.weekStartDate).toList()..sort((a, b) => b.compareTo(a));
        }
        throw NetworkException(
          AppStrings.connectionError,
          code: 'offline_no_cache',
          context: {'userUuid': userUuid, 'action': 'get_available_weeks'},
        );
      }

      final query =
          await _firestore
              .collection('weeklyReports')
              .where('userUuid', isEqualTo: userUuid)
              .orderBy('weekStartDate', descending: true)
              .get();

      final weeks = query.docs.map((doc) => (doc.data()['weekStartDate'] as Timestamp).toDate()).toList();

      log('[WeeklyReportService] Found ${weeks.length} available weeks');
      return weeks;
    } catch (e) {
      log('[WeeklyReportService] Error getting available weeks: $e');

      // Try cached data on error
      if (ErrorHandler.isNetworkError(e)) {
        try {
          final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
          if (cachedReports != null) {
            log('[WeeklyReportService] Returning cached available weeks due to network error');
            return cachedReports.map((report) => report.weekStartDate).toList()..sort((a, b) => b.compareTo(a));
          }
        } catch (cacheError) {
          log('[WeeklyReportService] Cache check for available weeks failed: $cacheError');
        }
      }

      // Don't throw error for this method, just return empty list
      return [];
    }
  }

  /// Get earliest report date for user
  Future<DateTime?> getEarliestReportDate(String userUuid) async {
    try {
      log('[WeeklyReportService] Getting earliest report date for user: $userUuid');

      // If offline, check cached data
      if (OfflineManager.instance.isOffline) {
        final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
        if (cachedReports != null && cachedReports.isNotEmpty) {
          final sortedReports = cachedReports.toList()..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));
          return sortedReports.first.weekStartDate;
        }
        return null;
      }

      final query =
          await _firestore
              .collection('weeklyReports')
              .where('userUuid', isEqualTo: userUuid)
              .orderBy('weekStartDate', descending: false)
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final earliestDate = (query.docs.first.data()['weekStartDate'] as Timestamp).toDate();
        log('[WeeklyReportService] Earliest report date: $earliestDate');
        return earliestDate;
      }

      log('[WeeklyReportService] No reports found for user');
      return null;
    } catch (e) {
      log('[WeeklyReportService] Error getting earliest report date: $e');

      // Try cached data on error
      if (ErrorHandler.isNetworkError(e)) {
        try {
          final cachedReports = await OfflineManager.instance.getCachedWeeklyReports(userUuid);
          if (cachedReports != null && cachedReports.isNotEmpty) {
            log('[WeeklyReportService] Returning cached earliest date due to network error');
            final sortedReports = cachedReports.toList()..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));
            return sortedReports.first.weekStartDate;
          }
        } catch (cacheError) {
          log('[WeeklyReportService] Cache check for earliest date failed: $cacheError');
        }
      }

      // Don't throw error for this method, just return null
      return null;
    }
  }

  /// Clear cache for better memory management
  void clearCache() {
    _reportCache.clear();
    _cacheTimestamps.clear();
    log('[WeeklyReportService] Cache cleared');
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value).inMinutes > _cacheExpirationMinutes) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _reportCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      log('[WeeklyReportService] Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Update cache with report data
  void _updateCache(WeeklyReport report, [String? customKey]) {
    final key = customKey ?? '${report.userUuid}_${report.weekStartDate.millisecondsSinceEpoch}';
    _reportCache[key] = report;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Check if cache entry is valid
  bool _isValidCache(String key) {
    if (!_reportCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[key]!;
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < _cacheExpirationMinutes;
  }

  /// Get the start of the week (Sunday) for a given date
  DateTime _getWeekStart(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  /// Get the end of the week (Saturday) for a given week start
  DateTime _getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }
}
