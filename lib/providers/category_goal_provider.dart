import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/models/category_goal_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_goal_service.dart';

/// State for category goals
class CategoryGoalState {
  final List<CategoryGoal> goals;
  final CategoryGoalSummary summary;
  final CategoryDiversityTarget? diversityTarget;
  final List<CategoryConsistencyGoal> consistencyGoals;
  final List<CategoryExplorationChallenge> explorationChallenges;
  final bool isLoading;
  final String? error;

  const CategoryGoalState({
    this.goals = const [],
    required this.summary,
    this.diversityTarget,
    this.consistencyGoals = const [],
    this.explorationChallenges = const [],
    this.isLoading = false,
    this.error,
  });

  CategoryGoalState copyWith({
    List<CategoryGoal>? goals,
    CategoryGoalSummary? summary,
    CategoryDiversityTarget? diversityTarget,
    List<CategoryConsistencyGoal>? consistencyGoals,
    List<CategoryExplorationChallenge>? explorationChallenges,
    bool? isLoading,
    String? error,
  }) {
    return CategoryGoalState(
      goals: goals ?? this.goals,
      summary: summary ?? this.summary,
      diversityTarget: diversityTarget ?? this.diversityTarget,
      consistencyGoals: consistencyGoals ?? this.consistencyGoals,
      explorationChallenges: explorationChallenges ?? this.explorationChallenges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for category goals
class CategoryGoalNotifier extends StateNotifier<CategoryGoalState> {
  final CategoryGoalService _goalService;

  CategoryGoalNotifier(this._goalService) : super(CategoryGoalState(summary: CategoryGoalSummary.empty()));

  /// Initialize goals based on current and historical reports
  Future<void> initializeGoals(WeeklyReport currentReport, List<WeeklyReport> historicalReports) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      log('[CategoryGoalNotifier] Initializing goals for user');

      // Generate dynamic goals
      final goals = await _goalService.generateDynamicGoals(currentReport, historicalReports);

      // Create diversity target
      final diversityTarget = await _goalService.createDiversityTarget(currentReport, historicalReports);

      // Create consistency goals
      final consistencyGoals = await _goalService.createConsistencyGoals(currentReport, historicalReports);

      // Create exploration challenges
      final explorationChallenges = await _goalService.createExplorationChallenges(currentReport, historicalReports);

      // Generate summary
      final summary = await _goalService.getGoalSummary(goals);

      state = state.copyWith(
        goals: goals,
        diversityTarget: diversityTarget,
        consistencyGoals: consistencyGoals,
        explorationChallenges: explorationChallenges,
        summary: summary,
        isLoading: false,
      );

      log(
        '[CategoryGoalNotifier] Initialized ${goals.length} goals, ${consistencyGoals.length} consistency goals, ${explorationChallenges.length} exploration challenges',
      );
    } catch (e, stackTrace) {
      log('[CategoryGoalNotifier] Error initializing goals: $e', stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: 'Failed to initialize goals: $e');
    }
  }

  /// Update goal progress based on current report
  Future<void> updateGoalProgress(WeeklyReport currentReport) async {
    try {
      log('[CategoryGoalNotifier] Updating goal progress');

      final updatedGoals = <CategoryGoal>[];

      for (final goal in state.goals) {
        final updatedGoal = await _goalService.updateGoalProgress(goal, currentReport);
        updatedGoals.add(updatedGoal);
      }

      // Update diversity target progress
      CategoryDiversityTarget? updatedDiversityTarget;
      if (state.diversityTarget != null) {
        updatedDiversityTarget = _updateDiversityTargetProgress(state.diversityTarget!, currentReport);
      }

      // Update consistency goals progress
      final updatedConsistencyGoals =
          state.consistencyGoals.map((goal) {
            return _updateConsistencyGoalProgress(goal, currentReport);
          }).toList();

      // Update exploration challenges progress
      final updatedExplorationChallenges =
          state.explorationChallenges.map((challenge) {
            return _updateExplorationChallengeProgress(challenge, currentReport);
          }).toList();

      // Generate updated summary
      final summary = await _goalService.getGoalSummary(updatedGoals);

      state = state.copyWith(
        goals: updatedGoals,
        diversityTarget: updatedDiversityTarget,
        consistencyGoals: updatedConsistencyGoals,
        explorationChallenges: updatedExplorationChallenges,
        summary: summary,
      );

      log('[CategoryGoalNotifier] Updated progress for ${updatedGoals.length} goals');
    } catch (e, stackTrace) {
      log('[CategoryGoalNotifier] Error updating goal progress: $e', stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to update goal progress: $e');
    }
  }

  /// Add a new custom goal
  Future<void> addCustomGoal(CategoryGoal goal) async {
    try {
      log('[CategoryGoalNotifier] Adding custom goal: ${goal.title}');

      final updatedGoals = [...state.goals, goal];
      final summary = await _goalService.getGoalSummary(updatedGoals);

      state = state.copyWith(goals: updatedGoals, summary: summary);

      log('[CategoryGoalNotifier] Added custom goal successfully');
    } catch (e, stackTrace) {
      log('[CategoryGoalNotifier] Error adding custom goal: $e', stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to add custom goal: $e');
    }
  }

  /// Remove a goal
  Future<void> removeGoal(String goalId) async {
    try {
      log('[CategoryGoalNotifier] Removing goal: $goalId');

      final updatedGoals = state.goals.where((goal) => goal.id != goalId).toList();
      final summary = await _goalService.getGoalSummary(updatedGoals);

      state = state.copyWith(goals: updatedGoals, summary: summary);

      log('[CategoryGoalNotifier] Removed goal successfully');
    } catch (e, stackTrace) {
      log('[CategoryGoalNotifier] Error removing goal: $e', stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to remove goal: $e');
    }
  }

  /// Mark goal as completed manually
  Future<void> completeGoal(String goalId) async {
    try {
      log('[CategoryGoalNotifier] Completing goal: $goalId');

      final updatedGoals =
          state.goals.map((goal) {
            if (goal.id == goalId) {
              return goal.copyWith(
                isCompleted: true,
                completedAt: DateTime.now(),
                currentValue: goal.targetValue,
                progress: 1.0,
              );
            }
            return goal;
          }).toList();

      final summary = await _goalService.getGoalSummary(updatedGoals);

      state = state.copyWith(goals: updatedGoals, summary: summary);

      log('[CategoryGoalNotifier] Completed goal successfully');
    } catch (e, stackTrace) {
      log('[CategoryGoalNotifier] Error completing goal: $e', stackTrace: stackTrace);
      state = state.copyWith(error: 'Failed to complete goal: $e');
    }
  }

  /// Get goals by type
  List<CategoryGoal> getGoalsByType(CategoryGoalType type) {
    return state.goals.where((goal) => goal.type == type).toList();
  }

  /// Get active goals
  List<CategoryGoal> getActiveGoals() {
    return state.goals.where((goal) => goal.isAchievable).toList();
  }

  /// Get completed goals
  List<CategoryGoal> getCompletedGoals() {
    return state.goals.where((goal) => goal.isCompleted).toList();
  }

  /// Get goals by difficulty
  List<CategoryGoal> getGoalsByDifficulty(GoalDifficulty difficulty) {
    return state.goals.where((goal) => goal.difficulty == difficulty).toList();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Update diversity target progress
  CategoryDiversityTarget _updateDiversityTargetProgress(CategoryDiversityTarget target, WeeklyReport currentReport) {
    final currentExerciseCount = currentReport.stats.exerciseCategories.length;
    final currentDietCount = currentReport.stats.dietCategories.length;
    final currentTotalCount = currentExerciseCount + currentDietCount;

    // Update category targets
    final updatedCategoryTargets = <String, bool>{};
    target.categoryTargets.forEach((category, _) {
      final isAchieved =
          currentReport.stats.exerciseCategories.containsKey(category) ||
          currentReport.stats.dietCategories.containsKey(category);
      updatedCategoryTargets[category] = isAchieved;
    });

    // Calculate diversity score (simplified)
    final diversityScore = currentTotalCount > 0 ? (currentTotalCount / 10.0).clamp(0.0, 1.0) : 0.0;

    final isAchieved = currentTotalCount >= target.totalTargetCount && diversityScore >= target.targetDiversityScore;

    return CategoryDiversityTarget(
      id: target.id,
      title: target.title,
      exerciseTargetCount: target.exerciseTargetCount,
      dietTargetCount: target.dietTargetCount,
      totalTargetCount: target.totalTargetCount,
      currentExerciseCount: currentExerciseCount,
      currentDietCount: currentDietCount,
      currentTotalCount: currentTotalCount,
      diversityScore: diversityScore,
      targetDiversityScore: target.targetDiversityScore,
      isAchieved: isAchieved,
      weekStart: target.weekStart,
      weekEnd: target.weekEnd,
      categoryTargets: updatedCategoryTargets,
    );
  }

  /// Update consistency goal progress
  CategoryConsistencyGoal _updateConsistencyGoalProgress(CategoryConsistencyGoal goal, WeeklyReport currentReport) {
    final hasCategory =
        currentReport.stats.exerciseCategories.containsKey(goal.categoryName) ||
        currentReport.stats.dietCategories.containsKey(goal.categoryName);

    if (hasCategory) {
      final currentFrequency =
          (currentReport.stats.exerciseCategories[goal.categoryName] ?? 0) +
          (currentReport.stats.dietCategories[goal.categoryName] ?? 0);

      final updatedWeeklyFrequencies = [...goal.weeklyFrequencies, currentFrequency];
      final meetsTarget = currentFrequency >= goal.targetFrequency;
      final currentWeeks = meetsTarget ? goal.currentWeeks + 1 : 0; // Reset if target not met

      final isAchieved = currentWeeks >= goal.targetWeeks;

      return CategoryConsistencyGoal(
        id: goal.id,
        title: goal.title,
        categoryName: goal.categoryName,
        categoryType: goal.categoryType,
        targetWeeks: goal.targetWeeks,
        currentWeeks: currentWeeks,
        targetFrequency: goal.targetFrequency,
        weeklyFrequencies: updatedWeeklyFrequencies,
        isAchieved: isAchieved,
        startDate: goal.startDate,
        achievedDate: isAchieved && goal.achievedDate == null ? DateTime.now() : goal.achievedDate,
        consistencyScore: _calculateConsistencyScore(updatedWeeklyFrequencies, goal.targetFrequency),
      );
    }

    // Category not found, reset progress
    return goal.copyWith(currentWeeks: 0);
  }

  /// Update exploration challenge progress
  CategoryExplorationChallenge _updateExplorationChallengeProgress(
    CategoryExplorationChallenge challenge,
    WeeklyReport currentReport,
  ) {
    final currentCategories = {
      ...currentReport.stats.exerciseCategories.keys,
      ...currentReport.stats.dietCategories.keys,
    };

    final newCompletedCategories =
        challenge.targetCategories.where((category) => currentCategories.contains(category)).toSet();

    final updatedCompletedCategories = {...challenge.completedCategories, ...newCompletedCategories}.toList();

    final currentCount = updatedCompletedCategories.length;
    final isCompleted = currentCount >= challenge.targetCount;

    // Update first try dates
    final updatedFirstTryDates = Map<String, DateTime>.from(challenge.categoryFirstTryDates);
    for (final category in newCompletedCategories) {
      if (!updatedFirstTryDates.containsKey(category)) {
        updatedFirstTryDates[category] = DateTime.now();
      }
    }

    return CategoryExplorationChallenge(
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      targetCategories: challenge.targetCategories,
      completedCategories: updatedCompletedCategories,
      targetCount: challenge.targetCount,
      currentCount: currentCount,
      isCompleted: isCompleted,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      completedDate: isCompleted && challenge.completedDate == null ? DateTime.now() : challenge.completedDate,
      rewardPoints: challenge.rewardPoints,
      categoryFirstTryDates: updatedFirstTryDates,
    );
  }

  /// Calculate consistency score
  double _calculateConsistencyScore(List<int> weeklyFrequencies, int targetFrequency) {
    if (weeklyFrequencies.isEmpty) return 0.0;

    final meetsTargetCount = weeklyFrequencies.where((freq) => freq >= targetFrequency).length;
    return meetsTargetCount / weeklyFrequencies.length;
  }
}

/// Provider for category goal notifier
final categoryGoalProvider = StateNotifierProvider<CategoryGoalNotifier, CategoryGoalState>((ref) {
  return CategoryGoalNotifier(CategoryGoalService.instance);
});

/// Provider for active goals
final activeGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  final goalState = ref.watch(categoryGoalProvider);
  return goalState.goals.where((goal) => goal.isAchievable).toList();
});

/// Provider for completed goals
final completedGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  final goalState = ref.watch(categoryGoalProvider);
  return goalState.goals.where((goal) => goal.isCompleted).toList();
});

/// Provider for goals by type
final goalsByTypeProvider = Provider.family<List<CategoryGoal>, CategoryGoalType>((ref, type) {
  final goalState = ref.watch(categoryGoalProvider);
  return goalState.goals.where((goal) => goal.type == type).toList();
});

/// Provider for diversity goals
final diversityGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  return ref.watch(goalsByTypeProvider(CategoryGoalType.diversity));
});

/// Provider for consistency goals
final consistencyGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  return ref.watch(goalsByTypeProvider(CategoryGoalType.consistency));
});

/// Provider for exploration goals
final explorationGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  return ref.watch(goalsByTypeProvider(CategoryGoalType.exploration));
});

/// Provider for balance goals
final balanceGoalsProvider = Provider<List<CategoryGoal>>((ref) {
  return ref.watch(goalsByTypeProvider(CategoryGoalType.balance));
});
