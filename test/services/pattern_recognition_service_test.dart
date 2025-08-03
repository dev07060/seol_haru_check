import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/pattern_recognition_service.dart';

void main() {
  group('PatternRecognitionService', () {
    late PatternRecognitionService service;

    setUp(() {
      service = PatternRecognitionService();
    });

    group('analyzeCategoryTrends', () {
      test('returns empty analysis for insufficient data', () {
        final reports = [_createMockReport(DateTime.now(), 1, 1)];

        final result = service.analyzeCategoryTrends(reports);

        expect(result.weeksAnalyzed, equals(0));
        expect(result.exerciseCategoryTrends, isEmpty);
        expect(result.dietCategoryTrends, isEmpty);
      });

      test('analyzes trends with sufficient data', () {
        final reports = [
          _createMockReport(DateTime.now().subtract(const Duration(days: 21)), 2, 3),
          _createMockReport(DateTime.now().subtract(const Duration(days: 14)), 3, 4),
          _createMockReport(DateTime.now().subtract(const Duration(days: 7)), 4, 5),
          _createMockReport(DateTime.now(), 5, 6),
        ];

        final result = service.analyzeCategoryTrends(reports);

        expect(result.weeksAnalyzed, equals(4));
        expect(result.exerciseCategoryTrends, isNotEmpty);
        expect(result.dietCategoryTrends, isNotEmpty);
        expect(result.overallTrendDirection, isNotNull);
        expect(result.analysisConfidence, greaterThan(0));
      });

      test('calculates trend direction correctly', () {
        final reports = [
          _createMockReport(DateTime.now().subtract(const Duration(days: 21)), 1, 1),
          _createMockReport(DateTime.now().subtract(const Duration(days: 14)), 2, 2),
          _createMockReport(DateTime.now().subtract(const Duration(days: 7)), 3, 3),
          _createMockReport(DateTime.now(), 4, 4),
        ];

        final result = service.analyzeCategoryTrends(reports);

        expect(result.overallTrendDirection, equals(TrendDirection.up));
      });
    });

    group('generateOptimalCategoryMix', () {
      test('generates recommendations based on current vs optimal mix', () {
        final reports = [
          _createMockReport(DateTime.now().subtract(const Duration(days: 7)), 5, 5),
          _createMockReport(DateTime.now(), 5, 5),
        ];
        final trendAnalysis = service.analyzeCategoryTrends(reports);

        final recommendations = service.generateOptimalCategoryMix(reports, trendAnalysis);

        expect(recommendations, isNotEmpty);
        expect(recommendations.every((r) => r.priority != null), isTrue);
        expect(recommendations.every((r) => r.reason.isNotEmpty), isTrue);
      });

      test('prioritizes recommendations correctly', () {
        final reports = [
          _createMockReport(DateTime.now().subtract(const Duration(days: 7)), 10, 1),
          _createMockReport(DateTime.now(), 10, 1),
        ];
        final trendAnalysis = service.analyzeCategoryTrends(reports);

        final recommendations = service.generateOptimalCategoryMix(reports, trendAnalysis);

        final highPriorityRecs = recommendations.where((r) => r.priority == PatternRecommendationPriority.high);
        expect(highPriorityRecs, isNotEmpty);
      });
    });

    group('analyzeCategoryBalance', () {
      test('returns empty analysis for no data', () {
        final result = service.analyzeCategoryBalance([]);

        expect(result.weeksAnalyzed, equals(0));
        expect(result.overallBalanceScore, equals(0.0));
        expect(result.balanceRecommendations, isEmpty);
        expect(result.healthInsights, isEmpty);
      });

      test('calculates balance scores correctly', () {
        final reports = [
          _createBalancedMockReport(DateTime.now().subtract(const Duration(days: 7))),
          _createBalancedMockReport(DateTime.now()),
        ];

        final result = service.analyzeCategoryBalance(reports);

        expect(result.overallBalanceScore, greaterThan(0));
        expect(result.exerciseBalance.diversityScore, greaterThanOrEqualTo(0));
        expect(result.dietBalance.diversityScore, greaterThanOrEqualTo(0));
      });

      test('generates appropriate recommendations for imbalanced data', () {
        final reports = [
          _createImbalancedMockReport(DateTime.now().subtract(const Duration(days: 7))),
          _createImbalancedMockReport(DateTime.now()),
        ];

        final result = service.analyzeCategoryBalance(reports);

        expect(result.balanceRecommendations, isNotEmpty);
        expect(result.healthInsights, isNotEmpty);
      });
    });

    group('predictSeasonalTrends', () {
      test('predicts trends based on historical seasonal patterns', () {
        final reports = _createSeasonalMockReports();
        final targetDate = DateTime(2024, 6, 15); // Summer

        final result = service.predictSeasonalTrends(reports, targetDate);

        expect(result.targetSeason, equals(Season.summer));
        expect(result.exercisePredictions, isNotEmpty);
        expect(result.dietPredictions, isNotEmpty);
        expect(result.confidenceScore, greaterThanOrEqualTo(0));
      });

      test('handles insufficient seasonal data gracefully', () {
        final reports = [_createMockReport(DateTime.now(), 1, 1)];
        final targetDate = DateTime.now().add(const Duration(days: 30));

        final result = service.predictSeasonalTrends(reports, targetDate);

        expect(result.confidenceScore, lessThanOrEqualTo(0.5));
        expect(result.seasonalPatterns, isNotEmpty);
      });
    });
  });
}

