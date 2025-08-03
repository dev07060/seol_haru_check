import 'dart:developer';

import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/extensions/category_extensions.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_mapping_service.dart';

/// Service for processing weekly report data into visualization-friendly formats
class VisualizationDataService {
  final CategoryMappingService _categoryMappingService;

  VisualizationDataService() : _categoryMappingService = CategoryMappingService.instance;

  /// Process weekly report data for visualization
  Future<VisualizationData> processWeeklyData(WeeklyReport report) async {
    try {
      log('[VisualizationDataService] Processing weekly data for report: ${report.id}');

      // Process exercise categories with emoji and color mapping
      final exerciseCategoryData = _processExerciseCategories(report.stats.exerciseCategories);

      // Process diet categories with proper categorization
      final dietCategoryData = _processDietCategories(report.stats.dietCategories);

      // Process hierarchical data for main types and subcategories
      final hierarchicalData = _processHierarchicalData(report.stats);

      // Calculate daily activity distribution
      final dailyActivityData = await _calculateDailyActivityData(report);

      return VisualizationData(
        dailyExerciseActivity: dailyActivityData,
        exerciseTypeDistribution: report.stats.exerciseTypes,
        dietCategoryDistribution: report.stats.dietCategories,
        exerciseCategoryData: exerciseCategoryData,
        dietCategoryData: dietCategoryData,
        mealTimingData: {}, // Will be implemented in future tasks
        dailyBreakdown: [], // Will be implemented in future tasks
        consistencyMetrics: ConsistencyMetrics.basic(report.stats.consistencyScore),
        goalProgress: _calculateBasicGoalProgress(report),
        categoryTrends: CategoryTrendData.empty(), // Will be calculated with historical data
        hierarchicalData: hierarchicalData,
      );
    } catch (e, stackTrace) {
      log('[VisualizationDataService] Error processing weekly data: $e', stackTrace: stackTrace);
      return _generateFallbackData(report);
    }
  }

  /// Process exercise categories with emoji and color mapping
  List<CategoryVisualizationData> _processExerciseCategories(Map<String, int> categories) {
    log('[VisualizationDataService] Processing exercise categories: $categories');

    if (categories.isEmpty) {
      return [];
    }

    final total = categories.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return [];
    }

