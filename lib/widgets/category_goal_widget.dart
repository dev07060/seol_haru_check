import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_goal_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying category-based goals
class CategoryGoalWidget extends StatelessWidget {
  final CategoryGoal goal;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool isCompact;

  const CategoryGoalWidget({
    super.key,
    required this.goal,
    this.onTap,
    this.showProgress = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: goal.isCompleted ? goal.type.color : SPColors.gray200, width: goal.isCompleted ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isCompact ? _buildCompactContent(context) : _buildFullContent(context),
        ),
      ),
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        _buildDescription(context),
        if (showProgress) ...[const SizedBox(height: 12), _buildProgress(context)],
        const SizedBox(height: 8),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: FTextStyles.body1_16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: goal.isCompleted ? goal.type.color : SPColors.textColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (showProgress) _buildCompactProgress(context),
            ],
          ),
        ),
        _buildStatusBadge(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: FTextStyles.title3_18.copyWith(
                  fontWeight: FontWeight.w600,
                  color: goal.isCompleted ? goal.type.color : SPColors.textColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [_buildTypeChip(), const SizedBox(width: 8), _buildDifficultyChip()]),
            ],
          ),
        ),
        _buildStatusBadge(context),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: goal.type.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(goal.type.icon, color: goal.type.color, size: 24),
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: goal.type.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        goal.type.displayName,
        style: FTextStyles.caption_12.copyWith(color: goal.type.color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDifficultyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: goal.difficulty.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        goal.difficulty.displayName,
        style: FTextStyles.caption_12.copyWith(color: goal.difficulty.color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (goal.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: SPColors.success100, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text('완료', style: FTextStyles.caption_12.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else if (goal.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: SPColors.gray400, borderRadius: BorderRadius.circular(16)),
        child: Text('만료', style: FTextStyles.caption_12.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      );
    } else if (goal.daysRemaining != null && goal.daysRemaining! <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: SPColors.danger100, borderRadius: BorderRadius.circular(16)),
        child: Text('마감임박', style: FTextStyles.caption_12.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      goal.description,
      style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('진행률', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w500)),
            Text(
              '${goal.currentValue}/${goal.targetValue} (${goal.progressPercentage.toStringAsFixed(0)}%)',
              style: FTextStyles.body2_14.copyWith(color: goal.type.color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: goal.progress,
          backgroundColor: SPColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(goal.type.color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildCompactProgress(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: goal.progress,
            backgroundColor: SPColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(goal.type.color),
            minHeight: 4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${goal.progressPercentage.toStringAsFixed(0)}%',
          style: FTextStyles.caption_12.copyWith(color: goal.type.color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (goal.daysRemaining != null)
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: SPColors.gray500),
              const SizedBox(width: 4),
              Text(
                goal.daysRemaining! > 0 ? '${goal.daysRemaining}일 남음' : '오늘 마감',
                style: FTextStyles.caption_12.copyWith(
                  color: goal.daysRemaining! <= 1 ? SPColors.danger100 : SPColors.gray500,
                ),
              ),
            ],
          ),
        Row(
          children: [
            Icon(Icons.stars, size: 16, color: SPColors.podOrange),
            const SizedBox(width: 4),
            Text(
              '${goal.totalPoints}점',
              style: FTextStyles.caption_12.copyWith(color: SPColors.podOrange, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for displaying category goal summary
class CategoryGoalSummaryWidget extends StatelessWidget {
  final CategoryGoalSummary summary;

  const CategoryGoalSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('목표 현황', style: FTextStyles.title2_20.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _buildSummaryStats(context),
            const SizedBox(height: 16),
            _buildProgressBar(context),
            const SizedBox(height: 16),
            _buildPointsInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatItem(context, '전체', summary.totalGoals.toString(), SPColors.gray600)),
        Expanded(child: _buildStatItem(context, '진행중', summary.activeGoals.toString(), SPColors.podBlue)),
        Expanded(child: _buildStatItem(context, '완료', summary.completedGoals.toString(), SPColors.success100)),
        Expanded(child: _buildStatItem(context, '만료', summary.expiredGoals.toString(), SPColors.gray400)),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: FTextStyles.title1_24.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: FTextStyles.caption_12.copyWith(color: SPColors.gray500)),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('전체 진행률', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600)),
            Text(
              '${(summary.overallProgress * 100).toStringAsFixed(1)}%',
              style: FTextStyles.body1_16.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: summary.overallProgress,
          backgroundColor: SPColors.gray200,
          valueColor: const AlwaysStoppedAnimation<Color>(SPColors.podGreen),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPointsInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.podOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.stars, color: SPColors.podOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('획득 포인트', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
                const SizedBox(height: 4),
                Text(
                  '${summary.totalPointsEarned} / ${summary.totalPointsPossible}',
                  style: FTextStyles.title3_18.copyWith(color: SPColors.podOrange, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(
            '${summary.totalPointsPossible > 0 ? ((summary.totalPointsEarned / summary.totalPointsPossible) * 100).toStringAsFixed(0) : 0}%',
            style: FTextStyles.title3_18.copyWith(color: SPColors.podOrange, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying category diversity target
class CategoryDiversityTargetWidget extends StatelessWidget {
  final CategoryDiversityTarget target;
  final VoidCallback? onTap;

  const CategoryDiversityTargetWidget({super.key, required this.target, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: target.isAchieved ? SPColors.success100 : SPColors.gray200,
          width: target.isAchieved ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildProgressSection(context),
              const SizedBox(height: 16),
              _buildCategoryTargets(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: SPColors.podGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.diversity_3, color: SPColors.podGreen, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                target.title,
                style: FTextStyles.title3_18.copyWith(
                  fontWeight: FontWeight.w600,
                  color: target.isAchieved ? SPColors.success100 : SPColors.textColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${target.weekStart.month}/${target.weekStart.day} - ${target.weekEnd.month}/${target.weekEnd.day}',
                style: FTextStyles.caption_12.copyWith(color: SPColors.gray500),
              ),
            ],
          ),
        ),
        if (target.isAchieved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: SPColors.success100, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('달성', style: FTextStyles.caption_12.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildProgressItem(
            context,
            '운동',
            target.currentExerciseCount,
            target.exerciseTargetCount,
            target.exerciseProgress,
            SPColors.podBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildProgressItem(
            context,
            '식단',
            target.currentDietCount,
            target.dietTargetCount,
            target.dietProgress,
            SPColors.podOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(BuildContext context, String label, int current, int target, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: FTextStyles.body2_14.copyWith(fontWeight: FontWeight.w500)),
            Text('$current/$target', style: FTextStyles.body2_14.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: SPColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildCategoryTargets(BuildContext context) {
    if (target.categoryTargets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('카테고리 목표', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              target.categoryTargets.entries.map((entry) {
                final categoryName = entry.key;
                final isAchieved = entry.value;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAchieved ? SPColors.success100.withOpacity(0.1) : SPColors.gray100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isAchieved ? SPColors.success100 : SPColors.gray300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAchieved)
                        Icon(Icons.check_circle, color: SPColors.success100, size: 16)
                      else
                        Icon(Icons.radio_button_unchecked, color: SPColors.gray400, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        categoryName,
                        style: FTextStyles.caption_12.copyWith(
                          color: isAchieved ? SPColors.success100 : SPColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
