import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Service for detecting and managing category-based achievements
class CategoryAchievementService {
  /// Detect all category-based achievements for a weekly report
  Future<List<CategoryAchievement>> detectAchievements(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    try {
      final achievements = <CategoryAchievement>[];

      // Detect variety achievements
      achievements.addAll(await _detectVarietyAchievements(currentReport, historicalReports));

      // Detect consistency achievements
      achievements.addAll(await _detectConsistencyAchievements(currentReport, historicalReports));

      // Detect exploration achievements
      achievements.addAll(await _detectExplorationAchievements(currentReport, historicalReports));

      // Detect balance achievements
      achievements.addAll(await _detectBalanceAchievements(currentReport, historicalReports));

      log('[CategoryAchievementService] Detected ${achievements.length} achievements');
      return achievements;
    } catch (e) {
      log('[CategoryAchievementService] Error detecting achievements: $e');
      return [];
    }
  }

  /// Detect category variety achievements
  Future<List<CategoryAchievement>> _detectVarietyAchievements(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final achievements = <CategoryAchievement>[];
    final exerciseCategories = currentReport.stats.exerciseCategories.keys.toSet();
    final dietCategories = currentReport.stats.dietCategories.keys.toSet();
    final totalCategories = exerciseCategories.length + dietCategories.length;

    // Well-Rounded Week (5+ different categories)
    if (totalCategories >= 5) {
      achievements.add(
        CategoryAchievement(
          id: 'well_rounded_week_${currentReport.weekIdentifier}',
          title: '균형잡힌 한 주',
          description: '이번 주에 $totalCategories개의 다양한 카테고리를 경험했습니다!',
          type: AchievementType.categoryVariety,
          rarity: totalCategories >= 8 ? AchievementRarity.rare : AchievementRarity.uncommon,
          icon: Icons.diversity_3,
          color: SPColors.podGreen,
          achievedAt: DateTime.now(),
          points: totalCategories >= 8 ? 50 : 25,
          metadata: {
            'totalCategories': totalCategories,
            'exerciseCategories': exerciseCategories.length,
            'dietCategories': dietCategories.length,
          },
        ),
      );
    }

    // Exercise Variety Master (4+ exercise categories)
    if (exerciseCategories.length >= 4) {
      achievements.add(
        CategoryAchievement(
          id: 'exercise_variety_master_${currentReport.weekIdentifier}',
          title: '운동 다양성 마스터',
          description: '${exerciseCategories.length}가지 운동 카테고리를 모두 경험했습니다!',
          type: AchievementType.categoryVariety,
          rarity: exerciseCategories.length >= 6 ? AchievementRarity.epic : AchievementRarity.rare,
          icon: Icons.fitness_center,
          color: SPColors.podBlue,
          achievedAt: DateTime.now(),
          points: exerciseCategories.length >= 6 ? 100 : 50,
          metadata: {'exerciseCategories': exerciseCategories.length, 'categories': exerciseCategories.toList()},
        ),
      );
    }

    // Diet Variety Champion (4+ diet categories)
    if (dietCategories.length >= 4) {
      achievements.add(
        CategoryAchievement(
          id: 'diet_variety_champion_${currentReport.weekIdentifier}',
          title: '식단 다양성 챔피언',
          description: '${dietCategories.length}가지 식단 카테고리를 균형있게 섭취했습니다!',
          type: AchievementType.categoryVariety,
          rarity: dietCategories.length >= 6 ? AchievementRarity.epic : AchievementRarity.rare,
          icon: Icons.restaurant,
          color: SPColors.podOrange,
          achievedAt: DateTime.now(),
          points: dietCategories.length >= 6 ? 100 : 50,
          metadata: {'dietCategories': dietCategories.length, 'categories': dietCategories.toList()},
        ),
      );
    }

    // Perfect Variety (all categories covered)
    final allExerciseCategories = ExerciseCategory.values.map((e) => e.displayName).toSet();
    final allDietCategories = DietCategory.values.map((e) => e.displayName).toSet();

    if (exerciseCategories.containsAll(allExerciseCategories) && dietCategories.containsAll(allDietCategories)) {
      achievements.add(
        CategoryAchievement(
          id: 'perfect_variety_${currentReport.weekIdentifier}',
          title: '완벽한 다양성',
          description: '모든 운동과 식단 카테고리를 경험한 완벽한 한 주였습니다!',
          type: AchievementType.categoryVariety,
          rarity: AchievementRarity.legendary,
          icon: Icons.star,
          color: SPColors.podOrange,
          achievedAt: DateTime.now(),
          points: 250,
          metadata: {'perfectWeek': true, 'totalCategories': totalCategories},
        ),
      );
    }

    return achievements;
  }

