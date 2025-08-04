import 'dart:developer';
import 'dart:math' as math;

import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_predictive_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';

/// Service for category-based predictive analytics and recommendations
class CategoryPredictiveAnalyticsService {
  static final CategoryPredictiveAnalyticsService _instance = CategoryPredictiveAnalyticsService._internal();
  static CategoryPredictiveAnalyticsService get instance => _instance;
  CategoryPredictiveAnalyticsService._internal();

  /// Minimum weeks required for reliable predictions
  static const int _minWeeksForPrediction = 3;

  /// Maximum weeks to consider for prediction analysis
  static const int _maxWeeksForPrediction = 12;

  /// Confidence threshold for making predictions
  static const double _predictionConfidenceThreshold = 0.6;

  /// Create category preference prediction algorithms
  Future<CategoryPreferencePrediction> predictCategoryPreferences(
    List<WeeklyReport> historicalReports, {
    int weeksAhead = 4,
  }) async {
    log('[CategoryPredictiveAnalyticsService] Predicting category preferences for $weeksAhead weeks ahead');

    if (historicalReports.length < _minWeeksForPrediction) {
      return CategoryPreferencePrediction.empty();
    }

    try {
      // Sort reports by date (oldest first for time series analysis)
      final sortedReports = List<WeeklyReport>.from(historicalReports)
        ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

      // Limit analysis to reasonable timeframe
      final reportsToAnalyze =
          sortedReports.length > _maxWeeksForPrediction
              ? sortedReports.sublist(sortedReports.length - _maxWeeksForPrediction)
              : sortedReports;

      // Predict exercise category preferences
      final exercisePredictions = await _predictExerciseCategoryPreferences(reportsToAnalyze, weeksAhead);

      // Predict diet category preferences
      final dietPredictions = await _predictDietCategoryPreferences(reportsToAnalyze, weeksAhead);

      // Calculate prediction confidence
      final confidence = _calculatePredictionConfidence(reportsToAnalyze);

      // Generate preference insights
      final insights = _generatePreferenceInsights(exercisePredictions, dietPredictions, confidence);

      return CategoryPreferencePrediction(
        exercisePredictions: exercisePredictions,
        dietPredictions: dietPredictions,
        predictionConfidence: confidence,
        weeksAhead: weeksAhead,
        insights: insights,
        analysisDate: DateTime.now(),
        weeksAnalyzed: reportsToAnalyze.length,
      );
    } catch (e, stackTrace) {
      log('[CategoryPredictiveAnalyticsService] Error predicting category preferences: $e', stackTrace: stackTrace);
      return CategoryPreferencePrediction.empty();
    }
  }

  /// Add seasonal category trend forecasting
  Future<SeasonalCategoryForecast> forecastSeasonalCategoryTrends(
    List<WeeklyReport> historicalReports,
    DateTime targetDate,
  ) async {
    log('[CategoryPredictiveAnalyticsService] Forecasting seasonal category trends for ${targetDate.toString()}');

    if (historicalReports.length < _minWeeksForPrediction) {
      return SeasonalCategoryForecast.empty();
    }

    try {
      // Sort reports by date
      final sortedReports = List<WeeklyReport>.from(historicalReports)
        ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

      // Analyze seasonal patterns
      final seasonalPatterns = await _analyzeSeasonalPatterns(sortedReports);

      // Determine target season
      final targetSeason = _getSeason(targetDate);

      // Generate seasonal forecasts
      final exerciseForecasts = _generateSeasonalExerciseForecasts(seasonalPatterns, targetSeason);
      final dietForecasts = _generateSeasonalDietForecasts(seasonalPatterns, targetSeason);

      // Calculate forecast confidence
      final confidence = _calculateSeasonalForecastConfidence(sortedReports, targetDate);

      // Generate seasonal recommendations
      final recommendations = _generateSeasonalRecommendations(
        exerciseForecasts,
        dietForecasts,
        targetSeason,
        confidence,
      );

      return SeasonalCategoryForecast(
        targetDate: targetDate,
        targetSeason: targetSeason,
        exerciseForecasts: exerciseForecasts,
        dietForecasts: dietForecasts,
        seasonalPatterns: seasonalPatterns,
        forecastConfidence: confidence,
        recommendations: recommendations,
        analysisDate: DateTime.now(),
        weeksAnalyzed: sortedReports.length,
      );
    } catch (e, stackTrace) {
      log('[CategoryPredictiveAnalyticsService] Error forecasting seasonal trends: $e', stackTrace: stackTrace);
      return SeasonalCategoryForecast.empty();
    }
  }

  /// Implement category-based activity suggestions
  Future<CategoryActivitySuggestions> generateCategoryBasedActivitySuggestions(
    List<WeeklyReport> historicalReports,
    WeeklyReport? currentReport,
  ) async {
    log('[CategoryPredictiveAnalyticsService] Generating category-based activity suggestions');

    if (historicalReports.isEmpty) {
      return CategoryActivitySuggestions.empty();
    }

    try {
      // Analyze current category patterns
      final categoryPatterns = await _analyzeCategoryPatterns(historicalReports, currentReport);

      // Generate exercise suggestions
      final exerciseSuggestions = await _generateExerciseSuggestions(categoryPatterns, currentReport);

      // Generate diet suggestions
      final dietSuggestions = await _generateDietSuggestions(categoryPatterns, currentReport);

      // Generate timing suggestions
      final timingSuggestions = _generateTimingSuggestions(historicalReports, currentReport);

      // Calculate suggestion confidence
      final confidence = _calculateSuggestionConfidence(historicalReports, categoryPatterns);

      return CategoryActivitySuggestions(
        exerciseSuggestions: exerciseSuggestions,
        dietSuggestions: dietSuggestions,
        timingSuggestions: timingSuggestions,
        suggestionConfidence: confidence,
        analysisDate: DateTime.now(),
        weeksAnalyzed: historicalReports.length,
      );
    } catch (e, stackTrace) {
      log('[CategoryPredictiveAnalyticsService] Error generating activity suggestions: $e', stackTrace: stackTrace);
      return CategoryActivitySuggestions.empty();
    }
  }

  /// Create category optimization recommendations
  Future<CategoryOptimizationRecommendations> generateCategoryOptimizationRecommendations(
    List<WeeklyReport> historicalReports,
    WeeklyReport? currentReport,
  ) async {
    log('[CategoryPredictiveAnalyticsService] Generating category optimization recommendations');

    if (historicalReports.isEmpty) {
      return CategoryOptimizationRecommendations.empty();
    }

    try {
      // Analyze current category balance
      final balanceAnalysis = await _analyzeCategoryBalance(historicalReports, currentReport);

      // Identify optimization opportunities
      final optimizationOpportunities = await _identifyOptimizationOpportunities(balanceAnalysis, historicalReports);

      // Generate specific recommendations
      final recommendations = await _generateOptimizationRecommendations(
        optimizationOpportunities,
        balanceAnalysis,
        historicalReports,
      );

      // Calculate expected outcomes
      final expectedOutcomes = _calculateExpectedOutcomes(recommendations, balanceAnalysis);

      // Prioritize recommendations
      final prioritizedRecommendations = _prioritizeRecommendations(recommendations, expectedOutcomes);

      return CategoryOptimizationRecommendations(
        recommendations: prioritizedRecommendations,
        optimizationOpportunities: optimizationOpportunities,
        expectedOutcomes: expectedOutcomes,
        currentBalance: balanceAnalysis,
        analysisDate: DateTime.now(),
        weeksAnalyzed: historicalReports.length,
      );
    } catch (e, stackTrace) {
      log(
        '[CategoryPredictiveAnalyticsService] Error generating optimization recommendations: $e',
        stackTrace: stackTrace,
      );
      return CategoryOptimizationRecommendations.empty();
    }
  }

  /// Implement analysis of category combinations and their effectiveness
  Future<CategoryCorrelationAnalysis> analyzeCategoryCorrelations(
    List<WeeklyReport> historicalReports,
    WeeklyReport? currentReport,
  ) async {
    log('[CategoryPredictiveAnalyticsService] Analyzing category correlations and combinations');

    if (historicalReports.length < _minWeeksForPrediction) {
      return CategoryCorrelationAnalysis.empty();
    }

    try {
      final allReports = currentReport != null ? [...historicalReports, currentReport] : historicalReports;

      // Calculate correlation matrices
      final exerciseCorrelations = await _calculateExerciseCategoryCorrelations(allReports);
      final dietCorrelations = await _calculateDietCategoryCorrelations(allReports);
      final crossTypeCorrelations = await _calculateCrossTypeCategoryCorrelations(allReports);

      // Identify effective combinations
      final effectiveCombinations = await _identifyEffectiveCategoryCombinations(
        allReports,
        exerciseCorrelations,
        dietCorrelations,
        crossTypeCorrelations,
      );

      // Generate synergy recommendations
      final synergyRecommendations = await _generateCategorySynergyRecommendations(
        effectiveCombinations,
        exerciseCorrelations,
        dietCorrelations,
        crossTypeCorrelations,
      );

      // Create balance optimization
      final balanceOptimization = await _createCategoryBalanceOptimization(allReports, effectiveCombinations);

      // Generate habit stacking recommendations
      final habitStackingRecommendations = await _generateHabitStackingRecommendations(
        allReports,
        effectiveCombinations,
        synergyRecommendations,
      );

      return CategoryCorrelationAnalysis(
        exerciseCorrelations: exerciseCorrelations,
        dietCorrelations: dietCorrelations,
        crossTypeCorrelations: crossTypeCorrelations,
        effectiveCombinations: effectiveCombinations,
        synergyRecommendations: synergyRecommendations,
        balanceOptimization: balanceOptimization,
        habitStackingRecommendations: habitStackingRecommendations,
        analysisDate: DateTime.now(),
        weeksAnalyzed: allReports.length,
      );
    } catch (e, stackTrace) {
      log('[CategoryPredictiveAnalyticsService] Error analyzing category correlations: $e', stackTrace: stackTrace);
      return CategoryCorrelationAnalysis.empty();
    }
  }

