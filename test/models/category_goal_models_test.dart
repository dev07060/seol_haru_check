import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_goal_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';

void main() {
  group('CategoryGoal', () {
    test('should create CategoryGoal with all required fields', () {
      // Arrange & Act
      final goal = CategoryGoal(
        id: 'test-goal',
        title: 'Test Goal',
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

      // Assert
      expect(goal.id, equals('test-goal'));
      expect(goal.title, equals('Test Goal'));
      expect(goal.type, equals(CategoryGoalType.diversity));
      expect(goal.difficulty, equals(GoalDifficulty.medium));
      expect(goal.targetValue, equals(5));
      expect(goal.currentValue, equals(3));
      expect(goal.progress, equals(0.6));
      expect(goal.isCompleted, isFalse);
      expect(goal.isActive, isTrue);
      expect(goal.basePoints, equals(20));
    });

    test('should calculate total points with difficulty multiplier', () {
      // Arrange
      final easyGoal = CategoryGoal(
        id: 'easy-goal',
        title: 'Easy Goal',
        description: 'Easy description',
        type: CategoryGoalType.diversity,
        difficulty: GoalDifficulty.easy,
        targetValue: 3,
        currentValue: 1,
        progress: 0.33,
        isCompleted: false,
        isActive: true,
        createdAt: DateTime.now(),
        basePoints: 20,
      );

      final expertGoal = CategoryGoal(
        id: 'expert-goal',
        title: 'Expert Goal',
        description: 'Expert description',
        type: CategoryGoalType.diversity,
        difficulty: GoalDifficulty.expert,
        targetValue: 10,
        currentValue: 2,
        progress: 0.2,
        isCompleted: false,
        isActive: true,
        createdAt: DateTime.now(),
        basePoints: 20,
      );

      // Act & Assert
      expect(easyGoal.totalPoints, equals(20)); // 20 * 1.0
      expect(expertGoal.totalPoints, equals(60)); // 20 * 3.0
    });

    test('should calculate progress percentage correctly', () {
      // Arrange
      final goal = CategoryGoal(
        id: 'test-goal',
        title: 'Test Goal',
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

      // Act & Assert
      expect(goal.progressPercentage, equals(60.0));
    });

    test('should calculate remaining value correctly', () {
      // Arrange
      final goal = CategoryGoal(
        id: 'test-goal',
        title: 'Test Goal',
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

      // Act & Assert
      expect(goal.remainingValue, equals(2));
    });

    test('should detect expired goals correctly', () {
      // Arrange
      final expiredGoal = CategoryGoal(
        id: 'expired-goal',
        title: 'Expired Goal',
        description: 'Expired description',
        type: CategoryGoalType.diversity,
        difficulty: GoalDifficulty.medium,
        targetValue: 5,
        currentValue: 3,
        progress: 0.6,
        isCompleted: false,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        basePoints: 20,
      );

      final activeGoal = CategoryGoal(
        id: 'active-goal',
        title: 'Active Goal',
        description: 'Active description',
        type: CategoryGoalType.diversity,
        difficulty: GoalDifficulty.medium,
        targetValue: 5,
        currentValue: 3,
        progress: 0.6,
        isCompleted: false,
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        basePoints: 20,
      );

      // Act & Assert
      expect(expiredGoal.isExpired, isTrue);
      expect(activeGoal.isExpired, isFalse);
    });

    test('should calculate days remaining correctly', () {
      // Arrange
      final goal = CategoryGoal(
        id: 'test-goal',
        title: 'Test Goal',
        description: 'Test description',
        type: CategoryGoalType.diversity,
        difficulty: GoalDifficulty.medium,
        targetValue: 5,
        currentValue: 3,
        progress: 0.6,
        isCompleted: false,
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        basePoints: 20,
      );

      // Act & Assert
      expect(goal.daysRemaining, greaterThanOrEqualTo(2)); // Allow for timing differences
    });

    test('should serialize to and from map correctly', () {
      // Arrange
      final originalGoal = CategoryGoal(
        id: 'test-goal',
        title: 'Test Goal',
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
        targetCategories: ['category1', 'category2'],
      );

      // Act
      final map = originalGoal.toMap();
      final deserializedGoal = CategoryGoal.fromMap(map);

      // Assert
      expect(deserializedGoal.id, equals(originalGoal.id));
      expect(deserializedGoal.title, equals(originalGoal.title));
      expect(deserializedGoal.description, equals(originalGoal.description));
      expect(deserializedGoal.type, equals(originalGoal.type));
      expect(deserializedGoal.difficulty, equals(originalGoal.difficulty));
      expect(deserializedGoal.targetValue, equals(originalGoal.targetValue));
      expect(deserializedGoal.currentValue, equals(originalGoal.currentValue));
      expect(deserializedGoal.progress, equals(originalGoal.progress));
      expect(deserializedGoal.isCompleted, equals(originalGoal.isCompleted));
      expect(deserializedGoal.isActive, equals(originalGoal.isActive));
      expect(deserializedGoal.basePoints, equals(originalGoal.basePoints));
      expect(deserializedGoal.targetCategories, equals(originalGoal.targetCategories));
    });
  });

  group('CategoryDiversityTarget', () {
    test('should create CategoryDiversityTarget with all required fields', () {
      // Arrange & Act
      final target = CategoryDiversityTarget(
        id: 'test-target',
        title: 'Test Diversity Target',
        exerciseTargetCount: 3,
        dietTargetCount: 3,
        totalTargetCount: 6,
        currentExerciseCount: 2,
        currentDietCount: 2,
        currentTotalCount: 4,
        diversityScore: 0.6,
        targetDiversityScore: 0.8,
        isAchieved: false,
        weekStart: DateTime.now(),
        weekEnd: DateTime.now().add(const Duration(days: 6)),
      );

      // Assert
      expect(target.id, equals('test-target'));
      expect(target.title, equals('Test Diversity Target'));
      expect(target.exerciseTargetCount, equals(3));
      expect(target.dietTargetCount, equals(3));
      expect(target.totalTargetCount, equals(6));
      expect(target.currentExerciseCount, equals(2));
      expect(target.currentDietCount, equals(2));
      expect(target.currentTotalCount, equals(4));
      expect(target.diversityScore, equals(0.6));
      expect(target.targetDiversityScore, equals(0.8));
      expect(target.isAchieved, isFalse);
    });

    test('should calculate progress correctly', () {
      // Arrange
      final target = CategoryDiversityTarget(
        id: 'test-target',
        title: 'Test Diversity Target',
        exerciseTargetCount: 4,
        dietTargetCount: 3,
        totalTargetCount: 7,
        currentExerciseCount: 2,
        currentDietCount: 3,
        currentTotalCount: 5,
        diversityScore: 0.6,
        targetDiversityScore: 0.8,
        isAchieved: false,
        weekStart: DateTime.now(),
        weekEnd: DateTime.now().add(const Duration(days: 6)),
      );

      // Act & Assert
      expect(target.exerciseProgress, equals(0.5)); // 2/4
      expect(target.dietProgress, equals(1.0)); // 3/3
      expect(target.totalProgress, closeTo(0.714, 0.001)); // 5/7
      expect(target.diversityProgress, closeTo(0.75, 0.001)); // 0.6/0.8 with floating point tolerance
    });

    test('should serialize to and from map correctly', () {
      // Arrange
      final originalTarget = CategoryDiversityTarget(
        id: 'test-target',
        title: 'Test Diversity Target',
        exerciseTargetCount: 3,
        dietTargetCount: 3,
        totalTargetCount: 6,
        currentExerciseCount: 2,
        currentDietCount: 2,
        currentTotalCount: 4,
        diversityScore: 0.6,
        targetDiversityScore: 0.8,
        isAchieved: false,
        weekStart: DateTime.now(),
        weekEnd: DateTime.now().add(const Duration(days: 6)),
        categoryTargets: {'category1': true, 'category2': false},
      );

      // Act
      final map = originalTarget.toMap();
      final deserializedTarget = CategoryDiversityTarget.fromMap(map);

      // Assert
      expect(deserializedTarget.id, equals(originalTarget.id));
      expect(deserializedTarget.title, equals(originalTarget.title));
      expect(deserializedTarget.exerciseTargetCount, equals(originalTarget.exerciseTargetCount));
      expect(deserializedTarget.dietTargetCount, equals(originalTarget.dietTargetCount));
      expect(deserializedTarget.totalTargetCount, equals(originalTarget.totalTargetCount));
      expect(deserializedTarget.currentExerciseCount, equals(originalTarget.currentExerciseCount));
      expect(deserializedTarget.currentDietCount, equals(originalTarget.currentDietCount));
      expect(deserializedTarget.currentTotalCount, equals(originalTarget.currentTotalCount));
      expect(deserializedTarget.diversityScore, equals(originalTarget.diversityScore));
      expect(deserializedTarget.targetDiversityScore, equals(originalTarget.targetDiversityScore));
      expect(deserializedTarget.isAchieved, equals(originalTarget.isAchieved));
      expect(deserializedTarget.categoryTargets, equals(originalTarget.categoryTargets));
    });
  });

  group('CategoryConsistencyGoal', () {
    test('should create CategoryConsistencyGoal with all required fields', () {
      // Arrange & Act
      final goal = CategoryConsistencyGoal(
        id: 'test-consistency',
        title: 'Test Consistency Goal',
        categoryName: '근력 운동',
        categoryType: CategoryType.exercise,
        targetWeeks: 4,
        currentWeeks: 2,
        targetFrequency: 3,
        weeklyFrequencies: [3, 2, 4, 3],
        isAchieved: false,
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        consistencyScore: 0.75,
      );

      // Assert
      expect(goal.id, equals('test-consistency'));
      expect(goal.title, equals('Test Consistency Goal'));
      expect(goal.categoryName, equals('근력 운동'));
      expect(goal.categoryType, equals(CategoryType.exercise));
      expect(goal.targetWeeks, equals(4));
      expect(goal.currentWeeks, equals(2));
      expect(goal.targetFrequency, equals(3));
      expect(goal.weeklyFrequencies, equals([3, 2, 4, 3]));
      expect(goal.isAchieved, isFalse);
      expect(goal.consistencyScore, equals(0.75));
    });

    test('should calculate progress and average frequency correctly', () {
      // Arrange
      final goal = CategoryConsistencyGoal(
        id: 'test-consistency',
        title: 'Test Consistency Goal',
        categoryName: '근력 운동',
        categoryType: CategoryType.exercise,
        targetWeeks: 4,
        currentWeeks: 2,
        targetFrequency: 3,
        weeklyFrequencies: [3, 2, 4, 1],
        isAchieved: false,
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        consistencyScore: 0.75,
      );

      // Act & Assert
      expect(goal.progress, equals(0.5)); // 2/4
      expect(goal.averageWeeklyFrequency, equals(2.5)); // (3+2+4+1)/4
      expect(goal.currentWeekMeetsTarget, isFalse); // Last frequency (1) < target (3)
    });

    test('should serialize to and from map correctly', () {
      // Arrange
      final originalGoal = CategoryConsistencyGoal(
        id: 'test-consistency',
        title: 'Test Consistency Goal',
        categoryName: '근력 운동',
        categoryType: CategoryType.exercise,
        targetWeeks: 4,
        currentWeeks: 2,
        targetFrequency: 3,
        weeklyFrequencies: [3, 2, 4, 3],
        isAchieved: false,
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        consistencyScore: 0.75,
      );

      // Act
      final map = originalGoal.toMap();
      final deserializedGoal = CategoryConsistencyGoal.fromMap(map);

      // Assert
      expect(deserializedGoal.id, equals(originalGoal.id));
      expect(deserializedGoal.title, equals(originalGoal.title));
      expect(deserializedGoal.categoryName, equals(originalGoal.categoryName));
      expect(deserializedGoal.categoryType, equals(originalGoal.categoryType));
      expect(deserializedGoal.targetWeeks, equals(originalGoal.targetWeeks));
      expect(deserializedGoal.currentWeeks, equals(originalGoal.currentWeeks));
      expect(deserializedGoal.targetFrequency, equals(originalGoal.targetFrequency));
      expect(deserializedGoal.weeklyFrequencies, equals(originalGoal.weeklyFrequencies));
      expect(deserializedGoal.isAchieved, equals(originalGoal.isAchieved));
      expect(deserializedGoal.consistencyScore, equals(originalGoal.consistencyScore));
    });
  });

  group('CategoryExplorationChallenge', () {
    test('should create CategoryExplorationChallenge with all required fields', () {
      // Arrange & Act
      final challenge = CategoryExplorationChallenge(
        id: 'test-exploration',
        title: 'Test Exploration Challenge',
        description: 'Try new categories',
        targetCategories: ['스트레칭/요가', '단백질 위주', '구기/스포츠'],
        completedCategories: ['스트레칭/요가'],
        targetCount: 3,
        currentCount: 1,
        isCompleted: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        rewardPoints: 50,
      );

      // Assert
      expect(challenge.id, equals('test-exploration'));
      expect(challenge.title, equals('Test Exploration Challenge'));
      expect(challenge.description, equals('Try new categories'));
      expect(challenge.targetCategories, equals(['스트레칭/요가', '단백질 위주', '구기/스포츠']));
      expect(challenge.completedCategories, equals(['스트레칭/요가']));
      expect(challenge.targetCount, equals(3));
      expect(challenge.currentCount, equals(1));
      expect(challenge.isCompleted, isFalse);
      expect(challenge.rewardPoints, equals(50));
    });

    test('should calculate progress and remaining categories correctly', () {
      // Arrange
      final challenge = CategoryExplorationChallenge(
        id: 'test-exploration',
        title: 'Test Exploration Challenge',
        description: 'Try new categories',
        targetCategories: ['스트레칭/요가', '단백질 위주', '구기/스포츠'],
        completedCategories: ['스트레칭/요가'],
        targetCount: 3,
        currentCount: 1,
        isCompleted: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        rewardPoints: 50,
      );

      // Act & Assert
      expect(challenge.progress, closeTo(0.333, 0.001)); // 1/3
      expect(challenge.remainingCategories, equals(['단백질 위주', '구기/스포츠']));
      expect(challenge.daysRemaining, greaterThanOrEqualTo(6)); // Allow for timing differences
      expect(challenge.isExpired, isFalse);
      expect(challenge.isActive, isTrue);
    });

    test('should detect expired challenges correctly', () {
      // Arrange
      final expiredChallenge = CategoryExplorationChallenge(
        id: 'expired-exploration',
        title: 'Expired Exploration Challenge',
        description: 'Try new categories',
        targetCategories: ['스트레칭/요가', '단백질 위주'],
        completedCategories: [],
        targetCount: 2,
        currentCount: 0,
        isCompleted: false,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        rewardPoints: 50,
      );

      // Act & Assert
      expect(expiredChallenge.isExpired, isTrue);
      expect(expiredChallenge.isActive, isFalse);
      expect(expiredChallenge.daysRemaining, equals(0));
    });

    test('should serialize to and from map correctly', () {
      // Arrange
      final originalChallenge = CategoryExplorationChallenge(
        id: 'test-exploration',
        title: 'Test Exploration Challenge',
        description: 'Try new categories',
        targetCategories: ['스트레칭/요가', '단백질 위주'],
        completedCategories: ['스트레칭/요가'],
        targetCount: 2,
        currentCount: 1,
        isCompleted: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        rewardPoints: 50,
        categoryFirstTryDates: {'스트레칭/요가': DateTime.now()},
      );

      // Act
      final map = originalChallenge.toMap();
      final deserializedChallenge = CategoryExplorationChallenge.fromMap(map);

      // Assert
      expect(deserializedChallenge.id, equals(originalChallenge.id));
      expect(deserializedChallenge.title, equals(originalChallenge.title));
      expect(deserializedChallenge.description, equals(originalChallenge.description));
      expect(deserializedChallenge.targetCategories, equals(originalChallenge.targetCategories));
      expect(deserializedChallenge.completedCategories, equals(originalChallenge.completedCategories));
      expect(deserializedChallenge.targetCount, equals(originalChallenge.targetCount));
      expect(deserializedChallenge.currentCount, equals(originalChallenge.currentCount));
      expect(deserializedChallenge.isCompleted, equals(originalChallenge.isCompleted));
      expect(deserializedChallenge.rewardPoints, equals(originalChallenge.rewardPoints));
      expect(
        deserializedChallenge.categoryFirstTryDates.length,
        equals(originalChallenge.categoryFirstTryDates.length),
      );
    });
  });

  group('CategoryGoalSummary', () {
    test('should create CategoryGoalSummary with all required fields', () {
      // Arrange & Act
      final summary = CategoryGoalSummary(
        totalGoals: 10,
        activeGoals: 5,
        completedGoals: 3,
        expiredGoals: 2,
        overallProgress: 0.65,
        totalPointsEarned: 150,
        totalPointsPossible: 250,
        goalsByType: {
          CategoryGoalType.diversity: 3,
          CategoryGoalType.consistency: 4,
          CategoryGoalType.exploration: 2,
          CategoryGoalType.balance: 1,
        },
        goalsByDifficulty: {
          GoalDifficulty.easy: 2,
          GoalDifficulty.medium: 5,
          GoalDifficulty.hard: 2,
          GoalDifficulty.expert: 1,
        },
        lastUpdated: DateTime.now(),
      );

      // Assert
      expect(summary.totalGoals, equals(10));
      expect(summary.activeGoals, equals(5));
      expect(summary.completedGoals, equals(3));
      expect(summary.expiredGoals, equals(2));
      expect(summary.overallProgress, equals(0.65));
      expect(summary.totalPointsEarned, equals(150));
      expect(summary.totalPointsPossible, equals(250));
      expect(summary.goalsByType.length, equals(4));
      expect(summary.goalsByDifficulty.length, equals(4));
    });

    test('should calculate completion rate correctly', () {
      // Arrange
      final summary = CategoryGoalSummary(
        totalGoals: 10,
        activeGoals: 5,
        completedGoals: 3,
        expiredGoals: 2,
        overallProgress: 0.65,
        totalPointsEarned: 150,
        totalPointsPossible: 250,
        goalsByType: {},
        goalsByDifficulty: {},
        lastUpdated: DateTime.now(),
      );

      // Act & Assert
      expect(summary.completionRate, equals(0.3)); // 3/10
    });

    test('should calculate success rate correctly', () {
      // Arrange
      final summary = CategoryGoalSummary(
        totalGoals: 10,
        activeGoals: 5,
        completedGoals: 3,
        expiredGoals: 2,
        overallProgress: 0.65,
        totalPointsEarned: 150,
        totalPointsPossible: 250,
        goalsByType: {},
        goalsByDifficulty: {},
        lastUpdated: DateTime.now(),
      );

      // Act & Assert
      expect(summary.successRate, equals(0.6)); // 3/(3+2) = 3/5
    });

    test('should handle empty summary correctly', () {
      // Arrange & Act
      final emptySummary = CategoryGoalSummary.empty();

      // Assert
      expect(emptySummary.totalGoals, equals(0));
      expect(emptySummary.activeGoals, equals(0));
      expect(emptySummary.completedGoals, equals(0));
      expect(emptySummary.expiredGoals, equals(0));
      expect(emptySummary.overallProgress, equals(0.0));
      expect(emptySummary.totalPointsEarned, equals(0));
      expect(emptySummary.totalPointsPossible, equals(0));
      expect(emptySummary.completionRate, equals(0.0));
      expect(emptySummary.successRate, equals(0.0));
    });
  });

  group('CategoryGoalType', () {
    test('should have correct display names', () {
      expect(CategoryGoalType.diversity.displayName, equals('다양성 목표'));
      expect(CategoryGoalType.consistency.displayName, equals('일관성 목표'));
      expect(CategoryGoalType.exploration.displayName, equals('탐험 목표'));
      expect(CategoryGoalType.balance.displayName, equals('균형 목표'));
    });

    test('should have appropriate icons', () {
      expect(CategoryGoalType.diversity.icon, isNotNull);
      expect(CategoryGoalType.consistency.icon, isNotNull);
      expect(CategoryGoalType.exploration.icon, isNotNull);
      expect(CategoryGoalType.balance.icon, isNotNull);
    });

    test('should have appropriate colors', () {
      expect(CategoryGoalType.diversity.color, isNotNull);
      expect(CategoryGoalType.consistency.color, isNotNull);
      expect(CategoryGoalType.exploration.color, isNotNull);
      expect(CategoryGoalType.balance.color, isNotNull);
    });
  });

  group('GoalDifficulty', () {
    test('should have correct display names', () {
      expect(GoalDifficulty.easy.displayName, equals('쉬움'));
      expect(GoalDifficulty.medium.displayName, equals('보통'));
      expect(GoalDifficulty.hard.displayName, equals('어려움'));
      expect(GoalDifficulty.expert.displayName, equals('전문가'));
    });

    test('should have correct point multipliers', () {
      expect(GoalDifficulty.easy.pointMultiplier, equals(1.0));
      expect(GoalDifficulty.medium.pointMultiplier, equals(1.5));
      expect(GoalDifficulty.hard.pointMultiplier, equals(2.0));
      expect(GoalDifficulty.expert.pointMultiplier, equals(3.0));
    });

    test('should have appropriate colors', () {
      expect(GoalDifficulty.easy.color, isNotNull);
      expect(GoalDifficulty.medium.color, isNotNull);
      expect(GoalDifficulty.hard.color, isNotNull);
      expect(GoalDifficulty.expert.color, isNotNull);
    });
  });
}