  /// Detect category consistency achievements
  Future<List<CategoryAchievement>> _detectConsistencyAchievements(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final achievements = <CategoryAchievement>[];

    if (historicalReports.isEmpty) return achievements;

    // Analyze consistency patterns
    final consistencyData = _analyzeConsistencyPatterns(currentReport, historicalReports);

    // Consistent Category Champion (same categories for 3+ weeks)
    final consistentCategories = consistencyData['consistentCategories'] as List<String>? ?? [];
    if (consistentCategories.length >= 3) {
      achievements.add(
        CategoryAchievement(
          id: 'consistent_category_champion_${currentReport.weekIdentifier}',
          title: '일관성 챔피언',
          description: '${consistentCategories.length}개 카테고리를 꾸준히 유지하고 있습니다!',
          type: AchievementType.categoryConsistency,
          rarity: consistentCategories.length >= 5 ? AchievementRarity.rare : AchievementRarity.uncommon,
          icon: Icons.trending_up,
          color: SPColors.podBlue,
          achievedAt: DateTime.now(),
          points: consistentCategories.length >= 5 ? 50 : 25,
          metadata: {
            'consistentCategories': consistentCategories.length,
            'categories': consistentCategories,
            'weeksConsistent': consistencyData['weeksConsistent'] ?? 3,
          },
        ),
      );
    }

    // Habit Builder (same category for 4+ weeks)
    final longTermCategories = consistencyData['longTermCategories'] as List<String>? ?? [];
    if (longTermCategories.isNotEmpty) {
      achievements.add(
        CategoryAchievement(
          id: 'habit_builder_${currentReport.weekIdentifier}',
          title: '습관 형성자',
          description: '${longTermCategories.first} 카테고리를 4주 이상 꾸준히 유지했습니다!',
          type: AchievementType.categoryConsistency,
          rarity: AchievementRarity.epic,
          icon: Icons.psychology,
          color: SPColors.podPurple,
          achievedAt: DateTime.now(),
          points: 100,
          metadata: {
            'category': longTermCategories.first,
            'weeksConsistent': consistencyData['maxWeeksConsistent'] ?? 4,
          },
        ),
      );
    }

    // Consistency Streak (consistent variety for multiple weeks)
    final varietyStreak = consistencyData['varietyStreak'] as int? ?? 0;
    if (varietyStreak >= 3) {
      achievements.add(
        CategoryAchievement(
          id: 'consistency_streak_${currentReport.weekIdentifier}',
          title: '일관성 연속 기록',
          description: '$varietyStreak주 연속으로 다양한 카테고리를 유지했습니다!',
          type: AchievementType.categoryConsistency,
          rarity: varietyStreak >= 5 ? AchievementRarity.epic : AchievementRarity.rare,
          icon: Icons.local_fire_department,
          color: SPColors.danger100,
          achievedAt: DateTime.now(),
          points: varietyStreak >= 5 ? 100 : 50,
          metadata: {'streakWeeks': varietyStreak},
        ),
      );
    }

    return achievements;
  }