  // Private helper methods for exercise category preference prediction
  Future<Map<String, CategoryPreferenceMetrics>> _predictExerciseCategoryPreferences(
    List<WeeklyReport> reports,
    int weeksAhead,
  ) async {
    final predictions = <String, CategoryPreferenceMetrics>{};

    for (final category in ExerciseCategory.values) {
      final categoryName = category.displayName;
      final historicalData = reports.map((r) => r.stats.exerciseCategories[categoryName] ?? 0).toList();

      final prediction = _predictCategoryPreference(categoryName, CategoryType.exercise, historicalData, weeksAhead);
      predictions[categoryName] = prediction;
    }

    return predictions;
  }

  Future<Map<String, CategoryPreferenceMetrics>> _predictDietCategoryPreferences(
    List<WeeklyReport> reports,
    int weeksAhead,
  ) async {
    final predictions = <String, CategoryPreferenceMetrics>{};

    for (final category in DietCategory.values) {
      final categoryName = category.displayName;
      final historicalData = reports.map((r) => r.stats.dietCategories[categoryName] ?? 0).toList();

      final prediction = _predictCategoryPreference(categoryName, CategoryType.diet, historicalData, weeksAhead);
      predictions[categoryName] = prediction;
    }

    return predictions;
  }

  CategoryPreferenceMetrics _predictCategoryPreference(
    String categoryName,
    CategoryType type,
    List<int> historicalData,
    int weeksAhead,
  ) {
    if (historicalData.length < 2) {
      return CategoryPreferenceMetrics.empty(categoryName, type);
    }

    // Calculate trend using linear regression
    final trend = _calculateLinearTrend(historicalData);

    // Calculate seasonal adjustment
    final seasonalAdjustment = _calculateSeasonalAdjustment(historicalData);

    // Predict future values
    final predictedValue = _predictFutureValue(historicalData, trend, seasonalAdjustment, weeksAhead);

    // Calculate prediction confidence
    final confidence = _calculateCategoryPredictionConfidence(historicalData, trend);

    // Calculate preference strength
    final preferenceStrength = _calculatePreferenceStrength(historicalData, predictedValue);

    return CategoryPreferenceMetrics(
      categoryName: categoryName,
      categoryType: type,
      predictedValue: predictedValue,
      confidence: confidence,
      trend: trend,
      preferenceStrength: preferenceStrength,
      historicalAverage: historicalData.reduce((a, b) => a + b) / historicalData.length,
      volatility: _calculateVolatility(historicalData),
    );
  }

  double _calculateLinearTrend(List<int> data) {
    if (data.length < 2) return 0.0;

    final n = data.length;
    final xSum = (n * (n - 1)) / 2;
    final ySum = data.reduce((a, b) => a + b);
    final xySum = data.asMap().entries.fold(0.0, (sum, entry) => sum + entry.key * entry.value);
    final xSquaredSum = (n * (n - 1) * (2 * n - 1)) / 6;

    if (n * xSquaredSum - xSum * xSum == 0) return 0.0;

    return (n * xySum - xSum * ySum) / (n * xSquaredSum - xSum * xSum);
  }

  double _calculateSeasonalAdjustment(List<int> data) {
    // Simplified seasonal adjustment - in a real implementation,
    // this would use more sophisticated seasonal decomposition
    if (data.length < 4) return 0.0;

    final recentQuarter = data.sublist(data.length - 4);
    final previousQuarter = data.length >= 8 ? data.sublist(data.length - 8, data.length - 4) : data.sublist(0, 4);

    final recentAvg = recentQuarter.reduce((a, b) => a + b) / recentQuarter.length;
    final previousAvg = previousQuarter.reduce((a, b) => a + b) / previousQuarter.length;

    return previousAvg > 0 ? (recentAvg - previousAvg) / previousAvg : 0.0;
  }

  double _predictFutureValue(List<int> data, double trend, double seasonalAdjustment, int weeksAhead) {
    final lastValue = data.last.toDouble();
    final trendComponent = trend * weeksAhead;
    final seasonalComponent = seasonalAdjustment * lastValue * 0.1; // Dampen seasonal effect

    return math.max(0.0, lastValue + trendComponent + seasonalComponent);
  }

  double _calculateCategoryPredictionConfidence(List<int> data, double trend) {
    if (data.length < 3) return 0.3;

    // Base confidence on data consistency and trend strength
    final volatility = _calculateVolatility(data);
    final mean = data.reduce((a, b) => a + b) / data.length;

    final consistencyScore = mean > 0 ? math.max(0.0, 1.0 - volatility / mean) : 0.0;
    final trendStrength = trend.abs() / (mean + 1); // Avoid division by zero

    final baseConfidence = math.min(data.length / _maxWeeksForPrediction, 1.0);

    return (baseConfidence + consistencyScore + math.min(trendStrength, 1.0)) / 3;
  }

  double _calculatePreferenceStrength(List<int> data, double predictedValue) {
    final mean = data.reduce((a, b) => a + b) / data.length;
    final maxValue = data.reduce(math.max).toDouble();

    if (maxValue == 0) return 0.0;

    // Preference strength based on consistency and predicted value
    final consistencyScore = mean / maxValue;
    final predictionScore = predictedValue / maxValue;

    return (consistencyScore + predictionScore) / 2;
  }

  double _calculateVolatility(List<int> data) {
    if (data.length < 2) return 0.0;

    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.fold(0.0, (sum, value) => sum + math.pow(value - mean, 2)) / data.length;

    return math.sqrt(variance);
  }

  double _calculatePredictionConfidence(List<WeeklyReport> reports) {
    if (reports.length < _minWeeksForPrediction) return 0.0;

    // Base confidence on data quantity and quality
    final dataQuantityScore = math.min(reports.length / _maxWeeksForPrediction, 1.0);
    final dataQualityScore = reports.where((r) => r.hasSufficientData).length / reports.length;

    return (dataQuantityScore + dataQualityScore) / 2;
  }

  List<PreferenceInsight> _generatePreferenceInsights(
    Map<String, CategoryPreferenceMetrics> exercisePredictions,
    Map<String, CategoryPreferenceMetrics> dietPredictions,
    double confidence,
  ) {
    final insights = <PreferenceInsight>[];

    if (confidence < _predictionConfidenceThreshold) {
      insights.add(
        PreferenceInsight(
          type: PreferenceInsightType.warning,
          message: '예측 신뢰도가 낮습니다. 더 많은 데이터가 필요합니다.',
          category: '전체',
          confidence: confidence,
        ),
      );
      return insights;
    }

    // Find strongest predicted preferences
    final strongExercisePreferences =
        exercisePredictions.entries.where((e) => e.value.preferenceStrength > 0.7).map((e) => e.key).toList();

    final strongDietPreferences =
        dietPredictions.entries.where((e) => e.value.preferenceStrength > 0.7).map((e) => e.key).toList();

    if (strongExercisePreferences.isNotEmpty) {
      insights.add(
        PreferenceInsight(
          type: PreferenceInsightType.positive,
          message: '${strongExercisePreferences.join(", ")} 운동을 지속적으로 선호할 것으로 예상됩니다.',
          category: '운동',
          confidence: confidence,
        ),
      );
    }

    if (strongDietPreferences.isNotEmpty) {
      insights.add(
        PreferenceInsight(
          type: PreferenceInsightType.positive,
          message: '${strongDietPreferences.join(", ")} 식단을 지속적으로 선호할 것으로 예상됩니다.',
          category: '식단',
          confidence: confidence,
        ),
      );
    }

    return insights;
  }

  // Seasonal forecasting methods
  Future<Map<String, SeasonalCategoryPattern>> _analyzeSeasonalPatterns(List<WeeklyReport> reports) async {
    final patterns = <String, SeasonalCategoryPattern>{};

    // Group reports by month
    final monthlyData = <int, List<WeeklyReport>>{};
    for (final report in reports) {
      final month = report.weekStartDate.month;
      monthlyData.putIfAbsent(month, () => []).add(report);
    }

    // Analyze exercise categories
    for (final category in ExerciseCategory.values) {
      final pattern = _analyzeSeasonalPatternForCategory(
        category.displayName,
        CategoryType.exercise,
        monthlyData,
        (report) => report.stats.exerciseCategories[category.displayName] ?? 0,
      );
      patterns[category.displayName] = pattern;
    }

    // Analyze diet categories
    for (final category in DietCategory.values) {
      final pattern = _analyzeSeasonalPatternForCategory(
        category.displayName,
        CategoryType.diet,
        monthlyData,
        (report) => report.stats.dietCategories[category.displayName] ?? 0,
      );
      patterns[category.displayName] = pattern;
    }

    return patterns;
  }

  SeasonalCategoryPattern _analyzeSeasonalPatternForCategory(
    String categoryName,
    CategoryType type,
    Map<int, List<WeeklyReport>> monthlyData,
    int Function(WeeklyReport) valueExtractor,
  ) {
    final monthlyAverages = <int, double>{};
    final monthlyVariability = <int, double>{};

    for (final entry in monthlyData.entries) {
      final month = entry.key;
      final reports = entry.value;

      if (reports.isNotEmpty) {
        final values = reports.map(valueExtractor).toList();
        final average = values.reduce((a, b) => a + b) / values.length;
        final variance = values.fold(0.0, (sum, value) => sum + math.pow(value - average, 2)) / values.length;

        monthlyAverages[month] = average;
        monthlyVariability[month] = math.sqrt(variance);
      }
    }

    // Determine peak and low seasons
    final peakMonth =
        monthlyAverages.entries.isNotEmpty
            ? monthlyAverages.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 1;

    final lowMonth =
        monthlyAverages.entries.isNotEmpty
            ? monthlyAverages.entries.reduce((a, b) => a.value < b.value ? a : b).key
            : 1;

    // Calculate seasonal strength
    final seasonalStrength = _calculateSeasonalStrength(monthlyAverages);

    return SeasonalCategoryPattern(
      categoryName: categoryName,
      categoryType: type,
      monthlyAverages: monthlyAverages,
      monthlyVariability: monthlyVariability,
      peakMonth: peakMonth,
      lowMonth: lowMonth,
      seasonalStrength: seasonalStrength,
    );
  }

