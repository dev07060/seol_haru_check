import 'dart:math';

import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';

/// Service for advanced pattern recognition and category insights
class PatternRecognitionService {
  static const int _minWeeksForTrends = 3;
  static const double _significantChangeThreshold = 0.2; // 20% change

  /// Analyze category-specific patterns from weekly reports
  CategoryTrendAnalysis analyzeCategoryTrends(List<WeeklyReport> reports) {
    if (reports.length < _minWeeksForTrends) {
      return CategoryTrendAnalysis.empty();
    }

    final sortedReports = List<WeeklyReport>.from(reports)..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

    final exerciseTrends = _analyzeExerciseCategoryTrends(sortedReports);
    final dietTrends = _analyzeDietCategoryTrends(sortedReports);
    final overallTrend = _calculateOverallTrend(exerciseTrends, dietTrends);
    final trendStrength = _calculateOverallTrendStrength(exerciseTrends, dietTrends);
    final confidence = _calculateAnalysisConfidence(sortedReports);
    final velocity = _calculateTrendVelocity(sortedReports);

    return CategoryTrendAnalysis(
      exerciseCategoryTrends: exerciseTrends,
      dietCategoryTrends: dietTrends,
      overallTrendDirection: overallTrend,
      trendStrength: trendStrength,
      analysisConfidence: confidence,
      trendVelocity: velocity,
      weeksAnalyzed: sortedReports.length,
      analysisDate: DateTime.now(),
    );
  }

  /// Generate optimal category mix recommendations
  List<CategoryMixRecommendation> generateOptimalCategoryMix(
    List<WeeklyReport> reports,
    CategoryTrendAnalysis trendAnalysis,
  ) {
    final recommendations = <CategoryMixRecommendation>[];

    // Analyze current category distribution
    final currentMix = _calculateCurrentCategoryMix(reports);
    final optimalMix = _calculateOptimalCategoryMix();

    // Generate exercise recommendations
    recommendations.addAll(_generateExerciseRecommendations(currentMix, optimalMix, trendAnalysis));

    // Generate diet recommendations
    recommendations.addAll(_generateDietRecommendations(currentMix, optimalMix, trendAnalysis));

    // Sort by priority
    recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return recommendations;
  }

  /// Analyze category balance for health insights
  CategoryBalanceAnalysis analyzeCategoryBalance(List<WeeklyReport> reports) {
    if (reports.isEmpty) {
      return CategoryBalanceAnalysis.empty();
    }

    final currentBalance = _calculateCategoryBalance(reports);
    final balanceScore = _calculateBalanceScore(currentBalance);
    final recommendations = _generateBalanceRecommendations(currentBalance);
    final healthInsights = _generateHealthInsights(currentBalance, balanceScore);

    return CategoryBalanceAnalysis(
      exerciseBalance: currentBalance.exerciseBalance,
      dietBalance: currentBalance.dietBalance,
      overallBalanceScore: balanceScore,
      balanceRecommendations: recommendations,
      healthInsights: healthInsights,
      analysisDate: DateTime.now(),
      weeksAnalyzed: reports.length,
    );
  }

  /// Predict seasonal category trends
  SeasonalTrendPrediction predictSeasonalTrends(List<WeeklyReport> reports, DateTime targetDate) {
    final seasonalPatterns = _analyzeSeasonalPatterns(reports);
    final targetSeason = _getSeason(targetDate);
    final predictions = _generateSeasonalPredictions(seasonalPatterns, targetSeason);
    final confidence = _calculateSeasonalConfidence(reports, targetDate);

    return SeasonalTrendPrediction(
      targetDate: targetDate,
      targetSeason: targetSeason,
      exercisePredictions: predictions.exercisePredictions,
      dietPredictions: predictions.dietPredictions,
      confidenceScore: confidence,
      seasonalPatterns: seasonalPatterns,
      analysisDate: DateTime.now(),
    );
  }

  // Private helper methods for exercise category trend analysis
  Map<String, CategoryTrendMetrics> _analyzeExerciseCategoryTrends(List<WeeklyReport> reports) {
    final trends = <String, CategoryTrendMetrics>{};

    for (final category in ExerciseCategory.values) {
      final categoryName = category.displayName;
      final metrics = _calculateCategoryTrendMetrics(
        reports,
        categoryName,
        CategoryType.exercise,
        (report) => report.stats.exerciseCategories[categoryName] ?? 0,
      );
      trends[categoryName] = metrics;
    }

    return trends;
  }