    return categories.entries.map((entry) {
      final categoryName = entry.key;
      final count = entry.value;
      final percentage = count / total;

      try {
        // Try to find matching exercise category enum
        final exerciseCategory = ExerciseCategory.fromDisplayName(categoryName);

        return exerciseCategory.toVisualizationData(
          count: count,
          percentage: percentage,
          description: '${exerciseCategory.displayName} 활동',
        );
      } catch (e) {
        // Handle unknown categories with fallback color and emoji
        log('[VisualizationDataService] Unknown exercise category: $categoryName, using fallback');

        return CategoryVisualizationData(
          categoryName: categoryName,
          emoji: _categoryMappingService.getCategoryEmojiByName(categoryName, CategoryType.exercise),
          count: count,
          percentage: percentage,
          color: _categoryMappingService.getCategoryColorByName(categoryName, CategoryType.exercise),
          type: CategoryType.exercise,
          description: '$categoryName 활동',
        );
      }
    }).toList();
  }

  /// Process diet categories with proper categorization
  List<CategoryVisualizationData> _processDietCategories(Map<String, int> categories) {
    log('[VisualizationDataService] Processing diet categories: $categories');

    if (categories.isEmpty) {
      return [];
    }

    final total = categories.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return [];
    }

    return categories.entries.map((entry) {
      final categoryName = entry.key;
      final count = entry.value;
      final percentage = count / total;

      try {
        // Try to find matching diet category enum
        final dietCategory = DietCategory.fromDisplayName(categoryName);

        return dietCategory.toVisualizationData(
          count: count,
          percentage: percentage,
          description: '${dietCategory.displayName} 섭취',
        );
      } catch (e) {
        // Handle unknown categories with fallback color and emoji
        log('[VisualizationDataService] Unknown diet category: $categoryName, using fallback');

        return CategoryVisualizationData(
          categoryName: categoryName,
          emoji: _categoryMappingService.getCategoryEmojiByName(categoryName, CategoryType.diet),
          count: count,
          percentage: percentage,
          color: _categoryMappingService.getCategoryColorByName(categoryName, CategoryType.diet),
          type: CategoryType.diet,
          description: '$categoryName 섭취',
        );
      }
    }).toList();
  }

  /// Process hierarchical data for main types and subcategories
  Map<String, Map<String, int>> _processHierarchicalData(WeeklyStats stats) {
    log('[VisualizationDataService] Processing hierarchical data');

    final hierarchicalData = <String, Map<String, int>>{};

    // Add exercise main type with subcategories
    if (stats.exerciseCategories.isNotEmpty) {
      hierarchicalData['운동'] = Map<String, int>.from(stats.exerciseCategories);
    }

    // Add diet main type with subcategories
    if (stats.dietCategories.isNotEmpty) {
      hierarchicalData['식단'] = Map<String, int>.from(stats.dietCategories);
    }

    // Add exercise types as another hierarchical level if available
    if (stats.exerciseTypes.isNotEmpty) {
      hierarchicalData['운동 유형'] = Map<String, int>.from(stats.exerciseTypes);
    }

    log('[VisualizationDataService] Generated hierarchical data: $hierarchicalData');
    return hierarchicalData;
  }

  /// Calculate category trend analysis and comparison logic
  Future<CategoryTrendData> calculateCategoryTrends(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[VisualizationDataService] Calculating category trends for ${historicalReports.length} historical reports');

    if (historicalReports.isEmpty) {
      return CategoryTrendData.empty();
    }

    try {
      // Sort historical reports by date (most recent first)
      final sortedReports = List<WeeklyReport>.from(historicalReports)
        ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

      // Calculate exercise category trends
      final exerciseCategoryTrends = _calculateCategoryTrendsForType(
        currentReport.stats.exerciseCategories,
        sortedReports.map((r) => r.stats.exerciseCategories).toList(),
        CategoryType.exercise,
      );

      // Calculate diet category trends
      final dietCategoryTrends = _calculateCategoryTrendsForType(
        currentReport.stats.dietCategories,
        sortedReports.map((r) => r.stats.dietCategories).toList(),
        CategoryType.diet,
      );

      // Calculate change percentages
      final categoryChangePercentages = _calculateCategoryChangePercentages(
        currentReport.stats,
        sortedReports.isNotEmpty ? sortedReports.first.stats : null,
      );

      // Identify emerging and declining categories
      final emergingCategories = _identifyEmergingCategories(
        currentReport.stats,
        sortedReports.map((r) => r.stats).toList(),
      );

      final decliningCategories = _identifyDecliningCategories(
        currentReport.stats,
        sortedReports.map((r) => r.stats).toList(),
      );

      return CategoryTrendData(
        exerciseCategoryTrends: exerciseCategoryTrends,
        dietCategoryTrends: dietCategoryTrends,
        categoryChangePercentages: categoryChangePercentages,
        emergingCategories: emergingCategories,
        decliningCategories: decliningCategories,
        analysisDate: DateTime.now(),
        weeksAnalyzed: sortedReports.length + 1, // +1 for current report
      );
    } catch (e, stackTrace) {
      log('[VisualizationDataService] Error calculating category trends: $e', stackTrace: stackTrace);
      return CategoryTrendData.empty();
    }
  }

  /// Calculate trends for a specific category type
  Map<String, TrendDirection> _calculateCategoryTrendsForType(
    Map<String, int> currentCategories,
    List<Map<String, int>> historicalCategories,
    CategoryType type,
  ) {
    final trends = <String, TrendDirection>{};

    if (historicalCategories.isEmpty) {
      return trends;
    }

    // Compare with the most recent historical data
    final previousCategories = historicalCategories.first;

    for (final categoryEntry in currentCategories.entries) {
      final categoryName = categoryEntry.key;
      final currentCount = categoryEntry.value;
      final previousCount = previousCategories[categoryName] ?? 0;

      TrendDirection trend;
      if (currentCount > previousCount) {
        trend = TrendDirection.up;
      } else if (currentCount < previousCount) {
        trend = TrendDirection.down;
      } else {
        trend = TrendDirection.stable;
      }

      trends[categoryName] = trend;
    }

    // Also check for categories that existed before but not now (declining to zero)
    for (final categoryEntry in previousCategories.entries) {
      final categoryName = categoryEntry.key;
      if (!currentCategories.containsKey(categoryName) && categoryEntry.value > 0) {
        trends[categoryName] = TrendDirection.down;
      }
    }

    return trends;
  }

  /// Calculate percentage changes for categories
  Map<String, double> _calculateCategoryChangePercentages(WeeklyStats currentStats, WeeklyStats? previousStats) {
    final changePercentages = <String, double>{};

    if (previousStats == null) {
      return changePercentages;
    }

    // Calculate exercise category changes
    _calculateChangePercentagesForCategories(
      currentStats.exerciseCategories,
      previousStats.exerciseCategories,
      changePercentages,
    );

    // Calculate diet category changes
    _calculateChangePercentagesForCategories(
      currentStats.dietCategories,
      previousStats.dietCategories,
      changePercentages,
    );

    return changePercentages;
  }

  /// Helper method to calculate change percentages for a category map
  void _calculateChangePercentagesForCategories(
    Map<String, int> currentCategories,
    Map<String, int> previousCategories,
    Map<String, double> changePercentages,
  ) {
    for (final categoryEntry in currentCategories.entries) {
      final categoryName = categoryEntry.key;
      final currentCount = categoryEntry.value;
      final previousCount = previousCategories[categoryName] ?? 0;

      if (previousCount > 0) {
        final changePercentage = ((currentCount - previousCount) / previousCount) * 100;
        changePercentages[categoryName] = changePercentage;
      } else if (currentCount > 0) {
        // New category appeared
        changePercentages[categoryName] = 100.0; // 100% increase from zero
      }
    }

    // Check for categories that disappeared
    for (final categoryEntry in previousCategories.entries) {
      final categoryName = categoryEntry.key;
      if (!currentCategories.containsKey(categoryName) && categoryEntry.value > 0) {
        changePercentages[categoryName] = -100.0; // 100% decrease to zero
      }
    }
  }

  /// Identify emerging categories (new or significantly increased)
  List<String> _identifyEmergingCategories(WeeklyStats currentStats, List<WeeklyStats> historicalStats) {
    final emergingCategories = <String>[];

    if (historicalStats.isEmpty) {
      return emergingCategories;
    }

    final previousStats = historicalStats.first;

    // Check exercise categories
    _identifyEmergingCategoriesForType(
      currentStats.exerciseCategories,
      previousStats.exerciseCategories,
      emergingCategories,
    );

    // Check diet categories
    _identifyEmergingCategoriesForType(currentStats.dietCategories, previousStats.dietCategories, emergingCategories);

    return emergingCategories;
  }

  /// Helper method to identify emerging categories for a specific type
  void _identifyEmergingCategoriesForType(
    Map<String, int> currentCategories,
    Map<String, int> previousCategories,
    List<String> emergingCategories,
  ) {
    for (final categoryEntry in currentCategories.entries) {
      final categoryName = categoryEntry.key;
      final currentCount = categoryEntry.value;
      final previousCount = previousCategories[categoryName] ?? 0;

      // Consider a category emerging if:
      // 1. It's completely new (previousCount == 0)
      // 2. It increased by more than 50%
      if (previousCount == 0 && currentCount > 0) {
        emergingCategories.add(categoryName);
      } else if (previousCount > 0 && currentCount > previousCount * 1.5) {
        emergingCategories.add(categoryName);
      }
    }
  }

  /// Identify declining categories (disappeared or significantly decreased)
  List<String> _identifyDecliningCategories(WeeklyStats currentStats, List<WeeklyStats> historicalStats) {
    final decliningCategories = <String>[];

    if (historicalStats.isEmpty) {
      return decliningCategories;
    }

    final previousStats = historicalStats.first;

    // Check exercise categories
    _identifyDecliningCategoriesForType(
      currentStats.exerciseCategories,
      previousStats.exerciseCategories,
      decliningCategories,
    );

    // Check diet categories
    _identifyDecliningCategoriesForType(currentStats.dietCategories, previousStats.dietCategories, decliningCategories);

    return decliningCategories;
  }

  /// Helper method to identify declining categories for a specific type
  void _identifyDecliningCategoriesForType(
    Map<String, int> currentCategories,
    Map<String, int> previousCategories,
    List<String> decliningCategories,
  ) {
    for (final categoryEntry in previousCategories.entries) {
      final categoryName = categoryEntry.key;
      final previousCount = categoryEntry.value;
      final currentCount = currentCategories[categoryName] ?? 0;

      // Consider a category declining if:
      // 1. It completely disappeared (currentCount == 0)
      // 2. It decreased by more than 50%
      if (previousCount > 0 && currentCount == 0) {
        decliningCategories.add(categoryName);
      } else if (previousCount > 0 && currentCount < previousCount * 0.5) {
        decliningCategories.add(categoryName);
      }
    }
  }

  /// Calculate daily activity data from report
  Future<Map<int, int>> _calculateDailyActivityData(WeeklyReport report) async {
    // This is a simplified implementation
    // In a real scenario, we would query daily certification data
    final dailyData = <int, int>{};

    // Distribute total certifications across the week
    final totalCertifications = report.stats.totalCertifications;
    final activeDays = report.stats.exerciseDays + report.stats.dietDays;

    if (activeDays > 0) {
      final avgPerDay = totalCertifications / activeDays;

      // Simulate distribution across weekdays (0 = Monday, 6 = Sunday)
      for (int i = 0; i < 7; i++) {
        if (i < activeDays) {
          dailyData[i] = avgPerDay.round();
        } else {
          dailyData[i] = 0;
        }
      }
    }

    return dailyData;
  }

  /// Calculate basic goal progress
  Map<String, double> _calculateBasicGoalProgress(WeeklyReport report) {
    return {
      'exercise_days': report.stats.exerciseDays / 7.0, // Assuming 7-day goal
      'diet_days': report.stats.dietDays / 7.0, // Assuming 7-day goal
      'consistency': report.stats.consistencyScore,
      'total_certifications': (report.stats.totalCertifications / 14.0).clamp(
        0.0,
        1.0,
      ), // Assuming 14 certification goal
    };
  }

  /// Generate fallback data when processing fails
  VisualizationData _generateFallbackData(WeeklyReport report) {
    log('[VisualizationDataService] Generating fallback data for report: ${report.id}');

    return VisualizationData(
      dailyExerciseActivity: _generateBasicActivityData(report),
      exerciseTypeDistribution: report.stats.exerciseTypes,
      dietCategoryDistribution: report.stats.dietCategories,
      exerciseCategoryData: [],
      dietCategoryData: [],
      mealTimingData: {},
      dailyBreakdown: [],
      consistencyMetrics: ConsistencyMetrics.basic(report.stats.consistencyScore),
      goalProgress: _calculateBasicGoalProgress(report),
      categoryTrends: CategoryTrendData.empty(),
      hierarchicalData: {},
    );
  }

  /// Generate basic activity data for fallback
  Map<int, int> _generateBasicActivityData(WeeklyReport report) {
    final dailyData = <int, int>{};
    final activeDays = report.stats.exerciseDays + report.stats.dietDays;

    // Simple distribution
    for (int i = 0; i < 7; i++) {
      dailyData[i] = i < activeDays ? 1 : 0;
    }

    return dailyData;
  }
}

