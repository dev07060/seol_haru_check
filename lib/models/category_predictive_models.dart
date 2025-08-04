import 'package:seol_haru_check/models/category_visualization_models.dart';

/// Model for category preference predictions
class CategoryPreferencePrediction {
  final Map<String, CategoryPreferenceMetrics> exercisePredictions;
  final Map<String, CategoryPreferenceMetrics> dietPredictions;
  final double predictionConfidence;
  final int weeksAhead;
  final List<PreferenceInsight> insights;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryPreferencePrediction({
    required this.exercisePredictions,
    required this.dietPredictions,
    required this.predictionConfidence,
    required this.weeksAhead,
    required this.insights,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  factory CategoryPreferencePrediction.empty() {
    return CategoryPreferencePrediction(
      exercisePredictions: {},
      dietPredictions: {},
      predictionConfidence: 0.0,
      weeksAhead: 0,
      insights: [],
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }
}

/// Metrics for individual category preference predictions
class CategoryPreferenceMetrics {
  final String categoryName;
  final CategoryType categoryType;
  final double predictedValue;
  final double confidence;
  final double trend;
  final double preferenceStrength;
  final double historicalAverage;
  final double volatility;

  const CategoryPreferenceMetrics({
    required this.categoryName,
    required this.categoryType,
    required this.predictedValue,
    required this.confidence,
    required this.trend,
    required this.preferenceStrength,
    required this.historicalAverage,
    required this.volatility,
  });

  factory CategoryPreferenceMetrics.empty(String categoryName, CategoryType type) {
    return CategoryPreferenceMetrics(
      categoryName: categoryName,
      categoryType: type,
      predictedValue: 0.0,
      confidence: 0.0,
      trend: 0.0,
      preferenceStrength: 0.0,
      historicalAverage: 0.0,
      volatility: 0.0,
    );
  }
}

/// Insights generated from preference predictions
class PreferenceInsight {
  final PreferenceInsightType type;
  final String message;
  final String category;
  final double confidence;

  const PreferenceInsight({
    required this.type,
    required this.message,
    required this.category,
    required this.confidence,
  });
}

enum PreferenceInsightType { positive, warning, neutral, recommendation }

/// Model for seasonal category forecasting
class SeasonalCategoryForecast {
  final DateTime targetDate;
  final Season targetSeason;
  final Map<String, SeasonalCategoryForecastItem> exerciseForecasts;
  final Map<String, SeasonalCategoryForecastItem> dietForecasts;
  final Map<String, SeasonalCategoryPattern> seasonalPatterns;
  final double forecastConfidence;
  final List<SeasonalRecommendation> recommendations;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const SeasonalCategoryForecast({
    required this.targetDate,
    required this.targetSeason,
    required this.exerciseForecasts,
    required this.dietForecasts,
    required this.seasonalPatterns,
    required this.forecastConfidence,
    required this.recommendations,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  factory SeasonalCategoryForecast.empty() {
    return SeasonalCategoryForecast(
      targetDate: DateTime.now(),
      targetSeason: Season.spring,
      exerciseForecasts: {},
      dietForecasts: {},
      seasonalPatterns: {},
      forecastConfidence: 0.0,
      recommendations: [],
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }
}

/// Individual seasonal category forecast
class SeasonalCategoryForecastItem {
  final String categoryName;
  final CategoryType categoryType;
  final double forecastValue;
  final double confidence;
  final Season targetSeason;
  final SeasonalCategoryPattern seasonalPattern;

  const SeasonalCategoryForecastItem({
    required this.categoryName,
    required this.categoryType,
    required this.forecastValue,
    required this.confidence,
    required this.targetSeason,
    required this.seasonalPattern,
  });
}

/// Pattern analysis for seasonal trends
class SeasonalCategoryPattern {
  final String categoryName;
  final CategoryType categoryType;
  final Map<int, double> monthlyAverages;
  final Map<int, double> monthlyVariability;
  final int peakMonth;
  final int lowMonth;
  final double seasonalStrength;

  const SeasonalCategoryPattern({
    required this.categoryName,
    required this.categoryType,
    required this.monthlyAverages,
    required this.monthlyVariability,
    required this.peakMonth,
    required this.lowMonth,
    required this.seasonalStrength,
  });
}

/// Seasonal recommendations
class SeasonalRecommendation {
  final String categoryName;
  final CategoryType categoryType;
  final SeasonalRecommendationType recommendationType;
  final Season targetSeason;
  final String message;
  final double confidence;

  const SeasonalRecommendation({
    required this.categoryName,
    required this.categoryType,
    required this.recommendationType,
    required this.targetSeason,
    required this.message,
    required this.confidence,
  });
}

enum SeasonalRecommendationType { increase, decrease, maintain, explore }

/// Model for category-based activity suggestions
class CategoryActivitySuggestions {
  final List<CategoryActivitySuggestion> exerciseSuggestions;
  final List<CategoryActivitySuggestion> dietSuggestions;
  final List<TimingSuggestion> timingSuggestions;
  final double suggestionConfidence;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryActivitySuggestions({
    required this.exerciseSuggestions,
    required this.dietSuggestions,
    required this.timingSuggestions,
    required this.suggestionConfidence,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  factory CategoryActivitySuggestions.empty() {
    return CategoryActivitySuggestions(
      exerciseSuggestions: [],
      dietSuggestions: [],
      timingSuggestions: [],
      suggestionConfidence: 0.0,
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }
}

/// Individual category activity suggestion
class CategoryActivitySuggestion {
  final String categoryName;
  final CategoryType categoryType;
  final ActivitySuggestionType suggestionType;
  final String message;
  final SuggestionPriority priority;
  final double confidence;

  const CategoryActivitySuggestion({
    required this.categoryName,
    required this.categoryType,
    required this.suggestionType,
    required this.message,
    required this.priority,
    required this.confidence,
  });
}

enum ActivitySuggestionType { explore, maintain, revive, balance }

enum SuggestionPriority { low, medium, high }

/// Timing-based suggestions
class TimingSuggestion {
  final int dayOfWeek;
  final TimingSuggestionType suggestionType;
  final String message;
  final double confidence;

  const TimingSuggestion({
    required this.dayOfWeek,
    required this.suggestionType,
    required this.message,
    required this.confidence,
  });
}

enum TimingSuggestionType { increase, decrease, maintain }

/// Analysis of category usage patterns
class CategoryPatternAnalysis {
  final Map<String, CategoryUsagePattern> exercisePatterns;
  final Map<String, CategoryUsagePattern> dietPatterns;
  final DateTime analysisDate;

  const CategoryPatternAnalysis({
    required this.exercisePatterns,
    required this.dietPatterns,
    required this.analysisDate,
  });
}

/// Usage pattern for individual categories
class CategoryUsagePattern {
  final String categoryName;
  final CategoryType categoryType;
  final double usageFrequency;
  final double averageUsage;
  final int peakUsage;
  final double consistency;
  final double trend;

  const CategoryUsagePattern({
    required this.categoryName,
    required this.categoryType,
    required this.usageFrequency,
    required this.averageUsage,
    required this.peakUsage,
    required this.consistency,
    required this.trend,
  });
}

/// Model for category optimization recommendations
class CategoryOptimizationRecommendations {
  final List<OptimizationRecommendation> recommendations;
  final List<OptimizationOpportunity> optimizationOpportunities;
  final Map<String, double> expectedOutcomes;
  final CategoryBalanceAnalysis currentBalance;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryOptimizationRecommendations({
    required this.recommendations,
    required this.optimizationOpportunities,
    required this.expectedOutcomes,
    required this.currentBalance,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  factory CategoryOptimizationRecommendations.empty() {
    return CategoryOptimizationRecommendations(
      recommendations: [],
      optimizationOpportunities: [],
      expectedOutcomes: {},
      currentBalance: CategoryBalanceAnalysis.empty(),
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }
}

/// Individual optimization recommendation
class OptimizationRecommendation {
  final OptimizationRecommendationType type;
  final String? categoryName;
  final CategoryType? categoryType;
  final String description;
  final double expectedImpact;
  final OptimizationPriority priority;
  final List<String> actionSteps;

  const OptimizationRecommendation({
    required this.type,
    this.categoryName,
    this.categoryType,
    required this.description,
    required this.expectedImpact,
    required this.priority,
    required this.actionSteps,
  });
}

enum OptimizationRecommendationType {
  increaseCategoryUsage,
  decreaseCategoryUsage,
  improveConsistency,
  balanceCategories,
}

enum OptimizationPriority { low, medium, high }

/// Optimization opportunities identified
class OptimizationOpportunity {
  final OptimizationOpportunityType type;
  final String description;
  final double currentScore;
  final double targetScore;
  final OptimizationPriority priority;

  const OptimizationOpportunity({
    required this.type,
    required this.description,
    required this.currentScore,
    required this.targetScore,
    required this.priority,
  });
}

enum OptimizationOpportunityType {
  increaseExerciseDiversity,
  increaseDietDiversity,
  improveConsistency,
  balanceActivity,
}

/// Category balance analysis
class CategoryBalanceAnalysis {
  final double exerciseBalance;
  final double dietBalance;
  final double overallBalance;
  final DateTime analysisDate;

  const CategoryBalanceAnalysis({
    required this.exerciseBalance,
    required this.dietBalance,
    required this.overallBalance,
    required this.analysisDate,
  });

  factory CategoryBalanceAnalysis.empty() {
    return CategoryBalanceAnalysis(
      exerciseBalance: 0.0,
      dietBalance: 0.0,
      overallBalance: 0.0,
      analysisDate: DateTime.now(),
    );
  }
}

/// Seasons for seasonal analysis
enum Season { spring, summer, autumn, winter }

/// Model for category correlation analysis
class CategoryCorrelationAnalysis {
  final Map<String, Map<String, double>> exerciseCorrelations;
  final Map<String, Map<String, double>> dietCorrelations;
  final Map<String, Map<String, double>> crossTypeCorrelations;
  final List<CategoryCombination> effectiveCombinations;
  final List<CategorySynergyRecommendation> synergyRecommendations;
  final CategoryBalanceOptimization balanceOptimization;
  final List<HabitStackingRecommendation> habitStackingRecommendations;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryCorrelationAnalysis({
    required this.exerciseCorrelations,
    required this.dietCorrelations,
    required this.crossTypeCorrelations,
    required this.effectiveCombinations,
    required this.synergyRecommendations,
    required this.balanceOptimization,
    required this.habitStackingRecommendations,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  factory CategoryCorrelationAnalysis.empty() {
    return CategoryCorrelationAnalysis(
      exerciseCorrelations: {},
      dietCorrelations: {},
      crossTypeCorrelations: {},
      effectiveCombinations: [],
      synergyRecommendations: [],
      balanceOptimization: CategoryBalanceOptimization.empty(),
      habitStackingRecommendations: [],
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }
}

/// Model for effective category combinations
class CategoryCombination {
  final List<String> categories;
  final List<CategoryType> categoryTypes;
  final double effectivenessScore;
  final double correlationStrength;
  final int occurrenceCount;
  final double consistencyScore;
  final List<String> benefits;
  final CombinationEffectivenessType effectivenessType;

  const CategoryCombination({
    required this.categories,
    required this.categoryTypes,
    required this.effectivenessScore,
    required this.correlationStrength,
    required this.occurrenceCount,
    required this.consistencyScore,
    required this.benefits,
    required this.effectivenessType,
  });
}

enum CombinationEffectivenessType { highSynergy, balanced, complementary, consistent }

/// Model for category synergy recommendations
class CategorySynergyRecommendation {
  final String primaryCategory;
  final CategoryType primaryType;
  final String recommendedCategory;
  final CategoryType recommendedType;
  final double synergyScore;
  final SynergyRecommendationType recommendationType;
  final String description;
  final List<String> expectedBenefits;
  final double confidence;
  final SynergyPriority priority;

  const CategorySynergyRecommendation({
    required this.primaryCategory,
    required this.primaryType,
    required this.recommendedCategory,
    required this.recommendedType,
    required this.synergyScore,
    required this.recommendationType,
    required this.description,
    required this.expectedBenefits,
    required this.confidence,
    required this.priority,
  });
}

enum SynergyRecommendationType { complement, enhance, balance, diversify }

enum SynergyPriority { low, medium, high, critical }

/// Model for category balance optimization
class CategoryBalanceOptimization {
  final double currentBalanceScore;
  final double targetBalanceScore;
  final Map<String, double> categoryWeights;
  final List<BalanceOptimizationSuggestion> suggestions;
  final Map<String, double> optimalDistribution;
  final double improvementPotential;
  final List<String> balanceIssues;

  const CategoryBalanceOptimization({
    required this.currentBalanceScore,
    required this.targetBalanceScore,
    required this.categoryWeights,
    required this.suggestions,
    required this.optimalDistribution,
    required this.improvementPotential,
    required this.balanceIssues,
  });

  factory CategoryBalanceOptimization.empty() {
    return const CategoryBalanceOptimization(
      currentBalanceScore: 0.0,
      targetBalanceScore: 0.0,
      categoryWeights: {},
      suggestions: [],
      optimalDistribution: {},
      improvementPotential: 0.0,
      balanceIssues: [],
    );
  }
}

/// Individual balance optimization suggestion
class BalanceOptimizationSuggestion {
  final String categoryName;
  final CategoryType categoryType;
  final BalanceOptimizationType optimizationType;
  final double currentUsage;
  final double recommendedUsage;
  final double impactScore;
  final String description;
  final List<String> actionSteps;

  const BalanceOptimizationSuggestion({
    required this.categoryName,
    required this.categoryType,
    required this.optimizationType,
    required this.currentUsage,
    required this.recommendedUsage,
    required this.impactScore,
    required this.description,
    required this.actionSteps,
  });
}

enum BalanceOptimizationType { increase, decrease, maintain, introduce }

/// Model for habit stacking recommendations
class HabitStackingRecommendation {
  final String anchorCategory;
  final CategoryType anchorType;
  final String stackedCategory;
  final CategoryType stackedType;
  final HabitStackingType stackingType;
  final double stackingScore;
  final String description;
  final List<String> implementationSteps;
  final double successProbability;
  final HabitStackingPriority priority;
  final Map<String, dynamic> timingRecommendations;

  const HabitStackingRecommendation({
    required this.anchorCategory,
    required this.anchorType,
    required this.stackedCategory,
    required this.stackedType,
    required this.stackingType,
    required this.stackingScore,
    required this.description,
    required this.implementationSteps,
    required this.successProbability,
    required this.priority,
    required this.timingRecommendations,
  });
}

enum HabitStackingType { sequential, simultaneous, alternating, preparatory }

enum HabitStackingPriority { low, medium, high }
