import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Enum for different types of category goals
enum CategoryGoalType {
  diversity,
  consistency,
  exploration,
  balance;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case CategoryGoalType.diversity:
        return '다양성 목표';
      case CategoryGoalType.consistency:
        return '일관성 목표';
      case CategoryGoalType.exploration:
        return '탐험 목표';
      case CategoryGoalType.balance:
        return '균형 목표';
    }
  }

  /// Get icon for goal type
  IconData get icon {
    switch (this) {
      case CategoryGoalType.diversity:
        return Icons.diversity_3;
      case CategoryGoalType.consistency:
        return Icons.trending_up;
      case CategoryGoalType.exploration:
        return Icons.explore;
      case CategoryGoalType.balance:
        return Icons.balance;
    }
  }

  /// Get color for goal type
  Color get color {
    switch (this) {
      case CategoryGoalType.diversity:
        return SPColors.podGreen;
      case CategoryGoalType.consistency:
        return SPColors.podBlue;
      case CategoryGoalType.exploration:
        return SPColors.podOrange;
      case CategoryGoalType.balance:
        return SPColors.podPurple;
    }
  }
}

/// Enum for goal difficulty levels
enum GoalDifficulty {
  easy,
  medium,
  hard,
  expert;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case GoalDifficulty.easy:
        return '쉬움';
      case GoalDifficulty.medium:
        return '보통';
      case GoalDifficulty.hard:
        return '어려움';
      case GoalDifficulty.expert:
        return '전문가';
    }
  }

  /// Get multiplier for points calculation
  double get pointMultiplier {
    switch (this) {
      case GoalDifficulty.easy:
        return 1.0;
      case GoalDifficulty.medium:
        return 1.5;
      case GoalDifficulty.hard:
        return 2.0;
      case GoalDifficulty.expert:
        return 3.0;
    }
  }

  /// Get color for difficulty
  Color get color {
    switch (this) {
      case GoalDifficulty.easy:
        return SPColors.success100;
      case GoalDifficulty.medium:
        return SPColors.podBlue;
      case GoalDifficulty.hard:
        return SPColors.podOrange;
      case GoalDifficulty.expert:
        return SPColors.danger100;
    }
  }
}

/// Model for category-based goals
class CategoryGoal {
  final String id;
  final String title;
  final String description;
  final CategoryGoalType type;
  final GoalDifficulty difficulty;
  final int targetValue;
  final int currentValue;
  final double progress;
  final bool isCompleted;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final int basePoints;
  final Map<String, dynamic> metadata;
  final List<String> targetCategories;

  const CategoryGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    required this.currentValue,
    required this.progress,
    required this.isCompleted,
    required this.isActive,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
    required this.basePoints,
    this.metadata = const {},
    this.targetCategories = const [],
  });

  /// Create from map data
  factory CategoryGoal.fromMap(Map<String, dynamic> map) {
    return CategoryGoal(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: CategoryGoalType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => CategoryGoalType.diversity,
      ),
      difficulty: GoalDifficulty.values.firstWhere(
        (difficulty) => difficulty.name == map['difficulty'],
        orElse: () => GoalDifficulty.medium,
      ),
      targetValue: map['targetValue'] ?? 1,
      currentValue: map['currentValue'] ?? 0,
      progress: (map['progress'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      basePoints: map['basePoints'] ?? 10,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      targetCategories: List<String>.from(map['targetCategories'] ?? []),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'progress': progress,
      'isCompleted': isCompleted,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'basePoints': basePoints,
      'metadata': metadata,
      'targetCategories': targetCategories,
    };
  }

  /// Get total points including difficulty multiplier
  int get totalPoints => (basePoints * difficulty.pointMultiplier).round();

  /// Get progress percentage (0-100)
  double get progressPercentage => (progress * 100).clamp(0, 100);

  /// Get remaining value to complete
  int get remainingValue => (targetValue - currentValue).clamp(0, targetValue);

  /// Check if goal is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if goal is achievable (not expired and active)
  bool get isAchievable => isActive && !isExpired && !isCompleted;

  /// Get days remaining until expiration
  int? get daysRemaining {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inDays;
  }

  /// Copy with modifications
  CategoryGoal copyWith({
    String? id,
    String? title,
    String? description,
    CategoryGoalType? type,
    GoalDifficulty? difficulty,
    int? targetValue,
    int? currentValue,
    double? progress,
    bool? isCompleted,
    bool? isActive,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    int? basePoints,
    Map<String, dynamic>? metadata,
    List<String>? targetCategories,
  }) {
    return CategoryGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      basePoints: basePoints ?? this.basePoints,
      metadata: metadata ?? this.metadata,
      targetCategories: targetCategories ?? this.targetCategories,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryGoal &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.difficulty == difficulty &&
        other.targetValue == targetValue &&
        other.currentValue == currentValue &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        type.hashCode ^
        difficulty.hashCode ^
        targetValue.hashCode ^
        currentValue.hashCode ^
        isCompleted.hashCode;
  }

  @override
  String toString() {
    return 'CategoryGoal(id: $id, title: $title, type: $type, progress: ${progressPercentage.toStringAsFixed(1)}%, completed: $isCompleted)';
  }
}

