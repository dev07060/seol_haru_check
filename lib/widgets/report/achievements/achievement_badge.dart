import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying achievement badges and milestones
class AchievementBadge extends StatefulWidget {
  final CategoryAchievement? achievement;
  final AchievementMilestone? milestone;
  final bool isUnlocked;
  final bool showProgress;
  final double? progress;
  final VoidCallback? onTap;
  final bool isCompact;

  const AchievementBadge({
    super.key,
    this.achievement,
    this.milestone,
    this.isUnlocked = false,
    this.showProgress = false,
    this.progress,
    this.onTap,
    this.isCompact = false,
  }) : assert(achievement != null || milestone != null);

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    if (widget.isUnlocked) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isUnlocked ? _pulseAnimation.value : 1.0,
            child: _buildBadgeContent(context),
          );
        },
      ),
    );
  }

  Widget _buildBadgeContent(BuildContext context) {
    final title = widget.achievement?.title ?? widget.milestone?.title ?? '';
    final description = widget.achievement?.description ?? widget.milestone?.description ?? '';
    final icon = widget.achievement?.icon ?? widget.achievement?.type.icon ?? Icons.star;
    final color = widget.achievement?.color ?? widget.achievement?.type.color ?? SPColors.podGreen;
    final rarity = widget.achievement?.rarity ?? widget.milestone?.rarity ?? AchievementRarity.common;
    final points = widget.achievement?.points ?? widget.milestone?.points ?? 0;

    if (widget.isCompact) {
      return _buildCompactBadge(context, title, icon, color, rarity);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isUnlocked ? color.withOpacity(0.1) : SPColors.gray100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isUnlocked ? color.withOpacity(0.3) : SPColors.gray300,
          width: widget.isUnlocked ? 2 : 1,
        ),
        boxShadow:
            widget.isUnlocked
                ? [BoxShadow(color: color.withOpacity(_glowAnimation.value * 0.3), blurRadius: 12, spreadRadius: 2)]
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with glow effect for unlocked achievements
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.isUnlocked ? color.withOpacity(0.2) : SPColors.gray200,
              borderRadius: BorderRadius.circular(28),
              boxShadow:
                  widget.isUnlocked
                      ? [
                        BoxShadow(color: color.withOpacity(_glowAnimation.value * 0.5), blurRadius: 8, spreadRadius: 1),
                      ]
                      : null,
            ),
            child: Icon(icon, size: 28, color: widget.isUnlocked ? color : SPColors.gray500),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: FTextStyles.body1_16.copyWith(
              color: widget.isUnlocked ? SPColors.textColor(context) : SPColors.gray500,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            description,
            style: FTextStyles.caption_12.copyWith(color: widget.isUnlocked ? SPColors.gray600 : SPColors.gray400),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Rarity and points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isUnlocked ? rarity.color.withOpacity(0.1) : SPColors.gray200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rarity.displayName,
                  style: FTextStyles.caption_10.copyWith(
                    color: widget.isUnlocked ? rarity.color : SPColors.gray500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$points점',
                style: FTextStyles.caption_10.copyWith(
                  color: widget.isUnlocked ? SPColors.podGreen : SPColors.gray400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Progress bar for milestones
          if (widget.showProgress && widget.progress != null) ...[
            const SizedBox(height: 8),
            _buildProgressBar(context, color),
          ],

          // Lock overlay for locked achievements
          if (!widget.isUnlocked) ...[
            const SizedBox(height: 8),
            Icon(Icons.lock_outline, size: 16, color: SPColors.gray400),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBadge(BuildContext context, String title, IconData icon, Color color, AchievementRarity rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isUnlocked ? color.withOpacity(0.1) : SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isUnlocked ? color.withOpacity(0.3) : SPColors.gray300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: widget.isUnlocked ? color : SPColors.gray500),
          const SizedBox(width: 4),
          Text(
            title,
            style: FTextStyles.caption_12.copyWith(
              color: widget.isUnlocked ? SPColors.textColor(context) : SPColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!widget.isUnlocked) ...[
            const SizedBox(width: 4),
            Icon(Icons.lock_outline, size: 12, color: SPColors.gray400),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, Color color) {
    final progress = widget.progress ?? 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('진행률', style: FTextStyles.caption_10.copyWith(color: SPColors.gray500)),
            Text(
              '${(progress * 100).toInt()}%',
              style: FTextStyles.caption_10.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: SPColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ],
    );
  }
}

/// Widget for displaying a grid of achievement badges
class AchievementBadgeGrid extends StatelessWidget {
  final List<CategoryAchievement> achievements;
  final List<AchievementMilestone> milestones;
  final int crossAxisCount;
  final double childAspectRatio;
  final VoidCallback? onBadgeTap;

  const AchievementBadgeGrid({
    super.key,
    this.achievements = const [],
    this.milestones = const [],
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.8,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = <Widget>[];

    // Add achievement badges
    for (final achievement in achievements) {
      allItems.add(AchievementBadge(achievement: achievement, isUnlocked: true, onTap: onBadgeTap));
    }

    // Add milestone badges
    for (final milestone in milestones) {
      allItems.add(AchievementBadge(milestone: milestone, isUnlocked: milestone.isUnlocked, onTap: onBadgeTap));
    }

    if (allItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) => allItems[index],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text(
            '아직 획득한 성취가 없습니다',
            style: FTextStyles.body1_16.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '다양한 카테고리를 시도하여\n성취를 잠금해제하세요!',
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