  /// Detect category exploration achievements
  Future<List<CategoryAchievement>> _detectExplorationAchievements(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final achievements = <CategoryAchievement>[];

    // Find new categories this week
    final currentCategories = {
      ...currentReport.stats.exerciseCategories.keys,
      ...currentReport.stats.dietCategories.keys,
    };

    final historicalCategories = <String>{};
    for (final report in historicalReports) {
      historicalCategories.addAll(report.stats.exerciseCategories.keys);
      historicalCategories.addAll(report.stats.dietCategories.keys);
    }

    final newCategories = currentCategories.difference(historicalCategories);

    // First Time Explorer (trying new category)
    if (newCategories.isNotEmpty) {
      for (final category in newCategories) {
        achievements.add(
          CategoryAchievement(
            id: 'first_time_explorer_${category}_${currentReport.weekIdentifier}',
            title: '첫 도전자',
            description: '$category을(를) 처음으로 시도해보셨네요!',
            type: AchievementType.categoryExploration,
            rarity: AchievementRarity.common,
            icon: Icons.explore,
            color: SPColors.podOrange,
            achievedAt: DateTime.now(),
            points: 10,
            metadata: {'newCategory': category, 'isFirstTime': true},
          ),
        );
      }
    }

    // Adventure Seeker (3+ new categories in one week)
    if (newCategories.length >= 3) {
      achievements.add(
        CategoryAchievement(
          id: 'adventure_seeker_${currentReport.weekIdentifier}',
          title: '모험가',
          description: '이번 주에 ${newCategories.length}개의 새로운 카테고리에 도전했습니다!',
          type: AchievementType.categoryExploration,
          rarity: AchievementRarity.rare,
          icon: Icons.explore_outlined,
          color: SPColors.podOrange,
          achievedAt: DateTime.now(),
          points: 50,
          metadata: {'newCategoriesCount': newCategories.length, 'newCategories': newCategories.toList()},
        ),
      );
    }

    // Category Collector (tried 80% of all categories)
    final allPossibleCategories = {
      ...ExerciseCategory.values.map((e) => e.displayName),
      ...DietCategory.values.map((e) => e.displayName),
    };
    final allTriedCategories = {...historicalCategories, ...currentCategories};
    final collectionPercentage = allTriedCategories.length / allPossibleCategories.length;

    if (collectionPercentage >= 0.8) {
      achievements.add(
        CategoryAchievement(
          id: 'category_collector_${currentReport.weekIdentifier}',
          title: '카테고리 수집가',
          description: '전체 카테고리의 ${(collectionPercentage * 100).toInt()}%를 경험했습니다!',
          type: AchievementType.categoryExploration,
          rarity: collectionPercentage >= 0.95 ? AchievementRarity.legendary : AchievementRarity.epic,
          icon: Icons.collections,
          color: SPColors.podPurple,
          achievedAt: DateTime.now(),
          points: collectionPercentage >= 0.95 ? 250 : 100,
          metadata: {
            'collectionPercentage': collectionPercentage,
            'categoriesCollected': allTriedCategories.length,
            'totalCategories': allPossibleCategories.length,
          },
        ),
      );
    }

    return achievements;
  }