  double _calculateSeasonalStrength(Map<int, double> monthlyAverages) {
    if (monthlyAverages.length < 2) return 0.0;

    final values = monthlyAverages.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;

    if (mean == 0) return 0.0;

    final variance = values.fold(0.0, (sum, value) => sum + math.pow(value - mean, 2)) / values.length;
    return math.sqrt(variance) / mean;
  }

  Season _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  Map<String, SeasonalCategoryForecastItem> _generateSeasonalExerciseForecasts(
    Map<String, SeasonalCategoryPattern> patterns,
    Season targetSeason,
  ) {
    final forecasts = <String, SeasonalCategoryForecastItem>{};
    final targetMonths = _getSeasonMonths(targetSeason);

    for (final entry in patterns.entries) {
      final categoryName = entry.key;
      final pattern = entry.value;

      if (pattern.categoryType != CategoryType.exercise) continue;

      final forecastValue = _calculateSeasonalForecast(pattern, targetMonths);
      final confidence = _calculateSeasonalForecastConfidenceForCategory(pattern);

      forecasts[categoryName] = SeasonalCategoryForecastItem(
        categoryName: categoryName,
        categoryType: CategoryType.exercise,
        forecastValue: forecastValue,
        confidence: confidence,
        targetSeason: targetSeason,
        seasonalPattern: pattern,
      );
    }

    return forecasts;
  }

  Map<String, SeasonalCategoryForecastItem> _generateSeasonalDietForecasts(
    Map<String, SeasonalCategoryPattern> patterns,
    Season targetSeason,
  ) {
    final forecasts = <String, SeasonalCategoryForecastItem>{};
    final targetMonths = _getSeasonMonths(targetSeason);

    for (final entry in patterns.entries) {
      final categoryName = entry.key;
      final pattern = entry.value;

      if (pattern.categoryType != CategoryType.diet) continue;

      final forecastValue = _calculateSeasonalForecast(pattern, targetMonths);
      final confidence = _calculateSeasonalForecastConfidenceForCategory(pattern);

      forecasts[categoryName] = SeasonalCategoryForecastItem(
        categoryName: categoryName,
        categoryType: CategoryType.diet,
        forecastValue: forecastValue,
        confidence: confidence,
        targetSeason: targetSeason,
        seasonalPattern: pattern,
      );
    }

    return forecasts;
  }

  List<int> _getSeasonMonths(Season season) {
    switch (season) {
      case Season.spring:
        return [3, 4, 5];
      case Season.summer:
        return [6, 7, 8];
      case Season.autumn:
        return [9, 10, 11];
      case Season.winter:
        return [12, 1, 2];
    }
  }

  double _calculateSeasonalForecast(SeasonalCategoryPattern pattern, List<int> targetMonths) {
    final relevantAverages =
        targetMonths.map((month) => pattern.monthlyAverages[month] ?? 0.0).where((avg) => avg > 0).toList();

    if (relevantAverages.isEmpty) return 0.0;

    return relevantAverages.reduce((a, b) => a + b) / relevantAverages.length;
  }

  double _calculateSeasonalForecastConfidence(List<WeeklyReport> reports, DateTime targetDate) {
    // Calculate confidence based on historical data coverage
    final yearsOfData =
        reports.isNotEmpty ? (reports.last.weekStartDate.year - reports.first.weekStartDate.year) + 1 : 0;

    final dataConfidence = math.min(yearsOfData / 2.0, 1.0); // Max confidence with 2+ years

    // Adjust for data recency
    final daysSinceLastReport = reports.isNotEmpty ? DateTime.now().difference(reports.last.weekStartDate).inDays : 365;

    final recencyScore = math.max(0.0, 1.0 - daysSinceLastReport / 365);

    return (dataConfidence + recencyScore) / 2;
  }

  double _calculateSeasonalForecastConfidenceForCategory(SeasonalCategoryPattern pattern) {
    // Confidence based on seasonal strength and data availability
    final dataAvailability = pattern.monthlyAverages.length / 12.0;
    final seasonalConsistency = 1.0 - pattern.seasonalStrength; // Lower variability = higher confidence

    return (dataAvailability + seasonalConsistency) / 2;
  }

  List<SeasonalRecommendation> _generateSeasonalRecommendations(
    Map<String, SeasonalCategoryForecastItem> exerciseForecasts,
    Map<String, SeasonalCategoryForecastItem> dietForecasts,
    Season targetSeason,
    double confidence,
  ) {
    final recommendations = <SeasonalRecommendation>[];

    if (confidence < _predictionConfidenceThreshold) {
      return recommendations;
    }

    // Find categories with high seasonal forecasts
    final highExerciseForecasts =
        exerciseForecasts.entries.where((e) => e.value.forecastValue > 2.0 && e.value.confidence > 0.6).toList();

    final highDietForecasts =
        dietForecasts.entries.where((e) => e.value.forecastValue > 2.0 && e.value.confidence > 0.6).toList();

    for (final forecast in highExerciseForecasts) {
      recommendations.add(
        SeasonalRecommendation(
          categoryName: forecast.key,
          categoryType: CategoryType.exercise,
          recommendationType: SeasonalRecommendationType.increase,
          targetSeason: targetSeason,
          message: '${_getSeasonName(targetSeason)}에는 ${forecast.key} 운동이 활발해질 것으로 예상됩니다.',
          confidence: forecast.value.confidence,
        ),
      );
    }

    for (final forecast in highDietForecasts) {
      recommendations.add(
        SeasonalRecommendation(
          categoryName: forecast.key,
          categoryType: CategoryType.diet,
          recommendationType: SeasonalRecommendationType.increase,
          targetSeason: targetSeason,
          message: '${_getSeasonName(targetSeason)}에는 ${forecast.key} 식단을 더 자주 선택할 것으로 예상됩니다.',
          confidence: forecast.value.confidence,
        ),
      );
    }

    return recommendations;
  }

  String _getSeasonName(Season season) {
    switch (season) {
      case Season.spring:
        return '봄';
      case Season.summer:
        return '여름';
      case Season.autumn:
        return '가을';
      case Season.winter:
        return '겨울';
    }
  }

  // Activity suggestion methods
  Future<CategoryPatternAnalysis> _analyzeCategoryPatterns(
    List<WeeklyReport> historicalReports,
    WeeklyReport? currentReport,
  ) async {
    // Analyze patterns in category usage
    final exercisePatterns = _analyzeCategoryPatternsForType(
      historicalReports,
      currentReport,
      CategoryType.exercise,
      (report) => report.stats.exerciseCategories,
    );

    final dietPatterns = _analyzeCategoryPatternsForType(
      historicalReports,
      currentReport,
      CategoryType.diet,
      (report) => report.stats.dietCategories,
    );

    return CategoryPatternAnalysis(
      exercisePatterns: exercisePatterns,
      dietPatterns: dietPatterns,
      analysisDate: DateTime.now(),
    );
  }

  Map<String, CategoryUsagePattern> _analyzeCategoryPatternsForType(
    List<WeeklyReport> historicalReports,
    WeeklyReport? currentReport,
    CategoryType type,
    Map<String, int> Function(WeeklyReport) categoryExtractor,
  ) {
    final patterns = <String, CategoryUsagePattern>{};
    final allReports = currentReport != null ? [...historicalReports, currentReport] : historicalReports;

    // Get all categories that have appeared
    final allCategories = <String>{};
    for (final report in allReports) {
      allCategories.addAll(categoryExtractor(report).keys);
    }

    for (final categoryName in allCategories) {
      final usageData = allReports.map((report) => categoryExtractor(report)[categoryName] ?? 0).toList();

      final pattern = CategoryUsagePattern(
        categoryName: categoryName,
        categoryType: type,
        usageFrequency: usageData.where((count) => count > 0).length / allReports.length,
        averageUsage: usageData.reduce((a, b) => a + b) / usageData.length,
        peakUsage: usageData.reduce(math.max),
        consistency: _calculateUsageConsistency(usageData),
        trend: _calculateUsageTrend(usageData),
      );

      patterns[categoryName] = pattern;
    }

    return patterns;
  }

  double _calculateUsageConsistency(List<int> usageData) {
    if (usageData.length < 2) return 1.0;

    final mean = usageData.reduce((a, b) => a + b) / usageData.length;
    if (mean == 0) return 0.0;

    final variance = usageData.fold(0.0, (sum, value) => sum + math.pow(value - mean, 2)) / usageData.length;
    final coefficientOfVariation = math.sqrt(variance) / mean;

    return math.max(0.0, 1.0 - coefficientOfVariation);
  }

  double _calculateUsageTrend(List<int> usageData) {
    if (usageData.length < 2) return 0.0;

    final recentHalf = usageData.sublist(usageData.length ~/ 2);
    final earlierHalf = usageData.sublist(0, usageData.length ~/ 2);

    final recentAvg = recentHalf.reduce((a, b) => a + b) / recentHalf.length;
    final earlierAvg = earlierHalf.reduce((a, b) => a + b) / earlierHalf.length;

    return earlierAvg > 0 ? (recentAvg - earlierAvg) / earlierAvg : 0.0;
  }

