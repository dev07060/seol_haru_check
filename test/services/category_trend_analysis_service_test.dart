import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_trend_analysis_service.dart';

void main() {
  group('CategoryTrendAnalysisService', () {
    late CategoryTrendAnalysisService service;

    setUp(() {
      service = CategoryTrendAnalysisService.instance;
    });

    group('analyzeWeekOverWeekTrends', () {
      test('should return empty analysis when no historical data', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 8),
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2},
          dietCategories: {'집밥/도시락': 5, '건강식/샐러드': 2},
        );

        final result = await service.analyzeWeekOverWeekTrends(currentReport, []);

        expect(result.weeksAnalyzed, equals(0));
        expect(result.exerciseCategoryTrends, isEmpty);
        expect(result.dietCategoryTrends, isEmpty);
        expect(result.overallTrendDirection, equals(TrendDirection.stable));
        expect(result.trendStrength, equals(0.0));
        expect(result.analysisConfidence, equals(0.0));
      });

      test('should analyze trends with historical data', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 5, '유산소 운동': 3},
          dietCategories: {'집밥/도시락': 7, '건강식/샐러드': 4},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 3, '유산소 운동': 2},
            dietCategories: {'집밥/도시락': 5, '건강식/샐러드': 2},
          ),
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 1),
            exerciseCategories: {'근력 운동': 2, '유산소 운동': 1},
            dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 1},
          ),
        ];

        final result = await service.analyzeWeekOverWeekTrends(currentReport, historicalReports);

        expect(result.weeksAnalyzed, equals(3));
        expect(result.exerciseCategoryTrends, isNotEmpty);
        expect(result.dietCategoryTrends, isNotEmpty);
        expect(result.hasSufficientData, isTrue);

        // Check exercise trends
        expect(result.exerciseCategoryTrends.containsKey('근력 운동'), isTrue);
        expect(result.exerciseCategoryTrends.containsKey('유산소 운동'), isTrue);

        final strengthTrend = result.exerciseCategoryTrends['근력 운동']!;
        expect(strengthTrend.direction, equals(TrendDirection.up));
        expect(strengthTrend.currentValue, equals(5));
        expect(strengthTrend.previousValue, equals(3));

        // Check diet trends
        expect(result.dietCategoryTrends.containsKey('집밥/도시락'), isTrue);
        expect(result.dietCategoryTrends.containsKey('건강식/샐러드'), isTrue);

        final homeMadeTrend = result.dietCategoryTrends['집밥/도시락']!;
        expect(homeMadeTrend.direction, equals(TrendDirection.up));
        expect(homeMadeTrend.currentValue, equals(7));
        expect(homeMadeTrend.previousValue, equals(5));
      });

      test('should calculate trend velocity correctly', () async {
        final currentReport = _createMockWeeklyReport(weekStart: DateTime(2024, 1, 22), totalCertifications: 10);

        final historicalReports = [
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 15), totalCertifications: 8),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 8), totalCertifications: 6),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 1), totalCertifications: 4),
        ];

        final result = await service.analyzeWeekOverWeekTrends(currentReport, historicalReports);

        // Velocity should be (10 - 4) / 3 weeks = 2.0 certifications per week
        expect(result.trendVelocity, equals(2.0));
        expect(result.overallTrendDirection, equals(TrendDirection.up));
      });
    });

    group('detectEmergingAndDecliningCategories', () {
      test('should return empty analysis with insufficient data', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 8),
          exerciseCategories: {'근력 운동': 3},
        );

        final result = await service.detectEmergingAndDecliningCategories(currentReport, []);

        expect(result.emergingCategories, isEmpty);
        expect(result.decliningCategories, isEmpty);
        expect(result.emergenceConfidence, equals(0.0));
        expect(result.hasEmergencePatterns, isFalse);
      });

      test('should detect emerging categories', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 3, '스트레칭/요가': 4}, // 스트레칭/요가 is new
          dietCategories: {'집밥/도시락': 5, '단백질 위주': 3}, // 단백질 위주 is new
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 3},
            dietCategories: {'집밥/도시락': 5},
          ),
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 1),
            exerciseCategories: {'근력 운동': 2},
            dietCategories: {'집밥/도시락': 4},
          ),
        ];

        final result = await service.detectEmergingAndDecliningCategories(currentReport, historicalReports);

        expect(result.emergingCategories.length, equals(2));
        expect(result.hasEmergencePatterns, isTrue);

        final emergingExercise = result.emergingCategories.firstWhere((c) => c.categoryName == '스트레칭/요가');
        expect(emergingExercise.isNewCategory, isTrue);
        expect(emergingExercise.currentCount, equals(4));
        expect(emergingExercise.historicalAverage, equals(0.0));

        final emergingDiet = result.emergingCategories.firstWhere((c) => c.categoryName == '단백질 위주');
        expect(emergingDiet.isNewCategory, isTrue);
        expect(emergingDiet.currentCount, equals(3));
      });

      test('should detect declining categories', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 1}, // Significantly decreased
          dietCategories: {'집밥/도시락': 2}, // Significantly decreased
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 5, '유산소 운동': 3}, // 유산소 운동 disappeared
            dietCategories: {'집밥/도시락': 6, '건강식/샐러드': 4}, // 건강식/샐러드 disappeared
          ),
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 1),
            exerciseCategories: {'근력 운동': 4, '유산소 운동': 2},
            dietCategories: {'집밥/도시락': 5, '건강식/샐러드': 3},
          ),
        ];

        final result = await service.detectEmergingAndDecliningCategories(currentReport, historicalReports);

        expect(result.decliningCategories.length, greaterThanOrEqualTo(2));

        // Check for disappeared categories
        final disappearedExercise =
            result.decliningCategories.where((c) => c.categoryName == '유산소 운동' && c.hasDisappeared).toList();
        expect(disappearedExercise, isNotEmpty);

        final disappearedDiet =
            result.decliningCategories.where((c) => c.categoryName == '건강식/샐러드' && c.hasDisappeared).toList();
        expect(disappearedDiet, isNotEmpty);
      });

      test('should analyze category lifecycles', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 22),
          exerciseCategories: {'근력 운동': 5, '유산소 운동': 3},
        );

        final historicalReports = [
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 15), exerciseCategories: {'근력 운동': 4, '유산소 운동': 2}),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 8), exerciseCategories: {'근력 운동': 3, '유산소 운동': 1}),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 1), exerciseCategories: {'근력 운동': 2}),
        ];

        final result = await service.detectEmergingAndDecliningCategories(currentReport, historicalReports);

        expect(result.lifecyclePatterns, isNotEmpty);
        expect(result.lifecyclePatterns.containsKey('근력 운동'), isTrue);

        final strengthLifecycle = result.lifecyclePatterns['근력 운동']!;
        expect(strengthLifecycle.activeWeeks, equals(4)); // Active in all 4 weeks
        expect(strengthLifecycle.totalWeeks, equals(4));
        expect(strengthLifecycle.activityRatio, equals(1.0));
        expect(strengthLifecycle.isActive, isTrue);
      });
    });

    group('recognizeCategoryPreferencePatterns', () {
      test('should return empty patterns with insufficient data', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 8),
          exerciseCategories: {'근력 운동': 3},
        );

        final result = await service.recognizeCategoryPreferencePatterns(currentReport, []);

        expect(result.exercisePreferences, isEmpty);
        expect(result.dietPreferences, isEmpty);
        expect(result.preferenceClusters, isEmpty);
      });

      test('should analyze exercise preferences', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 22),
          exerciseCategories: {'근력 운동': 5, '유산소 운동': 2},
        );

        final historicalReports = [
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 15), exerciseCategories: {'근력 운동': 4, '유산소 운동': 2}),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 8), exerciseCategories: {'근력 운동': 5, '유산소 운동': 1}),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 1), exerciseCategories: {'근력 운동': 3, '유산소 운동': 2}),
        ];

        final result = await service.recognizeCategoryPreferencePatterns(currentReport, historicalReports);

        expect(result.exercisePreferences, isNotEmpty);
        expect(result.exercisePreferences.containsKey('근력 운동'), isTrue);
        expect(result.exercisePreferences.containsKey('유산소 운동'), isTrue);

        final strengthPreference = result.exercisePreferences['근력 운동']!;
        expect(strengthPreference.totalCount, equals(17)); // 5+4+5+3
        expect(strengthPreference.frequency, equals(4)); // Active in all 4 weeks
        expect(strengthPreference.currentCount, equals(5));
        expect(strengthPreference.historicalAverage, equals(4.0)); // (4+5+3)/3

        // 근력 운동 should have higher intensity than 유산소 운동
        final cardioPreference = result.exercisePreferences['유산소 운동']!;
        expect(strengthPreference.intensity, greaterThan(cardioPreference.intensity));
      });

      test('should analyze preference stability', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 22),
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 3},
          dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 4},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 15),
            exerciseCategories: {'근력 운동': 3, '유산소 운동': 3},
            dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 4},
          ),
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 3, '유산소 운동': 3},
            dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 4},
          ),
        ];

        final result = await service.recognizeCategoryPreferencePatterns(currentReport, historicalReports);

        expect(result.preferenceStability.overallStability, greaterThan(0.8));
        expect(result.preferenceStability.exerciseStability, greaterThan(0.8));
        expect(result.preferenceStability.dietStability, greaterThan(0.8));
        expect(result.preferenceStability.stabilityTrend, equals(TrendDirection.stable));
      });

      test('should identify preference clusters', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2},
          dietCategories: {'집밥/도시락': 5, '건강식/샐러드': 3},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 2, '유산소 운동': 1},
            dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 2},
          ),
        ];

        final result = await service.recognizeCategoryPreferencePatterns(currentReport, historicalReports);

        expect(result.preferenceClusters, isNotEmpty);
        expect(result.preferenceClusters.length, equals(2)); // Exercise and diet clusters

        final exerciseCluster = result.preferenceClusters.firstWhere((c) => c.categoryType == CategoryType.exercise);
        expect(exerciseCluster.categories, contains('근력 운동'));
        expect(exerciseCluster.categories, contains('유산소 운동'));

        final dietCluster = result.preferenceClusters.firstWhere((c) => c.categoryType == CategoryType.diet);
        expect(dietCluster.categories, contains('집밥/도시락'));
        expect(dietCluster.categories, contains('건강식/샐러드'));
      });
    });

    group('analyzeCategoryDiversity', () {
      test('should calculate diversity score correctly', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 2, '유산소 운동': 2, '스트레칭/요가': 2},
          dietCategories: {'집밥/도시락': 2, '건강식/샐러드': 2, '단백질 위주': 2},
        );

        final result = await service.analyzeCategoryDiversity(currentReport, []);

        expect(result.currentDiversityScore, greaterThan(0.0));
        expect(result.diversityLevelDescription, isNotEmpty);
      });

      test('should analyze diversity trend', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 2, '유산소 운동': 2, '스트레칭/요가': 2},
          dietCategories: {'집밥/도시락': 2, '건강식/샐러드': 2, '단백질 위주': 2},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 5}, // Less diverse
            dietCategories: {'집밥/도시락': 5}, // Less diverse
          ),
        ];

        final result = await service.analyzeCategoryDiversity(currentReport, historicalReports);

        expect(result.diversityTrend, equals(TrendDirection.up));
        expect(result.currentDiversityScore, greaterThan(0.0));
      });

      test('should generate diversity recommendations', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 10}, // Very dominant category
          dietCategories: {'집밥/도시락': 10}, // Very dominant category
        );

        final result = await service.analyzeCategoryDiversity(currentReport, []);

        expect(result.recommendations, isNotEmpty);

        // Should recommend adding missing categories
        final addCategoryRecommendations =
            result.recommendations.where((r) => r.type == DiversityRecommendationType.addCategory).toList();
        expect(addCategoryRecommendations, isNotEmpty);

        // Should recommend balancing categories
        final balanceRecommendations =
            result.recommendations.where((r) => r.type == DiversityRecommendationType.balanceCategories).toList();
        expect(balanceRecommendations, isNotEmpty);

        // High priority recommendations should exist
        expect(result.highPriorityRecommendations, isNotEmpty);
      });

      test('should calculate diversity balance', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 3},
          dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 3},
        );

        final result = await service.analyzeCategoryDiversity(currentReport, []);

        expect(result.diversityBalance.overallBalance, greaterThan(0.0));
        expect(result.diversityBalance.exerciseBalance, greaterThan(0.0));
        expect(result.diversityBalance.dietBalance, greaterThan(0.0));
        expect(result.diversityBalance.balanceScore, greaterThan(0.0));
        expect(result.diversityBalance.balanceDescription, isNotEmpty);
      });

      test('should analyze diversity patterns', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 29),
          exerciseCategories: {'근력 운동': 2, '유산소 운동': 2, '스트레칭/요가': 2},
        );

        final historicalReports = [
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 22), exerciseCategories: {'근력 운동': 2, '유산소 운동': 2}),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 15), exerciseCategories: {'근력 운동': 2}),
          _createMockWeeklyReport(weekStart: DateTime(2024, 1, 8), exerciseCategories: {'근력 운동': 5}),
        ];

        final result = await service.analyzeCategoryDiversity(currentReport, historicalReports);

        expect(result.diversityPatterns, isNotEmpty);

        // Should detect increasing diversity pattern
        final increasingPatterns =
            result.diversityPatterns.where((p) => p.type == DiversityPatternType.increasing).toList();
        expect(increasingPatterns, isNotEmpty);
      });

      test('should calculate optimal diversity targets', () async {
        final currentReport = _createMockWeeklyReport(
          weekStart: DateTime(2024, 1, 15),
          exerciseCategories: {'근력 운동': 3},
          dietCategories: {'집밥/도시락': 4},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            weekStart: DateTime(2024, 1, 8),
            exerciseCategories: {'근력 운동': 2, '유산소 운동': 2},
            dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 2},
          ),
        ];

        final result = await service.analyzeCategoryDiversity(currentReport, historicalReports);

        expect(result.optimalTargets.currentScore, greaterThan(0.0));
        expect(result.optimalTargets.shortTermTarget, greaterThanOrEqualTo(result.optimalTargets.currentScore));
        expect(result.optimalTargets.longTermTarget, greaterThanOrEqualTo(result.optimalTargets.shortTermTarget));
        expect(result.optimalTargets.optimalExerciseCategories, greaterThan(0));
        expect(result.optimalTargets.optimalDietCategories, greaterThan(0));
        expect(result.optimalTargets.targetDescription, isNotEmpty);
      });
    });
  });
}

