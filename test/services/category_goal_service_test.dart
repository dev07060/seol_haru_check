import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_goal_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_goal_service.dart';

void main() {
  group('CategoryGoalService', () {
    late CategoryGoalService service;

    setUp(() {
      service = CategoryGoalService.instance;
    });

    group('generateDynamicGoals', () {
      test('should generate diversity goals based on user patterns', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(
          exerciseCategories: {'근력 운동': 3, '유산소 운동': 2},
          dietCategories: {'집밥/도시락': 4, '건강식/샐러드': 2},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            exerciseCategories: {'근력 운동': 2, '유산소 운동': 1},
            dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 1},
            weekOffset: -7,
          ),
          _createMockWeeklyReport(
            exerciseCategories: {'근력 운동': 1, '스트레칭/요가': 2},
            dietCategories: {'집밥/도시락': 2, '단백질 위주': 2},
            weekOffset: -14,
          ),
        ];

        // Act
        final goals = await service.generateDynamicGoals(currentReport, historicalReports);

        // Assert
        expect(goals, isNotEmpty);
        expect(goals.any((goal) => goal.type == CategoryGoalType.diversity), isTrue);
        expect(goals.any((goal) => goal.type == CategoryGoalType.consistency), isTrue);
        expect(goals.any((goal) => goal.type == CategoryGoalType.exploration), isTrue);
      });

      test('should generate appropriate difficulty levels', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(exerciseCategories: {'근력 운동': 1}, dietCategories: {'집밥/도시락': 1});

        final historicalReports = [
          _createMockWeeklyReport(exerciseCategories: {'근력 운동': 1}, dietCategories: {'집밥/도시락': 1}, weekOffset: -7),
        ];

        // Act
        final goals = await service.generateDynamicGoals(currentReport, historicalReports);

        // Assert
        final diversityGoals = goals.where((goal) => goal.type == CategoryGoalType.diversity).toList();
        expect(diversityGoals, isNotEmpty);

        // Should suggest reasonable increase in diversity
        final diversityGoal = diversityGoals.first;
        expect(diversityGoal.targetValue, greaterThan(2));
        expect(diversityGoal.difficulty, isIn([GoalDifficulty.easy, GoalDifficulty.medium]));
      });
    });

    group('createDiversityTarget', () {
      test('should create appropriate diversity targets', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(
          exerciseCategories: {'근력 운동': 2, '유산소 운동': 1},
          dietCategories: {'집밥/도시락': 3, '건강식/샐러드': 1},
        );

        final historicalReports = [
          _createMockWeeklyReport(
            exerciseCategories: {'근력 운동': 1, '유산소 운동': 2},
            dietCategories: {'집밥/도시락': 2, '건강식/샐러드': 2},
            weekOffset: -7,
          ),
        ];

        // Act
        final target = await service.createDiversityTarget(currentReport, historicalReports);

        // Assert
        expect(target.exerciseTargetCount, greaterThan(0));
        expect(target.dietTargetCount, greaterThan(0));
        expect(target.totalTargetCount, equals(target.exerciseTargetCount + target.dietTargetCount));
        expect(target.currentExerciseCount, equals(2));
        expect(target.currentDietCount, equals(2));
        expect(target.diversityScore, greaterThanOrEqualTo(0.0));
        expect(target.targetDiversityScore, greaterThan(target.diversityScore));
      });

      test('should handle empty historical data', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(exerciseCategories: {'근력 운동': 1}, dietCategories: {'집밥/도시락': 1});

        // Act
        final target = await service.createDiversityTarget(currentReport, []);

        // Assert
        expect(target.exerciseTargetCount, equals(3)); // Default target
        expect(target.dietTargetCount, equals(3)); // Default target
        expect(target.totalTargetCount, equals(6));
        expect(target.targetDiversityScore, equals(0.7)); // Default target
      });
    });

    group('createConsistencyGoals', () {
      test('should create consistency goals for regular categories', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(exerciseCategories: {'근력 운동': 3}, dietCategories: {'집밥/도시락': 4});

        final historicalReports = [
          _createMockWeeklyReport(exerciseCategories: {'근력 운동': 2}, dietCategories: {'집밥/도시락': 3}, weekOffset: -7),
          _createMockWeeklyReport(exerciseCategories: {'근력 운동': 1}, dietCategories: {'집밥/도시락': 2}, weekOffset: -14),
          _createMockWeeklyReport(exerciseCategories: {'근력 운동': 2}, dietCategories: {'집밥/도시락': 3}, weekOffset: -21),
        ];

        // Act
        final goals = await service.createConsistencyGoals(currentReport, historicalReports);

        // Assert
        expect(goals, isNotEmpty);

        final strengthGoal = goals.firstWhere(
          (goal) => goal.categoryName == '근력 운동',
          orElse: () => throw StateError('No strength goal found'),
        );

        expect(strengthGoal.targetWeeks, greaterThan(0));
        expect(strengthGoal.currentWeeks, greaterThan(0));
        expect(strengthGoal.consistencyScore, greaterThan(0.0));
      });

      test('should not create goals for inconsistent categories', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(exerciseCategories: {'근력 운동': 1}, dietCategories: {});

        final historicalReports = [
          _createMockWeeklyReport(exerciseCategories: {}, dietCategories: {'집밥/도시락': 1}, weekOffset: -7),
          _createMockWeeklyReport(exerciseCategories: {'유산소 운동': 1}, dietCategories: {}, weekOffset: -14),
        ];

        // Act
        final goals = await service.createConsistencyGoals(currentReport, historicalReports);

        // Assert
        // Should have few or no goals due to low consistency
        expect(goals.length, lessThanOrEqualTo(1));
      });
    });

    group('createExplorationChallenges', () {
      test('should create challenges for unexplored categories', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(exerciseCategories: {'근력 운동': 2}, dietCategories: {'집밥/도시락': 3});

        final historicalReports = [
          _createMockWeeklyReport(exerciseCategories: {'근력 운동': 1}, dietCategories: {'집밥/도시락': 2}, weekOffset: -7),
        ];

        // Act
        final challenges = await service.createExplorationChallenges(currentReport, historicalReports);

        // Assert
        expect(challenges, isNotEmpty);

        final weeklyChallenge = challenges.firstWhere(
          (challenge) => challenge.title.contains('주간'),
          orElse: () => throw StateError('No weekly challenge found'),
        );

        expect(weeklyChallenge.targetCount, greaterThan(0));
        expect(weeklyChallenge.targetCategories, isNotEmpty);
        expect(weeklyChallenge.rewardPoints, greaterThan(0));
      });

      test('should create type-specific exploration challenges', () async {
        // Arrange
        final currentReport = _createMockWeeklyReport(
          exerciseCategories: {'근력 운동': 1}, // Only one exercise category
          dietCategories: {'집밥/도시락': 1, '건강식/샐러드': 1}, // Two diet categories
        );

        // Act
        final challenges = await service.createExplorationChallenges(currentReport, []);

        // Assert
        expect(challenges, isNotEmpty);

        // Should have exercise exploration challenge since only 1 exercise category used
        final exerciseChallenge = challenges.where((challenge) => challenge.title.contains('운동')).toList();

        expect(exerciseChallenge, isNotEmpty);
      });
    });

    group('updateGoalProgress', () {
      test('should update diversity goal progress correctly', () async {
        // Arrange
        final goal = CategoryGoal(
          id: 'test-goal',
          title: 'Test Diversity Goal',
          description: 'Test description',
          type: CategoryGoalType.diversity,
          difficulty: GoalDifficulty.medium,
          targetValue: 5,
          currentValue: 3,
          progress: 0.6,
          isCompleted: false,
          isActive: true,
          createdAt: DateTime.now(),
          basePoints: 20,
        );

        final currentReport = _createMockWeeklyReport(
          exerciseCategories: {'근력 운동': 1, '유산소 운동': 1, '스트레칭/요가': 1},
          dietCategories: {'집밥/도시락': 1, '건강식/샐러드': 1},
        );

        // Act
        final updatedGoal = await service.updateGoalProgress(goal, currentReport);

        // Assert
        expect(updatedGoal.currentValue, equals(5)); // 3 exercise + 2 diet categories
        expect(updatedGoal.progress, equals(1.0)); // 5/5 = 100%
        expect(updatedGoal.isCompleted, isTrue);
        expect(updatedGoal.completedAt, isNotNull);
      });

      test('should update exploration goal progress correctly', () async {
        // Arrange
        final goal = CategoryGoal(
          id: 'test-exploration',
          title: 'Test Exploration Goal',
          description: 'Try new categories',
          type: CategoryGoalType.exploration,
          difficulty: GoalDifficulty.medium,
          targetValue: 2,
          currentValue: 0,
          progress: 0.0,
          isCompleted: false,
          isActive: true,
          createdAt: DateTime.now(),
          basePoints: 25,
          targetCategories: ['스트레칭/요가', '단백질 위주'],
        );

        final currentReport = _createMockWeeklyReport(
          exerciseCategories: {'스트레칭/요가': 1}, // One target category
          dietCategories: {'집밥/도시락': 1}, // Non-target category
        );

        // Act
        final updatedGoal = await service.updateGoalProgress(goal, currentReport);

        // Assert
        expect(updatedGoal.currentValue, equals(1)); // One target category achieved
        expect(updatedGoal.progress, equals(0.5)); // 1/2 = 50%
        expect(updatedGoal.isCompleted, isFalse);
      });
    });

    group('getGoalSummary', () {
      test('should calculate summary statistics correctly', () async {
        // Arrange
        final goals = [
          _createMockGoal(CategoryGoalType.diversity, isCompleted: true, points: 30),
          _createMockGoal(CategoryGoalType.consistency, isCompleted: false, points: 20),
          _createMockGoal(CategoryGoalType.exploration, isCompleted: true, points: 50),
          _createMockGoal(CategoryGoalType.balance, isCompleted: false, isExpired: true, points: 25),
        ];

        // Act
        final summary = await service.getGoalSummary(goals);

        // Assert
        expect(summary.totalGoals, equals(4));
        expect(summary.activeGoals, equals(1)); // Only consistency goal is active
        expect(summary.completedGoals, equals(2)); // Diversity and exploration
        expect(summary.expiredGoals, equals(1)); // Balance goal
        expect(summary.totalPointsEarned, equals(120)); // 45 (30*1.5) + 75 (50*1.5) for completed medium goals
        expect(
          summary.totalPointsPossible,
          equals(188),
        ); // 45 + 30 + 75 + 38 (all medium difficulty with 1.5x multiplier, rounded)
        expect(summary.completionRate, equals(0.5)); // 2/4
      });

      test('should handle empty goals list', () async {
        // Act
        final summary = await service.getGoalSummary([]);

        // Assert
        expect(summary.totalGoals, equals(0));
        expect(summary.activeGoals, equals(0));
        expect(summary.completedGoals, equals(0));
        expect(summary.expiredGoals, equals(0));
        expect(summary.overallProgress, equals(0.0));
        expect(summary.totalPointsEarned, equals(0));
        expect(summary.totalPointsPossible, equals(0));
      });
    });
  });
}