  Future<List<CategoryActivitySuggestion>> _generateExerciseSuggestions(
    CategoryPatternAnalysis patterns,
    WeeklyReport? currentReport,
  ) async {
    final suggestions = <CategoryActivitySuggestion>[];

    for (final entry in patterns.exercisePatterns.entries) {
      final categoryName = entry.key;
      final pattern = entry.value;

      // Suggest based on usage patterns
      if (pattern.usageFrequency > 0.5 && pattern.trend < -0.2) {
        suggestions.add(
          CategoryActivitySuggestion(
            categoryName: categoryName,
            categoryType: CategoryType.exercise,
            suggestionType: ActivitySuggestionType.revive,
            message: '최근 $categoryName 운동이 줄어들었습니다. 다시 시작해보세요!',
            priority: SuggestionPriority.medium,
            confidence: pattern.consistency,
          ),
        );
      } else if (pattern.usageFrequency < 0.3 && pattern.averageUsage > 0) {
        suggestions.add(
          CategoryActivitySuggestion(
            categoryName: categoryName,
            categoryType: CategoryType.exercise,
            suggestionType: ActivitySuggestionType.explore,
            message: '$categoryName 운동을 더 자주 시도해보세요.',
            priority: SuggestionPriority.low,
            confidence: pattern.consistency,
          ),
        );
      } else if (pattern.trend > 0.3) {
        suggestions.add(
          CategoryActivitySuggestion(
            categoryName: categoryName,
            categoryType: CategoryType.exercise,
            suggestionType: ActivitySuggestionType.maintain,
            message: '$categoryName 운동을 잘 유지하고 있습니다. 계속하세요!',
            priority: SuggestionPriority.high,
            confidence: pattern.consistency,
          ),
        );
      }
    }

    return suggestions;
  }

  Future<List<CategoryActivitySuggestion>> _generateDietSuggestions(
    CategoryPatternAnalysis patterns,
    WeeklyReport? currentReport,
  ) async {
    final suggestions = <CategoryActivitySuggestion>[];

    for (final entry in patterns.dietPatterns.entries) {
      final categoryName = entry.key;
      final pattern = entry.value;

      // Suggest based on usage patterns
      if (pattern.usageFrequency > 0.5 && pattern.trend < -0.2) {
        suggestions.add(
          CategoryActivitySuggestion(
            categoryName: categoryName,
            categoryType: CategoryType.diet,
            suggestionType: ActivitySuggestionType.revive,
            message: '최근 $categoryName 식단이 줄어들었습니다. 균형을 위해 다시 시도해보세요.',
            priority: SuggestionPriority.medium,
            confidence: pattern.consistency,
          ),
        );
      } else if (pattern.usageFrequency < 0.3 && pattern.averageUsage > 0) {
        suggestions.add(
          CategoryActivitySuggestion(
            categoryName: categoryName,
            categoryType: CategoryType.diet,
            suggestionType: ActivitySuggestionType.explore,
            message: '$categoryName 식단을 더 자주 시도해보세요.',
            priority: SuggestionPriority.low,
            confidence: pattern.consistency,
          ),
        );
      } else if (pattern.trend > 0.3) {
        suggestions.add(
          CategoryActivitySuggestion(
            categoryName: categoryName,
            categoryType: CategoryType.diet,
            suggestionType: ActivitySuggestionType.maintain,
            message: '$categoryName 식단을 잘 유지하고 있습니다. 계속하세요!',
            priority: SuggestionPriority.high,
            confidence: pattern.consistency,
          ),
        );
      }
    }

    return suggestions;
  }

  List<TimingSuggestion> _generateTimingSuggestions(List<WeeklyReport> historicalReports, WeeklyReport? currentReport) {
    final suggestions = <TimingSuggestion>[];

    // Analyze day-of-week patterns
    final dayPatterns = _analyzeDayOfWeekPatterns(historicalReports, currentReport);

    // Generate timing suggestions based on patterns
    for (final entry in dayPatterns.entries) {
      final dayOfWeek = entry.key;
      final activityLevel = entry.value;

      if (activityLevel < 0.3) {
        suggestions.add(
          TimingSuggestion(
            dayOfWeek: dayOfWeek,
            suggestionType: TimingSuggestionType.increase,
            message: '${_getDayName(dayOfWeek)}에 활동을 늘려보세요.',
            confidence: 0.7,
          ),
        );
      } else if (activityLevel > 0.8) {
        suggestions.add(
          TimingSuggestion(
            dayOfWeek: dayOfWeek,
            suggestionType: TimingSuggestionType.maintain,
            message: '${_getDayName(dayOfWeek)}의 활발한 활동을 유지하세요!',
            confidence: 0.8,
          ),
        );
      }
    }

    return suggestions;
  }

  Map<int, double> _analyzeDayOfWeekPatterns(List<WeeklyReport> historicalReports, WeeklyReport? currentReport) {
    // This is a simplified implementation
    // In a real scenario, we would need daily activity data
    final patterns = <int, double>{};

    for (int day = 1; day <= 7; day++) {
      // Placeholder logic - would need actual daily data
      patterns[day] = 0.5 + (math.Random().nextDouble() - 0.5) * 0.4;
    }

    return patterns;
  }

