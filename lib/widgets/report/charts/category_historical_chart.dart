import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Chart widget for displaying historical performance of a specific category
class CategoryHistoricalChart extends StatefulWidget {
  final String categoryName;
  final CategoryType categoryType;
  final List<WeeklyReport> historicalReports;
  final Color color;
  final bool showTrendLine;
  final bool showDataPoints;

  const CategoryHistoricalChart({
    super.key,
    required this.categoryName,
    required this.categoryType,
    required this.historicalReports,
    required this.color,
    this.showTrendLine = true,
    this.showDataPoints = true,
  });

  @override
  State<CategoryHistoricalChart> createState() => _CategoryHistoricalChartState();
}

class _CategoryHistoricalChartState extends State<CategoryHistoricalChart> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;
  final List<FlSpot> _dataPoints = [];
  final List<String> _weekLabels = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic);

    _processHistoricalData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processHistoricalData() {
    if (widget.historicalReports.isEmpty) return;

    final sortedReports = List<WeeklyReport>.from(widget.historicalReports)
      ..sort((a, b) => a.weekStartDate.compareTo(b.weekStartDate));

    _dataPoints.clear();
    _weekLabels.clear();

    for (int i = 0; i < sortedReports.length; i++) {
      final report = sortedReports[i];
      int count = 0;

      if (widget.categoryType == CategoryType.exercise) {
        count = report.stats.exerciseCategories[widget.categoryName] ?? 0;
      } else {
        count = report.stats.dietCategories[widget.categoryName] ?? 0;
      }

      _dataPoints.add(FlSpot(i.toDouble(), count.toDouble()));
      _weekLabels.add(DateFormat('M/d').format(report.weekStartDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartHeader(),
        const SizedBox(height: 20),
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return _buildChart();
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsSummary(),
      ],
    );
  }

  Widget _buildChartHeader() {
    return Row(
      children: [
        Icon(Icons.timeline, color: widget.color, size: 20),
        const SizedBox(width: 8),
        Text(
          '${widget.categoryName} 기록 추이',
          style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.color),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_dataPoints.length}주',
            style: FTextStyles.body3_13.copyWith(color: widget.color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
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
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _weekLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_weekLabels[index], style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: FTextStyles.body3_13.copyWith(color: SPColors.gray600));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: SPColors.gray200)),
          minX: 0,
          maxX: (_dataPoints.length - 1).toDouble(),
          minY: 0,
          maxY: _getMaxY(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              setState(() {
                if (touchResponse == null || touchResponse.lineBarSpots == null) {
                  _touchedIndex = -1;
                } else {
                  _touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
                }
              });
            },
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(color: widget.color.withValues(alpha: 0.5), strokeWidth: 2, dashArray: [5, 5]),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: widget.color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => widget.color.withValues(alpha: 0.9),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.spotIndex;
                  final weekLabel = index < _weekLabels.length ? _weekLabels[index] : '';
                  return LineTooltipItem(
                    '$weekLabel\n${barSpot.y.toInt()}회',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots:
                  _dataPoints.map((spot) {
                    return FlSpot(spot.x, spot.y * _animation.value);
                  }).toList(),
              isCurved: true,
              color: widget.color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: widget.showDataPoints,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: index == _touchedIndex ? 6 : 4,
                    color: widget.color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: true, color: widget.color.withValues(alpha: 0.1)),
            ),
            if (widget.showTrendLine) _buildTrendLine(),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildTrendLine() {
    if (_dataPoints.length < 2) {
      return LineChartBarData(spots: []);
    }

    // Calculate linear regression for trend line
    final n = _dataPoints.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (final point in _dataPoints) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumXX += point.x * point.x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final trendPoints = [
      FlSpot(0, intercept * _animation.value),
      FlSpot((_dataPoints.length - 1).toDouble(), (slope * (_dataPoints.length - 1) + intercept) * _animation.value),
    ];

    return LineChartBarData(
      spots: trendPoints,
      isCurved: false,
      color: widget.color.withValues(alpha: 0.5),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: [5, 5],
    );
  }

  Widget _buildStatsSummary() {
    final totalCount = _dataPoints.fold<double>(0, (sum, point) => sum + point.y);
    final averageCount = totalCount / _dataPoints.length;
    final maxCount = _dataPoints.fold<double>(0, (max, point) => point.y > max ? point.y : max);
    final trend = _calculateTrend();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(label: '총 횟수', value: '${totalCount.toInt()}회', icon: Icons.functions)),
          Expanded(
            child: _buildStatItem(label: '주평균', value: '${averageCount.toStringAsFixed(1)}회', icon: Icons.trending_up),
          ),
          Expanded(child: _buildStatItem(label: '최고기록', value: '${maxCount.toInt()}회', icon: Icons.star)),
          Expanded(
            child: _buildStatItem(
              label: '추세',
              value: trend,
              icon: _getTrendIcon(trend),
              valueColor: _getTrendColor(trend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, required IconData icon, Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: valueColor ?? widget.color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: FTextStyles.body2_14.copyWith(fontWeight: FontWeight.bold, color: valueColor ?? SPColors.gray800),
        ),
        const SizedBox(height: 2),
        Text(label, style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text('기록이 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '${widget.categoryName} 활동을 기록하면\n추이를 확인할 수 있습니다',
            textAlign: TextAlign.center,
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray500),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_dataPoints.isEmpty) return 10;
    final maxValue = _dataPoints.fold<double>(0, (max, point) => point.y > max ? point.y : max);
    return (maxValue + 1).ceilToDouble();
  }

  String _calculateTrend() {
    if (_dataPoints.length < 2) return '안정';

    final firstHalf = _dataPoints.take(_dataPoints.length ~/ 2);
    final secondHalf = _dataPoints.skip(_dataPoints.length ~/ 2);

    final firstAvg = firstHalf.fold<double>(0, (sum, point) => sum + point.y) / firstHalf.length;
    final secondAvg = secondHalf.fold<double>(0, (sum, point) => sum + point.y) / secondHalf.length;

    final difference = secondAvg - firstAvg;

    if (difference > 0.5) return '증가';
    if (difference < -0.5) return '감소';
    return '안정';
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case '증가':
        return Icons.trending_up;
      case '감소':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case '증가':
        return SPColors.success100;
      case '감소':
        return SPColors.danger100;
      default:
        return SPColors.gray600;
    }
  }
}