  /// Detect category balance achievements
  Future<List<CategoryAchievement>> _detectBalanceAchievements(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final achievements = <CategoryAchievement>[];

    // Calculate balance metrics
    final balanceMetrics = _calculateBalanceMetrics(currentReport);

    // Perfect Balance (optimal balance score)
    if (balanceMetrics.isOptimalBalance) {
      achievements.add(
        CategoryAchievement(
          id: 'perfect_balance_${currentReport.weekIdentifier}',
          title: '완벽한 균형',
          description: '운동과 식단 카테고리의 완벽한 균형을 달성했습니다!',
          type: AchievementType.categoryBalance,
          rarity: AchievementRarity.epic,
          icon: Icons.balance,
          color: SPColors.podPurple,
          achievedAt: DateTime.now(),
          points: 100,
          metadata: {
            'balanceScore': balanceMetrics.overallBalance,
            'exerciseBalance': balanceMetrics.exerciseBalance,
            'dietBalance': balanceMetrics.dietBalance,
          },
        ),
      );
    }

    // Harmony Master (high diversity with good balance)
    if (balanceMetrics.isHighDiversity && balanceMetrics.overallBalance >= 0.6) {
      achievements.add(
        CategoryAchievement(
          id: 'harmony_master_${currentReport.weekIdentifier}',
          title: '조화의 달인',
          description: '높은 다양성과 좋은 균형을 동시에 달성했습니다!',
          type: AchievementType.categoryBalance,
          rarity: AchievementRarity.rare,
          icon: Icons.auto_awesome,
          color: SPColors.podGreen,
          achievedAt: DateTime.now(),
          points: 50,
          metadata: {'diversityScore': balanceMetrics.diversityScore, 'balanceScore': balanceMetrics.overallBalance},
        ),
      );
    }

    // Health Optimizer (optimal mix of exercise and diet)
    final exerciseCount = currentReport.stats.exerciseCategories.values.fold(0, (a, b) => a + b);
    final dietCount = currentReport.stats.dietCategories.values.fold(0, (a, b) => a + b);
    final totalCount = exerciseCount + dietCount;

    if (totalCount > 0) {
      final exerciseRatio = exerciseCount / totalCount;
      final isOptimalMix = exerciseRatio >= 0.3 && exerciseRatio <= 0.7; // 30-70% range

      if (isOptimalMix && totalCount >= 10) {
        achievements.add(
          CategoryAchievement(
            id: 'health_optimizer_${currentReport.weekIdentifier}',
            title: '건강 최적화자',
            description: '운동과 식단의 최적 비율을 달성했습니다!',
            type: AchievementType.categoryBalance,
            rarity: AchievementRarity.uncommon,
            icon: Icons.health_and_safety,
            color: SPColors.success100,
            achievedAt: DateTime.now(),
            points: 25,
            metadata: {
              'exerciseRatio': exerciseRatio,
              'totalActivities': totalCount,
              'exerciseCount': exerciseCount,
              'dietCount': dietCount,
            },
          ),
        );
      }
    }

    return achievements;
  }

  /// Analyze consistency patterns across historical reports
  Map<String, dynamic> _analyzeConsistencyPatterns(WeeklyReport currentReport, List<WeeklyReport> historicalReports) {
    final allReports = [currentReport, ...historicalReports];
    allReports.sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

    final categoryWeekCounts = <String, int>{};

    // Count how many weeks each category appears
    for (final report in allReports) {
      final categories = {...report.stats.exerciseCategories.keys, ...report.stats.dietCategories.keys};

      for (final category in categories) {
        categoryWeekCounts[category] = (categoryWeekCounts[category] ?? 0) + 1;
      }
    }

    // Find consistent categories (appeared in 3+ weeks)
    final consistentCategories =
        categoryWeekCounts.entries.where((entry) => entry.value >= 3).map((entry) => entry.key).toList();

    // Find long-term categories (appeared in 4+ weeks)
    final longTermCategories =
        categoryWeekCounts.entries.where((entry) => entry.value >= 4).map((entry) => entry.key).toList();

    // Calculate variety streak (consecutive weeks with 3+ categories)
    int varietyStreak = 0;
    int currentStreak = 0;

    for (final report in allReports.reversed) {
      final totalCategories = report.stats.exerciseCategories.length + report.stats.dietCategories.length;

      if (totalCategories >= 3) {
        currentStreak++;
      } else {
        if (currentStreak > varietyStreak) {
          varietyStreak = currentStreak;
        }
        currentStreak = 0;
      }
    }

    if (currentStreak > varietyStreak) {
      varietyStreak = currentStreak;
    }

    return {
      'consistentCategories': consistentCategories,
      'longTermCategories': longTermCategories,
      'weeksConsistent': 3,
      'maxWeeksConsistent':
          categoryWeekCounts.values.isNotEmpty ? categoryWeekCounts.values.reduce((a, b) => a > b ? a : b) : 0,
      'varietyStreak': varietyStreak,
    };
  }

