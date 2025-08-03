import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/achievements/achievement_badge.dart';
import 'package:seol_haru_check/widgets/report/achievements/achievement_celebration.dart';
import 'package:seol_haru_check/widgets/report/achievements/achievement_tracker.dart';

/// Comprehensive widget for displaying weekly achievements in the report
class WeeklyAchievementsSection extends ConsumerStatefulWidget {
  final String? userUuid;
  final bool showCelebration;
  final bool showProgress;

  const WeeklyAchievementsSection({super.key, this.userUuid, this.showCelebration = true, this.showProgress = true});

  @override
  ConsumerState<WeeklyAchievementsSection> createState() => _WeeklyAchievementsSectionState();
}

class _WeeklyAchievementsSectionState extends ConsumerState<WeeklyAchievementsSection> with TickerProviderStateMixin {
  late TabController _tabController;
  int _celebrationIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(weeklyReportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, reportState),
        const SizedBox(height: 16),

        if (reportState.isLoadingAchievements) ...[
          _buildLoadingState(context),
        ] else if (reportState.achievements.isEmpty && reportState.achievementProgress.isEmpty) ...[
          _buildEmptyState(context),
        ] else ...[
          _buildAchievementTabs(context, reportState),
          const SizedBox(height: 16),
          _buildTabContent(context, reportState),
        ],