/// Container for all visualization data
class VisualizationData {
  final Map<int, int> dailyExerciseActivity; // weekday -> count
  final Map<String, int> exerciseTypeDistribution;
  final Map<String, int> dietCategoryDistribution;
  final List<CategoryVisualizationData> exerciseCategoryData;
  final List<CategoryVisualizationData> dietCategoryData;
  final Map<int, List<String>> mealTimingData; // hour -> meal types
  final List<DailyActivityData> dailyBreakdown;
  final ConsistencyMetrics consistencyMetrics;
  final Map<String, double> goalProgress;
  final CategoryTrendData categoryTrends;
  final Map<String, Map<String, int>> hierarchicalData; // main type -> subcategories

  const VisualizationData({
    required this.dailyExerciseActivity,
    required this.exerciseTypeDistribution,
    required this.dietCategoryDistribution,
    required this.exerciseCategoryData,
    required this.dietCategoryData,
    required this.mealTimingData,
    required this.dailyBreakdown,
    required this.consistencyMetrics,
    required this.goalProgress,
    required this.categoryTrends,
    required this.hierarchicalData,
  });

  /// Check if has sufficient data for visualization
  bool get hasSufficientData {
    return exerciseCategoryData.isNotEmpty || dietCategoryData.isNotEmpty;
  }