  /// Calculate category balance metrics
  CategoryBalanceMetrics _calculateBalanceMetrics(WeeklyReport report) {
    final exerciseCategories = report.stats.exerciseCategories;
    final dietCategories = report.stats.dietCategories;

    final exerciseTotal = exerciseCategories.values.fold(0, (a, b) => a + b);
    final dietTotal = dietCategories.values.fold(0, (a, b) => a + b);
    final grandTotal = exerciseTotal + dietTotal;

    if (grandTotal == 0) {
      return CategoryBalanceMetrics.empty();
    }

    // Calculate exercise balance (how evenly distributed exercise categories are)
    final exerciseBalance = _calculateCategoryDistributionBalance(exerciseCategories);

    // Calculate diet balance (how evenly distributed diet categories are)
    final dietBalance = _calculateCategoryDistributionBalance(dietCategories);

    // Calculate overall balance
    final exerciseRatio = exerciseTotal / grandTotal;
    final dietRatio = dietTotal / grandTotal;
    final ratioBalance = 1.0 - (exerciseRatio - dietRatio).abs();
    final overallBalance = (exerciseBalance + dietBalance + ratioBalance) / 3;

    // Calculate diversity score (Shannon diversity index)
    final allCategories = {...exerciseCategories, ...dietCategories};
    final diversityScore = _calculateShannonDiversity(allCategories, grandTotal);

    // Create category distribution map
    final categoryDistribution = <String, double>{};
    allCategories.forEach((category, count) {
      categoryDistribution[category] = count / grandTotal;
    });

    return CategoryBalanceMetrics(
      exerciseBalance: exerciseBalance,
      dietBalance: dietBalance,
      overallBalance: overallBalance,
      categoryDistribution: categoryDistribution,
      diversityScore: diversityScore,
      totalCategories: allCategories.length,
      activeCategories: allCategories.values.where((count) => count > 0).length,
    );
  }

  /// Calculate balance for a single category type (exercise or diet)
  double _calculateCategoryDistributionBalance(Map<String, int> categories) {
    if (categories.isEmpty) return 0.0;

    final total = categories.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0.0;

    final expectedRatio = 1.0 / categories.length;
    double balance = 0.0;

    for (final count in categories.values) {
      final actualRatio = count / total;
      balance += 1.0 - (actualRatio - expectedRatio).abs();
    }

    return balance / categories.length;
  }

  /// Calculate Shannon diversity index
  double _calculateShannonDiversity(Map<String, int> categories, int total) {
    if (categories.isEmpty || total == 0) return 0.0;

    double diversity = 0.0;
    for (final count in categories.values) {
      if (count > 0) {
        final proportion = count / total;
        diversity -= proportion * (proportion.log() / 2.302585); // log base 10
      }
    }

    // Normalize to 0-1 scale
    final maxDiversity = (categories.length.log() / 2.302585);
    return maxDiversity > 0 ? diversity / maxDiversity : 0.0;
  }

  /// Get achievement progress for tracking
  Future<List<AchievementProgress>> getAchievementProgress(
    WeeklyReport currentReport,
    List<WeeklyReport> historicalReports,
  ) async {
    final progressList = <AchievementProgress>[];

    // Variety progress
    final totalCategories = currentReport.stats.exerciseCategories.length + currentReport.stats.dietCategories.length;

    progressList.add(
      AchievementProgress(
        achievementId: 'well_rounded_week',
        title: '균형잡힌 한 주',
        description: '5개 이상의 다양한 카테고리 경험하기',
        type: AchievementType.categoryVariety,
        currentValue: totalCategories,
        targetValue: 5,
        progress: (totalCategories / 5).clamp(0.0, 1.0),
        isCompleted: totalCategories >= 5,
        completedAt: totalCategories >= 5 ? DateTime.now() : null,
        metadata: {'currentCategories': totalCategories},
      ),
    );

    // Balance progress
    final balanceMetrics = _calculateBalanceMetrics(currentReport);
    progressList.add(
      AchievementProgress(
        achievementId: 'perfect_balance',
        title: '완벽한 균형',
        description: '운동과 식단의 최적 균형 달성하기',
        type: AchievementType.categoryBalance,
        currentValue: (balanceMetrics.overallBalance * 100).round(),
        targetValue: 70,
        progress: balanceMetrics.overallBalance / 0.7,
        isCompleted: balanceMetrics.isOptimalBalance,
        completedAt: balanceMetrics.isOptimalBalance ? DateTime.now() : null,
        metadata: {'balanceScore': balanceMetrics.overallBalance},
      ),
    );

    return progressList;
  }
}

/// Extension for mathematical operations
extension MathExtension on num {
  double log() => math.log(this);
}