  Map<String, CategoryTrendMetrics> _analyzeDietCategoryTrends(List<WeeklyReport> reports) {
    final trends = <String, CategoryTrendMetrics>{};

    for (final category in DietCategory.values) {
      final categoryName = category.displayName;
      final metrics = _calculateCategoryTrendMetrics(
        reports,
        categoryName,
        CategoryType.diet,
        (report) => report.stats.dietCategories[categoryName] ?? 0,
      );
      trends[categoryName] = metrics;
    }

    return trends;
  }

  CategoryTrendMetrics _calculateCategoryTrendMetrics(
    List<WeeklyReport> reports,
    String categoryName,
    CategoryType categoryType,
    int Function(WeeklyReport) valueExtractor,
  ) {
    if (reports.length < 2) {
      return CategoryTrendMetrics.stable(categoryName, categoryType);
    }

    final values = reports.map(valueExtractor).toList();
    final currentValue = values.last;
    final previousValue = values[values.length - 2];
    final historicalAverage = values.reduce((a, b) => a + b) / values.length;

    final changePercentage =
        previousValue == 0 ? (currentValue > 0 ? 100.0 : 0.0) : ((currentValue - previousValue) / previousValue) * 100;

    final direction = _determineTrendDirection(changePercentage);
    final trendStrength = _calculateCategoryTrendStrength(values);
    final volatility = _calculateVolatility(values);
    final momentum = _calculateMomentum(values);

    return CategoryTrendMetrics(
      categoryName: categoryName,
      categoryType: categoryType,
      direction: direction,
      changePercentage: changePercentage,
      trendStrength: trendStrength,
      volatility: volatility,
      momentum: momentum,
      currentValue: currentValue,
      previousValue: previousValue,
      historicalAverage: historicalAverage,
    );
  }

  TrendDirection _determineTrendDirection(double changePercentage) {
    if (changePercentage > _significantChangeThreshold * 100) {
      return TrendDirection.up;
    } else if (changePercentage < -_significantChangeThreshold * 100) {
      return TrendDirection.down;
    } else {
      return TrendDirection.stable;
    }
  }

  double _calculateCategoryTrendStrength(List<int> values) {
    if (values.length < 3) return 0.0;

    // Calculate linear regression slope
    final n = values.length;
    final xSum = (n * (n - 1)) / 2;
    final ySum = values.reduce((a, b) => a + b);
    final xySum = values.asMap().entries.fold(0.0, (sum, entry) => sum + entry.key * entry.value);
    final xSquaredSum = (n * (n - 1) * (2 * n - 1)) / 6;

    final slope = (n * xySum - xSum * ySum) / (n * xSquaredSum - xSum * xSum);
    return (slope.abs() / (ySum / n)).clamp(0.0, 1.0);
  }

  double _calculateVolatility(List<int> values) {
    if (values.length < 2) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold(0.0, (sum, value) => sum + pow(value - mean, 2)) / values.length;
    return sqrt(variance) / mean;
  }

  double _calculateMomentum(List<int> values) {
    if (values.length < 3) return 0.0;

    final recentValues = values.sublist(values.length - 3);
    final olderValues = values.sublist(0, min(3, values.length - 3));

    final recentAvg = recentValues.reduce((a, b) => a + b) / recentValues.length;
    final olderAvg = olderValues.isEmpty ? 0.0 : olderValues.reduce((a, b) => a + b) / olderValues.length;

    return olderAvg == 0 ? 0.0 : (recentAvg - olderAvg) / olderAvg;
  }

  TrendDirection _calculateOverallTrend(
    Map<String, CategoryTrendMetrics> exerciseTrends,
    Map<String, CategoryTrendMetrics> dietTrends,
  ) {
    final allTrends = [...exerciseTrends.values, ...dietTrends.values];
    if (allTrends.isEmpty) return TrendDirection.stable;

    final upCount = allTrends.where((t) => t.direction == TrendDirection.up).length;
    final downCount = allTrends.where((t) => t.direction == TrendDirection.down).length;

    if (upCount > downCount * 1.5) return TrendDirection.up;
    if (downCount > upCount * 1.5) return TrendDirection.down;
    return TrendDirection.stable;
  }

