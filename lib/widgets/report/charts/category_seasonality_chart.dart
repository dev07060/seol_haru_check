import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying category seasonality patterns
class CategorySeasonalityChart extends StatefulWidget {
  final List<WeeklyReport> historicalReports;
  final CategoryType categoryType;
  final double height;

  const CategorySeasonalityChart({
    super.key,
    required this.historicalReports,
    required this.categoryType,
    this.height = 300,
  });

  @override
  State<CategorySeasonalityChart> createState() => _CategorySeasonalityChartState();
}

class _CategorySeasonalityChartState extends State<CategorySeasonalityChart> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<int, Map<String, double>> _monthlyData = {}; // month -> category -> intensity
  List<String> _topCategories = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _calculateSeasonalityData();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategorySeasonalityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historicalReports != widget.historicalReports || oldWidget.categoryType != widget.categoryType) {
      _calculateSeasonalityData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateSeasonalityData() {
    if (widget.historicalReports.isEmpty) return;

    // Group reports by month and calculate category intensities
    final monthlyReports = <int, List<WeeklyReport>>{};
    final categoryTotals = <String, int>{};

    for (final report in widget.historicalReports) {
      final month = report.weekStartDate.month;
      monthlyReports[month] = (monthlyReports[month] ?? [])..add(report);

      // Collect category totals for finding top categories
      final categories =
          widget.categoryType == CategoryType.exercise ? report.stats.exerciseCategories : report.stats.dietCategories;

      for (final entry in categories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    // Get top 3 categories by total count
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    _topCategories = sortedCategories.take(3).map((e) => e.key).toList();

    // Calculate monthly intensities for each category
    _monthlyData = {};

    for (final monthEntry in monthlyReports.entries) {
      final month = monthEntry.key;
      final reports = monthEntry.value;

      final categoryIntensities = <String, double>{};

      for (final categoryName in _topCategories) {
        double totalIntensity = 0;
        int totalWeeks = 0;

        for (final report in reports) {
          final categories =
              widget.categoryType == CategoryType.exercise
                  ? report.stats.exerciseCategories
                  : report.stats.dietCategories;

          final categoryCount = categories[categoryName] ?? 0;
          final totalCount = categories.values.fold<int>(0, (sum, count) => sum + count);

          if (totalCount > 0) {
            totalIntensity += (categoryCount / totalCount) * 100;
            totalWeeks++;
          }
        }

        categoryIntensities[categoryName] = totalWeeks > 0 ? totalIntensity / totalWeeks : 0;
      }

      _monthlyData[month] = categoryIntensities;
    }
  }

  List<BarChartGroupData> _getBarChartData() {
    final groups = <BarChartGroupData>[];
    final colors = [SPColors.reportGreen, SPColors.reportBlue, SPColors.reportOrange];

    final sortedMonths = _monthlyData.keys.toList()..sort();

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final categoryData = _monthlyData[month] ?? {};

      final barRods = <BarChartRodData>[];

      for (int j = 0; j < _topCategories.length; j++) {
        final categoryName = _topCategories[j];
        final intensity = categoryData[categoryName] ?? 0;
        final color = colors[j % colors.length];

        barRods.add(
          BarChartRodData(
            toY: intensity,
            color: color,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      }

      groups.add(BarChartGroupData(x: i, barRods: barRods, barsSpace: 4));
    }

    return groups;
  }

  double _getMaxY() {
    double maxY = 0;

    for (final monthData in _monthlyData.values) {
      for (final intensity in monthData.values) {
        if (intensity > maxY) {
          maxY = intensity;
        }
      }
    }

    return maxY > 0 ? maxY * 1.2 : 100; // Add 20% padding or max 100%
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    final sortedMonths = _monthlyData.keys.toList()..sort();
    final index = value.toInt();

    if (index < 0 || index >= sortedMonths.length) {
      return const SizedBox.shrink();
    }

    final month = sortedMonths[index];
    final monthNames = ['', '1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(monthNames[month], style: FTextStyles.body4_12.copyWith(color: SPColors.gray600)),
    );
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}%', style: FTextStyles.body4_12.copyWith(color: SPColors.gray600)),
    );
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
            // Chart title
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${widget.categoryType.displayName} 월별 패턴',
                style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ),

            // Chart
            SizedBox(
              height: widget.height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => SPColors.backgroundColor(context),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final sortedMonths = _monthlyData.keys.toList()..sort();
                        final month = sortedMonths[group.x];
                        final categoryName = _topCategories[rodIndex];

                        final monthNames = [
                          '',
                          '1월',
                          '2월',
                          '3월',
                          '4월',
                          '5월',
                          '6월',
                          '7월',
                          '8월',
                          '9월',
                          '10월',
                          '11월',
                          '12월',
                        ];

                        return BarTooltipItem(
                          '${monthNames[month]}\n$categoryName\n${rod.toY.toStringAsFixed(1)}%',
                          FTextStyles.body2_14.copyWith(
                            color: SPColors.textColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: _buildBottomTitles),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 40,
                        getTitlesWidget: _buildLeftTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: SPColors.gray200)),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: SPColors.gray200, strokeWidth: 1);
                    },
                  ),
                  barGroups: _getBarChartData(),
                ),
                duration: Duration(milliseconds: (1800 * _animation.value).toInt()),
                curve: Curves.easeInOut,
              ),
            ),

            // Legend
            const SizedBox(height: 16),
            _buildLegend(),

            // Seasonal insights
            const SizedBox(height: 16),
            _buildSeasonalInsights(),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    final colors = [SPColors.reportGreen, SPColors.reportBlue, SPColors.reportOrange];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          _topCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryName = entry.value;
            final color = colors[index % colors.length];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 6),
                Text(
                  categoryName,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildSeasonalInsights() {
    if (_topCategories.isEmpty || _monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find peak month for top category
    final topCategory = _topCategories.first;
    double maxIntensity = 0;
    int peakMonth = 1;

    for (final entry in _monthlyData.entries) {
      final intensity = entry.value[topCategory] ?? 0;
      if (intensity > maxIntensity) {
        maxIntensity = intensity;
        peakMonth = entry.key;
      }
    }

    final monthNames = ['', '1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny, size: 16, color: SPColors.reportOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$topCategory은(는) ${monthNames[peakMonth]}에 가장 활발합니다',
              style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 48, color: SPColors.gray400),
            const SizedBox(height: 16),
            Text('계절별 데이터가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
            const SizedBox(height: 8),
            Text('더 많은 월별 데이터가 필요합니다', style: FTextStyles.body2_14.copyWith(color: SPColors.gray500)),
          ],
        ),
      ),
    );
  }
}