// Helper functions for creating mock data
WeeklyReport _createMockWeeklyReport({
  required Map<String, int> exerciseCategories,
  required Map<String, int> dietCategories,
  int weekOffset = 0,
}) {
  final now = DateTime.now();
  final weekStart = now.add(Duration(days: weekOffset));

  return WeeklyReport(
    id: 'test-report-${weekStart.millisecondsSinceEpoch}',
    userUuid: 'test-user',
    weekStartDate: weekStart,
    weekEndDate: weekStart.add(const Duration(days: 6)),
    generatedAt: now,
    stats: WeeklyStats(
      totalCertifications:
          exerciseCategories.values.fold(0, (a, b) => a + b) + dietCategories.values.fold(0, (a, b) => a + b),
      exerciseDays: exerciseCategories.isNotEmpty ? exerciseCategories.length : 0,
      dietDays: dietCategories.isNotEmpty ? dietCategories.length : 0,
      exerciseTypes: exerciseCategories,
      exerciseCategories: exerciseCategories,
      dietCategories: dietCategories,
      consistencyScore: 0.8,
    ),
    analysis: const AIAnalysis(
      exerciseInsights: 'Test insights',
      dietInsights: 'Test insights',
      overallAssessment: 'Test assessment',
      strengthAreas: ['Test strength'],
      improvementAreas: ['Test improvement'],
    ),
    recommendations: ['Test recommendation'],
    status: ReportStatus.completed,
  );
}

CategoryGoal _createMockGoal(
  CategoryGoalType type, {
  bool isCompleted = false,
  bool isExpired = false,
  int points = 20,
}) {
  final now = DateTime.now();

  return CategoryGoal(
    id: 'test-goal-${type.name}',
    title: 'Test ${type.displayName}',
    description: 'Test description',
    type: type,
    difficulty: GoalDifficulty.medium,
    targetValue: 5,
    currentValue: isCompleted ? 5 : 2,
    progress: isCompleted ? 1.0 : 0.4,
    isCompleted: isCompleted,
    isActive: !isCompleted && !isExpired,
    createdAt: now.subtract(const Duration(days: 3)),
    completedAt: isCompleted ? now.subtract(const Duration(days: 1)) : null,
    expiresAt: isExpired ? now.subtract(const Duration(days: 1)) : now.add(const Duration(days: 4)),
    basePoints: points,
  );
}