  double _calculateOverallTrendStrength(
    Map<String, CategoryTrendMetrics> exerciseTrends,
    Map<String, CategoryTrendMetrics> dietTrends,
  ) {
    final allTrends = [...exerciseTrends.values, ...dietTrends.values];
    if (allTrends.isEmpty) return 0.0;

    return allTrends.fold(0.0, (sum, trend) => sum + trend.trendStrength) / allTrends.length;
  }

  double _calculateAnalysisConfidence(List<WeeklyReport> reports) {
    final baseConfidence = min(reports.length / 8.0, 1.0); // Max confidence at 8 weeks
    final dataQuality = reports.where((r) => r.hasSufficientData).length / reports.length;
    return (baseConfidence + dataQuality) / 2;
  }

  double _calculateTrendVelocity(List<WeeklyReport> reports) {
    if (reports.length < 3) return 0.0;

    final totalActivities = reports.map((r) => r.stats.totalCertifications).toList();
    final recentChange = totalActivities.last - totalActivities[totalActivities.length - 2];
    final previousChange = totalActivities[totalActivities.length - 2] - totalActivities[totalActivities.length - 3];

    return recentChange - previousChange.toDouble();
  }

  // Category mix recommendation methods
  CategoryMix _calculateCurrentCategoryMix(List<WeeklyReport> reports) {
    if (reports.isEmpty) return CategoryMix.empty();

    final recentReports = reports.length > 4 ? reports.sublist(reports.length - 4) : reports;

    final exerciseDistribution = <String, double>{};
    final dietDistribution = <String, double>{};

    for (final category in ExerciseCategory.values) {
      final total = recentReports.fold(
        0,
        (sum, report) => sum + (report.stats.exerciseCategories[category.displayName] ?? 0),
      );
      exerciseDistribution[category.displayName] = total.toDouble();
    }

    for (final category in DietCategory.values) {
      final total = recentReports.fold(
        0,
        (sum, report) => sum + (report.stats.dietCategories[category.displayName] ?? 0),
      );
      dietDistribution[category.displayName] = total.toDouble();
    }

    return CategoryMix(exerciseDistribution: exerciseDistribution, dietDistribution: dietDistribution);
  }

  CategoryMix _calculateOptimalCategoryMix() {
    // Define optimal distribution based on health guidelines
    return CategoryMix(
      exerciseDistribution: {
        ExerciseCategory.strength.displayName: 0.3,
        ExerciseCategory.cardio.displayName: 0.3,
        ExerciseCategory.flexibility.displayName: 0.2,
        ExerciseCategory.sports.displayName: 0.1,
        ExerciseCategory.outdoor.displayName: 0.05,
        ExerciseCategory.dance.displayName: 0.05,
      },
      dietDistribution: {
        DietCategory.homeMade.displayName: 0.4,
        DietCategory.healthy.displayName: 0.25,
        DietCategory.protein.displayName: 0.15,
        DietCategory.snack.displayName: 0.1,
        DietCategory.dining.displayName: 0.05,
        DietCategory.supplement.displayName: 0.05,
      },
    );
  }

  List<CategoryMixRecommendation> _generateExerciseRecommendations(
    CategoryMix currentMix,
    CategoryMix optimalMix,
    CategoryTrendAnalysis trendAnalysis,
  ) {
    final recommendations = <CategoryMixRecommendation>[];

    for (final entry in optimalMix.exerciseDistribution.entries) {
      final categoryName = entry.key;
      final optimalRatio = entry.value;
      final currentRatio = currentMix.exerciseDistribution[categoryName] ?? 0.0;
      final difference = optimalRatio - currentRatio;

      if (difference.abs() > 0.1) {
        // 10% threshold
        final priority =
            difference.abs() > 0.2 ? PatternRecommendationPriority.high : PatternRecommendationPriority.medium;

        recommendations.add(
          CategoryMixRecommendation(
            categoryName: categoryName,
            categoryType: CategoryType.exercise,
            recommendationType:
                difference > 0 ? PatternRecommendationType.increase : PatternRecommendationType.decrease,
            currentRatio: currentRatio,
            targetRatio: optimalRatio,
            priority: priority,
            reason: _generateRecommendationReason(categoryName, difference, CategoryType.exercise),
          ),
        );
      }
    }

    return recommendations;
  }

