import 'dart:developer';
import 'dart:math' as math;

import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_goal_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_trend_analysis_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing category-based goals and challenges
class CategoryGoalService {
  static final CategoryGoalService _instance = CategoryGoalService._internal();
  static CategoryGoalService get instance => _instance;
  CategoryGoalService._internal();

  final _uuid = const Uuid();
  final _trendAnalysisService = CategoryTrendAnalysisService.instance;

  /// Generate dynamic category goals based on user patterns
  Future<List<CategoryGoal>> generateDynamicGoals(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryGoalService] Generating dynamic goals based on user patterns');

    try {
      final goals = <CategoryGoal>[];

      // Generate diversity goals
      goals.addAll(await _generateDiversityGoals(currentReport, historicalReports));

      // Generate consistency goals
      goals.addAll(await _generateConsistencyGoals(currentReport, historicalReports));

      // Generate exploration goals
      goals.addAll(await _generateExplorationGoals(currentReport, historicalReports));

      // Generate balance goals
      goals.addAll(await _generateBalanceGoals(currentReport, historicalReports));

      log('[CategoryGoalService] Generated ${goals.length} dynamic goals');
      return goals;
    } catch (e, stackTrace) {
      log('[CategoryGoalService] Error generating dynamic goals: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// Create category diversity targets and tracking
  Future<CategoryDiversityTarget> createDiversityTarget(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryGoalService] Creating diversity target');

    try {
      // Analyze historical diversity patterns
      final diversityAnalysis = await _trendAnalysisService.analyzeCategoryDiversity(currentReport, historicalReports);

      // Calculate optimal targets based on user's historical performance
      final exerciseTarget = _calculateOptimalExerciseTarget(currentReport, historicalReports);
      final dietTarget = _calculateOptimalDietTarget(currentReport, historicalReports);
      final totalTarget = exerciseTarget + dietTarget;

      // Calculate target diversity score
      final targetDiversityScore = _calculateTargetDiversityScore(currentReport, historicalReports);

      // Get current counts
      final currentExerciseCount = currentReport.stats.exerciseCategories.length;
      final currentDietCount = currentReport.stats.dietCategories.length;
      final currentTotalCount = currentExerciseCount + currentDietCount;

      // Create category targets map
      final categoryTargets = <String, bool>{};

      // Add exercise category targets
      final allExerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toList();
      for (int i = 0; i < math.min(exerciseTarget, allExerciseCategories.length); i++) {
        final category = allExerciseCategories[i];
        categoryTargets[category] = currentReport.stats.exerciseCategories.containsKey(category);
      }

      // Add diet category targets
      final allDietCategories = DietCategory.values.map((e) => e.displayName).toList();
      for (int i = 0; i < math.min(dietTarget, allDietCategories.length); i++) {
        final category = allDietCategories[i];
        categoryTargets[category] = currentReport.stats.dietCategories.containsKey(category);
      }

      final weekStart = _getWeekStart(DateTime.now());
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Calculate current diversity score consistently
      final currentDiversityScore = currentTotalCount > 0 ? (currentTotalCount / 10.0).clamp(0.0, 1.0) : 0.0;

      return CategoryDiversityTarget(
        id: _uuid.v4(),
        title: '주간 카테고리 다양성 목표',
        exerciseTargetCount: exerciseTarget,
        dietTargetCount: dietTarget,
        totalTargetCount: totalTarget,
        currentExerciseCount: currentExerciseCount,
        currentDietCount: currentDietCount,
        currentTotalCount: currentTotalCount,
        diversityScore: currentDiversityScore,
        targetDiversityScore: targetDiversityScore,
        isAchieved: currentTotalCount >= totalTarget && currentDiversityScore >= targetDiversityScore,
        weekStart: weekStart,
        weekEnd: weekEnd,
        categoryTargets: categoryTargets,
      );
    } catch (e, stackTrace) {
      log('[CategoryGoalService] Error creating diversity target: $e', stackTrace: stackTrace);
      return _createDefaultDiversityTarget();
    }
  }

  /// Create category consistency goals and rewards
  Future<List<CategoryConsistencyGoal>> createConsistencyGoals(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryGoalService] Creating consistency goals');

    try {
      final goals = <CategoryConsistencyGoal>[];

      // Analyze user's most consistent categories
      final consistentCategories = _findConsistentCategories(currentReport, historicalReports);

      for (final categoryData in consistentCategories) {
        final goal = CategoryConsistencyGoal(
          id: _uuid.v4(),
          title: '${categoryData['categoryName']} 일관성 유지',
          categoryName: categoryData['categoryName'],
          categoryType: categoryData['categoryType'],
          targetWeeks: _calculateConsistencyTargetWeeks(categoryData['consistency']),
          currentWeeks: categoryData['currentWeeks'],
          targetFrequency: categoryData['targetFrequency'],
          weeklyFrequencies: List<int>.from(categoryData['weeklyFrequencies']),
          isAchieved: categoryData['isAchieved'],
          startDate: DateTime.now().subtract(Duration(days: categoryData['currentWeeks'] * 7)),
          achievedDate: categoryData['isAchieved'] ? DateTime.now() : null,
          consistencyScore: categoryData['consistency'],
        );

        goals.add(goal);
      }

      log('[CategoryGoalService] Created ${goals.length} consistency goals');
      return goals;
    } catch (e, stackTrace) {
      log('[CategoryGoalService] Error creating consistency goals: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// Implement category exploration challenges
  Future<List<CategoryExplorationChallenge>> createExplorationChallenges(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    log('[CategoryGoalService] Creating exploration challenges');

    try {
      final challenges = <CategoryExplorationChallenge>[];

      // Find unexplored categories
      final unexploredCategories = _findUnexploredCategories(currentReport, historicalReports);

      if (unexploredCategories.isNotEmpty) {
        // Create weekly exploration challenge
        final weeklyChallenge = _createWeeklyExplorationChallenge(unexploredCategories);
        challenges.add(weeklyChallenge);

        // Create monthly exploration challenge if enough categories available
        if (unexploredCategories.length >= 5) {
          final monthlyChallenge = _createMonthlyExplorationChallenge(unexploredCategories);
          challenges.add(monthlyChallenge);
        }
      }

      // Create category type exploration challenges
      final exerciseExploration = _createCategoryTypeExplorationChallenge(
        CategoryType.exercise,
        currentReport,
        historicalReports,
      );
      if (exerciseExploration != null) {
        challenges.add(exerciseExploration);
      }

      final dietExploration = _createCategoryTypeExplorationChallenge(
        CategoryType.diet,
        currentReport,
        historicalReports,
      );
      if (dietExploration != null) {
        challenges.add(dietExploration);
      }

      log('[CategoryGoalService] Created ${challenges.length} exploration challenges');
      return challenges;
    } catch (e, stackTrace) {
      log('[CategoryGoalService] Error creating exploration challenges: $e', stackTrace: stackTrace);
      return [];
    }
  }

  /// Update goal progress based on current report
  Future<CategoryGoal> updateGoalProgress(CategoryGoal goal, WeeklyReport currentReport) async {
    try {
      int newCurrentValue = goal.currentValue;
      bool isCompleted = goal.isCompleted;

      switch (goal.type) {
        case CategoryGoalType.diversity:
          newCurrentValue = _calculateDiversityProgress(goal, currentReport);
          break;
        case CategoryGoalType.consistency:
          newCurrentValue = _calculateConsistencyProgress(goal, currentReport);
          break;
        case CategoryGoalType.exploration:
          newCurrentValue = _calculateExplorationProgress(goal, currentReport);
          break;
        case CategoryGoalType.balance:
          newCurrentValue = _calculateBalanceProgress(goal, currentReport);
          break;
      }

      final newProgress = goal.targetValue > 0 ? (newCurrentValue / goal.targetValue).clamp(0.0, 1.0) : 0.0;
      isCompleted = newProgress >= 1.0;

      return goal.copyWith(
        currentValue: newCurrentValue,
        progress: newProgress,
        isCompleted: isCompleted,
        completedAt: isCompleted && goal.completedAt == null ? DateTime.now() : goal.completedAt,
      );
    } catch (e, stackTrace) {
      log('[CategoryGoalService] Error updating goal progress: $e', stackTrace: stackTrace);
      return goal;
    }
  }

  /// Get goal summary for user
  Future<CategoryGoalSummary> getGoalSummary(List<CategoryGoal> goals) async {
    try {
      final totalGoals = goals.length;
      final activeGoals = goals.where((goal) => goal.isAchievable).length;
      final completedGoals = goals.where((goal) => goal.isCompleted).length;
      final expiredGoals = goals.where((goal) => goal.isExpired).length;

      final overallProgress =
          totalGoals > 0 ? goals.map((goal) => goal.progress).reduce((a, b) => a + b) / totalGoals : 0.0;

      final totalPointsEarned = goals
          .where((goal) => goal.isCompleted)
          .map((goal) => goal.totalPoints)
          .fold<int>(0, (sum, points) => sum + points);

      final totalPointsPossible = goals.map((goal) => goal.totalPoints).fold<int>(0, (sum, points) => sum + points);

      final goalsByType = <CategoryGoalType, int>{};
      final goalsByDifficulty = <GoalDifficulty, int>{};

      for (final goal in goals) {
        goalsByType[goal.type] = (goalsByType[goal.type] ?? 0) + 1;
        goalsByDifficulty[goal.difficulty] = (goalsByDifficulty[goal.difficulty] ?? 0) + 1;
      }

      return CategoryGoalSummary(
        totalGoals: totalGoals,
        activeGoals: activeGoals,
        completedGoals: completedGoals,
        expiredGoals: expiredGoals,
        overallProgress: overallProgress,
        totalPointsEarned: totalPointsEarned,
        totalPointsPossible: totalPointsPossible,
        goalsByType: goalsByType,
        goalsByDifficulty: goalsByDifficulty,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      log('[CategoryGoalService] Error getting goal summary: $e', stackTrace: stackTrace);
      return CategoryGoalSummary.empty();
    }
  }

  /// Generate diversity goals
  Future<List<CategoryGoal>> _generateDiversityGoals(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final goals = <CategoryGoal>[];

    // Current diversity level
    final currentTotalCategories =
        currentReport.stats.exerciseCategories.length + currentReport.stats.dietCategories.length;

    // Historical average
    final historicalAverage =
        historicalReports.isNotEmpty
            ? historicalReports
                    .map((r) => r.stats.exerciseCategories.length + r.stats.dietCategories.length)
                    .reduce((a, b) => a + b) /
                historicalReports.length
            : 3.0;

    // Generate appropriate diversity goal
    final targetCategories = math.max(currentTotalCategories + 1, (historicalAverage + 2).round());
    final difficulty = _determineDifficulty(targetCategories, currentTotalCategories);

    goals.add(
      CategoryGoal(
        id: _uuid.v4(),
        title: '카테고리 다양성 확장',
        description: '이번 주에 $targetCategories개의 서로 다른 카테고리를 경험해보세요',
        type: CategoryGoalType.diversity,
        difficulty: difficulty,
        targetValue: targetCategories,
        currentValue: currentTotalCategories,
        progress: targetCategories > 0 ? (currentTotalCategories / targetCategories).clamp(0.0, 1.0) : 0.0,
        isCompleted: currentTotalCategories >= targetCategories,
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        basePoints: 20,
        metadata: {'historicalAverage': historicalAverage, 'currentCategories': currentTotalCategories},
      ),
    );

    return goals;
  }

  /// Generate consistency goals
  Future<List<CategoryGoal>> _generateConsistencyGoals(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final goals = <CategoryGoal>[];

    if (historicalReports.length < 2) return goals;

    // Find categories that appear consistently
    final categoryConsistency = _analyzeConsistencyPatterns(currentReport, historicalReports);

    for (final entry in categoryConsistency.entries) {
      final categoryName = entry.key;
      final consistency = entry.value;

      if (consistency >= 0.5) {
        // At least 50% consistency
        final targetWeeks = math.min(4, historicalReports.length + 1);
        final currentWeeks = _countConsecutiveWeeks(categoryName, currentReport, historicalReports);

        goals.add(
          CategoryGoal(
            id: _uuid.v4(),
            title: '$categoryName 일관성 유지',
            description: '$categoryName 카테고리를 $targetWeeks주 연속으로 유지해보세요',
            type: CategoryGoalType.consistency,
            difficulty: _determineDifficultyFromWeeks(targetWeeks),
            targetValue: targetWeeks,
            currentValue: currentWeeks,
            progress: targetWeeks > 0 ? (currentWeeks / targetWeeks).clamp(0.0, 1.0) : 0.0,
            isCompleted: currentWeeks >= targetWeeks,
            isActive: true,
            createdAt: DateTime.now(),
            basePoints: 15,
            metadata: {'categoryName': categoryName, 'consistency': consistency},
            targetCategories: [categoryName],
          ),
        );
      }
    }

    return goals;
  }

  /// Generate exploration goals
  Future<List<CategoryGoal>> _generateExplorationGoals(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final goals = <CategoryGoal>[];

    // Find unexplored categories
    final allCategories = {
      ...ExerciseCategory.values.map((e) => e.displayName),
      ...DietCategory.values.map((e) => e.displayName),
    };

    final exploredCategories = <String>{};
    exploredCategories.addAll(currentReport.stats.exerciseCategories.keys);
    exploredCategories.addAll(currentReport.stats.dietCategories.keys);

    for (final report in historicalReports) {
      exploredCategories.addAll(report.stats.exerciseCategories.keys);
      exploredCategories.addAll(report.stats.dietCategories.keys);
    }

    final unexploredCategories = allCategories.difference(exploredCategories);

    if (unexploredCategories.isNotEmpty) {
      final targetCount = math.min(3, unexploredCategories.length);

      goals.add(
        CategoryGoal(
          id: _uuid.v4(),
          title: '새로운 카테고리 탐험',
          description: '이번 주에 $targetCount개의 새로운 카테고리에 도전해보세요',
          type: CategoryGoalType.exploration,
          difficulty: _determineDifficultyFromCount(targetCount),
          targetValue: targetCount,
          currentValue: 0, // Will be updated based on new categories tried
          progress: 0.0,
          isCompleted: false,
          isActive: true,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          basePoints: 25,
          metadata: {'unexploredCount': unexploredCategories.length},
          targetCategories: unexploredCategories.take(targetCount).toList(),
        ),
      );
    }

    return goals;
  }

  /// Generate balance goals
  Future<List<CategoryGoal>> _generateBalanceGoals(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final goals = <CategoryGoal>[];

    // Calculate current balance
    final exerciseCount = currentReport.stats.exerciseCategories.values.fold(0, (a, b) => a + b);
    final dietCount = currentReport.stats.dietCategories.values.fold(0, (a, b) => a + b);
    final totalCount = exerciseCount + dietCount;

    if (totalCount > 0) {
      final exerciseRatio = exerciseCount / totalCount;
      final isBalanced = exerciseRatio >= 0.3 && exerciseRatio <= 0.7;

      if (!isBalanced) {
        goals.add(
          CategoryGoal(
            id: _uuid.v4(),
            title: '운동-식단 균형 달성',
            description: '운동과 식단 활동의 균형을 맞춰보세요 (30-70% 비율)',
            type: CategoryGoalType.balance,
            difficulty: GoalDifficulty.medium,
            targetValue: 1, // Binary goal: balanced or not
            currentValue: isBalanced ? 1 : 0,
            progress: isBalanced ? 1.0 : 0.0,
            isCompleted: isBalanced,
            isActive: true,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
            basePoints: 30,
            metadata: {'exerciseRatio': exerciseRatio, 'exerciseCount': exerciseCount, 'dietCount': dietCount},
          ),
        );
      }
    }

    return goals;
  }

  /// Calculate optimal exercise target based on historical data
  int _calculateOptimalExerciseTarget(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    if (historicalReports.isEmpty) return 3;

    final historicalCounts = historicalReports.map((r) => r.stats.exerciseCategories.length).toList();
    final averageCount = historicalCounts.reduce((a, b) => a + b) / historicalCounts.length;
    final maxCount = historicalCounts.reduce(math.max);

    // Target slightly above average but not exceeding max + 1
    return math.min((averageCount + 1).round(), maxCount + 1);
  }

  /// Calculate optimal diet target based on historical data
  int _calculateOptimalDietTarget(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    if (historicalReports.isEmpty) return 3;

    final historicalCounts = historicalReports.map((r) => r.stats.dietCategories.length).toList();
    final averageCount = historicalCounts.reduce((a, b) => a + b) / historicalCounts.length;
    final maxCount = historicalCounts.reduce(math.max);

    // Target slightly above average but not exceeding max + 1
    return math.min((averageCount + 1).round(), maxCount + 1);
  }

  /// Calculate target diversity score
  double _calculateTargetDiversityScore(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    if (historicalReports.isEmpty) return 0.7;

    // Calculate current diversity score first
    final currentCategories = currentReport.stats.exerciseCategories.length + currentReport.stats.dietCategories.length;
    final currentDiversityScore = currentCategories > 0 ? (currentCategories / 10.0).clamp(0.0, 1.0) : 0.0;

    // This would typically use Shannon diversity index or similar
    // For now, return a reasonable target based on category count
    final targetCategories =
        _calculateOptimalExerciseTarget(currentReport, historicalReports) +
        _calculateOptimalDietTarget(currentReport, historicalReports);

    final targetScore = math.min(0.9, 0.5 + (targetCategories * 0.05));

    // Ensure target is always higher than current
    return math.max(targetScore, currentDiversityScore + 0.1);
  }

  /// Create default diversity target
  CategoryDiversityTarget _createDefaultDiversityTarget() {
    final weekStart = _getWeekStart(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 6));

    return CategoryDiversityTarget(
      id: _uuid.v4(),
      title: '기본 다양성 목표',
      exerciseTargetCount: 3,
      dietTargetCount: 3,
      totalTargetCount: 6,
      currentExerciseCount: 0,
      currentDietCount: 0,
      currentTotalCount: 0,
      diversityScore: 0.0,
      targetDiversityScore: 0.7,
      isAchieved: false,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }

  /// Find consistent categories from historical data
  List<Map<String, dynamic>> _findConsistentCategories(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    final consistentCategories = <Map<String, dynamic>>[];

    if (historicalReports.isEmpty) return consistentCategories;

    // Analyze exercise categories
    final exerciseConsistency = _analyzeConsistencyPatterns(currentReport, historicalReports);

    for (final entry in exerciseConsistency.entries) {
      final categoryName = entry.key;
      final consistency = entry.value;

      if (consistency >= 0.6) {
        // 60% consistency threshold
        final weeklyFrequencies = _getWeeklyFrequencies(categoryName, currentReport, historicalReports);
        final currentWeeks = _countConsecutiveWeeks(categoryName, currentReport, historicalReports);
        final targetFrequency = _calculateTargetFrequency(weeklyFrequencies);

        consistentCategories.add({
          'categoryName': categoryName,
          'categoryType': _getCategoryType(categoryName),
          'consistency': consistency,
          'weeklyFrequencies': weeklyFrequencies,
          'currentWeeks': currentWeeks,
          'targetFrequency': targetFrequency,
          'isAchieved': currentWeeks >= 3, // 3 weeks consistency
        });
      }
    }

    return consistentCategories;
  }

  /// Find unexplored categories
  List<String> _findUnexploredCategories(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    final allCategories = {
      ...ExerciseCategory.values.map((e) => e.displayName),
      ...DietCategory.values.map((e) => e.displayName),
    };

    final exploredCategories = <String>{};
    exploredCategories.addAll(currentReport.stats.exerciseCategories.keys);
    exploredCategories.addAll(currentReport.stats.dietCategories.keys);

    for (final report in historicalReports) {
      exploredCategories.addAll(report.stats.exerciseCategories.keys);
      exploredCategories.addAll(report.stats.dietCategories.keys);
    }

    return allCategories.difference(exploredCategories).toList();
  }

  /// Create weekly exploration challenge
  CategoryExplorationChallenge _createWeeklyExplorationChallenge(List<String> unexploredCategories) {
    final targetCount = math.min(2, unexploredCategories.length);
    final targetCategories = unexploredCategories.take(targetCount).toList();

    return CategoryExplorationChallenge(
      id: _uuid.v4(),
      title: '주간 탐험 챌린지',
      description: '이번 주에 새로운 카테고리 $targetCount개에 도전해보세요!',
      targetCategories: targetCategories,
      completedCategories: [],
      targetCount: targetCount,
      currentCount: 0,
      isCompleted: false,
      startDate: _getWeekStart(DateTime.now()),
      endDate: _getWeekStart(DateTime.now()).add(const Duration(days: 6)),
      rewardPoints: 50,
    );
  }

  /// Create monthly exploration challenge
  CategoryExplorationChallenge _createMonthlyExplorationChallenge(List<String> unexploredCategories) {
    final targetCount = math.min(5, unexploredCategories.length);
    final targetCategories = unexploredCategories.take(targetCount).toList();

    return CategoryExplorationChallenge(
      id: _uuid.v4(),
      title: '월간 탐험 챌린지',
      description: '이번 달에 새로운 카테고리 $targetCount개에 도전해보세요!',
      targetCategories: targetCategories,
      completedCategories: [],
      targetCount: targetCount,
      currentCount: 0,
      isCompleted: false,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      rewardPoints: 150,
    );
  }

  /// Create category type exploration challenge
  CategoryExplorationChallenge? _createCategoryTypeExplorationChallenge(
    CategoryType type,
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    final allCategories =
        type == CategoryType.exercise
            ? ExerciseCategory.values.map((e) => e.displayName).toSet()
            : DietCategory.values.map((e) => e.displayName).toSet();

    final exploredCategories = <String>{};

    if (type == CategoryType.exercise) {
      exploredCategories.addAll(currentReport.stats.exerciseCategories.keys);
      for (final report in historicalReports) {
        exploredCategories.addAll(report.stats.exerciseCategories.keys);
      }
    } else {
      exploredCategories.addAll(currentReport.stats.dietCategories.keys);
      for (final report in historicalReports) {
        exploredCategories.addAll(report.stats.dietCategories.keys);
      }
    }

    final unexploredCategories = allCategories.difference(exploredCategories);

    if (unexploredCategories.length >= 2) {
      final targetCount = math.min(3, unexploredCategories.length);
      final typeName = type == CategoryType.exercise ? '운동' : '식단';

      return CategoryExplorationChallenge(
        id: _uuid.v4(),
        title: '$typeName 카테고리 탐험',
        description: '새로운 $typeName 카테고리 $targetCount개에 도전해보세요!',
        targetCategories: unexploredCategories.take(targetCount).toList(),
        completedCategories: [],
        targetCount: targetCount,
        currentCount: 0,
        isCompleted: false,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 14)),
        rewardPoints: 75,
      );
    }

    return null;
  }

  /// Helper methods for progress calculation
  int _calculateDiversityProgress(CategoryGoal goal, WeeklyReport currentReport) {
    return currentReport.stats.exerciseCategories.length + currentReport.stats.dietCategories.length;
  }

  int _calculateConsistencyProgress(CategoryGoal goal, WeeklyReport currentReport) {
    final categoryName = goal.targetCategories.isNotEmpty ? goal.targetCategories.first : '';
    final hasCategory =
        currentReport.stats.exerciseCategories.containsKey(categoryName) ||
        currentReport.stats.dietCategories.containsKey(categoryName);
    return hasCategory ? goal.currentValue + 1 : 0; // Reset if consistency broken
  }

  int _calculateExplorationProgress(CategoryGoal goal, WeeklyReport currentReport) {
    final currentCategories = {
      ...currentReport.stats.exerciseCategories.keys,
      ...currentReport.stats.dietCategories.keys,
    };

    return goal.targetCategories.where((category) => currentCategories.contains(category)).length;
  }

  int _calculateBalanceProgress(CategoryGoal goal, WeeklyReport currentReport) {
    final exerciseCount = currentReport.stats.exerciseCategories.values.fold(0, (a, b) => a + b);
    final dietCount = currentReport.stats.dietCategories.values.fold(0, (a, b) => a + b);
    final totalCount = exerciseCount + dietCount;

    if (totalCount == 0) return 0;

    final exerciseRatio = exerciseCount / totalCount;
    final isBalanced = exerciseRatio >= 0.3 && exerciseRatio <= 0.7;

    return isBalanced ? 1 : 0;
  }

  /// Helper methods for analysis
  Map<String, double> _analyzeConsistencyPatterns(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    final consistency = <String, double>{};
    final allCategories = <String>{};

    // Collect all categories
    allCategories.addAll(currentReport.stats.exerciseCategories.keys);
    allCategories.addAll(currentReport.stats.dietCategories.keys);
    for (final report in historicalReports) {
      allCategories.addAll(report.stats.exerciseCategories.keys);
      allCategories.addAll(report.stats.dietCategories.keys);
    }

    // Calculate consistency for each category
    for (final category in allCategories) {
      int appearances = 0;
      final totalWeeks = historicalReports.length + 1;

      // Check current report
      if (currentReport.stats.exerciseCategories.containsKey(category) ||
          currentReport.stats.dietCategories.containsKey(category)) {
        appearances++;
      }

      // Check historical reports
      for (final report in historicalReports) {
        if (report.stats.exerciseCategories.containsKey(category) ||
            report.stats.dietCategories.containsKey(category)) {
          appearances++;
        }
      }

      consistency[category] = appearances / totalWeeks;
    }

    return consistency;
  }

  int _countConsecutiveWeeks(String categoryName, WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    int consecutiveWeeks = 0;

    // Check current report
    if (currentReport.stats.exerciseCategories.containsKey(categoryName) ||
        currentReport.stats.dietCategories.containsKey(categoryName)) {
      consecutiveWeeks++;
    } else {
      return 0; // Streak broken
    }

    // Check historical reports (most recent first)
    final sortedReports = List<WeeklyReport>.from(historicalReports)
      ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

    for (final report in sortedReports) {
      if (report.stats.exerciseCategories.containsKey(categoryName) ||
          report.stats.dietCategories.containsKey(categoryName)) {
        consecutiveWeeks++;
      } else {
        break; // Streak broken
      }
    }

    return consecutiveWeeks;
  }

  List<int> _getWeeklyFrequencies(
    String categoryName,
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) {
    final frequencies = <int>[];

    // Current week frequency
    final currentFreq =
        (currentReport.stats.exerciseCategories[categoryName] ?? 0) +
        (currentReport.stats.dietCategories[categoryName] ?? 0);
    frequencies.add(currentFreq);

    // Historical frequencies
    for (final report in historicalReports) {
      final freq =
          (report.stats.exerciseCategories[categoryName] ?? 0) + (report.stats.dietCategories[categoryName] ?? 0);
      frequencies.add(freq);
    }

    return frequencies;
  }

  int _calculateTargetFrequency(List<int> weeklyFrequencies) {
    if (weeklyFrequencies.isEmpty) return 1;

    final average = weeklyFrequencies.reduce((a, b) => a + b) / weeklyFrequencies.length;
    return math.max(1, average.round());
  }

  CategoryType _getCategoryType(String categoryName) {
    final exerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toSet();
    return exerciseCategories.contains(categoryName) ? CategoryType.exercise : CategoryType.diet;
  }

  int _calculateConsistencyTargetWeeks(double consistency) {
    if (consistency >= 0.8) return 4;
    if (consistency >= 0.6) return 3;
    return 2;
  }

  GoalDifficulty _determineDifficulty(int target, int current) {
    final difference = target - current;
    if (difference <= 1) return GoalDifficulty.easy;
    if (difference <= 2) return GoalDifficulty.medium;
    if (difference <= 3) return GoalDifficulty.hard;
    return GoalDifficulty.expert;
  }

  GoalDifficulty _determineDifficultyFromWeeks(int weeks) {
    if (weeks <= 2) return GoalDifficulty.easy;
    if (weeks <= 3) return GoalDifficulty.medium;
    if (weeks <= 4) return GoalDifficulty.hard;
    return GoalDifficulty.expert;
  }

  GoalDifficulty _determineDifficultyFromCount(int count) {
    if (count <= 1) return GoalDifficulty.easy;
    if (count <= 2) return GoalDifficulty.medium;
    if (count <= 3) return GoalDifficulty.hard;
    return GoalDifficulty.expert;
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}