/// Model for category diversity targets
class CategoryDiversityTarget {
  final String id;
  final String title;
  final int exerciseTargetCount;
  final int dietTargetCount;
  final int totalTargetCount;
  final int currentExerciseCount;
  final int currentDietCount;
  final int currentTotalCount;
  final double diversityScore;
  final double targetDiversityScore;
  final bool isAchieved;
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<String, bool> categoryTargets; // category name -> achieved

  const CategoryDiversityTarget({
    required this.id,
    required this.title,
    required this.exerciseTargetCount,
    required this.dietTargetCount,
    required this.totalTargetCount,
    required this.currentExerciseCount,
    required this.currentDietCount,
    required this.currentTotalCount,
    required this.diversityScore,
    required this.targetDiversityScore,
    required this.isAchieved,
    required this.weekStart,
    required this.weekEnd,
    this.categoryTargets = const {},
  });

  /// Create from map data
  factory CategoryDiversityTarget.fromMap(Map<String, dynamic> map) {
    return CategoryDiversityTarget(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      exerciseTargetCount: map['exerciseTargetCount'] ?? 0,
      dietTargetCount: map['dietTargetCount'] ?? 0,
      totalTargetCount: map['totalTargetCount'] ?? 0,
      currentExerciseCount: map['currentExerciseCount'] ?? 0,
      currentDietCount: map['currentDietCount'] ?? 0,
      currentTotalCount: map['currentTotalCount'] ?? 0,
      diversityScore: (map['diversityScore'] ?? 0.0).toDouble(),
      targetDiversityScore: (map['targetDiversityScore'] ?? 0.0).toDouble(),
      isAchieved: map['isAchieved'] ?? false,
      weekStart: DateTime.parse(map['weekStart'] ?? DateTime.now().toIso8601String()),
      weekEnd: DateTime.parse(map['weekEnd'] ?? DateTime.now().toIso8601String()),
      categoryTargets: Map<String, bool>.from(map['categoryTargets'] ?? {}),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'exerciseTargetCount': exerciseTargetCount,
      'dietTargetCount': dietTargetCount,
      'totalTargetCount': totalTargetCount,
      'currentExerciseCount': currentExerciseCount,
      'currentDietCount': currentDietCount,
      'currentTotalCount': currentTotalCount,
      'diversityScore': diversityScore,
      'targetDiversityScore': targetDiversityScore,
      'isAchieved': isAchieved,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'categoryTargets': categoryTargets,
    };
  }

  /// Get exercise progress (0-1)
  double get exerciseProgress =>
      exerciseTargetCount > 0 ? (currentExerciseCount / exerciseTargetCount).clamp(0.0, 1.0) : 0.0;

  /// Get diet progress (0-1)
  double get dietProgress => dietTargetCount > 0 ? (currentDietCount / dietTargetCount).clamp(0.0, 1.0) : 0.0;

  /// Get total progress (0-1)
  double get totalProgress => totalTargetCount > 0 ? (currentTotalCount / totalTargetCount).clamp(0.0, 1.0) : 0.0;

  /// Get diversity progress (0-1)
  double get diversityProgress =>
      targetDiversityScore > 0 ? (diversityScore / targetDiversityScore).clamp(0.0, 1.0) : 0.0;

