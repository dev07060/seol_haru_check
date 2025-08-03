import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/core/error_handler.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline state manager for handling data caching and offline functionality
class OfflineManager {
  static const String _logTag = 'OfflineManager';
  static const String _cachePrefix = 'offline_cache_';
  static const String _lastSyncPrefix = 'last_sync_';
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const Duration _syncCheckInterval = Duration(minutes: 5);

  static OfflineManager? _instance;
  static OfflineManager get instance => _instance ??= OfflineManager._();

  OfflineManager._();

  SharedPreferences? _prefs;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isInitialized = false;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<String> _syncStatusController = StreamController<String>.broadcast();

  /// Initialize the offline manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Check initial connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      _isOnline = !connectivityResults.contains(ConnectivityResult.none);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          log('Connectivity subscription error: $error', name: _logTag);
        },
      );

      _isInitialized = true;

      log('OfflineManager initialized. Online: $_isOnline', name: _logTag);

      // Start periodic sync check
      _startPeriodicSyncCheck();
    } catch (error) {
      log('Failed to initialize OfflineManager: $error', name: _logTag);
      throw ErrorHandler.handleError(error, context: {'action': 'initialize_offline_manager'});
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _syncStatusController.close();
    _isInitialized = false;
  }

  /// Get connectivity stream
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Get sync status stream
  Stream<String> get syncStatusStream => _syncStatusController.stream;

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Check if device is offline
  bool get isOffline => !_isOnline;

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    log('Connectivity changed: $results (Online: $_isOnline)', name: _logTag);

    _connectivityController.add(_isOnline);

    // If we just came back online, trigger sync
    if (!wasOnline && _isOnline) {
      _syncStatusController.add(AppStrings.syncingData);
      _performSync();
    }
  }

  /// Start periodic sync check
  void _startPeriodicSyncCheck() {
    Timer.periodic(_syncCheckInterval, (timer) {
      if (_isOnline) {
        _checkAndSync();
      }
    });
  }

  /// Check if sync is needed and perform it
  Future<void> _checkAndSync() async {
    try {
      final lastSyncTime = await getLastSyncTime('weekly_reports');
      final now = DateTime.now();

      // Sync if last sync was more than 1 hour ago
      if (lastSyncTime == null || now.difference(lastSyncTime).inHours >= 1) {
        await _performSync();
      }
    } catch (error) {
      log('Sync check failed: $error', name: _logTag);
    }
  }

  /// Perform data synchronization
  Future<void> _performSync() async {
    if (!_isOnline) return;

    try {
      _syncStatusController.add(AppStrings.syncingData);

      // TODO: Implement actual sync logic with backend
      // This would typically involve:
      // 1. Uploading any pending local changes
      // 2. Downloading latest data from server
      // 3. Resolving conflicts if any

      await Future.delayed(const Duration(seconds: 2)); // Simulate sync

      await setLastSyncTime('weekly_reports', DateTime.now());
      _syncStatusController.add(AppStrings.syncCompleted);

      log('Sync completed successfully', name: _logTag);
    } catch (error) {
      log('Sync failed: $error', name: _logTag);
      _syncStatusController.add(AppStrings.syncFailed);
    }
  }

  /// Cache weekly reports data
  Future<void> cacheWeeklyReports(String userUuid, List<WeeklyReport> reports) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '${_cachePrefix}weekly_reports_$userUuid';
      final cacheData = {
        'data': reports.map((report) => _reportToMap(report)).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'userUuid': userUuid,
      };

      await _prefs!.setString(cacheKey, jsonEncode(cacheData));

      log('Cached ${reports.length} weekly reports for user $userUuid', name: _logTag);
    } catch (error) {
      log('Failed to cache weekly reports: $error', name: _logTag);
      throw ErrorHandler.handleError(
        error,
        context: {'action': 'cache_weekly_reports', 'userUuid': userUuid, 'reportCount': reports.length},
      );
    }
  }

  /// Get cached weekly reports
  Future<List<WeeklyReport>?> getCachedWeeklyReports(String userUuid) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '${_cachePrefix}weekly_reports_$userUuid';
      final cachedString = _prefs!.getString(cacheKey);

      if (cachedString == null) {
        log('No cached weekly reports found for user $userUuid', name: _logTag);
        return null;
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        log('Cached weekly reports expired for user $userUuid', name: _logTag);
        await clearCache('weekly_reports_$userUuid');
        return null;
      }

      final reportsData = cacheData['data'] as List<dynamic>;
      final reports = reportsData.map((data) => _mapToReport(data as Map<String, dynamic>)).toList();

      log('Retrieved ${reports.length} cached weekly reports for user $userUuid', name: _logTag);
      return reports;
    } catch (error) {
      log('Failed to get cached weekly reports: $error', name: _logTag);
      // Don't throw error for cache retrieval failures
      return null;
    }
  }

  /// Cache current week report
  Future<void> cacheCurrentWeekReport(String userUuid, WeeklyReport? report) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '${_cachePrefix}current_week_$userUuid';

      if (report == null) {
        await _prefs!.remove(cacheKey);
        return;
      }

      final cacheData = {
        'data': _reportToMap(report),
        'timestamp': DateTime.now().toIso8601String(),
        'userUuid': userUuid,
      };

      await _prefs!.setString(cacheKey, jsonEncode(cacheData));

      log('Cached current week report for user $userUuid', name: _logTag);
    } catch (error) {
      log('Failed to cache current week report: $error', name: _logTag);
      throw ErrorHandler.handleError(error, context: {'action': 'cache_current_week_report', 'userUuid': userUuid});
    }
  }

  /// Get cached current week report
  Future<WeeklyReport?> getCachedCurrentWeekReport(String userUuid) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '${_cachePrefix}current_week_$userUuid';
      final cachedString = _prefs!.getString(cacheKey);

      if (cachedString == null) {
        log('No cached current week report found for user $userUuid', name: _logTag);
        return null;
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);

      // Check if cache is expired (shorter expiration for current week)
      if (DateTime.now().difference(timestamp) > const Duration(hours: 6)) {
        log('Cached current week report expired for user $userUuid', name: _logTag);
        await clearCache('current_week_$userUuid');
        return null;
      }

      final reportData = cacheData['data'] as Map<String, dynamic>;
      final report = _mapToReport(reportData);

      log('Retrieved cached current week report for user $userUuid', name: _logTag);
      return report;
    } catch (error) {
      log('Failed to get cached current week report: $error', name: _logTag);
      // Don't throw error for cache retrieval failures
      return null;
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String cacheType) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '$_cachePrefix$cacheType';
      await _prefs!.remove(cacheKey);

      log('Cleared cache: $cacheType', name: _logTag);
    } catch (error) {
      log('Failed to clear cache $cacheType: $error', name: _logTag);
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }

      log('Cleared all cache (${cacheKeys.length} items)', name: _logTag);
    } catch (error) {
      log('Failed to clear all cache: $error', name: _logTag);
      throw ErrorHandler.handleError(error, context: {'action': 'clear_all_cache'});
    }
  }

  /// Get cache size information
  Future<Map<String, dynamic>> getCacheInfo() async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      int totalSize = 0;
      final cacheItems = <String, dynamic>{};

      for (final key in cacheKeys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          final size = value.length;
          totalSize += size;
          cacheItems[key.replaceFirst(_cachePrefix, '')] = {'size': size, 'sizeKB': (size / 1024).toStringAsFixed(2)};
        }
      }

      return {
        'totalItems': cacheKeys.length,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'items': cacheItems,
      };
    } catch (error) {
      log('Failed to get cache info: $error', name: _logTag);
      return {'totalItems': 0, 'totalSize': 0, 'totalSizeKB': '0.00', 'totalSizeMB': '0.00', 'items': {}};
    }
  }

  /// Set last sync time
  Future<void> setLastSyncTime(String syncType, DateTime time) async {
    if (_prefs == null) await initialize();

    try {
      final key = '$_lastSyncPrefix$syncType';
      await _prefs!.setString(key, time.toIso8601String());
    } catch (error) {
      log('Failed to set last sync time: $error', name: _logTag);
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime(String syncType) async {
    if (_prefs == null) await initialize();

    try {
      final key = '$_lastSyncPrefix$syncType';
      final timeString = _prefs!.getString(key);

      if (timeString == null) return null;

      return DateTime.parse(timeString);
    } catch (error) {
      log('Failed to get last sync time: $error', name: _logTag);
      return null;
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(String cacheType, {Duration? maxAge}) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '$_cachePrefix$cacheType';
      final cachedString = _prefs!.getString(cacheKey);

      if (cachedString == null) return false;

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      final age = DateTime.now().difference(timestamp);

      final maxCacheAge = maxAge ?? _cacheExpiration;
      return age <= maxCacheAge;
    } catch (error) {
      log('Failed to check cache validity: $error', name: _logTag);
      return false;
    }
  }

  /// Get cache age
  Future<Duration?> getCacheAge(String cacheType) async {
    if (_prefs == null) await initialize();

    try {
      final cacheKey = '$_cachePrefix$cacheType';
      final cachedString = _prefs!.getString(cacheKey);

      if (cachedString == null) return null;

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);

      return DateTime.now().difference(timestamp);
    } catch (error) {
      log('Failed to get cache age: $error', name: _logTag);
      return null;
    }
  }

  /// Convert WeeklyReport to Map for caching
  Map<String, dynamic> _reportToMap(WeeklyReport report) {
    return {
      'id': report.id,
      'userUuid': report.userUuid,
      'weekStartDate': report.weekStartDate.toIso8601String(),
      'weekEndDate': report.weekEndDate.toIso8601String(),
      'generatedAt': report.generatedAt.toIso8601String(),
      'stats': {
        'totalCertifications': report.stats.totalCertifications,
        'exerciseDays': report.stats.exerciseDays,
        'dietDays': report.stats.dietDays,
        'consistencyScore': report.stats.consistencyScore,
        'exerciseTypes': report.stats.exerciseTypes,
        'exerciseCategories': report.stats.exerciseCategories,
        'dietCategories': report.stats.dietCategories,
      },
      'analysis': {
        'exerciseInsights': report.analysis.exerciseInsights,
        'dietInsights': report.analysis.dietInsights,
        'overallAssessment': report.analysis.overallAssessment,
        'strengthAreas': report.analysis.strengthAreas,
        'improvementAreas': report.analysis.improvementAreas,
      },
      'recommendations': report.recommendations,
      'status': report.status.name,
    };
  }

  /// Convert Map to WeeklyReport from cache
  WeeklyReport _mapToReport(Map<String, dynamic> map) {
    return WeeklyReport(
      id: map['id'] as String,
      userUuid: map['userUuid'] as String,
      weekStartDate: DateTime.parse(map['weekStartDate'] as String),
      weekEndDate: DateTime.parse(map['weekEndDate'] as String),
      generatedAt: DateTime.parse(map['generatedAt'] as String),
      stats: WeeklyStats(
        totalCertifications: map['stats']['totalCertifications'] as int,
        exerciseDays: map['stats']['exerciseDays'] as int,
        dietDays: map['stats']['dietDays'] as int,
        consistencyScore: (map['stats']['consistencyScore'] as num).toDouble(),
        exerciseTypes: Map<String, int>.from(map['stats']['exerciseTypes'] as Map),
        exerciseCategories: Map<String, int>.from(map['stats']['exerciseCategories'] as Map? ?? {}),
        dietCategories: Map<String, int>.from(map['stats']['dietCategories'] as Map? ?? {}),
      ),
      analysis: AIAnalysis(
        exerciseInsights: map['analysis']['exerciseInsights'] as String,
        dietInsights: map['analysis']['dietInsights'] as String,
        overallAssessment: map['analysis']['overallAssessment'] as String,
        strengthAreas: List<String>.from(map['analysis']['strengthAreas'] as List),
        improvementAreas: List<String>.from(map['analysis']['improvementAreas'] as List),
      ),
      recommendations: List<String>.from(map['recommendations'] as List),
      status: ReportStatus.fromFirestore(map['status'] as String),
    );
  }
}