  List<CategoryMixRecommendation> _generateDietRecommendations(
    CategoryMix currentMix,
    CategoryMix optimalMix,
    CategoryTrendAnalysis trendAnalysis,
  ) {
    final recommendations = <CategoryMixRecommendation>[];

    for (final entry in optimalMix.dietDistribution.entries) {
      final categoryName = entry.key;
      final optimalRatio = entry.value;
      final currentRatio = currentMix.dietDistribution[categoryName] ?? 0.0;
      final difference = optimalRatio - currentRatio;

      if (difference.abs() > 0.1) {
        // 10% threshold
        final priority =
            difference.abs() > 0.2 ? PatternRecommendationPriority.high : PatternRecommendationPriority.medium;

        recommendations.add(
          CategoryMixRecommendation(
            categoryName: categoryName,
            categoryType: CategoryType.diet,
            recommendationType:
                difference > 0 ? PatternRecommendationType.increase : PatternRecommendationType.decrease,
            currentRatio: currentRatio,
            targetRatio: optimalRatio,
            priority: priority,
            reason: _generateRecommendationReason(categoryName, difference, CategoryType.diet),
          ),
        );
      }
    }

    return recommendations;
  }

  String _generateRecommendationReason(String categoryName, double difference, CategoryType type) {
    if (difference > 0) {
      return '$categoryName 활동을 늘려보세요. 균형잡힌 ${type.displayName} 루틴에 도움이 됩니다.';
    } else {
      return '$categoryName 활동의 비중을 조금 줄이고 다른 카테고리도 시도해보세요.';
    }
  }

  // Category balance analysis methods
  CategoryBalance _calculateCategoryBalance(List<WeeklyReport> reports) {
    final recentReports = reports.length > 4 ? reports.sublist(reports.length - 4) : reports;

    final exerciseBalance = _calculateExerciseBalance(recentReports);
    final dietBalance = _calculateDietBalance(recentReports);

    return CategoryBalance(exerciseBalance: exerciseBalance, dietBalance: dietBalance);
  }

  ExerciseBalance _calculateExerciseBalance(List<WeeklyReport> reports) {
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.exerciseCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    final totalExercises = categoryTotals.values.fold(0, (sum, count) => sum + count);
    final diversity = _calculateDiversityScore(categoryTotals);
    final strengthCardioRatio = _calculateStrengthCardioRatio(categoryTotals);
    final flexibilityRatio = _calculateFlexibilityRatio(categoryTotals, totalExercises);

    return ExerciseBalance(
      diversityScore: diversity,
      strengthCardioRatio: strengthCardioRatio,
      flexibilityRatio: flexibilityRatio,
      categoryDistribution: categoryTotals,
    );
  }

  DietBalance _calculateDietBalance(List<WeeklyReport> reports) {
    final categoryTotals = <String, int>{};

    for (final report in reports) {
      for (final entry in report.stats.dietCategories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    final totalMeals = categoryTotals.values.fold(0, (sum, count) => sum + count);
    final diversity = _calculateDiversityScore(categoryTotals);
    final homeVsOutRatio = _calculateHomeVsOutRatio(categoryTotals);
    final healthyRatio = _calculateHealthyRatio(categoryTotals, totalMeals);

    return DietBalance(
      diversityScore: diversity,
      homeVsOutRatio: homeVsOutRatio,
      healthyRatio: healthyRatio,
      categoryDistribution: categoryTotals,
    );
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
        entropy -= proportion * log(proportion) / ln2;
      }
    }

    // Normalize to 0-1 scale
    final maxEntropy = log(categoryTotals.length) / ln2;
    return maxEntropy > 0 ? entropy / maxEntropy : 0.0;
  }

  double _calculateStrengthCardioRatio(Map<String, int> categoryTotals) {
    final strength = categoryTotals[ExerciseCategory.strength.displayName] ?? 0;
    final cardio = categoryTotals[ExerciseCategory.cardio.displayName] ?? 0;

    if (strength + cardio == 0) return 0.5; // Neutral ratio
    return strength / (strength + cardio);
  }