  /// Get achieved category count
  int get achievedCategoryCount => categoryTargets.values.where((achieved) => achieved).length;

  /// Get total category targets
  int get totalCategoryTargets => categoryTargets.length;

  @override
  String toString() {
    return 'CategoryDiversityTarget(id: $id, title: $title, totalProgress: ${(totalProgress * 100).toStringAsFixed(1)}%, achieved: $isAchieved)';
  }
}

/// Model for category consistency goals
class CategoryConsistencyGoal {
  final String id;
  final String title;
  final String categoryName;
  final CategoryType categoryType;
  final int targetWeeks;
  final int currentWeeks;
  final int targetFrequency; // per week
  final List<int> weeklyFrequencies;
  final bool isAchieved;
  final DateTime startDate;
  final DateTime? achievedDate;
  final double consistencyScore;

  const CategoryConsistencyGoal({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.categoryType,
    required this.targetWeeks,
    required this.currentWeeks,
    required this.targetFrequency,
    required this.weeklyFrequencies,
    required this.isAchieved,
    required this.startDate,
    this.achievedDate,
    required this.consistencyScore,
  });

  /// Create from map data
  factory CategoryConsistencyGoal.fromMap(Map<String, dynamic> map) {
    return CategoryConsistencyGoal(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      categoryName: map['categoryName'] ?? '',
      categoryType: CategoryType.values.firstWhere(
        (type) => type.name == map['categoryType'],
        orElse: () => CategoryType.exercise,
      ),
      targetWeeks: map['targetWeeks'] ?? 1,
      currentWeeks: map['currentWeeks'] ?? 0,
      targetFrequency: map['targetFrequency'] ?? 1,
      weeklyFrequencies: List<int>.from(map['weeklyFrequencies'] ?? []),
      isAchieved: map['isAchieved'] ?? false,
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      achievedDate: map['achievedDate'] != null ? DateTime.parse(map['achievedDate']) : null,
      consistencyScore: (map['consistencyScore'] ?? 0.0).toDouble(),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'categoryName': categoryName,
      'categoryType': categoryType.name,
      'targetWeeks': targetWeeks,
      'currentWeeks': currentWeeks,
      'targetFrequency': targetFrequency,
      'weeklyFrequencies': weeklyFrequencies,
      'isAchieved': isAchieved,
      'startDate': startDate.toIso8601String(),
      if (achievedDate != null) 'achievedDate': achievedDate!.toIso8601String(),
      'consistencyScore': consistencyScore,
    };
  }

  /// Get progress (0-1)
  double get progress => targetWeeks > 0 ? (currentWeeks / targetWeeks).clamp(0.0, 1.0) : 0.0;

  /// Get average weekly frequency
  double get averageWeeklyFrequency =>
      weeklyFrequencies.isNotEmpty ? weeklyFrequencies.reduce((a, b) => a + b) / weeklyFrequencies.length : 0.0;

  /// Check if current week meets target
  bool get currentWeekMeetsTarget => weeklyFrequencies.isNotEmpty && weeklyFrequencies.last >= targetFrequency;

  /// Copy with modifications
  CategoryConsistencyGoal copyWith({
    String? id,
    String? title,
    String? categoryName,
    CategoryType? categoryType,
    int? targetWeeks,
    int? currentWeeks,
    int? targetFrequency,
    List<int>? weeklyFrequencies,
    bool? isAchieved,
    DateTime? startDate,
    DateTime? achievedDate,
    double? consistencyScore,
  }) {
    return CategoryConsistencyGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryName: categoryName ?? this.categoryName,
      categoryType: categoryType ?? this.categoryType,
      targetWeeks: targetWeeks ?? this.targetWeeks,
      currentWeeks: currentWeeks ?? this.currentWeeks,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      weeklyFrequencies: weeklyFrequencies ?? this.weeklyFrequencies,
      isAchieved: isAchieved ?? this.isAchieved,
      startDate: startDate ?? this.startDate,
      achievedDate: achievedDate ?? this.achievedDate,
      consistencyScore: consistencyScore ?? this.consistencyScore,
    );
  }

  @override
  String toString() {
    return 'CategoryConsistencyGoal(id: $id, category: $categoryName, progress: ${(progress * 100).toStringAsFixed(1)}%, achieved: $isAchieved)';
  }
}