// Helper methods for creating mock data
WeeklyReport _createMockReport(DateTime date, int exerciseCount, int dietCount) {
  final stats = WeeklyStats(
    totalCertifications: exerciseCount + dietCount,
    exerciseDays: exerciseCount > 0 ? (exerciseCount / 2).ceil() : 0,
    dietDays: dietCount > 0 ? (dietCount / 2).ceil() : 0,
    exerciseTypes: {'운동': exerciseCount},
    exerciseCategories: {
      ExerciseCategory.strength.displayName: (exerciseCount * 0.4).round(),
      ExerciseCategory.cardio.displayName: (exerciseCount * 0.3).round(),
      ExerciseCategory.flexibility.displayName: (exerciseCount * 0.2).round(),
      ExerciseCategory.sports.displayName: (exerciseCount * 0.1).round(),
    },
    dietCategories: {
      DietCategory.homeMade.displayName: (dietCount * 0.5).round(),
      DietCategory.healthy.displayName: (dietCount * 0.3).round(),
      DietCategory.protein.displayName: (dietCount * 0.2).round(),
    },
    consistencyScore: 0.8,
  );

  final analysis = const AIAnalysis(
    exerciseInsights: 'Test insights',
    dietInsights: 'Test insights',
    overallAssessment: 'Test assessment',
    strengthAreas: ['Test strength'],
    improvementAreas: ['Test improvement'],
  );

  return WeeklyReport(
    id: 'test-${date.millisecondsSinceEpoch}',
    userUuid: 'test-user',
    weekStartDate: date,
    weekEndDate: date.add(const Duration(days: 6)),
    generatedAt: DateTime.now(),
    stats: stats,
    analysis: analysis,
    recommendations: ['Test recommendation'],
    status: ReportStatus.completed,
  );
}

WeeklyReport _createBalancedMockReport(DateTime date) {
  final stats = WeeklyStats(
    totalCertifications: 10,
    exerciseDays: 4,
    dietDays: 5,
    exerciseTypes: {'운동': 5},
    exerciseCategories: {
      ExerciseCategory.strength.displayName: 2,
      ExerciseCategory.cardio.displayName: 2,
      ExerciseCategory.flexibility.displayName: 1,
    },
    dietCategories: {
      DietCategory.homeMade.displayName: 3,
      DietCategory.healthy.displayName: 1,
      DietCategory.protein.displayName: 1,
    },
    consistencyScore: 0.8,
  );

  final analysis = const AIAnalysis(
    exerciseInsights: 'Balanced exercise routine',
    dietInsights: 'Balanced diet',
    overallAssessment: 'Well balanced',
    strengthAreas: ['Consistency'],
    improvementAreas: [],
  );

  return WeeklyReport(
    id: 'balanced-${date.millisecondsSinceEpoch}',
    userUuid: 'test-user',
    weekStartDate: date,
    weekEndDate: date.add(const Duration(days: 6)),
    generatedAt: DateTime.now(),
    stats: stats,
    analysis: analysis,
    recommendations: [],
    status: ReportStatus.completed,
  );
}

WeeklyReport _createImbalancedMockReport(DateTime date) {
  final stats = WeeklyStats(
    totalCertifications: 8,
    exerciseDays: 2,
    dietDays: 6,
    exerciseTypes: {'운동': 2},
    exerciseCategories: {
      ExerciseCategory.strength.displayName: 2,
      ExerciseCategory.cardio.displayName: 0,
      ExerciseCategory.flexibility.displayName: 0,
    },
    dietCategories: {
      DietCategory.homeMade.displayName: 1,
      DietCategory.healthy.displayName: 0,
      DietCategory.dining.displayName: 5,
    },
    consistencyScore: 0.4,
  );

  final analysis = const AIAnalysis(
    exerciseInsights: 'Need more variety',
    dietInsights: 'Too much dining out',
    overallAssessment: 'Needs improvement',
    strengthAreas: [],
    improvementAreas: ['Exercise variety', 'Home cooking'],
  );

  return WeeklyReport(
    id: 'imbalanced-${date.millisecondsSinceEpoch}',
    userUuid: 'test-user',
    weekStartDate: date,
    weekEndDate: date.add(const Duration(days: 6)),
    generatedAt: DateTime.now(),
    stats: stats,
    analysis: analysis,
    recommendations: ['Try more exercise types', 'Cook more at home'],
    status: ReportStatus.completed,
  );
}

List<WeeklyReport> _createSeasonalMockReports() {
  final reports = <WeeklyReport>[];

  // Create reports across different seasons
  final seasons = [
    DateTime(2023, 3, 1), // Spring
    DateTime(2023, 6, 1), // Summer
    DateTime(2023, 9, 1), // Autumn
    DateTime(2023, 12, 1), // Winter
  ];

  for (final seasonStart in seasons) {
    for (int week = 0; week < 4; week++) {
      final date = seasonStart.add(Duration(days: week * 7));
      final isWinter = date.month == 12 || date.month <= 2;
      final isSummer = date.month >= 6 && date.month <= 8;

      // Adjust activity levels based on season
      final exerciseCount = isWinter ? 2 : (isSummer ? 6 : 4);
      final dietCount = isWinter ? 6 : (isSummer ? 4 : 5);

      reports.add(_createMockReport(date, exerciseCount, dietCount));
    }
  }

  return reports;
}
