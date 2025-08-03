import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/charts/category_historical_chart.dart';
import 'package:seol_haru_check/widgets/report/sections/category_goal_section.dart';
import 'package:seol_haru_check/widgets/report/sections/category_recommendations_section.dart';
import 'package:seol_haru_check/widgets/report/sections/subcategory_breakdown_section.dart';

/// Modal widget for detailed category drill-down functionality
class CategoryDrillDownModal extends StatefulWidget {
  final CategoryVisualizationData categoryData;
  final List<WeeklyReport> historicalReports;
  final Function(String categoryName, int goalValue)? onGoalSet;
  final VoidCallback? onClose;

  const CategoryDrillDownModal({
    super.key,
    required this.categoryData,
    required this.historicalReports,
    this.onGoalSet,
    this.onClose,
  });

  @override
  State<CategoryDrillDownModal> createState() => _CategoryDrillDownModalState();
}

class _CategoryDrillDownModalState extends State<CategoryDrillDownModal> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: _buildModalContent(context)),
        );
      },
    );
  }

  Widget _buildModalContent(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(), _buildHistoryTab(), _buildRecommendationsTab(), _buildGoalsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.categoryData.color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: SPColors.gray300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Category header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.categoryData.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(child: Text(widget.categoryData.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryData.categoryName,
                      style: FTextStyles.title2_20.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.categoryData.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.categoryData.type.displayName} • ${widget.categoryData.count}회 (${widget.categoryData.formattedPercentage})',
                      style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: _handleClose, icon: const Icon(Icons.close), color: SPColors.gray600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SPColors.gray200, width: 1))),
      child: TabBar(
        controller: _tabController,
        labelColor: widget.categoryData.color,
        unselectedLabelColor: SPColors.gray600,
        indicatorColor: widget.categoryData.color,
        labelStyle: FTextStyles.body2_14.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: FTextStyles.body2_14,
        tabs: const [Tab(text: '개요'), Tab(text: '기록'), Tab(text: '추천'), Tab(text: '목표')],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          if (widget.categoryData.hasSubcategories) ...[
            SubcategoryBreakdownSection(categoryData: widget.categoryData),
            const SizedBox(height: 24),
          ],
          _buildActivityPattern(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CategoryHistoricalChart(
        categoryName: widget.categoryData.categoryName,
        categoryType: widget.categoryData.type,
        historicalReports: widget.historicalReports,
        color: widget.categoryData.color,
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CategoryRecommendationsSection(
        categoryData: widget.categoryData,
        historicalReports: widget.historicalReports,
      ),
    );
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CategoryGoalSection(
        categoryData: widget.categoryData,
        historicalReports: widget.historicalReports,
        onGoalSet: widget.onGoalSet,
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: '이번 주',
            value: '${widget.categoryData.count}회',
            icon: Icons.today,
            color: widget.categoryData.color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: '비율',
            value: widget.categoryData.formattedPercentage,
            icon: Icons.pie_chart,
            color: SPColors.podBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: '평균',
            value: _calculateWeeklyAverage(),
            icon: Icons.trending_up,
            color: SPColors.podGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
        ],
      ),
    );
  }

  Widget _buildActivityPattern() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: widget.categoryData.color, size: 20),
              const SizedBox(width: 8),
              Text(
                '활동 패턴',
                style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.categoryData.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_generateActivityInsight(), style: FTextStyles.body2_14.copyWith(color: SPColors.gray700, height: 1.5)),
        ],
      ),
    );
  }

  String _calculateWeeklyAverage() {
    if (widget.historicalReports.isEmpty) return '0.0회';

    final categoryName = widget.categoryData.categoryName;
    final categoryType = widget.categoryData.type;

    int totalCount = 0;
    int validWeeks = 0;

    for (final report in widget.historicalReports) {
      int weekCount = 0;

      if (categoryType == CategoryType.exercise) {
        weekCount = report.stats.exerciseCategories[categoryName] ?? 0;
      } else {
        weekCount = report.stats.dietCategories[categoryName] ?? 0;
      }

      totalCount += weekCount;
      if (weekCount > 0) validWeeks++;
    }

    final average = validWeeks > 0 ? totalCount / widget.historicalReports.length : 0.0;
    return '${average.toStringAsFixed(1)}회';
  }

  String _generateActivityInsight() {
    final categoryName = widget.categoryData.categoryName;
    final currentCount = widget.categoryData.count;

    if (widget.historicalReports.isEmpty) {
      return '$categoryName 활동을 시작하셨네요! 꾸준히 기록해보세요.';
    }

    // Calculate trend
    final recentReports = widget.historicalReports.take(4).toList();
    final categoryType = widget.categoryData.type;

    final recentCounts =
        recentReports.map((report) {
          if (categoryType == CategoryType.exercise) {
            return report.stats.exerciseCategories[categoryName] ?? 0;
          } else {
            return report.stats.dietCategories[categoryName] ?? 0;
          }
        }).toList();

    if (recentCounts.length >= 2) {
      final previousCount = recentCounts[1];
      if (currentCount > previousCount) {
        return '$categoryName 활동이 증가하고 있습니다! 좋은 흐름을 유지해보세요.';
      } else if (currentCount < previousCount) {
        return '$categoryName 활동이 줄어들었네요. 다시 시작해보는 것은 어떨까요?';
      } else {
        return '$categoryName 활동을 꾸준히 유지하고 계시네요!';
      }
    }

    return '$categoryName 활동을 계속 기록해보세요. 패턴을 분석해드릴게요!';
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.of(context).pop();
      }
    });
  }
}
