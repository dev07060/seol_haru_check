import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_mapping_service.dart';
import 'package:seol_haru_check/services/consistency_calculator.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/consistency_explanation_dialog.dart';

/// Widget that displays a summary card of weekly statistics with category insights
class ReportSummaryCard extends StatelessWidget {
  final WeeklyReport report;
  final List<WeeklyReport> historicalReports;
  final List<CategoryAchievement> achievements;

  const ReportSummaryCard({
    super.key,
    required this.report,
    this.historicalReports = const [],
    this.achievements = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Recalculate consistency score with new algorithm for all reports
    final recalculatedStats = _getRecalculatedStats();

    final categoryBalanceMetrics = _calculateCategoryBalanceMetrics();
    final categoryDiversityScore = _calculateCategoryDiversityScore();
    final topCategories = _getTopCategories();
    final weeklyGoalsProgress = _calculateWeeklyGoalsProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.weeklyStats,
          style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const Gap(12),

        // Main Statistics Row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                AppStrings.totalCertifications,
                '${report.stats.totalCertifications}',
                '개',
                SPColors.podBlue,
                Icons.check_circle_outline,
              ),
            ),
            const Gap(4),
            Expanded(
              child: _buildStatItem(
                context,
                AppStrings.exerciseDays,
                '${report.stats.exerciseDays}',
                '일',
                SPColors.podGreen,
                Icons.fitness_center,
              ),
            ),
            const Gap(4),
            Expanded(
              child: _buildStatItem(
                context,
                AppStrings.dietDays,
                '${report.stats.dietDays}',
                '일',
                SPColors.podOrange,
                Icons.restaurant,
              ),
            ),
            const Gap(4),
            Expanded(
              child: _buildTappableStatItem(
                context,
                AppStrings.consistencyScore,
                _formatConsistencyScore(recalculatedStats.consistencyScore),
                '%',
                SPColors.podPurple,
                Icons.trending_up,
                onTap: () => _showConsistencyExplanation(context, recalculatedStats.consistencyScore),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Category Insights Row
        Row(
          children: [
            Expanded(
              child: _buildCategoryInsightItem(
                context,
                '카테고리 다양성',
                '${(categoryDiversityScore * 100).toInt()}점',
                categoryDiversityScore >= 0.7
                    ? SPColors.success100
                    : categoryDiversityScore >= 0.5
                    ? SPColors.podOrange
                    : SPColors.danger100,
                Icons.diversity_3,
                categoryDiversityScore,
              ),
            ),
            const Gap(4),
            Expanded(child: _buildCategoryBalanceIndicator(context, categoryBalanceMetrics)),
          ],
        ),

        const SizedBox(height: 16),

        // Top 3 Categories Overview
        if (topCategories.isNotEmpty) ...[
          Text(
            '주요 활동 카테고리',
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildTopCategoriesOverview(context, topCategories),
          const SizedBox(height: 16),
        ],

        // Weekly Goals Progress
        if (weeklyGoalsProgress.isNotEmpty) ...[
          Text(
            '주간 목표 달성률',
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildWeeklyGoalsProgress(context, weeklyGoalsProgress),
          const SizedBox(height: 16),
        ],

        // Exercise types breakdown if available
        if (report.stats.exerciseTypes.isNotEmpty) ...[
          Text(
            '운동 유형별 분포',
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildExerciseTypesBreakdown(context),
        ],
      ],
    );
  }

  /// Get recalculated stats with updated consistency score
  WeeklyStats _getRecalculatedStats() {
    // Recalculate consistency score using new algorithm
    final newConsistencyScore = ConsistencyCalculator.calculateConsistencyScore(report.stats);

    // Return stats with updated consistency score
    return report.stats.copyWith(consistencyScore: newConsistencyScore);
  }

  /// Format consistency score to prevent unrealistic values
  String _formatConsistencyScore(double score) {
    // Clamp the score to reasonable range (0-100%)
    final clampedScore = (score * 100).clamp(0, 100);
    return clampedScore.toInt().toString();
  }

  /// Show consistency explanation dialog
  void _showConsistencyExplanation(BuildContext context, double consistencyScore) {
    showDialog(
      context: context,
      builder: (context) => ConsistencyExplanationDialog(consistencyScore: consistencyScore),
    );
  }

  Widget _buildTappableStatItem(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(onTap: onTap, child: _buildStatItem(context, label, value, unit, color, icon));
  }

  Widget _buildStatItem(BuildContext context, String label, String value, String unit, Color color, IconData icon) {
    final valueStyle = FTextStyles.titleM.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w700);
    final unitStyle = valueStyle.copyWith(fontSize: valueStyle.fontSize! * 0.8, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const Gap(2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: value, style: valueStyle),
                    const WidgetSpan(child: SizedBox(width: 2)),
                    TextSpan(text: unit, style: unitStyle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTypesBreakdown(BuildContext context) {
    final sortedTypes = report.stats.exerciseTypes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children:
          sortedTypes.map((entry) {
            final percentage = (entry.value / report.stats.totalCertifications * 100);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: SPColors.gray200, borderRadius: BorderRadius.circular(4)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(color: SPColors.podGreen, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${entry.value}회',
                      style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// Calculate category balance metrics
  CategoryBalanceMetrics _calculateCategoryBalanceMetrics() {
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
        diversity -= proportion * (math.log(proportion) / math.log(2));
      }
    }

    // Normalize to 0-1 scale
    final maxDiversity = math.log(categories.length) / math.log(2);
    return maxDiversity > 0 ? diversity / maxDiversity : 0.0;
  }

  /// Calculate category diversity score
  double _calculateCategoryDiversityScore() {
    final exerciseCategories = report.stats.exerciseCategories.length;
    final dietCategories = report.stats.dietCategories.length;
    final totalCategories = exerciseCategories + dietCategories;

    // Maximum possible categories (6 exercise + 6 diet = 12)
    const maxCategories = 12;

    // Base diversity score
    final baseScore = totalCategories / maxCategories;

    // Bonus for having both exercise and diet categories
    final balanceBonus = (exerciseCategories > 0 && dietCategories > 0) ? 0.1 : 0.0;

    return (baseScore + balanceBonus).clamp(0.0, 1.0);
  }

  /// Get top 3 categories by count
  List<MapEntry<String, int>> _getTopCategories() {
    final allCategories = <String, int>{...report.stats.exerciseCategories, ...report.stats.dietCategories};

    final sortedCategories = allCategories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(3).toList();
  }

  /// Calculate weekly goals progress
  Map<String, double> _calculateWeeklyGoalsProgress() {
    final goals = <String, double>{};

    // Exercise goal: 5 days per week
    goals['운동 목표'] = (report.stats.exerciseDays / 5.0).clamp(0.0, 1.0);

    // Diet goal: 7 days per week
    goals['식단 목표'] = (report.stats.dietDays / 7.0).clamp(0.0, 1.0);

    // Category diversity goal: 5 categories
    final totalCategories = report.stats.exerciseCategories.length + report.stats.dietCategories.length;
    goals['다양성 목표'] = (totalCategories / 5.0).clamp(0.0, 1.0);

    return goals;
  }

  /// Build category insight item widget
  Widget _buildCategoryInsightItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: SPColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  /// Build category balance indicator
  Widget _buildCategoryBalanceIndicator(BuildContext context, CategoryBalanceMetrics metrics) {
    final balanceColor =
        metrics.overallBalance >= 0.7
            ? SPColors.success100
            : metrics.overallBalance >= 0.5
            ? SPColors.podOrange
            : SPColors.danger100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: balanceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: balanceColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, size: 16, color: balanceColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '카테고리 균형',
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metrics.balanceDescription,
            style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: metrics.overallBalance,
            backgroundColor: SPColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(balanceColor),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  /// Build top categories overview
  Widget _buildTopCategoriesOverview(BuildContext context, List<MapEntry<String, int>> topCategories) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Row(
        children:
            topCategories.map((category) {
              // Determine category type based on whether it's in exercise or diet categories
              final isExercise = report.stats.exerciseCategories.containsKey(category.key);
              final categoryType = isExercise ? CategoryType.exercise : CategoryType.diet;
              final emoji = CategoryMappingService.instance.getCategoryEmojiByName(category.key, categoryType);

              return Expanded(
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      category.key,
                      style: FTextStyles.body2_14.copyWith(
                        color: SPColors.textColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('${category.value}회', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Build weekly goals progress
  Widget _buildWeeklyGoalsProgress(BuildContext context, Map<String, double> goalsProgress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        children:
            goalsProgress.entries.map((entry) {
              final goalName = entry.key;
              final progress = entry.value;
              final progressColor =
                  progress >= 1.0
                      ? SPColors.success100
                      : progress >= 0.7
                      ? SPColors.podGreen
                      : progress >= 0.5
                      ? SPColors.podOrange
                      : SPColors.danger100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(goalName, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(color: SPColors.gray200, borderRadius: BorderRadius.circular(4)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(color: progressColor, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