/// Helper function to create mock weekly reports for testing
WeeklyReport _createMockWeeklyReport({
  required DateTime weekStart,
  Map<String, int> exerciseCategories = const {},
  Map<String, int> dietCategories = const {},
  int? totalCertifications,
}) {
  final calculatedTotal =
      totalCertifications ??
      (exerciseCategories.values.fold(0, (sum, count) => sum + count) +
          dietCategories.values.fold(0, (sum, count) => sum + count));

  final stats = WeeklyStats(
    totalCertifications: calculatedTotal,
    exerciseDays: exerciseCategories.isNotEmpty ? exerciseCategories.length : 0,
    dietDays: dietCategories.isNotEmpty ? dietCategories.length : 0,
    exerciseTypes: exerciseCategories,
    exerciseCategories: exerciseCategories,
    dietCategories: dietCategories,
    consistencyScore: 0.8,
  );

  final analysis = const AIAnalysis(
    exerciseInsights: 'Test exercise insights',
    dietInsights: 'Test diet insights',
    overallAssessment: 'Test overall assessment',
    strengthAreas: ['Test strength'],
    improvementAreas: ['Test improvement'],
  );

  return WeeklyReport(
    id: 'test_${weekStart.millisecondsSinceEpoch}',
    userUuid: 'test_user',
    weekStartDate: weekStart,
    weekEndDate: weekStart.add(const Duration(days: 6)),
    generatedAt: DateTime.now(),
    stats: stats,
    analysis: analysis,
    recommendations: ['Test recommendation'],
    status: ReportStatus.completed,
  );
}