  String _getDayName(int dayOfWeek) {
    const dayNames = ['', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return dayNames[dayOfWeek];
  }

  double _calculateSuggestionConfidence(List<WeeklyReport> reports, CategoryPatternAnalysis patterns) {
    if (reports.length < _minWeeksForPrediction) return 0.3;

    final dataConfidence = math.min(reports.length / _maxWeeksForPrediction, 1.0);
    final patternConsistency = _calculatePatternConsistency(patterns);

    return (dataConfidence + patternConsistency) / 2;
  }

  double _calculatePatternConsistency(CategoryPatternAnalysis patterns) {
    final allPatterns = [...patterns.exercisePatterns.values, ...patterns.dietPatterns.values];
    if (allPatterns.isEmpty) return 0.0;

    final avgConsistency = allPatterns.fold(0.0, (sum, pattern) => sum + pattern.consistency) / allPatterns.length;
    return avgConsistency;
  }

  // Optimization recommendation methods
  Future<CategoryBalanceAnalysis> _analyzeCategoryBalance(
    List<WeeklyReport> historicalReports,
    WeeklyReport? currentReport,
  ) async {
    // Analyze current category balance
    final allReports = currentReport != null ? [...historicalReports, currentReport] : historicalReports;

    final exerciseBalance = _calculateExerciseBalance(allReports);
    final dietBalance = _calculateDietBalance(allReports);
    final overallBalance = (exerciseBalance + dietBalance) / 2;

    return CategoryBalanceAnalysis(
      exerciseBalance: exerciseBalance,
      dietBalance: dietBalance,
      overallBalance: overallBalance,
      analysisDate: DateTime.now(),
    );
  }

  double _calculateExerciseBalance(List<WeeklyReport> reports) {
    if (reports.isEmpty) return 0.0;

    // Calculate diversity score for exercise categories
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.exerciseCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    return _calculateDiversityScore(categoryTotals);
  }

  double _calculateDietBalance(List<WeeklyReport> reports) {
    if (reports.isEmpty) return 0.0;

    // Calculate diversity score for diet categories
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.dietCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    return _calculateDiversityScore(categoryTotals);
  }

  double _calculateDiversityScore(Map<String, int> categoryTotals) {
    if (categoryTotals.isEmpty) return 0.0;

    final total = categoryTotals.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return 0.0;

    // Shannon diversity index
    double entropy = 0.0;
    for (final count in categoryTotals.values) {
      if (count > 0) {
        final proportion = count / total;
        entropy -= proportion * math.log(proportion) / math.ln2;
      }
    }

    // Normalize to 0-1 scale
    final maxEntropy = math.log(categoryTotals.length) / math.ln2;
    return maxEntropy > 0 ? entropy / maxEntropy : 0.0;
  }

  Future<List<OptimizationOpportunity>> _identifyOptimizationOpportunities(
    CategoryBalanceAnalysis balance,
    List<WeeklyReport> reports,
  ) async {
    final opportunities = <OptimizationOpportunity>[];

    // Identify balance opportunities
    if (balance.exerciseBalance < 0.6) {
      opportunities.add(
        OptimizationOpportunity(
          type: OptimizationOpportunityType.increaseExerciseDiversity,
          description: '운동 카테고리의 다양성을 높여보세요',
          currentScore: balance.exerciseBalance,
          targetScore: 0.8,
          priority: OptimizationPriority.high,
        ),
      );
    }

    if (balance.dietBalance < 0.6) {
      opportunities.add(
        OptimizationOpportunity(
          type: OptimizationOpportunityType.increaseDietDiversity,
          description: '식단 카테고리의 다양성을 높여보세요',
          currentScore: balance.dietBalance,
          targetScore: 0.8,
          priority: OptimizationPriority.high,
        ),
      );
    }

    // Identify consistency opportunities
    final consistencyScore = _calculateOverallConsistency(reports);
    if (consistencyScore < 0.7) {
      opportunities.add(
        OptimizationOpportunity(
          type: OptimizationOpportunityType.improveConsistency,
          description: '활동의 일관성을 개선해보세요',
          currentScore: consistencyScore,
          targetScore: 0.8,
          priority: OptimizationPriority.medium,
        ),
      );
    }

    return opportunities;
  }

  double _calculateOverallConsistency(List<WeeklyReport> reports) {
    if (reports.length < 2) return 1.0;

    final totalActivities = reports.map((r) => r.stats.totalCertifications).toList();
    final mean = totalActivities.reduce((a, b) => a + b) / totalActivities.length;

    if (mean == 0) return 0.0;

    final variance =
        totalActivities.fold(0.0, (sum, value) => sum + math.pow(value - mean, 2)) / totalActivities.length;
    final coefficientOfVariation = math.sqrt(variance) / mean;

    return math.max(0.0, 1.0 - coefficientOfVariation);
  }

  Future<List<OptimizationRecommendation>> _generateOptimizationRecommendations(
    List<OptimizationOpportunity> opportunities,
    CategoryBalanceAnalysis balance,
    List<WeeklyReport> reports,
  ) async {
    final recommendations = <OptimizationRecommendation>[];

    for (final opportunity in opportunities) {
      switch (opportunity.type) {
        case OptimizationOpportunityType.increaseExerciseDiversity:
          recommendations.addAll(await _generateExerciseDiversityRecommendations(reports));
          break;
        case OptimizationOpportunityType.increaseDietDiversity:
          recommendations.addAll(await _generateDietDiversityRecommendations(reports));
          break;
        case OptimizationOpportunityType.improveConsistency:
          recommendations.addAll(await _generateConsistencyRecommendations(reports));
          break;
        case OptimizationOpportunityType.balanceActivity:
          recommendations.addAll(await _generateBalanceActivityRecommendations(reports));
          break;
      }
    }

    return recommendations;
  }

  Future<List<OptimizationRecommendation>> _generateExerciseDiversityRecommendations(List<WeeklyReport> reports) async {
    final recommendations = <OptimizationRecommendation>[];

    // Find underused exercise categories
    final categoryUsage = <String, int>{};
    for (final report in reports) {
      for (final entry in report.stats.exerciseCategories.entries) {
        categoryUsage[entry.key] = (categoryUsage[entry.key] ?? 0) + entry.value;
      }
    }

    final sortedCategories = categoryUsage.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    final underusedCategories = sortedCategories.take(2).map((e) => e.key).toList();

    for (final category in underusedCategories) {
      recommendations.add(
        OptimizationRecommendation(
          type: OptimizationRecommendationType.increaseCategoryUsage,
          categoryName: category,
          categoryType: CategoryType.exercise,
          description: '$category 운동을 더 자주 시도해보세요',
          expectedImpact: 0.2,
          priority: OptimizationPriority.medium,
          actionSteps: ['주 1-2회 $category 운동 계획하기', '다양한 $category 운동 방법 찾아보기', '운동 일정에 $category 시간 배정하기'],
        ),
      );
    }

    return recommendations;
  }

  Future<List<OptimizationRecommendation>> _generateDietDiversityRecommendations(List<WeeklyReport> reports) async {
    final recommendations = <OptimizationRecommendation>[];

    // Find underused diet categories
    final categoryUsage = <String, int>{};
    for (final report in reports) {
      for (final entry in report.stats.dietCategories.entries) {
        categoryUsage[entry.key] = (categoryUsage[entry.key] ?? 0) + entry.value;
      }
    }

    final sortedCategories = categoryUsage.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    final underusedCategories = sortedCategories.take(2).map((e) => e.key).toList();

    for (final category in underusedCategories) {
      recommendations.add(
        OptimizationRecommendation(
          type: OptimizationRecommendationType.increaseCategoryUsage,
          categoryName: category,
          categoryType: CategoryType.diet,
          description: '$category 식단을 더 자주 시도해보세요',
          expectedImpact: 0.2,
          priority: OptimizationPriority.medium,
          actionSteps: ['주 2-3회 $category 식단 계획하기', '$category 관련 레시피 찾아보기', '식단 계획에 $category 포함하기'],
        ),
      );
    }

    return recommendations;
  }

  Future<List<OptimizationRecommendation>> _generateConsistencyRecommendations(List<WeeklyReport> reports) async {
    final recommendations = <OptimizationRecommendation>[];

    recommendations.add(
      OptimizationRecommendation(
        type: OptimizationRecommendationType.improveConsistency,
        categoryName: null,
        categoryType: null,
        description: '활동의 일관성을 개선하여 더 안정적인 패턴을 만들어보세요',
        expectedImpact: 0.3,
        priority: OptimizationPriority.high,
        actionSteps: ['매일 최소 1개의 활동 목표 설정하기', '주간 활동 계획 미리 세우기', '활동 알림 설정하여 규칙성 유지하기', '작은 목표부터 시작하여 점진적으로 늘리기'],
      ),
    );

    return recommendations;
  }

  Map<String, double> _calculateExpectedOutcomes(
    List<OptimizationRecommendation> recommendations,
    CategoryBalanceAnalysis balance,
  ) {
    final outcomes = <String, double>{};

    double expectedBalanceImprovement = 0.0;
    double expectedConsistencyImprovement = 0.0;

    for (final recommendation in recommendations) {
      switch (recommendation.type) {
        case OptimizationRecommendationType.increaseCategoryUsage:
          expectedBalanceImprovement += recommendation.expectedImpact;
          break;
        case OptimizationRecommendationType.decreaseCategoryUsage:
          expectedBalanceImprovement += recommendation.expectedImpact * 0.5;
          break;
        case OptimizationRecommendationType.improveConsistency:
          expectedConsistencyImprovement += recommendation.expectedImpact;
          break;
        case OptimizationRecommendationType.balanceCategories:
          expectedBalanceImprovement += recommendation.expectedImpact;
          break;
      }
    }

    outcomes['balance_improvement'] = math.min(expectedBalanceImprovement, 0.5);
    outcomes['consistency_improvement'] = math.min(expectedConsistencyImprovement, 0.4);
    outcomes['overall_improvement'] = (outcomes['balance_improvement']! + outcomes['consistency_improvement']!) / 2;

    return outcomes;
  }

  List<OptimizationRecommendation> _prioritizeRecommendations(
    List<OptimizationRecommendation> recommendations,
    Map<String, double> expectedOutcomes,
  ) {
    // Sort by priority and expected impact
    recommendations.sort((a, b) {
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;

      return b.expectedImpact.compareTo(a.expectedImpact);
    });

    return recommendations;
  }

  Future<List<OptimizationRecommendation>> _generateBalanceActivityRecommendations(List<WeeklyReport> reports) async {
    final recommendations = <OptimizationRecommendation>[];

    // Calculate exercise vs diet balance
    final totalExercise = reports.fold(0, (sum, report) => sum + report.stats.exerciseDays);
    final totalDiet = reports.fold(0, (sum, report) => sum + report.stats.dietDays);

    if (totalExercise > totalDiet * 1.5) {
      recommendations.add(
        OptimizationRecommendation(
          type: OptimizationRecommendationType.balanceCategories,
          categoryName: null,
          categoryType: null,
          description: '운동과 식단의 균형을 맞춰보세요. 식단 관리를 늘려보세요.',
          expectedImpact: 0.25,
          priority: OptimizationPriority.medium,
          actionSteps: ['주간 식단 계획 세우기', '건강한 식단 옵션 늘리기', '식단 인증 빈도 높이기'],
        ),
      );
    } else if (totalDiet > totalExercise * 1.5) {
      recommendations.add(
        OptimizationRecommendation(
          type: OptimizationRecommendationType.balanceCategories,
          categoryName: null,
          categoryType: null,
          description: '운동과 식단의 균형을 맞춰보세요. 운동 활동을 늘려보세요.',
          expectedImpact: 0.25,
          priority: OptimizationPriority.medium,
          actionSteps: ['주간 운동 계획 세우기', '다양한 운동 종류 시도하기', '운동 인증 빈도 높이기'],
        ),
      );
    }

    return recommendations;
  }

  // Category correlation analysis methods

  /// Calculate correlation matrix for exercise categories
  Future<Map<String, Map<String, double>>> _calculateExerciseCategoryCorrelations(List<WeeklyReport> reports) async {
    final correlations = <String, Map<String, double>>{};
    final exerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toList();

    for (final category1 in exerciseCategories) {
      correlations[category1] = {};
      for (final category2 in exerciseCategories) {
        if (category1 == category2) {
          correlations[category1]![category2] = 1.0;
        } else {
          final correlation = _calculateCategoryCorrelation(
            reports,
            category1,
            category2,
            (report) => report.stats.exerciseCategories,
          );
          correlations[category1]![category2] = correlation;
        }
      }
    }

    return correlations;
  }

  /// Calculate correlation matrix for diet categories
  Future<Map<String, Map<String, double>>> _calculateDietCategoryCorrelations(List<WeeklyReport> reports) async {
    final correlations = <String, Map<String, double>>{};
    final dietCategories = DietCategory.values.map((e) => e.displayName).toList();

    for (final category1 in dietCategories) {
      correlations[category1] = {};
      for (final category2 in dietCategories) {
        if (category1 == category2) {
          correlations[category1]![category2] = 1.0;
        } else {
          final correlation = _calculateCategoryCorrelation(
            reports,
            category1,
            category2,
            (report) => report.stats.dietCategories,
          );
          correlations[category1]![category2] = correlation;
        }
      }
    }

    return correlations;
  }

  /// Calculate cross-type correlations (exercise vs diet categories)
  Future<Map<String, Map<String, double>>> _calculateCrossTypeCategoryCorrelations(List<WeeklyReport> reports) async {
    final correlations = <String, Map<String, double>>{};
    final exerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toList();
    final dietCategories = DietCategory.values.map((e) => e.displayName).toList();

    for (final exerciseCategory in exerciseCategories) {
      correlations[exerciseCategory] = {};
      for (final dietCategory in dietCategories) {
        final correlation = _calculateCrossTypeCategoryCorrelation(reports, exerciseCategory, dietCategory);
        correlations[exerciseCategory]![dietCategory] = correlation;
      }
    }

    return correlations;
  }

  /// Calculate correlation coefficient between two categories
  double _calculateCategoryCorrelation(
    List<WeeklyReport> reports,
    String category1,
    String category2,
    Map<String, int> Function(WeeklyReport) categoryExtractor,
  ) {
    if (reports.length < 3) return 0.0;

    final values1 = reports.map((r) => (categoryExtractor(r)[category1] ?? 0).toDouble()).toList();
    final values2 = reports.map((r) => (categoryExtractor(r)[category2] ?? 0).toDouble()).toList();

    return _calculatePearsonCorrelation(values1, values2);
  }

  /// Calculate cross-type correlation between exercise and diet categories
  double _calculateCrossTypeCategoryCorrelation(
    List<WeeklyReport> reports,
    String exerciseCategory,
    String dietCategory,
  ) {
    if (reports.length < 3) return 0.0;

    final exerciseValues = reports.map((r) => (r.stats.exerciseCategories[exerciseCategory] ?? 0).toDouble()).toList();
    final dietValues = reports.map((r) => (r.stats.dietCategories[dietCategory] ?? 0).toDouble()).toList();

    return _calculatePearsonCorrelation(exerciseValues, dietValues);
  }

  /// Calculate Pearson correlation coefficient
  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return 0.0;

    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double numerator = 0.0;
    double sumXSquared = 0.0;
    double sumYSquared = 0.0;

    for (int i = 0; i < n; i++) {
      final deltaX = x[i] - meanX;
      final deltaY = y[i] - meanY;

      numerator += deltaX * deltaY;
      sumXSquared += deltaX * deltaX;
      sumYSquared += deltaY * deltaY;
    }

    final denominator = math.sqrt(sumXSquared * sumYSquared);

    return denominator > 0 ? numerator / denominator : 0.0;
  }

