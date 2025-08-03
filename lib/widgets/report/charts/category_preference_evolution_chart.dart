import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying category preference evolution over time
class CategoryPreferenceEvolutionChart extends StatefulWidget {
  final List<WeeklyReport> historicalReports;
  final CategoryType categoryType;
  final double height;
  final int maxCategoriesToShow;

  const CategoryPreferenceEvolutionChart({
    super.key,
    required this.historicalReports,
    required this.categoryType,
    this.height = 250,
    this.maxCategoriesToShow = 3,
  });

  @override
  State<CategoryPreferenceEvolutionChart> createState() => _CategoryPreferenceEvolutionChartState();
}

class _CategoryPreferenceEvolutionChartState extends State<CategoryPreferenceEvolutionChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, List<double>> _categoryPreferences = {};
  List<String> _topCategories = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _calculatePreferenceEvolution();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryPreferenceEvolutionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historicalReports != widget.historicalReports || oldWidget.categoryType != widget.categoryType) {
      _calculatePreferenceEvolution();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculatePreferenceEvolution() {
    if (widget.historicalReports.isEmpty) return;

    // Sort reports by date (oldest first)
    final sortedReports = List<WeeklyReport>.from(widget.historicalReports)
      ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

    // Collect all categories and their total counts
    final categoryTotals = <String, int>{};

    for (final report in sortedReports) {
      final categories =
          widget.categoryType == CategoryType.exercise ? report.stats.exerciseCategories : report.stats.dietCategories;

      for (final entry in categories.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0) + entry.value;
      }
    }

    // Get top categories by total count
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    _topCategories = sortedCategories.take(widget.maxCategoriesToShow).map((e) => e.key).toList();

    // Calculate preference percentages for each week
    _categoryPreferences = {};

    for (final categoryName in _topCategories) {
      final preferences = <double>[];

      for (final report in sortedReports) {
        final categories =
            widget.categoryType == CategoryType.exercise
                ? report.stats.exerciseCategories
                : report.stats.dietCategories;

        final totalCount = categories.values.fold<int>(0, (sum, count) => sum + count);
        final categoryCount = categories[categoryName] ?? 0;

        final preference = totalCount > 0 ? (categoryCount / totalCount) * 100 : 0.0;
        preferences.add(preference);
      }

      _categoryPreferences[categoryName] = preferences;
    }
  }

  List<LineChartBarData> _getLineChartData() {
    final lines = <LineChartBarData>[];
    final colors = [
      SPColors.reportGreen,
      SPColors.reportBlue,
      SPColors.reportOrange,
      SPColors.reportPurple,
      SPColors.success100,
    ];

    for (int i = 0; i < _topCategories.length; i++) {
      final categoryName = _topCategories[i];
      final preferences = _categoryPreferences[categoryName] ?? [];

      if (preferences.isEmpty) continue;

      final spots =
          preferences.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value);
          }).toList();

      final color = colors[i % colors.length];

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: SPColors.backgroundColor(context),
              );
            },
          ),
          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
        ),
      );
    }

    return lines;
  }

  double _getMaxY() {
    double maxY = 0;

    for (final preferences in _categoryPreferences.values) {
      for (final preference in preferences) {
        if (preference > maxY) {
          maxY = preference;
        }
      }
    }

    return maxY > 0 ? maxY * 1.1 : 100; // Add 10% padding or max 100%
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= widget.historicalReports.length) {
      return const SizedBox.shrink();
    }

    final sortedReports = List<WeeklyReport>.from(widget.historicalReports)
      ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

    final report = sortedReports[index];
    final dateFormat = DateFormat('M/d');

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        dateFormat.format(report.weekStartDate),
        style: FTextStyles.body4_12.copyWith(color: SPColors.gray600),
      ),
    );
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}%', style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
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
                '${widget.categoryType.displayName} 선호도 변화',
                style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ),

            // Chart
            SizedBox(
              height: widget.height,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: SPColors.gray200, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: _buildBottomTitles,
                      ),
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
                  minX: 0,
                  maxX: (widget.historicalReports.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: _getLineChartData(),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => SPColors.backgroundColor(context),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final categoryName = _topCategories[spot.barIndex];

                          return LineTooltipItem(
                            '$categoryName\n${spot.y.toStringAsFixed(1)}%',
                            FTextStyles.body2_14.copyWith(
                              color: SPColors.textColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                duration: Duration(milliseconds: (2000 * _animation.value).toInt()),
                curve: Curves.easeInOut,
              ),
            ),

            // Legend
            const SizedBox(height: 16),
            _buildLegend(),

            // Insights
            const SizedBox(height: 16),
            _buildInsights(),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    final colors = [
      SPColors.reportGreen,
      SPColors.reportBlue,
      SPColors.reportOrange,
      SPColors.reportPurple,
      SPColors.success100,
    ];

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
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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

  Widget _buildInsights() {
    if (_topCategories.isEmpty) return const SizedBox.shrink();

    // Calculate trend for most preferred category
    final topCategory = _topCategories.first;
    final preferences = _categoryPreferences[topCategory] ?? [];

    if (preferences.length < 2) return const SizedBox.shrink();

    final firstPreference = preferences.first;
    final lastPreference = preferences.last;
    final change = lastPreference - firstPreference;

    String trendText;
    Color trendColor;
    IconData trendIcon;

    if (change > 5) {
      trendText = '${change.toStringAsFixed(1)}% 증가';
      trendColor = SPColors.success100;
      trendIcon = Icons.trending_up;
    } else if (change < -5) {
      trendText = '${change.abs().toStringAsFixed(1)}% 감소';
      trendColor = SPColors.danger100;
      trendIcon = Icons.trending_down;
    } else {
      trendText = '안정적 유지';
      trendColor = SPColors.gray600;
      trendIcon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Row(
        children: [
          Icon(trendIcon, size: 16, color: trendColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$topCategory 선호도가 $trendText',
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
            Icon(Icons.timeline, size: 48, color: SPColors.gray400),
            const SizedBox(height: 16),
            Text('선호도 데이터가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
            const SizedBox(height: 8),
            Text('더 많은 주간 데이터가 필요합니다', style: FTextStyles.body2_14.copyWith(color: SPColors.gray500)),
          ],
        ),
      ),
    );
  }
}
