import 'dart:developer';
import 'dart:math' as math;

import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';

/// Service for advanced category trend analysis and pattern recognition
class CategoryTrendAnalysisService {
  static final CategoryTrendAnalysisService _instance = CategoryTrendAnalysisService._internal();
  static CategoryTrendAnalysisService get instance => _instance;
  CategoryTrendAnalysisService._internal();

  /// Threshold for considering a category as emerging (50% increase)
  static const double _emergingThreshold = 0.5;

  /// Threshold for considering a category as declining (50% decrease)
  static const double _decliningThreshold = 0.5;

  /// Minimum weeks required for reliable trend analysis
  static const int _minWeeksForAnalysis = 2;

  /// Maximum weeks to consider for trend analysis
  static const int _maxWeeksForAnalysis = 8;

  /// Implement week-over-week category trend analysis
  Future<CategoryTrendAnalysis> analyzeWeekOverWeekTrends(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log(
      '[CategoryTrendAnalysisService] Analyzing week-over-week trends for ${historicalReports.length} historical reports',
    );

    if (historicalReports.isEmpty) {
      return CategoryTrendAnalysis.empty();
    }

    try {
      // Sort historical reports by date (most recent first)
      final sortedReports = List<WeeklyReport>.from(historicalReports)
        ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

      // Limit analysis to reasonable timeframe
      final reportsToAnalyze = sortedReports.take(_maxWeeksForAnalysis).toList();

      // Calculate exercise category trends
      final exerciseTrends = await _analyzeExerciseCategoryTrends(currentReport, reportsToAnalyze);

      // Calculate diet category trends
      final dietTrends = await _analyzeDietCategoryTrends(currentReport, reportsToAnalyze);

      // Calculate overall trend metrics
      final overallMetrics = _calculateOverallTrendMetrics(currentReport, reportsToAnalyze);

      // Calculate trend velocity (rate of change)
      final trendVelocity = _calculateTrendVelocity(currentReport, reportsToAnalyze);

      return CategoryTrendAnalysis(
        exerciseCategoryTrends: exerciseTrends,
        dietCategoryTrends: dietTrends,
        overallTrendDirection: overallMetrics.overallDirection,
        trendStrength: overallMetrics.strength,
        analysisConfidence: overallMetrics.confidence,
        trendVelocity: trendVelocity,
        weeksAnalyzed: reportsToAnalyze.length + 1,
        analysisDate: DateTime.now(),
      );
    } catch (e, stackTrace) {
      log('[CategoryTrendAnalysisService] Error analyzing week-over-week trends: $e', stackTrace: stackTrace);
      return CategoryTrendAnalysis.empty();
    }
  }

  /// Add emerging and declining category detection
  Future<CategoryEmergenceAnalysis> detectEmergingAndDecliningCategories(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryTrendAnalysisService] Detecting emerging and declining categories');

    if (historicalReports.length < _minWeeksForAnalysis) {
      return CategoryEmergenceAnalysis.empty();
    }