  /// Identify effective category combinations
  Future<List<CategoryCombination>> _identifyEffectiveCategoryCombinations(
    List<WeeklyReport> reports,
    Map<String, Map<String, double>> exerciseCorrelations,
    Map<String, Map<String, double>> dietCorrelations,
    Map<String, Map<String, double>> crossTypeCorrelations,
  ) async {
    final combinations = <CategoryCombination>[];

    // Find highly correlated exercise category pairs
    for (final entry1 in exerciseCorrelations.entries) {
      for (final entry2 in entry1.value.entries) {
        if (entry1.key != entry2.key && entry2.value > 0.6) {
          final combination = await _createCategoryCombination(
            [entry1.key, entry2.key],
            [CategoryType.exercise, CategoryType.exercise],
            reports,
            entry2.value,
          );
          if (combination.effectivenessScore > 0.5) {
            combinations.add(combination);
          }
        }
      }
    }

    // Find highly correlated diet category pairs
    for (final entry1 in dietCorrelations.entries) {
      for (final entry2 in entry1.value.entries) {
        if (entry1.key != entry2.key && entry2.value > 0.6) {
          final combination = await _createCategoryCombination(
            [entry1.key, entry2.key],
            [CategoryType.diet, CategoryType.diet],
            reports,
            entry2.value,
          );
          if (combination.effectivenessScore > 0.5) {
            combinations.add(combination);
          }
        }
      }
    }

    // Find effective cross-type combinations
    for (final entry1 in crossTypeCorrelations.entries) {
      for (final entry2 in entry1.value.entries) {
        if (entry2.value > 0.5) {
          final combination = await _createCategoryCombination(
            [entry1.key, entry2.key],
            [CategoryType.exercise, CategoryType.diet],
            reports,
            entry2.value,
          );
          if (combination.effectivenessScore > 0.4) {
            combinations.add(combination);
          }
        }
      }
    }

    // Sort by effectiveness score
    combinations.sort((a, b) => b.effectivenessScore.compareTo(a.effectivenessScore));

    return combinations.take(10).toList(); // Return top 10 combinations
  }

  /// Create a category combination model
  Future<CategoryCombination> _createCategoryCombination(
    List<String> categories,
    List<CategoryType> types,
    List<WeeklyReport> reports,
    double correlationStrength,
  ) async {
    // Calculate occurrence count
    int occurrenceCount = 0;
    for (final report in reports) {
      bool hasAllCategories = true;
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        final type = types[i];
        final categoryMap =
            type == CategoryType.exercise ? report.stats.exerciseCategories : report.stats.dietCategories;

        if ((categoryMap[category] ?? 0) == 0) {
          hasAllCategories = false;
          break;
        }
      }
      if (hasAllCategories) occurrenceCount++;
    }

    // Calculate consistency score
    final consistencyScore = reports.isNotEmpty ? occurrenceCount / reports.length : 0.0;

    // Calculate effectiveness score
    final effectivenessScore = (correlationStrength + consistencyScore) / 2;

    // Determine effectiveness type
    final effectivenessType = _determineEffectivenessType(correlationStrength, consistencyScore);

    // Generate benefits
    final benefits = _generateCombinationBenefits(categories, types, correlationStrength);