/// Model for category exploration challenges
class CategoryExplorationChallenge {
  final String id;
  final String title;
  final String description;
  final List<String> targetCategories;
  final List<String> completedCategories;
  final int targetCount;
  final int currentCount;
  final bool isCompleted;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? completedDate;
  final int rewardPoints;
  final Map<String, DateTime> categoryFirstTryDates;

  const CategoryExplorationChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCategories,
    required this.completedCategories,
    required this.targetCount,
    required this.currentCount,
    required this.isCompleted,
    required this.startDate,
    required this.endDate,
    this.completedDate,
    required this.rewardPoints,
    this.categoryFirstTryDates = const {},
  });

  /// Create from map data
  factory CategoryExplorationChallenge.fromMap(Map<String, dynamic> map) {
    final categoryFirstTryDatesMap = Map<String, dynamic>.from(map['categoryFirstTryDates'] ?? {});
    final categoryFirstTryDates = <String, DateTime>{};
    categoryFirstTryDatesMap.forEach((key, value) {
      categoryFirstTryDates[key] = DateTime.parse(value);
    });

    return CategoryExplorationChallenge(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetCategories: List<String>.from(map['targetCategories'] ?? []),
      completedCategories: List<String>.from(map['completedCategories'] ?? []),
      targetCount: map['targetCount'] ?? 1,
      currentCount: map['currentCount'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String()),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      rewardPoints: map['rewardPoints'] ?? 50,
      categoryFirstTryDates: categoryFirstTryDates,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    final categoryFirstTryDatesMap = <String, String>{};
    categoryFirstTryDates.forEach((key, value) {
      categoryFirstTryDatesMap[key] = value.toIso8601String();
    });

    return {
      'id': id,
      'title': title,
      'description': description,
      'targetCategories': targetCategories,
      'completedCategories': completedCategories,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (completedDate != null) 'completedDate': completedDate!.toIso8601String(),
      'rewardPoints': rewardPoints,
      'categoryFirstTryDates': categoryFirstTryDatesMap,
    };
  }

  /// Get progress (0-1)
  double get progress => targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  /// Get remaining categories to explore
  List<String> get remainingCategories =>
      targetCategories.where((category) => !completedCategories.contains(category)).toList();

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Check if challenge is expired
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Check if challenge is active
  bool get isActive => !isCompleted && !isExpired;

  @override
  String toString() {
    return 'CategoryExplorationChallenge(id: $id, title: $title, progress: ${(progress * 100).toStringAsFixed(1)}%, completed: $isCompleted)';
  }
}

/// Model for category goal summary
class CategoryGoalSummary {
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;
  final int expiredGoals;
  final double overallProgress;
  final int totalPointsEarned;
  final int totalPointsPossible;
  final Map<CategoryGoalType, int> goalsByType;
  final Map<GoalDifficulty, int> goalsByDifficulty;
  final DateTime lastUpdated;

  const CategoryGoalSummary({
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
    required this.expiredGoals,
    required this.overallProgress,
    required this.totalPointsEarned,
    required this.totalPointsPossible,
    required this.goalsByType,
    required this.goalsByDifficulty,
    required this.lastUpdated,
  });

  /// Create empty summary
  factory CategoryGoalSummary.empty() {
    return CategoryGoalSummary(
      totalGoals: 0,
      activeGoals: 0,
      completedGoals: 0,
      expiredGoals: 0,
      overallProgress: 0.0,
      totalPointsEarned: 0,
      totalPointsPossible: 0,
      goalsByType: {},
      goalsByDifficulty: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Get completion rate (0-1)
  double get completionRate => totalGoals > 0 ? completedGoals / totalGoals : 0.0;

  /// Get success rate (completed / (completed + expired))
  double get successRate {
    final attempted = completedGoals + expiredGoals;
    return attempted > 0 ? completedGoals / attempted : 0.0;
  }

  @override
  String toString() {
    return 'CategoryGoalSummary(total: $totalGoals, active: $activeGoals, completed: $completedGoals, progress: ${(overallProgress * 100).toStringAsFixed(1)}%)';
  }
}