        // Show celebration overlay for new achievements
        if (widget.showCelebration && reportState.newAchievements.isNotEmpty)
          _buildCelebrationOverlay(context, reportState.newAchievements),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, WeeklyReportState reportState) {
    final totalPoints = reportState.achievements.fold<int>(0, (sum, achievement) => sum + achievement.points);
    final newAchievementsCount = reportState.newAchievements.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SPColors.reportGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.emoji_events, color: SPColors.reportGreen, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '이번 주 성취',
                    style: FTextStyles.title2_20.copyWith(
                      color: SPColors.textColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (newAchievementsCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: SPColors.danger100, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '+$newAchievementsCount',
                        style: FTextStyles.caption_12.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${reportState.achievements.length}개 달성 • $totalPoints점 획득',
                style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => ref.read(weeklyReportProvider.notifier).refreshAchievements(),
          icon: Icon(Icons.refresh, color: SPColors.gray600),
        ),
      ],
    );
  }

  Widget _buildAchievementTabs(BuildContext context, WeeklyReportState reportState) {
    return Container(
      decoration: BoxDecoration(color: SPColors.gray200, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          color: SPColors.backgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: SPColors.gray400.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: SPColors.textColor(context),
        unselectedLabelColor: SPColors.gray700,
        labelStyle: FTextStyles.body2_14.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: FTextStyles.body2_14,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 16),
                const SizedBox(width: 4),
                Text('달성 (${reportState.achievements.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.trending_up, size: 16), const SizedBox(width: 4), Text('진행 중')],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.analytics, size: 16), const SizedBox(width: 4), Text('통계')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WeeklyReportState reportState) {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          // Achievements tab
          _buildAchievementsTab(context, reportState),

          // Progress tab
          _buildProgressTab(context, reportState),

          // Statistics tab
          _buildStatisticsTab(context, reportState),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, WeeklyReportState reportState) {
    if (reportState.achievements.isEmpty) {
      return _buildEmptyAchievementsState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AchievementTracker(
            achievements: reportState.achievements,
            progressList: reportState.achievementProgress,
            showProgress: false,
            showNewBadge: true,
            onAchievementTap: () {
              // Handle achievement tap
            },
          ),
          const SizedBox(height: 16),
          _buildAchievementsByType(context, reportState.achievements),
        ],
      ),
    );
  }

  Widget _buildProgressTab(BuildContext context, WeeklyReportState reportState) {
    final incompleteProgress = reportState.achievementProgress.where((progress) => !progress.isCompleted).toList();

    if (incompleteProgress.isEmpty) {
      return _buildEmptyProgressState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AchievementTracker(
        achievements: const [],
        progressList: incompleteProgress,
        showProgress: true,
        showNewBadge: false,
      ),
    );
  }

  Widget _buildStatisticsTab(BuildContext context, WeeklyReportState reportState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAchievementStats(context, reportState.achievements),
          const SizedBox(height: 24),
          _buildRarityDistribution(context, reportState.achievements),
          const SizedBox(height: 24),
          _buildTypeDistribution(context, reportState.achievements),
        ],
      ),
    );
  }

  Widget _buildAchievementsByType(BuildContext context, List<CategoryAchievement> achievements) {
    final groupedAchievements = <AchievementType, List<CategoryAchievement>>{};

    for (final achievement in achievements) {
      groupedAchievements.putIfAbsent(achievement.type, () => []).add(achievement);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          groupedAchievements.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(entry.key.icon, color: entry.key.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        entry.key.displayName,
                        style: FTextStyles.body1_16.copyWith(
                          color: SPColors.textColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.key.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.value.length}개',
                          style: FTextStyles.caption_12.copyWith(color: entry.key.color, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        entry.value.map((achievement) {
                          return AchievementBadge(achievement: achievement, isUnlocked: true, isCompact: true);
                        }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAchievementStats(BuildContext context, List<CategoryAchievement> achievements) {
    final totalPoints = achievements.fold<int>(0, (sum, achievement) => sum + achievement.points);
    final averageRarity =
        achievements.isEmpty
            ? 0.0
            : achievements.map((a) => a.rarity.index).reduce((a, b) => a + b) / achievements.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '성취 통계',
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '총 성취',
                  '${achievements.length}개',
                  Icons.emoji_events,
                  SPColors.reportGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, '총 점수', '$totalPoints점', Icons.star, SPColors.reportOrange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '평균 희귀도',
                  averageRarity.toStringAsFixed(1),
                  Icons.diamond,
                  SPColors.reportPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  '이번 주 신규',
                  '${achievements.where((a) => a.isNew).length}개',
                  Icons.new_releases,
                  SPColors.danger100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
          ),
          Text(title, style: FTextStyles.caption_12.copyWith(color: SPColors.gray600)),
        ],
      ),
    );
  }

  Widget _buildRarityDistribution(BuildContext context, List<CategoryAchievement> achievements) {
    final rarityCount = <AchievementRarity, int>{};
    for (final achievement in achievements) {
      rarityCount[achievement.rarity] = (rarityCount[achievement.rarity] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '희귀도별 분포',
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...AchievementRarity.values.map((rarity) {
            final count = rarityCount[rarity] ?? 0;
            final percentage = achievements.isEmpty ? 0.0 : count / achievements.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: rarity.color, borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rarity.displayName,
                      style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context)),
                    ),
                  ),
                  Text(
                    '$count개 (${(percentage * 100).toInt()}%)',
                    style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeDistribution(BuildContext context, List<CategoryAchievement> achievements) {
    final typeCount = <AchievementType, int>{};
    for (final achievement in achievements) {
      typeCount[achievement.type] = (typeCount[achievement.type] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '유형별 분포',
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...AchievementType.values.map((type) {
            final count = typeCount[type] ?? 0;
            final percentage = achievements.isEmpty ? 0.0 : count / achievements.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(type.icon, color: type.color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context)),
                    ),
                  ),
                  Text(
                    '$count개 (${(percentage * 100).toInt()}%)',
                    style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay(BuildContext context, List<CategoryAchievement> newAchievements) {
    if (_celebrationIndex >= newAchievements.length) return const SizedBox.shrink();

    return Positioned.fill(
      child: AchievementCelebration(
        achievement: newAchievements[_celebrationIndex],
        onDismiss: () {
          setState(() {
            _celebrationIndex++;
          });

          // If all celebrations are done, mark achievements as seen
          if (_celebrationIndex >= newAchievements.length) {
            ref.read(weeklyReportProvider.notifier).markNewAchievementsAsSeen();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(SPColors.reportGreen)),
            const SizedBox(height: 16),
            Text('성취를 분석하고 있습니다...', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: SPColors.gray400),
            const SizedBox(height: 16),
            Text('아직 달성한 성취가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
            const SizedBox(height: 8),
            Text(
              '다양한 카테고리를 시도하여 성취를 잠금해제하세요!',
              style: FTextStyles.body2_14.copyWith(color: SPColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAchievementsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text('이번 주 달성한 성취가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: SPColors.reportGreen),
          const SizedBox(height: 16),
          Text('모든 성취를 완료했습니다!', style: FTextStyles.body1_16.copyWith(color: SPColors.reportGreen)),
        ],
      ),
    );
  }
}