    return CategoryCombination(
      categories: categories,
      categoryTypes: types,
      effectivenessScore: effectivenessScore,
      correlationStrength: correlationStrength,
      occurrenceCount: occurrenceCount,
      consistencyScore: consistencyScore,
      benefits: benefits,
      effectivenessType: effectivenessType,
    );
  }

  /// Determine the effectiveness type of a combination
  CombinationEffectivenessType _determineEffectivenessType(double correlationStrength, double consistencyScore) {
    if (correlationStrength > 0.8 && consistencyScore > 0.7) {
      return CombinationEffectivenessType.highSynergy;
    } else if (correlationStrength > 0.6 && consistencyScore > 0.6) {
      return CombinationEffectivenessType.balanced;
    } else if (correlationStrength > 0.5) {
      return CombinationEffectivenessType.complementary;
    } else {
      return CombinationEffectivenessType.consistent;
    }
  }

  /// Generate benefits for a category combination
  List<String> _generateCombinationBenefits(
    List<String> categories,
    List<CategoryType> types,
    double correlationStrength,
  ) {
    final benefits = <String>[];

    if (correlationStrength > 0.7) {
      benefits.add('높은 시너지 효과');
    }
    if (correlationStrength > 0.6) {
      benefits.add('상호 보완적 효과');
    }

    // Add specific benefits based on category combinations
    if (types.contains(CategoryType.exercise) && types.contains(CategoryType.diet)) {
      benefits.add('운동과 식단의 균형잡힌 조합');
      benefits.add('전체적인 건강 관리 효과');
    }

    if (benefits.isEmpty) {
      benefits.add('일관된 활동 패턴');
    }

    return benefits;
  }

  /// Generate category synergy recommendations
  Future<List<CategorySynergyRecommendation>> _generateCategorySynergyRecommendations(
    List<CategoryCombination> effectiveCombinations,
    Map<String, Map<String, double>> exerciseCorrelations,
    Map<String, Map<String, double>> dietCorrelations,
    Map<String, Map<String, double>> crossTypeCorrelations,
  ) async {
    final recommendations = <CategorySynergyRecommendation>[];

    // Generate recommendations based on effective combinations
    for (final combination in effectiveCombinations.take(5)) {
      if (combination.categories.length == 2) {
        final recommendation = _createSynergyRecommendation(
          combination.categories[0],
          combination.categoryTypes[0],
          combination.categories[1],
          combination.categoryTypes[1],
          combination.correlationStrength,
          combination.benefits,
        );
        recommendations.add(recommendation);
      }
    }

    // Find missing synergies (high correlation but low usage)
    for (final entry1 in crossTypeCorrelations.entries) {
      for (final entry2 in entry1.value.entries) {
        if (entry2.value > 0.6) {
          // Check if this combination is underutilized
          final isUnderutilized =
              !effectiveCombinations.any(
                (combo) => combo.categories.contains(entry1.key) && combo.categories.contains(entry2.key),
              );

          if (isUnderutilized) {
            final recommendation = _createSynergyRecommendation(
              entry1.key,
              CategoryType.exercise,
              entry2.key,
              CategoryType.diet,
              entry2.value,
              ['잠재적 시너지 효과', '균형잡힌 건강 관리'],
            );
            recommendations.add(recommendation);
          }
        }
      }
    }

    // Sort by synergy score and limit results
    recommendations.sort((a, b) => b.synergyScore.compareTo(a.synergyScore));
    return recommendations.take(8).toList();
  }

  /// Create a synergy recommendation
  CategorySynergyRecommendation _createSynergyRecommendation(
    String primaryCategory,
    CategoryType primaryType,
    String recommendedCategory,
    CategoryType recommendedType,
    double synergyScore,
    List<String> benefits,
  ) {
    final recommendationType = _determineSynergyRecommendationType(primaryType, recommendedType);
    final priority = _determineSynergyPriority(synergyScore);

    final description = _generateSynergyDescription(
      primaryCategory,
      primaryType,
      recommendedCategory,
      recommendedType,
      recommendationType,
    );

    return CategorySynergyRecommendation(
      primaryCategory: primaryCategory,
      primaryType: primaryType,
      recommendedCategory: recommendedCategory,
      recommendedType: recommendedType,
      synergyScore: synergyScore,
      recommendationType: recommendationType,
      description: description,
      expectedBenefits: benefits,
      confidence: synergyScore,
      priority: priority,
    );
  }

  /// Determine synergy recommendation type
  SynergyRecommendationType _determineSynergyRecommendationType(
    CategoryType primaryType,
    CategoryType recommendedType,
  ) {
    if (primaryType == recommendedType) {
      return SynergyRecommendationType.enhance;
    } else {
      return SynergyRecommendationType.complement;
    }
  }

  /// Determine synergy priority
  SynergyPriority _determineSynergyPriority(double synergyScore) {
    if (synergyScore > 0.8) return SynergyPriority.critical;
    if (synergyScore > 0.6) return SynergyPriority.high;
    if (synergyScore > 0.4) return SynergyPriority.medium;
    return SynergyPriority.low;
  }

  /// Generate synergy description
  String _generateSynergyDescription(
    String primaryCategory,
    CategoryType primaryType,
    String recommendedCategory,
    CategoryType recommendedType,
    SynergyRecommendationType recommendationType,
  ) {
    final primaryTypeStr = primaryType == CategoryType.exercise ? '운동' : '식단';
    final recommendedTypeStr = recommendedType == CategoryType.exercise ? '운동' : '식단';

    switch (recommendationType) {
      case SynergyRecommendationType.complement:
        return '$primaryCategory $primaryTypeStr과 $recommendedCategory $recommendedTypeStr을 함께 하면 상호 보완적인 효과를 얻을 수 있습니다.';
      case SynergyRecommendationType.enhance:
        return '$primaryCategory $primaryTypeStr과 $recommendedCategory $primaryTypeStr을 함께 하면 시너지 효과를 얻을 수 있습니다.';
      case SynergyRecommendationType.balance:
        return '$primaryCategory $primaryTypeStr과 $recommendedCategory $recommendedTypeStr의 균형을 맞춰보세요.';
      case SynergyRecommendationType.diversify:
        return '$primaryCategory $primaryTypeStr에서 $recommendedCategory $recommendedTypeStr으로 다양성을 늘려보세요.';
    }
  }

  /// Create category balance optimization
  Future<CategoryBalanceOptimization> _createCategoryBalanceOptimization(
    List<WeeklyReport> reports,
    List<CategoryCombination> effectiveCombinations,
  ) async {
    // Calculate current balance score
    final currentBalanceScore = await _calculateCurrentBalanceScore(reports);

    // Calculate optimal distribution
    final optimalDistribution = await _calculateOptimalCategoryDistribution(reports, effectiveCombinations);

    // Generate balance suggestions
    final suggestions = await _generateBalanceOptimizationSuggestions(reports, optimalDistribution);

    // Calculate category weights
    final categoryWeights = await _calculateCategoryWeights(reports);

    // Calculate improvement potential
    final improvementPotential = _calculateImprovementPotential(currentBalanceScore, optimalDistribution);

    // Identify balance issues
    final balanceIssues = _identifyBalanceIssues(reports, optimalDistribution);

    return CategoryBalanceOptimization(
      currentBalanceScore: currentBalanceScore,
      targetBalanceScore: math.min(currentBalanceScore + improvementPotential, 1.0),
      categoryWeights: categoryWeights,
      suggestions: suggestions,
      optimalDistribution: optimalDistribution,
      improvementPotential: improvementPotential,
      balanceIssues: balanceIssues,
    );
  }

  /// Calculate current balance score
  Future<double> _calculateCurrentBalanceScore(List<WeeklyReport> reports) async {
    if (reports.isEmpty) return 0.0;

    // Calculate exercise category balance
    final exerciseBalance = _calculateCategoryTypeBalance(reports, (report) => report.stats.exerciseCategories);

    // Calculate diet category balance
    final dietBalance = _calculateCategoryTypeBalance(reports, (report) => report.stats.dietCategories);

    // Calculate overall balance between exercise and diet
    final totalExercise = reports.fold(0, (sum, report) => sum + report.stats.exerciseDays);
    final totalDiet = reports.fold(0, (sum, report) => sum + report.stats.dietDays);
    final overallBalance =
        totalExercise + totalDiet > 0 ? 1.0 - (totalExercise - totalDiet).abs() / (totalExercise + totalDiet) : 0.0;

    return (exerciseBalance + dietBalance + overallBalance) / 3;
  }

  /// Calculate balance for a specific category type
  double _calculateCategoryTypeBalance(
    List<WeeklyReport> reports,
    Map<String, int> Function(WeeklyReport) categoryExtractor,
  ) {
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in categoryExtractor(report).entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    if (categoryTotals.isEmpty) return 0.0;

    final values = categoryTotals.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;

    if (mean == 0) return 0.0;

    final variance = values.fold(0.0, (sum, value) => sum + math.pow(value - mean, 2)) / values.length;
    final coefficientOfVariation = math.sqrt(variance) / mean;

    return math.max(0.0, 1.0 - coefficientOfVariation);
  }

  /// Calculate optimal category distribution
  Future<Map<String, double>> _calculateOptimalCategoryDistribution(
    List<WeeklyReport> reports,
    List<CategoryCombination> effectiveCombinations,
  ) async {
    final optimalDistribution = <String, double>{};

    // Base distribution on effective combinations
    final categoryScores = <String, double>{};

    for (final combination in effectiveCombinations) {
      for (final category in combination.categories) {
        categoryScores[category] = (categoryScores[category] ?? 0.0) + combination.effectivenessScore;
      }
    }

    // Normalize scores to create distribution
    final totalScore = categoryScores.values.fold(0.0, (sum, score) => sum + score);

    if (totalScore > 0) {
      for (final entry in categoryScores.entries) {
        optimalDistribution[entry.key] = entry.value / totalScore;
      }
    }

    return optimalDistribution;
  }

  /// Generate balance optimization suggestions
  Future<List<BalanceOptimizationSuggestion>> _generateBalanceOptimizationSuggestions(
    List<WeeklyReport> reports,
    Map<String, double> optimalDistribution,
  ) async {
    final suggestions = <BalanceOptimizationSuggestion>[];

    // Calculate current distribution
    final currentDistribution = await _calculateCurrentCategoryDistribution(reports);

    for (final entry in optimalDistribution.entries) {
      final category = entry.key;
      final optimalUsage = entry.value;
      final currentUsage = currentDistribution[category] ?? 0.0;

      if ((optimalUsage - currentUsage).abs() > 0.1) {
        final optimizationType =
            optimalUsage > currentUsage ? BalanceOptimizationType.increase : BalanceOptimizationType.decrease;

        final suggestion = BalanceOptimizationSuggestion(
          categoryName: category,
          categoryType: _getCategoryType(category),
          optimizationType: optimizationType,
          currentUsage: currentUsage,
          recommendedUsage: optimalUsage,
          impactScore: (optimalUsage - currentUsage).abs(),
          description: _generateBalanceOptimizationDescription(category, optimizationType),
          actionSteps: _generateBalanceOptimizationActionSteps(category, optimizationType),
        );

        suggestions.add(suggestion);
      }
    }

    // Sort by impact score
    suggestions.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    return suggestions.take(5).toList();
  }

  /// Calculate current category distribution
  Future<Map<String, double>> _calculateCurrentCategoryDistribution(List<WeeklyReport> reports) async {
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.exerciseCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
      for (final entry in report.stats.dietCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    final totalCount = categoryTotals.values.fold(0, (sum, count) => sum + count);
    final distribution = <String, double>{};

    if (totalCount > 0) {
      for (final entry in categoryTotals.entries) {
        distribution[entry.key] = entry.value / totalCount;
      }
    }

    return distribution;
  }

  /// Get category type for a category name
  CategoryType _getCategoryType(String categoryName) {
    for (final category in ExerciseCategory.values) {
      if (category.displayName == categoryName) {
        return CategoryType.exercise;
      }
    }
    return CategoryType.diet;
  }

  /// Generate balance optimization description
  String _generateBalanceOptimizationDescription(String category, BalanceOptimizationType type) {
    switch (type) {
      case BalanceOptimizationType.increase:
        return '$category 활동을 늘려서 균형을 개선해보세요.';
      case BalanceOptimizationType.decrease:
        return '$category 활동을 줄이고 다른 활동을 늘려보세요.';
      case BalanceOptimizationType.maintain:
        return '$category 활동을 현재 수준으로 유지하세요.';
      case BalanceOptimizationType.introduce:
        return '$category 활동을 새롭게 시작해보세요.';
    }
  }

  /// Generate balance optimization action steps
  List<String> _generateBalanceOptimizationActionSteps(String category, BalanceOptimizationType type) {
    switch (type) {
      case BalanceOptimizationType.increase:
        return ['$category 활동 빈도를 주 1-2회 늘리기', '$category 관련 계획 세우기', '다양한 $category 옵션 탐색하기'];
      case BalanceOptimizationType.decrease:
        return ['$category 활동 빈도 조절하기', '다른 카테고리 활동 늘리기', '전체적인 균형 고려하기'];
      case BalanceOptimizationType.maintain:
        return ['현재 $category 활동 수준 유지하기', '꾸준한 실행을 위한 계획 세우기'];
      case BalanceOptimizationType.introduce:
        return ['$category 활동 시작하기', '초보자용 $category 옵션 찾기', '점진적으로 빈도 늘리기'];
    }
  }

  /// Calculate category weights
  Future<Map<String, double>> _calculateCategoryWeights(List<WeeklyReport> reports) async {
    final weights = <String, double>{};
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.exerciseCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
      for (final entry in report.stats.dietCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    final totalCount = categoryTotals.values.fold(0, (sum, count) => sum + count);

    if (totalCount > 0) {
      for (final entry in categoryTotals.entries) {
        weights[entry.key] = entry.value / totalCount;
      }
    }

    return weights;
  }

  /// Calculate improvement potential
  double _calculateImprovementPotential(double currentScore, Map<String, double> optimalDistribution) {
    // Improvement potential based on how far current score is from ideal
    final maxPossibleScore = 1.0;
    final improvementGap = maxPossibleScore - currentScore;

    // Factor in the quality of optimal distribution
    final distributionQuality = optimalDistribution.isNotEmpty ? 0.8 : 0.3;

    return improvementGap * distributionQuality * 0.5; // Conservative estimate
  }

  /// Identify balance issues
  List<String> _identifyBalanceIssues(List<WeeklyReport> reports, Map<String, double> optimalDistribution) {
    final issues = <String>[];

    // Check for over-concentration in single categories
    final currentDistribution = <String, double>{};
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.exerciseCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
      for (final entry in report.stats.dietCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    final totalCount = categoryTotals.values.fold(0, (sum, count) => sum + count);

    if (totalCount > 0) {
      for (final entry in categoryTotals.entries) {
        currentDistribution[entry.key] = entry.value / totalCount;
      }
    }

    // Find over-concentrated categories
    for (final entry in currentDistribution.entries) {
      if (entry.value > 0.5) {
        issues.add('${entry.key} 카테고리에 과도하게 집중되어 있습니다');
      }
    }

    // Check for missing categories
    final exerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toSet();
    final dietCategories = DietCategory.values.map((e) => e.displayName).toSet();
    final usedCategories = currentDistribution.keys.toSet();

    final missingExerciseCategories = exerciseCategories.difference(usedCategories);
    final missingDietCategories = dietCategories.difference(usedCategories);

    if (missingExerciseCategories.length > exerciseCategories.length * 0.5) {
      issues.add('운동 카테고리의 다양성이 부족합니다');
    }
    if (missingDietCategories.length > dietCategories.length * 0.5) {
      issues.add('식단 카테고리의 다양성이 부족합니다');
    }

    return issues;
  }

  /// Generate habit stacking recommendations
  Future<List<HabitStackingRecommendation>> _generateHabitStackingRecommendations(
    List<WeeklyReport> reports,
    List<CategoryCombination> effectiveCombinations,
    List<CategorySynergyRecommendation> synergyRecommendations,
  ) async {
    final recommendations = <HabitStackingRecommendation>[];

    // Generate recommendations based on effective combinations
    for (final combination in effectiveCombinations.take(3)) {
      if (combination.categories.length == 2) {
        final recommendation = await _createHabitStackingRecommendation(
          combination.categories[0],
          combination.categoryTypes[0],
          combination.categories[1],
          combination.categoryTypes[1],
          combination.effectivenessScore,
          reports,
        );
        recommendations.add(recommendation);
      }
    }

    // Generate recommendations based on synergy recommendations
    for (final synergy in synergyRecommendations.take(3)) {
      if (synergy.priority == SynergyPriority.high || synergy.priority == SynergyPriority.critical) {
        final recommendation = await _createHabitStackingRecommendation(
          synergy.primaryCategory,
          synergy.primaryType,
          synergy.recommendedCategory,
          synergy.recommendedType,
          synergy.synergyScore,
          reports,
        );
        recommendations.add(recommendation);
      }
    }

    // Remove duplicates and sort by stacking score
    final uniqueRecommendations = <HabitStackingRecommendation>[];
    for (final rec in recommendations) {
      final isDuplicate = uniqueRecommendations.any(
        (existing) => existing.anchorCategory == rec.anchorCategory && existing.stackedCategory == rec.stackedCategory,
      );
      if (!isDuplicate) {
        uniqueRecommendations.add(rec);
      }
    }

    uniqueRecommendations.sort((a, b) => b.stackingScore.compareTo(a.stackingScore));
    return uniqueRecommendations.take(5).toList();
  }

  /// Create a habit stacking recommendation
  Future<HabitStackingRecommendation> _createHabitStackingRecommendation(
    String anchorCategory,
    CategoryType anchorType,
    String stackedCategory,
    CategoryType stackedType,
    double effectivenessScore,
    List<WeeklyReport> reports,
  ) async {
    final stackingType = _determineHabitStackingType(anchorType, stackedType);
    final priority = _determineHabitStackingPriority(effectivenessScore);
    final successProbability = _calculateHabitStackingSuccessProbability(anchorCategory, stackedCategory, reports);

    final description = _generateHabitStackingDescription(
      anchorCategory,
      anchorType,
      stackedCategory,
      stackedType,
      stackingType,
    );

    final implementationSteps = _generateHabitStackingImplementationSteps(
      anchorCategory,
      stackedCategory,
      stackingType,
    );

    final timingRecommendations = _generateHabitStackingTimingRecommendations(anchorType, stackedType, stackingType);

    return HabitStackingRecommendation(
      anchorCategory: anchorCategory,
      anchorType: anchorType,
      stackedCategory: stackedCategory,
      stackedType: stackedType,
      stackingType: stackingType,
      stackingScore: effectivenessScore,
      description: description,
      implementationSteps: implementationSteps,
      successProbability: successProbability,
      priority: priority,
      timingRecommendations: timingRecommendations,
    );
  }

  /// Determine habit stacking type
  HabitStackingType _determineHabitStackingType(CategoryType anchorType, CategoryType stackedType) {
    if (anchorType == stackedType) {
      return HabitStackingType.sequential;
    } else {
      return HabitStackingType.simultaneous;
    }
  }

  /// Determine habit stacking priority
  HabitStackingPriority _determineHabitStackingPriority(double effectivenessScore) {
    if (effectivenessScore > 0.7) return HabitStackingPriority.high;
    if (effectivenessScore > 0.5) return HabitStackingPriority.medium;
    return HabitStackingPriority.low;
  }

  /// Calculate habit stacking success probability
  double _calculateHabitStackingSuccessProbability(
    String anchorCategory,
    String stackedCategory,
    List<WeeklyReport> reports,
  ) {
    if (reports.isEmpty) return 0.5;

    // Calculate consistency of anchor category
    final anchorConsistency = _calculateCategoryConsistency(anchorCategory, reports);

    // Calculate current usage of stacked category
    final stackedUsage = _calculateCategoryUsage(stackedCategory, reports);

    // Success probability based on anchor consistency and stacked category familiarity
    return (anchorConsistency * 0.7 + stackedUsage * 0.3).clamp(0.2, 0.9);
  }

  /// Calculate category consistency
  double _calculateCategoryConsistency(String category, List<WeeklyReport> reports) {
    final usageData = <int>[];

    for (final report in reports) {
      final exerciseCount = report.stats.exerciseCategories[category] ?? 0;
      final dietCount = report.stats.dietCategories[category] ?? 0;
      usageData.add(exerciseCount + dietCount);
    }

    if (usageData.isEmpty) return 0.0;

    final mean = usageData.reduce((a, b) => a + b) / usageData.length;
    if (mean == 0) return 0.0;

    final variance = usageData.fold(0.0, (sum, value) => sum + math.pow(value - mean, 2)) / usageData.length;
    final coefficientOfVariation = math.sqrt(variance) / mean;

    return math.max(0.0, 1.0 - coefficientOfVariation);
  }

  /// Calculate category usage
  double _calculateCategoryUsage(String category, List<WeeklyReport> reports) {
    if (reports.isEmpty) return 0.0;

    final totalUsage = reports.fold(0, (sum, report) {
      final exerciseCount = report.stats.exerciseCategories[category] ?? 0;
      final dietCount = report.stats.dietCategories[category] ?? 0;
      return sum + exerciseCount + dietCount;
    });

    final maxPossibleUsage = reports.length * 7; // Assuming max 7 activities per week
    return totalUsage / maxPossibleUsage;
  }

  /// Generate habit stacking description
  String _generateHabitStackingDescription(
    String anchorCategory,
    CategoryType anchorType,
    String stackedCategory,
    CategoryType stackedType,
    HabitStackingType stackingType,
  ) {
    final anchorTypeStr = anchorType == CategoryType.exercise ? '운동' : '식단';
    final stackedTypeStr = stackedType == CategoryType.exercise ? '운동' : '식단';

    switch (stackingType) {
      case HabitStackingType.sequential:
        return '$anchorCategory $anchorTypeStr 후에 $stackedCategory $stackedTypeStr을 연이어서 해보세요.';
      case HabitStackingType.simultaneous:
        return '$anchorCategory $anchorTypeStr과 $stackedCategory $stackedTypeStr을 같은 시기에 함께 해보세요.';
      case HabitStackingType.alternating:
        return '$anchorCategory $anchorTypeStr과 $stackedCategory $stackedTypeStr을 번갈아가며 해보세요.';
      case HabitStackingType.preparatory:
        return '$anchorCategory $anchorTypeStr을 위한 준비로 $stackedCategory $stackedTypeStr을 먼저 해보세요.';
    }
  }

  /// Generate habit stacking implementation steps
  List<String> _generateHabitStackingImplementationSteps(
    String anchorCategory,
    String stackedCategory,
    HabitStackingType stackingType,
  ) {
    switch (stackingType) {
      case HabitStackingType.sequential:
        return ['$anchorCategory 활동을 완료한 직후 $stackedCategory 활동 시작하기', '두 활동 사이의 간격을 최소화하기', '연속 활동을 위한 시간 계획 세우기'];
      case HabitStackingType.simultaneous:
        return ['$anchorCategory와 $stackedCategory 활동을 같은 날에 계획하기', '두 활동을 위한 충분한 시간 확보하기', '활동 순서와 타이밍 정하기'];
      case HabitStackingType.alternating:
        return ['$anchorCategory와 $stackedCategory 활동을 교대로 계획하기', '규칙적인 교대 패턴 만들기', '각 활동의 효과를 모니터링하기'];
      case HabitStackingType.preparatory:
        return ['$stackedCategory 활동을 $anchorCategory의 준비 단계로 설정하기', '준비 활동의 효과 확인하기', '점진적으로 두 활동의 연결성 강화하기'];
    }
  }

  /// Generate habit stacking timing recommendations
  Map<String, dynamic> _generateHabitStackingTimingRecommendations(
    CategoryType anchorType,
    CategoryType stackedType,
    HabitStackingType stackingType,
  ) {
    final recommendations = <String, dynamic>{};

    if (anchorType == CategoryType.exercise && stackedType == CategoryType.diet) {
      recommendations['timing'] = '운동 후 30분 이내';
      recommendations['reason'] = '운동 후 영양 보충이 효과적';
    } else if (anchorType == CategoryType.diet && stackedType == CategoryType.exercise) {
      recommendations['timing'] = '식사 후 1-2시간 후';
      recommendations['reason'] = '소화 후 운동이 안전';
    } else {
      recommendations['timing'] = '연속적으로 또는 같은 시간대에';
      recommendations['reason'] = '습관 형성에 도움';
    }

    recommendations['frequency'] = '주 3-4회부터 시작';
    recommendations['duration'] = '2-3주간 지속하여 습관화';

    return recommendations;
  }
}
