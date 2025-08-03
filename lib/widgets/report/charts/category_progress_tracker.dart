import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for tracking category-based progress over months
class CategoryProgressTracker extends StatefulWidget {
  final List<WeeklyReport> historicalReports;
  final CategoryType categoryType;
  final int monthsToShow;

  const CategoryProgressTracker({
    super.key,
    required this.historicalReports,
    required this.categoryType,
    this.monthsToShow = 6,
  });

  @override
  State<CategoryProgressTracker> createState() => _CategoryProgressTrackerState();
}

class _CategoryProgressTrackerState extends State<CategoryProgressTracker> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, List<MonthlyProgress>> _categoryProgress = {};
  List<String> _topCategories = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _calculateMonthlyProgress();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryProgressTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historicalReports != widget.historicalReports || oldWidget.categoryType != widget.categoryType) {
      _calculateMonthlyProgress();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateMonthlyProgress() {
    if (widget.historicalReports.isEmpty) return;

    // Group reports by month
    final monthlyReports = <String, List<WeeklyReport>>{};
    final categoryTotals = <String, int>{};

    for (final report in widget.historicalReports) {
      final monthKey = DateFormat('yyyy-MM').format(report.weekStartDate);
      monthlyReports[monthKey] = (monthlyReports[monthKey] ?? [])..add(report);

      // Collect category totals for finding top categories
      final categories =
          widget.categoryType == CategoryType.exercise ? report.stats.exerciseCategories : report.stats.dietCategories;

      for (final entry in categories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    // Get top 4 categories by total count
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    _topCategories = sortedCategories.take(4).map((e) => e.key).toList();

    // Calculate monthly progress for each category
    _categoryProgress = {};

    for (final categoryName in _topCategories) {
      final progressList = <MonthlyProgress>[];

      // Sort months chronologically
      final sortedMonths = monthlyReports.keys.toList()..sort();
      final recentMonths = sortedMonths.take(widget.monthsToShow).toList();

      for (final monthKey in recentMonths) {
        final reports = monthlyReports[monthKey] ?? [];

        int totalCount = 0;
        int weeksWithActivity = 0;
        double averageIntensity = 0;

        for (final report in reports) {
          final categories =
              widget.categoryType == CategoryType.exercise
                  ? report.stats.exerciseCategories
                  : report.stats.dietCategories;

          final categoryCount = categories[categoryName] ?? 0;
          totalCount += categoryCount;

          if (categoryCount > 0) {
            weeksWithActivity++;
          }

          final totalWeekCount = categories.values.fold<int>(0, (sum, count) => sum + count);
          if (totalWeekCount > 0) {
            averageIntensity += (categoryCount / totalWeekCount) * 100;
          }
        }

        averageIntensity = reports.isNotEmpty ? averageIntensity / reports.length : 0;
        final consistency = reports.isNotEmpty ? weeksWithActivity / reports.length : 0;

        progressList.add(
          MonthlyProgress(
            monthKey: monthKey,
            totalCount: totalCount,
            weeksWithActivity: weeksWithActivity,
            totalWeeks: reports.length,
            averageIntensity: averageIntensity.toDouble(),
            consistency: consistency.toDouble(),
          ),
        );
      }

      _categoryProgress[categoryName] = progressList;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicalReports.isEmpty || _topCategories.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${widget.categoryType.displayName} 카테고리별 월간 진행도',
                style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ),

            // Progress cards for each category
            ...(_topCategories.map((categoryName) => _buildCategoryProgressCard(categoryName))),
          ],
        );
      },
    );
  }

  Widget _buildCategoryProgressCard(String categoryName) {
    final progressList = _categoryProgress[categoryName] ?? [];
    if (progressList.isEmpty) return const SizedBox.shrink();

    final colors = [SPColors.reportGreen, SPColors.reportBlue, SPColors.reportOrange, SPColors.reportPurple];

    final colorIndex = _topCategories.indexOf(categoryName);
    final color = colors[colorIndex % colors.length];

    // Calculate overall trend
    final recentProgress = progressList.length >= 2 ? progressList.last : null;
    final previousProgress = progressList.length >= 2 ? progressList[progressList.length - 2] : null;

    TrendDirection trend = TrendDirection.stable;
    double changePercentage = 0;

    if (recentProgress != null && previousProgress != null) {
      final recentScore = recentProgress.totalCount;
      final previousScore = previousProgress.totalCount;

      if (recentScore > previousScore) {
        trend = TrendDirection.up;
        changePercentage = previousScore > 0 ? ((recentScore - previousScore) / previousScore) * 100 : 100;
      } else if (recentScore < previousScore) {
        trend = TrendDirection.down;
        changePercentage = previousScore > 0 ? ((previousScore - recentScore) / previousScore) * 100 : 0;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
        boxShadow: [
          BoxShadow(color: SPColors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
                ),
              ),
              // Trend indicator
              if (trend != TrendDirection.stable) ...[
                Icon(trend.icon, size: 16, color: trend.color),
                const SizedBox(width: 4),
                Text(
                  '${changePercentage.toStringAsFixed(0)}%',
                  style: FTextStyles.body2_14.copyWith(color: trend.color, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Monthly progress bars
          Row(children: progressList.map((progress) => _buildMonthlyProgressBar(progress, color)).toList()),

          const SizedBox(height: 8),

          // Month labels
          Row(children: progressList.map((progress) => _buildMonthLabel(progress)).toList()),

          const SizedBox(height: 12),

          // Summary stats
          if (recentProgress != null) _buildSummaryStats(recentProgress, color),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgressBar(MonthlyProgress progress, Color color) {
    final maxHeight = 60.0;
    final maxCount = _getMaxCountForCategory();
    final height = maxCount > 0 ? (progress.totalCount / maxCount) * maxHeight : 0.0;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Container(
              height: maxHeight,
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: Duration(milliseconds: (2000 * _animation.value).toInt()),
                height: height,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              progress.totalCount.toString(),
              style: FTextStyles.body4_12.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthLabel(MonthlyProgress progress) {
    final date = DateTime.parse('${progress.monthKey}-01');
    final monthName = DateFormat('M월').format(date);

    return Expanded(
      child: Text(
        monthName,
        textAlign: TextAlign.center,
        style: FTextStyles.body4_12.copyWith(color: SPColors.gray600),
      ),
    );
  }

  Widget _buildSummaryStats(MonthlyProgress progress, Color color) {
    return Row(
      children: [
        _buildStatItem('일관성', '${(progress.consistency * 100).toStringAsFixed(0)}%', color),
        const SizedBox(width: 16),
        _buildStatItem('강도', '${progress.averageIntensity.toStringAsFixed(1)}%', color),
        const SizedBox(width: 16),
        _buildStatItem('활동 주', '${progress.weeksWithActivity}/${progress.totalWeeks}', color),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FTextStyles.body4_12.copyWith(color: SPColors.gray600)),
        const SizedBox(height: 2),
        Text(value, style: FTextStyles.body2_14.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  double _getMaxCountForCategory() {
    double maxCount = 0;

    for (final progressList in _categoryProgress.values) {
      for (final progress in progressList) {
        if (progress.totalCount > maxCount) {
          maxCount = progress.totalCount.toDouble();
        }
      }
    }

    return maxCount;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.track_changes, size: 48, color: SPColors.gray400),
            const SizedBox(height: 16),
            Text('진행도 데이터가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
            const SizedBox(height: 8),
            Text('더 많은 월별 데이터가 필요합니다', style: FTextStyles.body2_14.copyWith(color: SPColors.gray500)),
          ],
        ),
      ),
    );
  }
}

/// Model for monthly progress data
class MonthlyProgress {
  final String monthKey;
  final int totalCount;
  final int weeksWithActivity;
  final int totalWeeks;
  final double averageIntensity;
  final double consistency;

  const MonthlyProgress({
    required this.monthKey,
    required this.totalCount,
    required this.weeksWithActivity,
    required this.totalWeeks,
    required this.averageIntensity,
    required this.consistency,
  });
}