  double _calculateFlexibilityRatio(Map<String, int> categoryTotals, int totalExercises) {
    final flexibility = categoryTotals[ExerciseCategory.flexibility.displayName] ?? 0;
    return totalExercises > 0 ? flexibility / totalExercises : 0.0;
  }

  double _calculateHomeVsOutRatio(Map<String, int> categoryTotals) {
    final homeMade = categoryTotals[DietCategory.homeMade.displayName] ?? 0;
    final dining = categoryTotals[DietCategory.dining.displayName] ?? 0;

    if (homeMade + dining == 0) return 0.5; // Neutral ratio
    return homeMade / (homeMade + dining);
  }

  double _calculateHealthyRatio(Map<String, int> categoryTotals, int totalMeals) {
    final healthy =
        (categoryTotals[DietCategory.healthy.displayName] ?? 0) +
        (categoryTotals[DietCategory.protein.displayName] ?? 0) +
        (categoryTotals[DietCategory.homeMade.displayName] ?? 0);
    return totalMeals > 0 ? healthy / totalMeals : 0.0;
  }

  double _calculateBalanceScore(CategoryBalance balance) {
    final exerciseScore =
        (balance.exerciseBalance.diversityScore +
            (1 - (balance.exerciseBalance.strengthCardioRatio - 0.5).abs() * 2) +
            balance.exerciseBalance.flexibilityRatio) /
        3;

    final dietScore =
        (balance.dietBalance.diversityScore + balance.dietBalance.homeVsOutRatio + balance.dietBalance.healthyRatio) /
        3;

    return (exerciseScore + dietScore) / 2;
  }

  List<BalanceRecommendation> _generateBalanceRecommendations(CategoryBalance balance) {
    final recommendations = <BalanceRecommendation>[];

    // Exercise balance recommendations
    if (balance.exerciseBalance.diversityScore < 0.6) {
      recommendations.add(
        BalanceRecommendation(
          type: BalanceRecommendationType.increaseDiversity,
          categoryType: CategoryType.exercise,
          message: '운동 종류를 더 다양하게 시도해보세요',
          priority: PatternRecommendationPriority.medium,
        ),
      );
    }

    if ((balance.exerciseBalance.strengthCardioRatio - 0.5).abs() > 0.3) {
      final needsMore = balance.exerciseBalance.strengthCardioRatio < 0.5 ? '근력' : '유산소';
      recommendations.add(
        BalanceRecommendation(
          type: BalanceRecommendationType.balanceStrengthCardio,
          categoryType: CategoryType.exercise,
          message: '$needsMore 운동의 비중을 늘려보세요',
          priority: PatternRecommendationPriority.high,
        ),
      );
    }

    // Diet balance recommendations
    if (balance.dietBalance.healthyRatio < 0.6) {
      recommendations.add(
        BalanceRecommendation(
          type: BalanceRecommendationType.increaseHealthyOptions,
          categoryType: CategoryType.diet,
          message: '건강한 식단 옵션을 늘려보세요',
          priority: PatternRecommendationPriority.high,
        ),
      );
    }

    return recommendations;
  }

  List<HealthInsight> _generateHealthInsights(CategoryBalance balance, double balanceScore) {
    final insights = <HealthInsight>[];

    if (balanceScore > 0.8) {
      insights.add(
        HealthInsight(type: HealthInsightType.positive, message: '매우 균형잡힌 활동 패턴을 보이고 있습니다!', category: '전체 균형'),
      );
    } else if (balanceScore < 0.4) {
      insights.add(HealthInsight(type: HealthInsightType.warning, message: '활동의 균형을 맞춰보세요', category: '전체 균형'));
    }

    // Add specific insights based on patterns
    if (balance.exerciseBalance.flexibilityRatio > 0.3) {
      insights.add(
        HealthInsight(type: HealthInsightType.positive, message: '스트레칭과 유연성 운동을 잘 실천하고 있습니다', category: '운동 균형'),
      );
    }

    return insights;
  }

