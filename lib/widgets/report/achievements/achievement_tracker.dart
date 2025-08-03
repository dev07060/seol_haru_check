import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying and tracking category-based achievements
class AchievementTracker extends StatefulWidget {
  final List<CategoryAchievement> achievements;
  final List<AchievementProgress> progressList;
  final VoidCallback? onAchievementTap;
  final bool showProgress;
  final bool showNewBadge;

  const AchievementTracker({
    super.key,
    required this.achievements,
    this.progressList = const [],
    this.onAchievementTap,
    this.showProgress = true,
    this.showNewBadge = true,
  });

  @override
  State<AchievementTracker> createState() => _AchievementTrackerState();
}

class _AchievementTrackerState extends State<AchievementTracker> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: _buildContent(context)),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.gray200),
        boxShadow: [BoxShadow(color: SPColors.gray400.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          if (widget.achievements.isNotEmpty) ...[
            _buildAchievementsList(context),
            if (widget.showProgress && widget.progressList.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildProgressSection(context),
            ],
          ] else ...[
            _buildEmptyState(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final totalPoints = widget.achievements.fold<int>(0, (sum, achievement) => sum + achievement.points);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: SPColors.podGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.emoji_events, color: SPColors.podGreen, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '카테고리 성취',
                style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
              ),
              if (widget.achievements.isNotEmpty)
                Text(
                  '${widget.achievements.length}개 달성 • $totalPoints점',
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                ),
            ],
          ),
        ),
        if (widget.achievements.where((a) => a.isNew).isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: SPColors.danger100, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'NEW',
              style: FTextStyles.caption_12.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildAchievementsList(BuildContext context) {
    return Column(
      children:
          widget.achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAchievementCard(context, achievement),
            );
          }).toList(),
    );
  }

  Widget _buildAchievementCard(BuildContext context, CategoryAchievement achievement) {
    return GestureDetector(
      onTap: widget.onAchievementTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: achievement.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: achievement.color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: achievement.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(achievement.icon, color: achievement.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: FTextStyles.body1_16.copyWith(
                            color: SPColors.textColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.showNewBadge && achievement.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: SPColors.danger100, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'NEW',
                            style: FTextStyles.caption_10.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(achievement.description, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRarityBadge(achievement.rarity),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: SPColors.podGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${achievement.points}점',
                          style: FTextStyles.caption_12.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge(AchievementRarity rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: rarity.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rarity.color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        rarity.displayName,
        style: FTextStyles.caption_12.copyWith(color: rarity.color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '진행 중인 성취',
          style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...widget.progressList
            .where((progress) => !progress.isCompleted)
            .map(
              (progress) =>
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildProgressCard(context, progress)),
            ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, AchievementProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.gray100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(progress.type.icon, color: progress.type.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.title,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${progress.currentValue}/${progress.targetValue}',
                style: FTextStyles.caption_12.copyWith(color: SPColors.gray600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(progress.description, style: FTextStyles.caption_12.copyWith(color: SPColors.gray600)),
          const SizedBox(height: 12),
          _buildProgressBar(progress),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AchievementProgress progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('진행률', style: FTextStyles.caption_12.copyWith(color: SPColors.gray600)),
            Text(
              '${progress.progressPercentage.toStringAsFixed(0)}%',
              style: FTextStyles.caption_12.copyWith(color: progress.type.color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.progress.clamp(0.0, 1.0),
          backgroundColor: SPColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(progress.type.color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: SPColors.gray400),
          const SizedBox(height: 12),
          Text('아직 달성한 성취가 없습니다', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
          const SizedBox(height: 4),
          Text('다양한 카테고리를 시도해보세요!', style: FTextStyles.caption_12.copyWith(color: SPColors.gray500)),
        ],
      ),
    );
  }
}