    try {
      // Sort historical reports by date (most recent first)
      final sortedReports = List<WeeklyReport>.from(historicalReports)
        ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

      // Analyze emergence patterns
      final emergingCategories = await _detectEmergingCategories(currentReport, sortedReports);

      // Analyze decline patterns
      final decliningCategories = await _detectDecliningCategories(currentReport, sortedReports);

      // Analyze category lifecycle patterns
      final lifecyclePatterns = _analyzeCategoryLifecycles(currentReport, sortedReports);

      // Calculate emergence confidence scores
      final emergenceConfidence = _calculateEmergenceConfidence(
        emergingCategories,
        decliningCategories,
        sortedReports.length,
      );

      return CategoryEmergenceAnalysis(
        emergingCategories: emergingCategories,
        decliningCategories: decliningCategories,
        lifecyclePatterns: lifecyclePatterns,
        emergenceConfidence: emergenceConfidence,
        analysisDate: DateTime.now(),
        weeksAnalyzed: sortedReports.length + 1,
      );
    } catch (e, stackTrace) {
      log('[CategoryTrendAnalysisService] Error detecting emerging/declining categories: $e', stackTrace: stackTrace);
      return CategoryEmergenceAnalysis.empty();
    }
  }

  /// Create category preference pattern recognition
  Future<CategoryPreferencePatterns> recognizeCategoryPreferencePatterns(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryTrendAnalysisService] Recognizing category preference patterns');

    if (historicalReports.length < _minWeeksForAnalysis) {
      return CategoryPreferencePatterns.empty();
    }

    try {
      // Sort historical reports by date (oldest first for pattern analysis)
      final sortedReports = List<WeeklyReport>.from(historicalReports)
        ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

      // Analyze exercise preferences
      final exercisePreferences = _analyzeExercisePreferences(currentReport, sortedReports);

      // Analyze diet preferences
      final dietPreferences = _analyzeDietPreferences(currentReport, sortedReports);

      // Detect seasonal patterns
      final seasonalPatterns = _detectSeasonalPatterns(currentReport, sortedReports);

      // Analyze preference stability
      final preferenceStability = _analyzePreferenceStability(currentReport, sortedReports);

      // Identify preference clusters
      final preferenceClusters = _identifyPreferenceClusters(currentReport, sortedReports);

      return CategoryPreferencePatterns(
        exercisePreferences: exercisePreferences,
        dietPreferences: dietPreferences,
        seasonalPatterns: seasonalPatterns,
        preferenceStability: preferenceStability,
        preferenceClusters: preferenceClusters,
        analysisDate: DateTime.now(),
        weeksAnalyzed: sortedReports.length + 1,
      );
    } catch (e, stackTrace) {
      log('[CategoryTrendAnalysisService] Error recognizing preference patterns: $e', stackTrace: stackTrace);
      return CategoryPreferencePatterns.empty();
    }
  }

  /// Implement category diversity scoring and recommendations
  Future<CategoryDiversityAnalysis> analyzeCategoryDiversity(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryTrendAnalysisService] Analyzing category diversity');

    try {
      // Calculate current diversity scores
      final currentDiversityScore = _calculateDiversityScore(currentReport.stats);

      // Calculate historical diversity trend
      final diversityTrend = _calculateDiversityTrend(currentReport, historicalReports);

      // Generate diversity recommendations
      final recommendations = await _generateDiversityRecommendations(
        currentReport,
        historicalReports,
        currentDiversityScore,
      );

      // Calculate diversity balance
      final diversityBalance = _calculateDiversityBalance(currentReport.stats);

      // Analyze diversity patterns
      final diversityPatterns = _analyzeDiversityPatterns(currentReport, historicalReports);

      // Calculate optimal diversity targets
      final optimalTargets = _calculateOptimalDiversityTargets(currentReport, historicalReports);

      return CategoryDiversityAnalysis(
        currentDiversityScore: currentDiversityScore,
        diversityTrend: diversityTrend,
        recommendations: recommendations,
        diversityBalance: diversityBalance,
        diversityPatterns: diversityPatterns,
        optimalTargets: optimalTargets,
        analysisDate: DateTime.now(),
        weeksAnalyzed: historicalReports.length + 1,
      );
    } catch (e, stackTrace) {
      log('[CategoryTrendAnalysisService] Error analyzing category diversity: $e', stackTrace: stackTrace);
      return CategoryDiversityAnalysis.empty();
    }
  }

  /// Analyze exercise category trends
  Future<Map<String, CategoryTrendMetrics>> _analyzeExerciseCategoryTrends(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final trends = <String, CategoryTrendMetrics>{};

    final currentCategories = currentReport.stats.exerciseCategories;

    for (final categoryEntry in currentCategories.entries) {
      final categoryName = categoryEntry.key;
      final currentCount = categoryEntry.value;

      // Collect historical data for this category
      final historicalCounts =
          historicalReports.map((report) => report.stats.exerciseCategories[categoryName] ?? 0).toList();

      // Calculate trend metrics
      final trendMetrics = _calculateCategoryTrendMetrics(
        categoryName,
        currentCount,
        historicalCounts,
        CategoryType.exercise,
      );

      trends[categoryName] = trendMetrics;
    }

    return trends;
  }

  /// Analyze diet category trends
  Future<Map<String, CategoryTrendMetrics>> _analyzeDietCategoryTrends(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final trends = <String, CategoryTrendMetrics>{};

    final currentCategories = currentReport.stats.dietCategories;

    for (final categoryEntry in currentCategories.entries) {
      final categoryName = categoryEntry.key;
      final currentCount = categoryEntry.value;

      // Collect historical data for this category
      final historicalCounts =
          historicalReports.map((report) => report.stats.dietCategories[categoryName] ?? 0).toList();

      // Calculate trend metrics
      final trendMetrics = _calculateCategoryTrendMetrics(
        categoryName,
        currentCount,
        historicalCounts,
        CategoryType.diet,
      );

      trends[categoryName] = trendMetrics;
    }

    return trends;
  }

  /// Calculate trend metrics for a specific category
  CategoryTrendMetrics _calculateCategoryTrendMetrics(
    String categoryName,
    int currentCount,
    List<int> historicalCounts,
    CategoryType type,
  ) {
    if (historicalCounts.isEmpty) {
      return CategoryTrendMetrics.stable(categoryName, type);
    }

    // Calculate trend direction
    final recentCount = historicalCounts.first;
    TrendDirection direction;
    if (currentCount > recentCount) {
      direction = TrendDirection.up;
    } else if (currentCount < recentCount) {
      direction = TrendDirection.down;
    } else {
      direction = TrendDirection.stable;
    }

    // Calculate change percentage
    final changePercentage =
        recentCount > 0 ? ((currentCount - recentCount) / recentCount) * 100 : (currentCount > 0 ? 100.0 : 0.0);

    // Calculate trend strength based on consistency
    final trendStrength = _calculateTrendStrength(currentCount, historicalCounts);

    // Calculate volatility
    final volatility = _calculateVolatility(historicalCounts);

    // Calculate momentum
    final momentum = _calculateMomentum(currentCount, historicalCounts);

    return CategoryTrendMetrics(
      categoryName: categoryName,
      categoryType: type,
      direction: direction,
      changePercentage: changePercentage,
      trendStrength: trendStrength,
      volatility: volatility,
      momentum: momentum,
      currentValue: currentCount,
      previousValue: recentCount,
      historicalAverage:
          historicalCounts.isNotEmpty ? historicalCounts.reduce((a, b) => a + b) / historicalCounts.length : 0.0,
    );
  }

  /// Calculate overall trend metrics
  _OverallTrendMetrics _calculateOverallTrendMetrics(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    if (historicalReports.isEmpty) {
      return _OverallTrendMetrics(overallDirection: TrendDirection.stable, strength: 0.0, confidence: 0.0);
    }

    final recentReport = historicalReports.first;

    // Calculate overall activity trend
    final currentTotal = currentReport.stats.totalCertifications;
    final previousTotal = recentReport.stats.totalCertifications;

    TrendDirection overallDirection;
    if (currentTotal > previousTotal) {
      overallDirection = TrendDirection.up;
    } else if (currentTotal < previousTotal) {
      overallDirection = TrendDirection.down;
    } else {
      overallDirection = TrendDirection.stable;
    }

    // Calculate trend strength
    final strength =
        previousTotal > 0 ? (currentTotal - previousTotal).abs() / previousTotal : (currentTotal > 0 ? 1.0 : 0.0);

    // Calculate confidence based on data consistency
    final confidence = math.min(historicalReports.length / _maxWeeksForAnalysis, 1.0);

    return _OverallTrendMetrics(overallDirection: overallDirection, strength: strength, confidence: confidence);
  }

  /// Calculate trend velocity (rate of change over time)
  double _calculateTrendVelocity(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    if (historicalReports.length < 2) {
      return 0.0;
    }

    final currentTotal = currentReport.stats.totalCertifications;
    final oldestReport = historicalReports.last;
    final oldestTotal = oldestReport.stats.totalCertifications;

    final weeksDifference = historicalReports.length;

    if (weeksDifference == 0 || oldestTotal == 0) {
      return 0.0;
    }

    // Calculate velocity as change per week
    return (currentTotal - oldestTotal) / weeksDifference.toDouble();
  }

  /// Detect emerging categories
  Future<List<EmergingCategory>> _detectEmergingCategories(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final emergingCategories = <EmergingCategory>[];

    // Check exercise categories
    _detectEmergingCategoriesForType(
      currentReport.stats.exerciseCategories,
      historicalReports.map((r) => r.stats.exerciseCategories).toList(),
      CategoryType.exercise,
      emergingCategories,
    );

    // Check diet categories
    _detectEmergingCategoriesForType(
      currentReport.stats.dietCategories,
      historicalReports.map((r) => r.stats.dietCategories).toList(),
      CategoryType.diet,
      emergingCategories,
    );

    return emergingCategories;
  }

  /// Detect declining categories
  Future<List<DecliningCategory>> _detectDecliningCategories(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final decliningCategories = <DecliningCategory>[];

    // Check exercise categories
    _detectDecliningCategoriesForType(
      currentReport.stats.exerciseCategories,
      historicalReports.map((r) => r.stats.exerciseCategories).toList(),
      CategoryType.exercise,
      decliningCategories,
    );

    // Check diet categories
    _detectDecliningCategoriesForType(
      currentReport.stats.dietCategories,
      historicalReports.map((r) => r.stats.dietCategories).toList(),
      CategoryType.diet,
      decliningCategories,
    );

    return decliningCategories;
  }

  /// Helper method to detect emerging categories for a specific type
  void _detectEmergingCategoriesForType(
    Map<String, int> currentCategories,
    List<Map<String, int>> historicalCategories,
    CategoryType type,
    List<EmergingCategory> emergingCategories,
  ) {
    for (final categoryEntry in currentCategories.entries) {
      final categoryName = categoryEntry.key;
      final currentCount = categoryEntry.value;

      // Calculate historical average
      final historicalCounts = historicalCategories.map((categories) => categories[categoryName] ?? 0).toList();

      final historicalAverage =
          historicalCounts.isNotEmpty ? historicalCounts.reduce((a, b) => a + b) / historicalCounts.length : 0.0;

      // Check if category is emerging
      final isNewCategory = historicalAverage == 0 && currentCount > 0;
      final isSignificantIncrease =
          historicalAverage > 0 && currentCount > historicalAverage * (1 + _emergingThreshold);

      if (isNewCategory || isSignificantIncrease) {
        final emergenceStrength =
            historicalAverage > 0
                ? (currentCount - historicalAverage) / historicalAverage
                : 1.0; // New category has maximum emergence strength

        emergingCategories.add(
          EmergingCategory(
            categoryName: categoryName,
            categoryType: type,
            currentCount: currentCount,
            historicalAverage: historicalAverage,
            emergenceStrength: emergenceStrength,
            isNewCategory: isNewCategory,
            weeksActive: historicalCounts.where((count) => count > 0).length + 1,
          ),
        );
      }
    }
  }

  /// Helper method to detect declining categories for a specific type
  void _detectDecliningCategoriesForType(
    Map<String, int> currentCategories,
    List<Map<String, int>> historicalCategories,
    CategoryType type,
    List<DecliningCategory> decliningCategories,
  ) {
    // Check all historical categories for decline
    final allHistoricalCategories = <String>{};
    for (final categories in historicalCategories) {
      allHistoricalCategories.addAll(categories.keys);
    }

    for (final categoryName in allHistoricalCategories) {
      final currentCount = currentCategories[categoryName] ?? 0;

      // Calculate historical average
      final historicalCounts = historicalCategories.map((categories) => categories[categoryName] ?? 0).toList();

      final historicalAverage =
          historicalCounts.isNotEmpty ? historicalCounts.reduce((a, b) => a + b) / historicalCounts.length : 0.0;

      // Check if category is declining
      final hasDisappeared = historicalAverage > 0 && currentCount == 0;
      final hasSignificantDecrease =
          historicalAverage > 0 && currentCount < historicalAverage * (1 - _decliningThreshold);

      if (hasDisappeared || hasSignificantDecrease) {
        final declineStrength = historicalAverage > 0 ? (historicalAverage - currentCount) / historicalAverage : 0.0;

        decliningCategories.add(
          DecliningCategory(
            categoryName: categoryName,
            categoryType: type,
            currentCount: currentCount,
            historicalAverage: historicalAverage,
            declineStrength: declineStrength,
            hasDisappeared: hasDisappeared,
            weeksInactive: currentCount == 0 ? 1 : 0,
          ),
        );
      }
    }
  }

  /// Calculate trend strength based on consistency
  double _calculateTrendStrength(int currentCount, List<int> historicalCounts) {
    if (historicalCounts.length < 2) {
      return 0.0;
    }

    // Calculate the consistency of the trend direction
    var consistentChanges = 0;
    var totalChanges = 0;

    for (int i = 0; i < historicalCounts.length - 1; i++) {
      final current = i == 0 ? currentCount : historicalCounts[i - 1];
      final next = historicalCounts[i];

      if (current != next) {
        totalChanges++;
        // Check if change is in the same direction as overall trend
        final overallTrend = currentCount - historicalCounts.last;
        final localTrend = current - next;

        if ((overallTrend > 0 && localTrend > 0) || (overallTrend < 0 && localTrend < 0)) {
          consistentChanges++;
        }
      }
    }

    return totalChanges > 0 ? consistentChanges / totalChanges : 0.0;
  }

  /// Calculate volatility of historical data
  double _calculateVolatility(List<int> historicalCounts) {
    if (historicalCounts.length < 2) {
      return 0.0;
    }

    final mean = historicalCounts.reduce((a, b) => a + b) / historicalCounts.length;
    final variance =
        historicalCounts.map((count) => math.pow(count - mean, 2)).reduce((a, b) => a + b) / historicalCounts.length;

    return math.sqrt(variance);
  }

  /// Calculate momentum of trend
  double _calculateMomentum(int currentCount, List<int> historicalCounts) {
    if (historicalCounts.length < 2) {
      return 0.0;
    }

    // Calculate recent momentum (last 3 weeks)
    final recentCounts = [currentCount, ...historicalCounts.take(2)];

    var momentum = 0.0;
    for (int i = 0; i < recentCounts.length - 1; i++) {
      final change = recentCounts[i] - recentCounts[i + 1];
      momentum += change * (recentCounts.length - i); // Weight recent changes more
    }

    return momentum / recentCounts.length;
  }

  /// Analyze category lifecycles
  Map<String, CategoryLifecycle> _analyzeCategoryLifecycles(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    final lifecycles = <String, CategoryLifecycle>{};

    // Analyze exercise categories
    _analyzeCategoryLifecyclesForType(
      currentReport.stats.exerciseCategories,
      historicalReports.map((r) => r.stats.exerciseCategories).toList(),
      CategoryType.exercise,
      lifecycles,
    );

    // Analyze diet categories
    _analyzeCategoryLifecyclesForType(
      currentReport.stats.dietCategories,
      historicalReports.map((r) => r.stats.dietCategories).toList(),
      CategoryType.diet,
      lifecycles,
    );

    return lifecycles;
  }

  /// Analyze category lifecycles for a specific type
  void _analyzeCategoryLifecyclesForType(
    Map<String, int> currentCategories,
    List<Map<String, int>> historicalCategories,
    CategoryType type,
    Map<String, CategoryLifecycle> lifecycles,
  ) {
    // Get all categories that have appeared at any point
    final allCategories = <String>{};
    allCategories.addAll(currentCategories.keys);
    for (final categories in historicalCategories) {
      allCategories.addAll(categories.keys);
    }

    for (final categoryName in allCategories) {
      final currentCount = currentCategories[categoryName] ?? 0;
      final historicalCounts = historicalCategories.map((categories) => categories[categoryName] ?? 0).toList();

      // Determine lifecycle stage
      final lifecycle = _determineCategoryLifecycle(categoryName, type, currentCount, historicalCounts);

      lifecycles[categoryName] = lifecycle;
    }
  }

  /// Determine the lifecycle stage of a category
  CategoryLifecycle _determineCategoryLifecycle(
    String categoryName,
    CategoryType type,
    int currentCount,
    List<int> historicalCounts,
  ) {
    final totalWeeks = historicalCounts.length + 1;
    final activeWeeks = historicalCounts.where((count) => count > 0).length + (currentCount > 0 ? 1 : 0);

    final activityRatio = activeWeeks / totalWeeks;
    final maxCount = math.max(currentCount, historicalCounts.isNotEmpty ? historicalCounts.reduce(math.max) : 0);

    // Determine lifecycle stage
    CategoryLifecycleStage stage;
    if (currentCount == 0 && historicalCounts.any((count) => count > 0)) {
      stage = CategoryLifecycleStage.dormant;
    } else if (activityRatio < 0.3) {
      stage = CategoryLifecycleStage.experimental;
    } else if (activityRatio < 0.7) {
      stage = CategoryLifecycleStage.developing;
    } else if (currentCount >= maxCount * 0.8) {
      stage = CategoryLifecycleStage.mature;
    } else {
      stage = CategoryLifecycleStage.declining;
    }

    return CategoryLifecycle(
      categoryName: categoryName,
      categoryType: type,
      stage: stage,
      activeWeeks: activeWeeks,
      totalWeeks: totalWeeks,
      activityRatio: activityRatio,
      peakCount: maxCount,
      currentCount: currentCount,
    );
  }

  /// Calculate emergence confidence
  double _calculateEmergenceConfidence(
    List<EmergingCategory> emergingCategories,
    List<DecliningCategory> decliningCategories,
    int weeksAnalyzed,
  ) {
    if (weeksAnalyzed < _minWeeksForAnalysis) {
      return 0.0;
    }

    // Base confidence on amount of data
    final dataConfidence = math.min(weeksAnalyzed / _maxWeeksForAnalysis, 1.0);

    // Adjust confidence based on pattern consistency
    final totalCategories = emergingCategories.length + decliningCategories.length;
    if (totalCategories == 0) {
      return dataConfidence * 0.5; // Lower confidence when no patterns detected
    }

    // Higher confidence when patterns are clear and consistent
    final avgEmergenceStrength =
        emergingCategories.isNotEmpty
            ? emergingCategories.map((c) => c.emergenceStrength).reduce((a, b) => a + b) / emergingCategories.length
            : 0.0;

    final avgDeclineStrength =
        decliningCategories.isNotEmpty
            ? decliningCategories.map((c) => c.declineStrength).reduce((a, b) => a + b) / decliningCategories.length
            : 0.0;

    final patternStrength = (avgEmergenceStrength + avgDeclineStrength) / 2;

    return dataConfidence * (0.5 + patternStrength * 0.5);
  }

  /// Analyze exercise preferences
  Map<String, PreferenceMetrics> _analyzeExercisePreferences(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    return _analyzePreferencesForType(
      currentReport.stats.exerciseCategories,
      historicalReports.map((r) => r.stats.exerciseCategories).toList(),
      CategoryType.exercise,
    );
  }

  /// Analyze diet preferences
  Map<String, PreferenceMetrics> _analyzeDietPreferences(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    return _analyzePreferencesForType(
      currentReport.stats.dietCategories,
      historicalReports.map((r) => r.stats.dietCategories).toList(),
      CategoryType.diet,
    );
  }

  /// Analyze preferences for a specific category type
  Map<String, PreferenceMetrics> _analyzePreferencesForType(
    Map<String, int> currentCategories,
    List<Map<String, int>> historicalCategories,
    CategoryType type,
  ) {
    final preferences = <String, PreferenceMetrics>{};

    // Get all categories
    final allCategories = <String>{};
    allCategories.addAll(currentCategories.keys);
    for (final categories in historicalCategories) {
      allCategories.addAll(categories.keys);
    }

    for (final categoryName in allCategories) {
      final currentCount = currentCategories[categoryName] ?? 0;
      final historicalCounts = historicalCategories.map((categories) => categories[categoryName] ?? 0).toList();

      // Calculate preference metrics
      final totalCount = currentCount + historicalCounts.fold<int>(0, (sum, count) => sum + count);
      final frequency = historicalCounts.where((count) => count > 0).length + (currentCount > 0 ? 1 : 0);
      final consistency = _calculatePreferenceConsistency(currentCount, historicalCounts);
      final intensity = totalCount.toDouble() / (historicalCounts.length + 1);

      preferences[categoryName] = PreferenceMetrics(
        categoryName: categoryName,
        categoryType: type,
        totalCount: totalCount,
        frequency: frequency,
        consistency: consistency,
        intensity: intensity,
        currentCount: currentCount,
        historicalAverage:
            historicalCounts.isNotEmpty ? historicalCounts.reduce((a, b) => a + b) / historicalCounts.length : 0.0,
      );
    }

    return preferences;
  }

  /// Calculate preference consistency
  double _calculatePreferenceConsistency(int currentCount, List<int> historicalCounts) {
    if (historicalCounts.isEmpty) {
      return currentCount > 0 ? 1.0 : 0.0;
    }

    final allCounts = [currentCount, ...historicalCounts];
    final mean = allCounts.reduce((a, b) => a + b) / allCounts.length;

    if (mean == 0) {
      return 0.0;
    }

    final variance = allCounts.map((count) => math.pow(count - mean, 2)).reduce((a, b) => a + b) / allCounts.length;

    // Consistency is inverse of coefficient of variation
    final coefficientOfVariation = math.sqrt(variance) / mean;
    return math.max(0.0, 1.0 - coefficientOfVariation);
  }

  /// Detect seasonal patterns
  Map<String, SeasonalPattern> _detectSeasonalPatterns(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    // This is a simplified implementation
    // In a real scenario, we would need more sophisticated seasonal analysis
    final patterns = <String, SeasonalPattern>{};

    // For now, return empty patterns as we need more data for seasonal analysis
    return patterns;
  }

  /// Analyze preference stability
  PreferenceStabilityMetrics _analyzePreferenceStability(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    if (historicalReports.isEmpty) {
      return PreferenceStabilityMetrics.empty();
    }

    // Calculate stability for exercise categories
    final exerciseStability = _calculateCategoryStability(
      currentReport.stats.exerciseCategories,
      historicalReports.map((r) => r.stats.exerciseCategories).toList(),
    );

    // Calculate stability for diet categories
    final dietStability = _calculateCategoryStability(
      currentReport.stats.dietCategories,
      historicalReports.map((r) => r.stats.dietCategories).toList(),
    );

    // Calculate overall stability
    final overallStability = (exerciseStability + dietStability) / 2;

    return PreferenceStabilityMetrics(
      overallStability: overallStability,
      exerciseStability: exerciseStability,
      dietStability: dietStability,
      stabilityTrend: TrendDirection.stable, // Simplified for now
      weeksAnalyzed: historicalReports.length + 1,
    );
  }

  /// Calculate category stability
  double _calculateCategoryStability(Map<String, int> currentCategories, List<Map<String, int>> historicalCategories) {
    if (historicalCategories.isEmpty) {
      return 1.0;
    }

    // Calculate how much the category distribution changes over time
    var totalVariation = 0.0;
    var comparisons = 0;

    for (int i = 0; i < historicalCategories.length; i++) {
      final categories1 = i == 0 ? currentCategories : historicalCategories[i - 1];
      final categories2 = historicalCategories[i];

      final variation = _calculateDistributionVariation(categories1, categories2);
      totalVariation += variation;
      comparisons++;
    }

    final averageVariation = comparisons > 0 ? totalVariation / comparisons : 0.0;
    return math.max(0.0, 1.0 - averageVariation);
  }

  /// Calculate distribution variation between two category maps
  double _calculateDistributionVariation(Map<String, int> categories1, Map<String, int> categories2) {
    final allCategories = <String>{};
    allCategories.addAll(categories1.keys);
    allCategories.addAll(categories2.keys);

    if (allCategories.isEmpty) {
      return 0.0;
    }

    var totalVariation = 0.0;
    for (final category in allCategories) {
      final count1 = categories1[category] ?? 0;
      final count2 = categories2[category] ?? 0;
      totalVariation += (count1 - count2).abs();
    }

    final total1 = categories1.values.fold(0, (sum, count) => sum + count);
    final total2 = categories2.values.fold(0, (sum, count) => sum + count);
    final maxTotal = math.max(total1, total2);

    return maxTotal > 0 ? totalVariation / (2 * maxTotal) : 0.0;
  }

  /// Identify preference clusters
  List<PreferenceCluster> _identifyPreferenceClusters(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    // This is a simplified implementation
    // In a real scenario, we would use clustering algorithms
    final clusters = <PreferenceCluster>[];

    // For now, create basic clusters based on category types
    final exerciseCategories = currentReport.stats.exerciseCategories.keys.toList();
    final dietCategories = currentReport.stats.dietCategories.keys.toList();

    if (exerciseCategories.isNotEmpty) {
      clusters.add(
        PreferenceCluster(
          name: '운동 선호',
          categories: exerciseCategories,
          categoryType: CategoryType.exercise,
          strength: 0.8, // Simplified
          consistency: 0.7, // Simplified
        ),
      );
    }

    if (dietCategories.isNotEmpty) {
      clusters.add(
        PreferenceCluster(
          name: '식단 선호',
          categories: dietCategories,
          categoryType: CategoryType.diet,
          strength: 0.8, // Simplified
          consistency: 0.7, // Simplified
        ),
      );
    }

    return clusters;
  }

  /// Calculate diversity score
  double _calculateDiversityScore(WeeklyStats stats) {
    // Calculate Shannon diversity index for both exercise and diet categories
    final exerciseDiversity = _calculateShannonDiversity(stats.exerciseCategories);
    final dietDiversity = _calculateShannonDiversity(stats.dietCategories);

    // Combine diversities with equal weight
    return (exerciseDiversity + dietDiversity) / 2;
  }

  /// Calculate Shannon diversity index
  double _calculateShannonDiversity(Map<String, int> categories) {
    if (categories.isEmpty) {
      return 0.0;
    }

    final total = categories.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return 0.0;
    }

    var diversity = 0.0;
    for (final count in categories.values) {
      if (count > 0) {
        final proportion = count / total;
        diversity -= proportion * math.log(proportion) / math.ln2;
      }
    }

    return diversity;
  }

  /// Calculate diversity trend
  TrendDirection _calculateDiversityTrend(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    if (historicalReports.isEmpty) {
      return TrendDirection.stable;
    }

    final currentDiversity = _calculateDiversityScore(currentReport.stats);
    final previousDiversity = _calculateDiversityScore(historicalReports.first.stats);

    if (currentDiversity > previousDiversity * 1.1) {
      return TrendDirection.up;
    } else if (currentDiversity < previousDiversity * 0.9) {
      return TrendDirection.down;
    } else {
      return TrendDirection.stable;
    }
  }

  /// Generate diversity recommendations
  Future<List<DiversityRecommendation>> _generateDiversityRecommendations(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
    double currentDiversityScore,
  ) async {
    final recommendations = <DiversityRecommendation>[];

    // Analyze current diversity gaps
    final exerciseCategories = currentReport.stats.exerciseCategories;
    final dietCategories = currentReport.stats.dietCategories;

    // Recommend missing exercise categories
    final allExerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toSet();
    final missingExerciseCategories = allExerciseCategories.difference(exerciseCategories.keys.toSet());

    for (final missingCategory in missingExerciseCategories.take(3)) {
      recommendations.add(
        DiversityRecommendation(
          type: DiversityRecommendationType.addCategory,
          categoryName: missingCategory,
          categoryType: CategoryType.exercise,
          priority: RecommendationPriority.medium,
          reason: '$missingCategory 활동을 추가하여 운동 다양성을 높여보세요',
          expectedImpact: 0.1,
        ),
      );
    }

    // Recommend missing diet categories
    final allDietCategories = DietCategory.values.map((e) => e.displayName).toSet();
    final missingDietCategories = allDietCategories.difference(dietCategories.keys.toSet());

    for (final missingCategory in missingDietCategories.take(3)) {
      recommendations.add(
        DiversityRecommendation(
          type: DiversityRecommendationType.addCategory,
          categoryName: missingCategory,
          categoryType: CategoryType.diet,
          priority: RecommendationPriority.medium,
          reason: '$missingCategory 식단을 추가하여 식단 다양성을 높여보세요',
          expectedImpact: 0.1,
        ),
      );
    }

    // Recommend balancing existing categories
    final dominantExerciseCategory = exerciseCategories.entries.reduce((a, b) => a.value > b.value ? a : b);

    if (dominantExerciseCategory.value > exerciseCategories.values.fold(0, (sum, count) => sum + count) * 0.6) {
      recommendations.add(
        DiversityRecommendation(
          type: DiversityRecommendationType.balanceCategories,
          categoryName: dominantExerciseCategory.key,
          categoryType: CategoryType.exercise,
          priority: RecommendationPriority.high,
          reason: '${dominantExerciseCategory.key} 외에 다른 운동도 균형있게 해보세요',
          expectedImpact: 0.2,
        ),
      );
    }

    return recommendations;
  }

  /// Calculate diversity balance
  DiversityBalance _calculateDiversityBalance(WeeklyStats stats) {
    final exerciseBalance = _calculateCategoryBalance(stats.exerciseCategories);
    final dietBalance = _calculateCategoryBalance(stats.dietCategories);

    return DiversityBalance(
      overallBalance: (exerciseBalance + dietBalance) / 2,
      exerciseBalance: exerciseBalance,
      dietBalance: dietBalance,
      balanceScore: _calculateBalanceScore(stats),
    );
  }

  /// Calculate category balance
  double _calculateCategoryBalance(Map<String, int> categories) {
    if (categories.isEmpty || categories.length == 1) {
      return categories.isNotEmpty ? 0.5 : 0.0;
    }

    final total = categories.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return 0.0;
    }

    // Calculate how evenly distributed the categories are
    final expectedProportion = 1.0 / categories.length;
    var balanceScore = 0.0;

    for (final count in categories.values) {
      final actualProportion = count / total;
      final deviation = (actualProportion - expectedProportion).abs();
      balanceScore += 1.0 - deviation;
    }

    return balanceScore / categories.length;
  }

  /// Calculate balance score
  double _calculateBalanceScore(WeeklyStats stats) {
    // Balance between exercise and diet activities
    final totalExercise = stats.exerciseCategories.values.fold(0, (sum, count) => sum + count);
    final totalDiet = stats.dietCategories.values.fold(0, (sum, count) => sum + count);
    final total = totalExercise + totalDiet;

    if (total == 0) {
      return 0.0;
    }

    final exerciseProportion = totalExercise / total;
    final idealProportion = 0.5; // Ideal 50-50 balance

    return 1.0 - (exerciseProportion - idealProportion).abs() * 2;
  }

  /// Analyze diversity patterns
  List<DiversityPattern> _analyzeDiversityPatterns(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    final patterns = <DiversityPattern>[];

    if (historicalReports.length < 3) {
      return patterns;
    }

    // Analyze diversity evolution over time
    final diversityScores = [
      _calculateDiversityScore(currentReport.stats),
      ...historicalReports.map((r) => _calculateDiversityScore(r.stats)),
    ];

    // Detect increasing diversity pattern
    if (_isIncreasingPattern(diversityScores)) {
      patterns.add(
        DiversityPattern(
          type: DiversityPatternType.increasing,
          strength: _calculatePatternStrength(diversityScores),
          description: '다양성이 지속적으로 증가하고 있습니다',
          weeksObserved: diversityScores.length,
        ),
      );
    }

    // Detect decreasing diversity pattern
    if (_isDecreasingPattern(diversityScores)) {
      patterns.add(
        DiversityPattern(
          type: DiversityPatternType.decreasing,
          strength: _calculatePatternStrength(diversityScores),
          description: '다양성이 감소하는 경향을 보입니다',
          weeksObserved: diversityScores.length,
        ),
      );
    }

    // Detect cyclical pattern
    if (_isCyclicalPattern(diversityScores)) {
      patterns.add(
        DiversityPattern(
          type: DiversityPatternType.cyclical,
          strength: _calculatePatternStrength(diversityScores),
          description: '다양성이 주기적으로 변화합니다',
          weeksObserved: diversityScores.length,
        ),
      );
    }

    return patterns;
  }

  /// Check if pattern is increasing
  bool _isIncreasingPattern(List<double> values) {
    if (values.length < 3) return false;

    var increasingCount = 0;
    for (int i = 0; i < values.length - 1; i++) {
      if (values[i] > values[i + 1]) {
        increasingCount++;
      }
    }

    return increasingCount >= (values.length - 1) * 0.7;
  }

  /// Check if pattern is decreasing
  bool _isDecreasingPattern(List<double> values) {
    if (values.length < 3) return false;

    var decreasingCount = 0;
    for (int i = 0; i < values.length - 1; i++) {
      if (values[i] < values[i + 1]) {
        decreasingCount++;
      }
    }

    return decreasingCount >= (values.length - 1) * 0.7;
  }

  /// Check if pattern is cyclical
  bool _isCyclicalPattern(List<double> values) {
    // Simplified cyclical detection
    if (values.length < 4) return false;

    var directionChanges = 0;
    for (int i = 1; i < values.length - 1; i++) {
      final prevDiff = values[i - 1] - values[i];
      final nextDiff = values[i] - values[i + 1];

      if ((prevDiff > 0 && nextDiff < 0) || (prevDiff < 0 && nextDiff > 0)) {
        directionChanges++;
      }
    }

    return directionChanges >= 2;
  }

  /// Calculate pattern strength
  double _calculatePatternStrength(List<double> values) {
    if (values.length < 2) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((value) => math.pow(value - mean, 2)).reduce((a, b) => a + b) / values.length;

    return math.min(1.0, math.sqrt(variance));
  }

  /// Calculate optimal diversity targets
  OptimalDiversityTargets _calculateOptimalDiversityTargets(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    // Calculate target based on user's historical performance and best practices
    final currentDiversity = _calculateDiversityScore(currentReport.stats);

    // Calculate historical best
    final historicalDiversities = historicalReports.map((r) => _calculateDiversityScore(r.stats)).toList();

    final historicalBest = historicalDiversities.isNotEmpty ? historicalDiversities.reduce(math.max) : currentDiversity;

    // Set targets slightly above current performance
    final shortTermTarget = math.min(1.0, currentDiversity * 1.1);
    final longTermTarget = math.min(1.0, math.max(historicalBest, currentDiversity * 1.3));

    return OptimalDiversityTargets(
      currentScore: currentDiversity,
      shortTermTarget: shortTermTarget,
      longTermTarget: longTermTarget,
      optimalExerciseCategories: 4, // Recommended number of exercise categories
      optimalDietCategories: 5, // Recommended number of diet categories
      targetBalance: 0.8, // Target balance score
    );
  }
}

// Helper class for overall trend metrics
class _OverallTrendMetrics {
  final TrendDirection overallDirection;
  final double strength;
  final double confidence;

  const _OverallTrendMetrics({required this.overallDirection, required this.strength, required this.confidence});
}
