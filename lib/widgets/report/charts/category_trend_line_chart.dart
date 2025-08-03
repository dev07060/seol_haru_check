import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying category trends over time as a line chart
class CategoryTrendLineChart extends StatefulWidget {
  final List<WeeklyReport> historicalReports;
  final CategoryType categoryType;
  final List<String> selectedCategories;
  final Function(String categoryName)? onCategoryToggle;
  final double height;
  final bool showLegend;

  const CategoryTrendLineChart({
    super.key,
    required this.historicalReports,
    required this.categoryType,
    this.selectedCategories = const [],
    this.onCategoryToggle,
    this.height = 300,
    this.showLegend = true,
  });

  @override
  State<CategoryTrendLineChart> createState() => _CategoryTrendLineChartState();
}

class _CategoryTrendLineChartState extends State<CategoryTrendLineChart> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, Color> _categoryColors = {};
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _processHistoricalData();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CategoryTrendLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historicalReports != widget.historicalReports || oldWidget.categoryType != widget.categoryType) {
      _processHistoricalData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processHistoricalData() {
    final allCategories = <String>{};

    // Collect all categories from historical reports
    for (final report in widget.historicalReports) {
      final categories =
          widget.categoryType == CategoryType.exercise ? report.stats.exerciseCategories : report.stats.dietCategories;
      allCategories.addAll(categories.keys);
    }

    _availableCategories = allCategories.toList()..sort();

    // Assign colors to categories
    _categoryColors = {};
    final colors = [
      SPColors.reportGreen,
      SPColors.reportBlue,
      SPColors.reportOrange,
      SPColors.reportPurple,
      SPColors.success100,
      SPColors.reportAmber,
      SPColors.reportTeal,
      SPColors.danger100,
    ];

    for (int i = 0; i < _availableCategories.length; i++) {
      _categoryColors[_availableCategories[i]] = colors[i % colors.length];
    }
  }

  List<FlSpot> _getDataPointsForCategory(String categoryName) {
    final spots = <FlSpot>[];

    // Sort reports by date (oldest first)
    final sortedReports = List<WeeklyReport>.from(widget.historicalReports)
      ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

    for (int i = 0; i < sortedReports.length; i++) {
      final report = sortedReports[i];
      final categories =
          widget.categoryType == CategoryType.exercise ? report.stats.exerciseCategories : report.stats.dietCategories;

      final count = categories[categoryName] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return spots;
  }

  double _getMaxY() {
    double maxY = 0;

    for (final categoryName in _availableCategories) {
      final spots = _getDataPointsForCategory(categoryName);
      for (final spot in spots) {
        if (spot.y > maxY) {
          maxY = spot.y;
        }
      }
    }

    return maxY > 0 ? maxY * 1.1 : 10; // Add 10% padding or minimum 10
  }

  List<LineChartBarData> _getLineChartData() {
    final lines = <LineChartBarData>[];

    final categoriesToShow =
        widget.selectedCategories.isNotEmpty
            ? widget.selectedCategories
            : _availableCategories.take(5).toList(); // Show top 5 by default

    for (final categoryName in categoriesToShow) {
      if (!_availableCategories.contains(categoryName)) continue;

      final spots = _getDataPointsForCategory(categoryName);
      if (spots.isEmpty) continue;

      final color = _categoryColors[categoryName] ?? SPColors.gray400;

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
      child: Text(value.toInt().toString(), style: FTextStyles.body4_12.copyWith(color: SPColors.gray600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicalReports.isEmpty) {
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
                '${widget.categoryType.displayName} 카테고리 트렌드',
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
                    horizontalInterval: 1,
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
                        interval: 1,
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
                          final categoryName =
                              widget.selectedCategories.isNotEmpty
                                  ? widget.selectedCategories[spot.barIndex]
                                  : _availableCategories[spot.barIndex];

                          return LineTooltipItem(
                            '$categoryName\n${spot.y.toInt()}회',
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
                duration: Duration(milliseconds: (1500 * _animation.value).toInt()),
                curve: Curves.easeInOut,
              ),
            ),

            // Legend
            if (widget.showLegend) ...[const SizedBox(height: 16), _buildLegend()],
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    final categoriesToShow =
        widget.selectedCategories.isNotEmpty ? widget.selectedCategories : _availableCategories.take(5).toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          categoriesToShow.map((categoryName) {
            final color = _categoryColors[categoryName] ?? SPColors.gray400;
            final isSelected = widget.selectedCategories.isEmpty || widget.selectedCategories.contains(categoryName);

            return GestureDetector(
              onTap: () => widget.onCategoryToggle?.call(categoryName),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      categoryName,
                      style: FTextStyles.body2_14.copyWith(
                        color: SPColors.textColor(context),
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
            Icon(Icons.show_chart, size: 48, color: SPColors.gray400),
            const SizedBox(height: 16),
            Text('트렌드 데이터가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
            const SizedBox(height: 8),
            Text('더 많은 주간 데이터가 필요합니다', style: FTextStyles.body2_14.copyWith(color: SPColors.gray500)),
          ],
        ),
      ),
    );
  }
}