  // Seasonal trend prediction methods
  Map<String, SeasonalPattern> _analyzeSeasonalPatterns(List<WeeklyReport> reports) {
    final patterns = <String, SeasonalPattern>{};

    // Group reports by month
    final monthlyData = <int, List<WeeklyReport>>{};
    for (final report in reports) {
      final month = report.weekStartDate.month;
      monthlyData.putIfAbsent(month, () => []).add(report);
    }

    // Analyze exercise categories
    for (final category in ExerciseCategory.values) {
      final monthlyIntensity = <int, double>{};

      for (final entry in monthlyData.entries) {
        final month = entry.key;
        final monthReports = entry.value;
        final totalCount = monthReports.fold(
          0,
          (sum, report) => sum + (report.stats.exerciseCategories[category.displayName] ?? 0),
        );
        final avgIntensity = monthReports.isEmpty ? 0.0 : totalCount / monthReports.length;
        monthlyIntensity[month] = avgIntensity;
      }

      patterns[category.displayName] = SeasonalPattern(
        categoryName: category.displayName,
        categoryType: CategoryType.exercise,
        monthlyIntensity: monthlyIntensity,
        patternDescription: _generateSeasonalDescription(category.displayName, monthlyIntensity),
        seasonalStrength: _calculateSeasonalStrength(monthlyIntensity),
      );
    }

    // Analyze diet categories
    for (final category in DietCategory.values) {
      final monthlyIntensity = <int, double>{};

      for (final entry in monthlyData.entries) {
        final month = entry.key;
        final monthReports = entry.value;
        final totalCount = monthReports.fold(
          0,
          (sum, report) => sum + (report.stats.dietCategories[category.displayName] ?? 0),
        );
        final avgIntensity = monthReports.isEmpty ? 0.0 : totalCount / monthReports.length;
        monthlyIntensity[month] = avgIntensity;
      }

      patterns[category.displayName] = SeasonalPattern(
        categoryName: category.displayName,
        categoryType: CategoryType.diet,
        monthlyIntensity: monthlyIntensity,
        patternDescription: _generateSeasonalDescription(category.displayName, monthlyIntensity),
        seasonalStrength: _calculateSeasonalStrength(monthlyIntensity),
      );
    }

    return patterns;
  }

  Season _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  SeasonalPredictions _generateSeasonalPredictions(Map<String, SeasonalPattern> patterns, Season targetSeason) {
    final exercisePredictions = <String, double>{};
    final dietPredictions = <String, double>{};

    final targetMonths = _getSeasonMonths(targetSeason);

    for (final pattern in patterns.values) {
      final avgIntensity =
          targetMonths
              .map((month) => pattern.monthlyIntensity[month] ?? 0.0)
              .fold(0.0, (sum, intensity) => sum + intensity) /
          targetMonths.length;

      if (pattern.categoryType == CategoryType.exercise) {
        exercisePredictions[pattern.categoryName] = avgIntensity;
      } else {
        dietPredictions[pattern.categoryName] = avgIntensity;
      }
    }

    return SeasonalPredictions(exercisePredictions: exercisePredictions, dietPredictions: dietPredictions);
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

  double _calculateSeasonalConfidence(List<WeeklyReport> reports, DateTime targetDate) {
    final yearsOfData = reports.isEmpty ? 0 : (reports.last.weekStartDate.year - reports.first.weekStartDate.year) + 1;
    return min(yearsOfData / 2.0, 1.0); // Max confidence with 2+ years of data
  }

  String _generateSeasonalDescription(String categoryName, Map<int, double> monthlyIntensity) {
    if (monthlyIntensity.isEmpty) return '$categoryName의 계절별 패턴을 분석 중입니다';

    final maxMonth = monthlyIntensity.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final minMonth = monthlyIntensity.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    return '$categoryName은(는) $maxMonth월에 가장 활발하고 $minMonth월에 가장 적습니다';
  }

  double _calculateSeasonalStrength(Map<int, double> monthlyIntensity) {
    if (monthlyIntensity.length < 2) return 0.0;

    final values = monthlyIntensity.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold(0.0, (sum, value) => sum + pow(value - mean, 2)) / values.length;

    return mean > 0 ? sqrt(variance) / mean : 0.0;
  }
}

// Supporting model classes
class CategoryMix {
  final Map<String, double> exerciseDistribution;
  final Map<String, double> dietDistribution;