  /// Get total categories count
  int get totalCategoriesCount {
    return exerciseCategoryData.length + dietCategoryData.length;
  }

  /// Get all category data combined
  List<CategoryVisualizationData> get allCategoryData {
    return [...exerciseCategoryData, ...dietCategoryData];
  }
}

/// Model for daily activity data
class DailyActivityData {
  final DateTime date;
  final int exerciseCount;
  final int dietCount;
  final List<String> exerciseTypes;
  final List<String> mealTypes;

  const DailyActivityData({
    required this.date,
    required this.exerciseCount,
    required this.dietCount,
    required this.exerciseTypes,
    required this.mealTypes,
  });
}

/// Model for consistency metrics
class ConsistencyMetrics {
  final double consistencyScore;
  final int streakDays;
  final int totalActiveDays;
  final double weeklyGoalProgress;

  const ConsistencyMetrics({
    required this.consistencyScore,
    required this.streakDays,
    required this.totalActiveDays,
    required this.weeklyGoalProgress,
  });

  /// Create basic consistency metrics
  factory ConsistencyMetrics.basic(double consistencyScore) {
    return ConsistencyMetrics(
      consistencyScore: consistencyScore,
      streakDays: 0,
      totalActiveDays: 0,
      weeklyGoalProgress: consistencyScore,
    );
  }
}
