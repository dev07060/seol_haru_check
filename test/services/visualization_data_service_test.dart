import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/visualization_data_service.dart';

@GenerateMocks([FirebaseFirestore])
void main() {
  group('VisualizationDataService', () {
    late VisualizationDataService service;
    setUp(() {
      service = VisualizationDataService();
    });

    group('_processExerciseCategories', () {
      test('should process exercise categories with emoji and color mapping', () async {
        // Arrange
        final weeklyStats = WeeklyStats(
          totalCertifications: 10,
          exerciseDays: 5,
          dietDays: 4,
          exerciseTypes: {'strength': 3, 'cardio': 2},
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2, '스트레칭/요가': 1},
          dietCategories: {},
          consistencyScore: 0.8,
        );

        final report = WeeklyReport(
          id: 'test-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: weeklyStats,
          analysis: AIAnalysis(
            exerciseInsights: 'Good exercise variety',
            dietInsights: 'Balanced diet',
            overallAssessment: 'Great week',
            strengthAreas: ['consistency'],
            improvementAreas: ['variety'],
          ),
          recommendations: ['Keep it up'],
          status: ReportStatus.completed,
        );

        // Act
        final result = await service.processWeeklyData(report);

        // Assert
        expect(result.exerciseCategoryData, hasLength(3));

        final strengthData = result.exerciseCategoryData.firstWhere((data) => data.categoryName == '근력 운동');
        expect(strengthData.emoji, equals('💪'));
        expect(strengthData.count, equals(3));
        expect(strengthData.percentage, equals(3 / 6)); // 3 out of 6 total
        expect(strengthData.type, equals(CategoryType.exercise));

        final cardioData = result.exerciseCategoryData.firstWhere((data) => data.categoryName == '유산소 운동');
        expect(cardioData.emoji, equals('🏃'));
        expect(cardioData.count, equals(2));
        expect(cardioData.percentage, equals(2 / 6));
      });

      test('should handle unknown exercise categories with fallback', () async {
        // Arrange
        final weeklyStats = WeeklyStats(
          totalCertifications: 5,
          exerciseDays: 3,
          dietDays: 2,
          exerciseTypes: {},
          exerciseCategories: {'Unknown Exercise': 3, '근력 운동': 2},
          dietCategories: {},
          consistencyScore: 0.6,
        );

        final report = WeeklyReport(
          id: 'test-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: weeklyStats,
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: '',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        // Act
        final result = await service.processWeeklyData(report);

        // Assert
        expect(result.exerciseCategoryData, hasLength(2));

        final unknownData = result.exerciseCategoryData.firstWhere((data) => data.categoryName == 'Unknown Exercise');
        expect(unknownData.emoji, equals('🏃')); // Default exercise emoji
        expect(unknownData.count, equals(3));
        expect(unknownData.type, equals(CategoryType.exercise));
      });
    });

    group('_processDietCategories', () {
      test('should process diet categories with proper categorization', () async {
        // Arrange
        final weeklyStats = WeeklyStats(
          totalCertifications: 8,
          exerciseDays: 3,
          dietDays: 5,
          exerciseTypes: {},
          exerciseCategories: {},
          dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 2, '외식/배달': 1},
          consistencyScore: 0.7,
        );

        final report = WeeklyReport(
          id: 'test-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: weeklyStats,
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: 'Good diet variety',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        // Act
        final result = await service.processWeeklyData(report);

        // Assert
        expect(result.dietCategoryData, hasLength(3));

        final homeMadeData = result.dietCategoryData.firstWhere((data) => data.categoryName == '집밥/도시락');
        expect(homeMadeData.emoji, equals('🍱'));
        expect(homeMadeData.count, equals(3));
        expect(homeMadeData.percentage, equals(3 / 6)); // 3 out of 6 total
        expect(homeMadeData.type, equals(CategoryType.diet));

        final healthyData = result.dietCategoryData.firstWhere((data) => data.categoryName == '건강식/샐러드');
        expect(healthyData.emoji, equals('🥗'));
        expect(healthyData.count, equals(2));
        expect(healthyData.percentage, equals(2 / 6));
      });
    });

    group('_processHierarchicalData', () {
      test('should create hierarchical data structure', () async {
        // Arrange
        final weeklyStats = WeeklyStats(
          totalCertifications: 10,
          exerciseDays: 5,
          dietDays: 4,
          exerciseTypes: {'strength': 3, 'cardio': 2},
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2},
          dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 1},
          consistencyScore: 0.8,
        );

        final report = WeeklyReport(
          id: 'test-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: weeklyStats,
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: '',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        // Act
        final result = await service.processWeeklyData(report);

        // Assert
        expect(result.hierarchicalData, hasLength(3));
        expect(result.hierarchicalData.containsKey('운동'), isTrue);
        expect(result.hierarchicalData.containsKey('식단'), isTrue);
        expect(result.hierarchicalData.containsKey('운동 유형'), isTrue);

        expect(result.hierarchicalData['운동'], equals({'근력 운동': 3, '유산소 운동': 2}));
        expect(result.hierarchicalData['식단'], equals({'집밥/도시락': 3, '건강식/샐러드': 1}));
        expect(result.hierarchicalData['운동 유형'], equals({'strength': 3, 'cardio': 2}));
      });
    });

    group('calculateCategoryTrends', () {
      test('should calculate category trends and comparison logic', () async {
        // Arrange
        final currentStats = WeeklyStats(
          totalCertifications: 10,
          exerciseDays: 5,
          dietDays: 4,
          exerciseTypes: {},
          exerciseCategories: {'근력 운동': 5, '유산소 운동': 3}, // Increased from previous
          dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 2}, // New category added
          consistencyScore: 0.8,
        );

        final currentReport = WeeklyReport(
          id: 'current-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 8),
          weekEndDate: DateTime(2024, 1, 14),
          generatedAt: DateTime.now(),
          stats: currentStats,
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: '',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        final previousStats = WeeklyStats(
          totalCertifications: 8,
          exerciseDays: 4,
          dietDays: 3,
          exerciseTypes: {},
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2, '스트레칭/요가': 1}, // 스트레칭/요가 disappeared
          dietCategories: {'집밥/도시락': 3}, // 건강식/샐러드 is new
          consistencyScore: 0.7,
        );

        final historicalReport = WeeklyReport(
          id: 'historical-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: previousStats,
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: '',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        // Act
        final trendData = await service.calculateCategoryTrends(currentReport, [historicalReport]);

        // Assert
        expect(trendData.hasTrendData, isTrue);
        expect(trendData.weeksAnalyzed, equals(2));

        // Exercise category trends
        expect(trendData.exerciseCategoryTrends['근력 운동'], equals(TrendDirection.up)); // 3 -> 5
        expect(trendData.exerciseCategoryTrends['유산소 운동'], equals(TrendDirection.up)); // 2 -> 3
        expect(trendData.exerciseCategoryTrends['스트레칭/요가'], equals(TrendDirection.down)); // 1 -> 0

        // Diet category trends
        expect(trendData.dietCategoryTrends['집밥/도시락'], equals(TrendDirection.up)); // 3 -> 4
        expect(trendData.dietCategoryTrends.containsKey('건강식/샐러드'), isTrue); // New category

        // Change percentages
        expect(trendData.categoryChangePercentages['근력 운동'], closeTo(66.67, 0.1)); // (5-3)/3 * 100
        expect(trendData.categoryChangePercentages['집밥/도시락'], closeTo(33.33, 0.1)); // (4-3)/3 * 100
        expect(trendData.categoryChangePercentages['건강식/샐러드'], equals(100.0)); // New category
        expect(trendData.categoryChangePercentages['스트레칭/요가'], equals(-100.0)); // Disappeared

        // Emerging categories
        expect(trendData.emergingCategories, contains('건강식/샐러드')); // New category
        expect(trendData.emergingCategories, contains('근력 운동')); // Increased by >50%

        // Declining categories
        expect(trendData.decliningCategories, contains('스트레칭/요가')); // Disappeared
      });

      test('should return empty trends when no historical data', () async {
        // Arrange
        final currentReport = WeeklyReport(
          id: 'current-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 8),
          weekEndDate: DateTime(2024, 1, 14),
          generatedAt: DateTime.now(),
          stats: WeeklyStats(
            totalCertifications: 10,
            exerciseDays: 5,
            dietDays: 4,
            exerciseTypes: {},
            exerciseCategories: {'근력 운동': 5},
            dietCategories: {'집밥/도시락': 4},
            consistencyScore: 0.8,
          ),
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: '',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        // Act
        final trendData = await service.calculateCategoryTrends(currentReport, []);

        // Assert
        expect(trendData.hasTrendData, isFalse);
        expect(trendData.weeksAnalyzed, equals(0));
        expect(trendData.exerciseCategoryTrends, isEmpty);
        expect(trendData.dietCategoryTrends, isEmpty);
        expect(trendData.emergingCategories, isEmpty);
        expect(trendData.decliningCategories, isEmpty);
      });
    });

    group('processWeeklyData', () {
      test('should process complete weekly data successfully', () async {
        // Arrange
        final weeklyStats = WeeklyStats(
          totalCertifications: 12,
          exerciseDays: 5,
          dietDays: 6,
          exerciseTypes: {'strength': 4, 'cardio': 3},
          exerciseCategories: {'근력 운동': 4, '유산소 운동': 3, '스트레칭/요가': 1},
          dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 2, '외식/배달': 1},
          consistencyScore: 0.85,
        );

        final report = WeeklyReport(
          id: 'test-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: weeklyStats,
          analysis: AIAnalysis(
            exerciseInsights: 'Great exercise variety',
            dietInsights: 'Balanced nutrition',
            overallAssessment: 'Excellent week',
            strengthAreas: ['consistency', 'variety'],
            improvementAreas: ['hydration'],
          ),
          recommendations: ['Keep up the good work', 'Drink more water'],
          status: ReportStatus.completed,
        );

        // Act
        final result = await service.processWeeklyData(report);

        // Assert
        expect(result.hasSufficientData, isTrue);
        expect(result.totalCategoriesCount, equals(6)); // 3 exercise + 3 diet
        expect(result.exerciseCategoryData, hasLength(3));
        expect(result.dietCategoryData, hasLength(3));
        expect(result.hierarchicalData, hasLength(3));
        expect(result.consistencyMetrics.consistencyScore, equals(0.85));
        expect(result.goalProgress.containsKey('exercise_days'), isTrue);
        expect(result.goalProgress.containsKey('diet_days'), isTrue);
        expect(result.goalProgress.containsKey('consistency'), isTrue);
      });

      test('should handle empty categories gracefully', () async {
        // Arrange
        final weeklyStats = WeeklyStats(
          totalCertifications: 0,
          exerciseDays: 0,
          dietDays: 0,
          exerciseTypes: {},
          exerciseCategories: {},
          dietCategories: {},
          consistencyScore: 0.0,
        );

        final report = WeeklyReport(
          id: 'empty-report',
          userUuid: 'test-user',
          weekStartDate: DateTime(2024, 1, 1),
          weekEndDate: DateTime(2024, 1, 7),
          generatedAt: DateTime.now(),
          stats: weeklyStats,
          analysis: AIAnalysis(
            exerciseInsights: '',
            dietInsights: '',
            overallAssessment: '',
            strengthAreas: [],
            improvementAreas: [],
          ),
          recommendations: [],
          status: ReportStatus.completed,
        );

        // Act
        final result = await service.processWeeklyData(report);

        // Assert
        expect(result.hasSufficientData, isFalse);
        expect(result.totalCategoriesCount, equals(0));
        expect(result.exerciseCategoryData, isEmpty);
        expect(result.dietCategoryData, isEmpty);
        expect(result.hierarchicalData, isEmpty);
        expect(result.consistencyMetrics.consistencyScore, equals(0.0));
      });
    });
  });
}