  const CategoryMix({required this.exerciseDistribution, required this.dietDistribution});

  factory CategoryMix.empty() {
    return const CategoryMix(exerciseDistribution: {}, dietDistribution: {});
  }
}

class CategoryMixRecommendation {
  final String categoryName;
  final CategoryType categoryType;
  final PatternRecommendationType recommendationType;
  final double currentRatio;
  final double targetRatio;
  final PatternRecommendationPriority priority;
  final String reason;

  const CategoryMixRecommendation({
    required this.categoryName,
    required this.categoryType,
    required this.recommendationType,
    required this.currentRatio,
    required this.targetRatio,
    required this.priority,
    required this.reason,
  });
}

enum PatternRecommendationType { increase, decrease, maintain }

enum PatternRecommendationPriority { low, medium, high }

class CategoryBalance {
  final ExerciseBalance exerciseBalance;
  final DietBalance dietBalance;

  const CategoryBalance({required this.exerciseBalance, required this.dietBalance});
}

class ExerciseBalance {
  final double diversityScore;
  final double strengthCardioRatio;
  final double flexibilityRatio;
  final Map<String, int> categoryDistribution;

  const ExerciseBalance({
    required this.diversityScore,
    required this.strengthCardioRatio,
    required this.flexibilityRatio,
    required this.categoryDistribution,
  });
}

class DietBalance {
  final double diversityScore;
  final double homeVsOutRatio;
  final double healthyRatio;
  final Map<String, int> categoryDistribution;

  const DietBalance({
    required this.diversityScore,
    required this.homeVsOutRatio,
    required this.healthyRatio,
    required this.categoryDistribution,
  });
}

class CategoryBalanceAnalysis {
  final ExerciseBalance exerciseBalance;
  final DietBalance dietBalance;
  final double overallBalanceScore;
  final List<BalanceRecommendation> balanceRecommendations;
  final List<HealthInsight> healthInsights;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryBalanceAnalysis({
    required this.exerciseBalance,
    required this.dietBalance,
    required this.overallBalanceScore,
    required this.balanceRecommendations,
    required this.healthInsights,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  factory CategoryBalanceAnalysis.empty() {
    return CategoryBalanceAnalysis(
      exerciseBalance: const ExerciseBalance(
        diversityScore: 0.0,
        strengthCardioRatio: 0.5,
        flexibilityRatio: 0.0,
        categoryDistribution: {},
      ),
      dietBalance: const DietBalance(
        diversityScore: 0.0,
        homeVsOutRatio: 0.5,
        healthyRatio: 0.0,
        categoryDistribution: {},
      ),
      overallBalanceScore: 0.0,
      balanceRecommendations: [],
      healthInsights: [],
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }
}

class BalanceRecommendation {
  final BalanceRecommendationType type;
  final CategoryType categoryType;
  final String message;
  final PatternRecommendationPriority priority;

  const BalanceRecommendation({
    required this.type,
    required this.categoryType,
    required this.message,
    required this.priority,
  });
}

enum BalanceRecommendationType { increaseDiversity, balanceStrengthCardio, increaseHealthyOptions, maintainBalance }

class HealthInsight {
  final HealthInsightType type;
  final String message;
  final String category;

  const HealthInsight({required this.type, required this.message, required this.category});
}

enum HealthInsightType { positive, warning, neutral }

class SeasonalTrendPrediction {
  final DateTime targetDate;
  final Season targetSeason;
  final Map<String, double> exercisePredictions;
  final Map<String, double> dietPredictions;
  final double confidenceScore;
  final Map<String, SeasonalPattern> seasonalPatterns;
  final DateTime analysisDate;

  const SeasonalTrendPrediction({
    required this.targetDate,
    required this.targetSeason,
    required this.exercisePredictions,
    required this.dietPredictions,
    required this.confidenceScore,
    required this.seasonalPatterns,
    required this.analysisDate,
  });
}

class SeasonalPredictions {
  final Map<String, double> exercisePredictions;
  final Map<String, double> dietPredictions;

  const SeasonalPredictions({required this.exercisePredictions, required this.dietPredictions});
}

enum Season { spring, summer, autumn, winter }
