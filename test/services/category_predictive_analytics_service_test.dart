import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_predictive_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_predictive_analytics_service.dart';

import '../helpers/test_data_helper.dart';

void main() {
  group('CategoryPredictiveAnalyticsService', () {
    late CategoryPredictiveAnalyticsService service;

    setUp(() {
      service = CategoryPredictiveAnalyticsService.instance;
    });

    group('predictCategoryPreferences', () {
      test('should return empty prediction when insufficient data', () async {
        final reports = <WeeklyReport>[];

        final result = await service.predictCategoryPreferences(reports);

        expect(result.exercisePredictions, isEmpty);
        expect(result.dietPredictions, isEmpty);
        expect(result.predictionConfidence, equals(0.0));
        expect(result.weeksAnalyzed, equals(0));
      });

      test('should generate predictions with sufficient data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(5);

        final result = await service.predictCategoryPreferences(reports, weeksAhead: 4);

        expect(result.exercisePredictions, isNotEmpty);
        expect(result.dietPredictions, isNotEmpty);
        expect(result.predictionConfidence, greaterThan(0.0));
        expect(result.weeksAhead, equals(4));
        expect(result.weeksAnalyzed, equals(5));
      });

      test('should calculate prediction confidence based on data quality', () async {
        final reports = TestDataHelper.createMockWeeklyReports(8);

        final result = await service.predictCategoryPreferences(reports);

        expect(result.predictionConfidence, greaterThan(0.3));
        expect(result.predictionConfidence, lessThanOrEqualTo(1.0));
      });

      test('should generate insights when confidence is high', () async {
        final reports = TestDataHelper.createMockWeeklyReports(6);

        final result = await service.predictCategoryPreferences(reports);

        if (result.predictionConfidence > 0.6) {
          expect(result.insights, isNotEmpty);
        }
      });
    });

    group('forecastSeasonalCategoryTrends', () {
      test('should return empty forecast when insufficient data', () async {
        final reports = <WeeklyReport>[];
        final targetDate = DateTime.now().add(const Duration(days: 30));

        final result = await service.forecastSeasonalCategoryTrends(reports, targetDate);

        expect(result.exerciseForecasts, isEmpty);
        expect(result.dietForecasts, isEmpty);
        expect(result.forecastConfidence, equals(0.0));
      });

      test('should generate seasonal forecasts with sufficient data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(10);
        final targetDate = DateTime.now().add(const Duration(days: 90));

        final result = await service.forecastSeasonalCategoryTrends(reports, targetDate);

        expect(result.targetDate, equals(targetDate));
        expect(result.targetSeason, isA<Season>());
        expect(result.seasonalPatterns, isNotEmpty);
        expect(result.weeksAnalyzed, equals(10));
      });

      test('should determine correct season for target date', () async {
        final reports = TestDataHelper.createMockWeeklyReports(5);
        final springDate = DateTime(2024, 4, 15);

        final result = await service.forecastSeasonalCategoryTrends(reports, springDate);

        expect(result.targetSeason, equals(Season.spring));
      });
    });

    group('generateCategoryBasedActivitySuggestions', () {
      test('should return empty suggestions when no data', () async {
        final reports = <WeeklyReport>[];

        final result = await service.generateCategoryBasedActivitySuggestions(reports, null);

        expect(result.exerciseSuggestions, isEmpty);
        expect(result.dietSuggestions, isEmpty);
        expect(result.timingSuggestions, isEmpty);
        expect(result.suggestionConfidence, equals(0.0));
      });

      test('should generate activity suggestions with historical data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(6);
        final currentReport = TestDataHelper.createMockWeeklyReport();

        final result = await service.generateCategoryBasedActivitySuggestions(reports, currentReport);

        expect(result.weeksAnalyzed, equals(6));
        expect(result.suggestionConfidence, greaterThan(0.0));
      });

      test('should generate suggestions for different activity types', () async {
        final reports = TestDataHelper.createMockWeeklyReports(4);

        final result = await service.generateCategoryBasedActivitySuggestions(reports, null);

        // Verify suggestion types are properly categorized
        for (final suggestion in result.exerciseSuggestions) {
          expect(suggestion.categoryType, equals(CategoryType.exercise));
          expect(suggestion.suggestionType, isA<ActivitySuggestionType>());
          expect(suggestion.priority, isA<SuggestionPriority>());
        }

        for (final suggestion in result.dietSuggestions) {
          expect(suggestion.categoryType, equals(CategoryType.diet));
          expect(suggestion.suggestionType, isA<ActivitySuggestionType>());
          expect(suggestion.priority, isA<SuggestionPriority>());
        }
      });
    });

    group('generateCategoryOptimizationRecommendations', () {
      test('should return empty recommendations when no data', () async {
        final reports = <WeeklyReport>[];

        final result = await service.generateCategoryOptimizationRecommendations(reports, null);

        expect(result.recommendations, isEmpty);
        expect(result.optimizationOpportunities, isEmpty);
        expect(result.expectedOutcomes, isEmpty);
        expect(result.weeksAnalyzed, equals(0));
      });

      test('should generate optimization recommendations with data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(8);
        final currentReport = TestDataHelper.createMockWeeklyReport();

        final result = await service.generateCategoryOptimizationRecommendations(reports, currentReport);

        expect(result.weeksAnalyzed, equals(8));
        expect(result.currentBalance, isA<CategoryBalanceAnalysis>());
        expect(result.currentBalance.overallBalance, greaterThanOrEqualTo(0.0));
        expect(result.currentBalance.overallBalance, lessThanOrEqualTo(1.0));
      });

      test('should identify optimization opportunities', () async {
        final reports = TestDataHelper.createMockWeeklyReports(6);

        final result = await service.generateCategoryOptimizationRecommendations(reports, null);

        // Should identify opportunities when balance is low
        if (result.currentBalance.overallBalance < 0.6) {
          expect(result.optimizationOpportunities, isNotEmpty);
        }
      });

      test('should prioritize recommendations correctly', () async {
        final reports = TestDataHelper.createMockWeeklyReports(5);

        final result = await service.generateCategoryOptimizationRecommendations(reports, null);

        if (result.recommendations.isNotEmpty) {
          // Verify recommendations are sorted by priority
          for (int i = 0; i < result.recommendations.length - 1; i++) {
            final current = result.recommendations[i];
            final next = result.recommendations[i + 1];
            expect(current.priority.index, greaterThanOrEqualTo(next.priority.index));
          }
        }
      });

      test('should calculate expected outcomes', () async {
        final reports = TestDataHelper.createMockWeeklyReports(7);

        final result = await service.generateCategoryOptimizationRecommendations(reports, null);

        if (result.recommendations.isNotEmpty) {
          expect(result.expectedOutcomes, isNotEmpty);
          expect(result.expectedOutcomes.containsKey('overall_improvement'), isTrue);
        }
      });
    });

    group('analyzeCategoryCorrelations', () {
      test('should return empty analysis when insufficient data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(2); // Less than minimum

        final result = await service.analyzeCategoryCorrelations(reports, null);

        expect(result.exerciseCorrelations, isEmpty);
        expect(result.dietCorrelations, isEmpty);
        expect(result.crossTypeCorrelations, isEmpty);
        expect(result.effectiveCombinations, isEmpty);
        expect(result.synergyRecommendations, isEmpty);
        expect(result.habitStackingRecommendations, isEmpty);
        expect(result.weeksAnalyzed, equals(0));
      });

      test('should calculate correlation matrices with sufficient data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(6);
        final currentReport = TestDataHelper.createMockWeeklyReport();

        final result = await service.analyzeCategoryCorrelations(reports, currentReport);

        expect(result.exerciseCorrelations, isNotEmpty);
        expect(result.dietCorrelations, isNotEmpty);
        expect(result.crossTypeCorrelations, isNotEmpty);
        expect(result.weeksAnalyzed, equals(7)); // 6 + 1 current
      });

      test('should identify effective category combinations', () async {
        final reports = TestDataHelper.createMockWeeklyReports(8);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        expect(result.effectiveCombinations, isA<List<CategoryCombination>>());

        for (final combination in result.effectiveCombinations) {
          expect(combination.categories, hasLength(2));
          expect(combination.categoryTypes, hasLength(2));
          expect(combination.effectivenessScore, greaterThanOrEqualTo(0.0));
          expect(combination.effectivenessScore, lessThanOrEqualTo(1.0));
          expect(combination.correlationStrength, greaterThanOrEqualTo(-1.0));
          expect(combination.correlationStrength, lessThanOrEqualTo(1.0));
          expect(combination.consistencyScore, greaterThanOrEqualTo(0.0));
          expect(combination.consistencyScore, lessThanOrEqualTo(1.0));
          expect(combination.benefits, isNotEmpty);
          expect(combination.effectivenessType, isA<CombinationEffectivenessType>());
        }
      });

      test('should generate category synergy recommendations', () async {
        final reports = TestDataHelper.createMockWeeklyReports(7);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        expect(result.synergyRecommendations, isA<List<CategorySynergyRecommendation>>());

        for (final recommendation in result.synergyRecommendations) {
          expect(recommendation.primaryCategory, isNotEmpty);
          expect(recommendation.recommendedCategory, isNotEmpty);
          expect(recommendation.primaryType, isA<CategoryType>());
          expect(recommendation.recommendedType, isA<CategoryType>());
          expect(recommendation.synergyScore, greaterThanOrEqualTo(0.0));
          expect(recommendation.synergyScore, lessThanOrEqualTo(1.0));
          expect(recommendation.recommendationType, isA<SynergyRecommendationType>());
          expect(recommendation.description, isNotEmpty);
          expect(recommendation.expectedBenefits, isNotEmpty);
          expect(recommendation.confidence, greaterThanOrEqualTo(0.0));
          expect(recommendation.confidence, lessThanOrEqualTo(1.0));
          expect(recommendation.priority, isA<SynergyPriority>());
        }
      });

      test('should create category balance optimization', () async {
        final reports = TestDataHelper.createMockWeeklyReports(6);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        expect(result.balanceOptimization, isA<CategoryBalanceOptimization>());
        expect(result.balanceOptimization.currentBalanceScore, greaterThanOrEqualTo(0.0));
        expect(result.balanceOptimization.currentBalanceScore, lessThanOrEqualTo(1.0));
        expect(result.balanceOptimization.targetBalanceScore, greaterThanOrEqualTo(0.0));
        expect(result.balanceOptimization.targetBalanceScore, lessThanOrEqualTo(1.0));
        expect(result.balanceOptimization.improvementPotential, greaterThanOrEqualTo(0.0));
        expect(result.balanceOptimization.improvementPotential, lessThanOrEqualTo(1.0));

        for (final suggestion in result.balanceOptimization.suggestions) {
          expect(suggestion.categoryName, isNotEmpty);
          expect(suggestion.categoryType, isA<CategoryType>());
          expect(suggestion.optimizationType, isA<BalanceOptimizationType>());
          expect(suggestion.currentUsage, greaterThanOrEqualTo(0.0));
          expect(suggestion.recommendedUsage, greaterThanOrEqualTo(0.0));
          expect(suggestion.impactScore, greaterThanOrEqualTo(0.0));
          expect(suggestion.description, isNotEmpty);
          expect(suggestion.actionSteps, isNotEmpty);
        }
      });

      test('should generate habit stacking recommendations', () async {
        final reports = TestDataHelper.createMockWeeklyReports(8);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        expect(result.habitStackingRecommendations, isA<List<HabitStackingRecommendation>>());

        for (final recommendation in result.habitStackingRecommendations) {
          expect(recommendation.anchorCategory, isNotEmpty);
          expect(recommendation.stackedCategory, isNotEmpty);
          expect(recommendation.anchorType, isA<CategoryType>());
          expect(recommendation.stackedType, isA<CategoryType>());
          expect(recommendation.stackingType, isA<HabitStackingType>());
          expect(recommendation.stackingScore, greaterThanOrEqualTo(0.0));
          expect(recommendation.stackingScore, lessThanOrEqualTo(1.0));
          expect(recommendation.description, isNotEmpty);
          expect(recommendation.implementationSteps, isNotEmpty);
          expect(recommendation.successProbability, greaterThanOrEqualTo(0.0));
          expect(recommendation.successProbability, lessThanOrEqualTo(1.0));
          expect(recommendation.priority, isA<HabitStackingPriority>());
          expect(recommendation.timingRecommendations, isNotEmpty);
        }
      });

      test('should handle correlation calculations correctly', () async {
        final reports = TestDataHelper.createMockWeeklyReports(5);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        // Verify correlation matrices have proper structure
        for (final entry in result.exerciseCorrelations.entries) {
          expect(entry.value, isA<Map<String, double>>());
          for (final correlation in entry.value.values) {
            expect(correlation, greaterThanOrEqualTo(-1.0));
            expect(correlation, lessThanOrEqualTo(1.0));
          }
        }

        for (final entry in result.dietCorrelations.entries) {
          expect(entry.value, isA<Map<String, double>>());
          for (final correlation in entry.value.values) {
            expect(correlation, greaterThanOrEqualTo(-1.0));
            expect(correlation, lessThanOrEqualTo(1.0));
          }
        }

        for (final entry in result.crossTypeCorrelations.entries) {
          expect(entry.value, isA<Map<String, double>>());
          for (final correlation in entry.value.values) {
            expect(correlation, greaterThanOrEqualTo(-1.0));
            expect(correlation, lessThanOrEqualTo(1.0));
          }
        }
      });

      test('should prioritize recommendations by effectiveness', () async {
        final reports = TestDataHelper.createMockWeeklyReports(10);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        // Verify effective combinations are sorted by effectiveness score
        if (result.effectiveCombinations.length > 1) {
          for (int i = 0; i < result.effectiveCombinations.length - 1; i++) {
            final current = result.effectiveCombinations[i];
            final next = result.effectiveCombinations[i + 1];
            expect(current.effectivenessScore, greaterThanOrEqualTo(next.effectivenessScore));
          }
        }

        // Verify synergy recommendations are sorted by synergy score
        if (result.synergyRecommendations.length > 1) {
          for (int i = 0; i < result.synergyRecommendations.length - 1; i++) {
            final current = result.synergyRecommendations[i];
            final next = result.synergyRecommendations[i + 1];
            expect(current.synergyScore, greaterThanOrEqualTo(next.synergyScore));
          }
        }

        // Verify habit stacking recommendations are sorted by stacking score
        if (result.habitStackingRecommendations.length > 1) {
          for (int i = 0; i < result.habitStackingRecommendations.length - 1; i++) {
            final current = result.habitStackingRecommendations[i];
            final next = result.habitStackingRecommendations[i + 1];
            expect(current.stackingScore, greaterThanOrEqualTo(next.stackingScore));
          }
        }
      });

      test('should identify balance issues correctly', () async {
        final reports = TestDataHelper.createMockWeeklyReports(6);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        expect(result.balanceOptimization.balanceIssues, isA<List<String>>());

        // Balance issues should be meaningful strings
        for (final issue in result.balanceOptimization.balanceIssues) {
          expect(issue, isNotEmpty);
          expect(issue, contains(RegExp(r'카테고리|다양성|집중')));
        }
      });

      test('should generate meaningful timing recommendations for habit stacking', () async {
        final reports = TestDataHelper.createMockWeeklyReports(7);

        final result = await service.analyzeCategoryCorrelations(reports, null);

        for (final recommendation in result.habitStackingRecommendations) {
          expect(recommendation.timingRecommendations['timing'], isNotEmpty);
          expect(recommendation.timingRecommendations['reason'], isNotEmpty);
          expect(recommendation.timingRecommendations['frequency'], isNotEmpty);
          expect(recommendation.timingRecommendations['duration'], isNotEmpty);
        }
      });
    });

    group('edge cases and error handling', () {
      test('should handle reports with no category data', () async {
        final reports = TestDataHelper.createMockWeeklyReports(3, emptyCategoryData: true);

        final predictions = await service.predictCategoryPreferences(reports);
        final suggestions = await service.generateCategoryBasedActivitySuggestions(reports, null);
        final optimizations = await service.generateCategoryOptimizationRecommendations(reports, null);

        expect(predictions.predictionConfidence, lessThan(0.5));
        expect(suggestions.suggestionConfidence, lessThan(0.5));
        expect(optimizations.currentBalance.overallBalance, equals(0.0));
      });

      test('should handle single report gracefully', () async {
        final reports = [TestDataHelper.createMockWeeklyReport()];

        final predictions = await service.predictCategoryPreferences(reports);
        final suggestions = await service.generateCategoryBasedActivitySuggestions(reports, null);

        expect(predictions.predictionConfidence, lessThan(0.5));
        expect(suggestions.suggestionConfidence, lessThan(0.5));
      });

      test('should handle future dates for seasonal forecasting', () async {
        final reports = TestDataHelper.createMockWeeklyReports(4);
        final futureDate = DateTime.now().add(const Duration(days: 365));

        final result = await service.forecastSeasonalCategoryTrends(reports, futureDate);

        expect(result.targetDate, equals(futureDate));
        expect(result.forecastConfidence, greaterThanOrEqualTo(0.0));
      });
    });
  });
}
