import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/charts/base_chart_widget.dart';
import 'package:seol_haru_check/widgets/report/charts/chart_error_handler.dart';

/// Data model for heatmap cell
class HeatmapCellData {
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String categoryName;
  final String emoji;
  final int activityCount;
  final double intensity; // 0.0 to 1.0
  final Color baseColor;
  final List<String> activities; // List of specific activities
  final DateTime? lastActivity;

  const HeatmapCellData({
    required this.dayOfWeek,
    required this.categoryName,
    required this.emoji,
    required this.activityCount,
    required this.intensity,
    required this.baseColor,
    this.activities = const [],
    this.lastActivity,
  });

  /// Get intensity-based color
  Color get intensityColor {
    if (activityCount == 0) {
      return SPColors.gray100;
    }
    return Color.lerp(baseColor.withValues(alpha: 0.2), baseColor, intensity) ?? baseColor;
  }

  /// Get display text for tooltip
  String get tooltipText {
    if (activityCount == 0) {
      return '$emoji $categoryName\n활동 없음';
    }
    return '$emoji $categoryName\n$activityCount회 활동\n강도: ${(intensity * 100).toInt()}%';
  }

  /// Check if cell has activity
  bool get hasActivity => activityCount > 0;

  /// Get activity description
  String get activityDescription {
    if (activities.isEmpty) return '활동 없음';
    if (activities.length == 1) return activities.first;
    return '${activities.first} 외 ${activities.length - 1}개';
  }
}

/// Data model for heatmap chart
class CategoryHeatmapData {
  final List<HeatmapCellData> cells;
  final List<String> categories;
  final List<String> dayLabels;
  final int maxActivityCount;
  final double maxIntensity;
  final CategoryType type;
  final DateTimeRange dateRange;

  const CategoryHeatmapData({
    required this.cells,
    required this.categories,
    required this.dayLabels,
    required this.maxActivityCount,
    required this.maxIntensity,
    required this.type,
    required this.dateRange,
  });

  /// Create empty heatmap data
  factory CategoryHeatmapData.empty(CategoryType type) {
    return CategoryHeatmapData(
      cells: [],
      categories: [],
      dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
      maxActivityCount: 0,
      maxIntensity: 0.0,
      type: type,
      dateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
    );
  }

  /// Get cell data for specific day and category
  HeatmapCellData? getCellData(int dayOfWeek, String categoryName) {
    try {
      return cells.firstWhere((cell) => cell.dayOfWeek == dayOfWeek && cell.categoryName == categoryName);
    } catch (e) {
      return null;
    }
  }

  /// Get total activities for a day
  int getTotalActivitiesForDay(int dayOfWeek) {
    return cells.where((cell) => cell.dayOfWeek == dayOfWeek).fold(0, (sum, cell) => sum + cell.activityCount);
  }

  /// Get total activities for a category
  int getTotalActivitiesForCategory(String categoryName) {
    return cells.where((cell) => cell.categoryName == categoryName).fold(0, (sum, cell) => sum + cell.activityCount);
  }

  /// Check if has any activity data
  bool get hasActivityData => cells.any((cell) => cell.hasActivity);

  /// Get most active day
  int get mostActiveDay {
    if (cells.isEmpty) return 0;

    final dayTotals = <int, int>{};
    for (int day = 0; day < 7; day++) {
      dayTotals[day] = getTotalActivitiesForDay(day);
    }

    return dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get most active category
  String get mostActiveCategory {
    if (categories.isEmpty) return '';

    final categoryTotals = <String, int>{};
    for (final category in categories) {
      categoryTotals[category] = getTotalActivitiesForCategory(category);
    }

    return categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Day-of-week vs category heatmap visualization with interactive features
class CategoryHeatmapChart extends BaseChartWidget {
  final CategoryHeatmapData heatmapData;
  final bool enableInteraction;
  final Function(HeatmapCellData)? onCellTap;
  final Function(HeatmapCellData)? onCellLongPress;
  final bool showIntensityLegend;
  final bool showCategoryLabels;
  final bool showDayLabels;
  final bool highlightOptimalTiming;
  final double cellSize;
  final double cellSpacing;

  const CategoryHeatmapChart({
    super.key,
    required this.heatmapData,
    this.enableInteraction = true,
    this.onCellTap,
    this.onCellLongPress,
    this.showIntensityLegend = true,
    this.showCategoryLabels = true,
    this.showDayLabels = true,
    this.highlightOptimalTiming = true,
    this.cellSize = 32.0,
    this.cellSpacing = 2.0,
    super.theme,
    super.animationConfig,
    super.height,
    super.padding,
    super.title,
    super.showTitle,
  });

  @override
  State<CategoryHeatmapChart> createState() => _CategoryHeatmapChartState();
}

class _CategoryHeatmapChartState extends BaseChartState<CategoryHeatmapChart> {
  HeatmapCellData? _selectedCell;
  HeatmapCellData? _hoveredCell;

  @override
  Widget buildChart(BuildContext context) {
    if (!widget.heatmapData.hasActivityData) {
      return ChartErrorHandler.createEmptyPlaceholder(
        message: '${widget.heatmapData.type.displayName} 활동 패턴 데이터가 없습니다',
        icon: Icons.grid_view,
      );
    }

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(animation: animationController, builder: (context, child) => _buildHeatmapGrid()),
        ),
        if (widget.showIntensityLegend) ...[const SizedBox(height: 16), _buildIntensityLegend()],
        if (_selectedCell != null) ...[const SizedBox(height: 12), _buildCellDetails(_selectedCell!)],
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    final categories = widget.heatmapData.categories;
    final dayLabels = widget.heatmapData.dayLabels;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          // Day labels header
          if (widget.showDayLabels) _buildDayLabelsHeader(dayLabels),

          // Heatmap grid
          Expanded(
            child: Row(
              children: [
                // Category labels column
                if (widget.showCategoryLabels) _buildCategoryLabelsColumn(categories),

                // Heatmap cells grid
                Expanded(child: _buildCellsGrid(categories, dayLabels)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabelsHeader(List<String> dayLabels) {
    return Padding(
      padding: EdgeInsets.only(left: widget.showCategoryLabels ? 80 : 0, bottom: 8),
      child: Row(
        children:
            dayLabels.asMap().entries.map((entry) {
              final dayIndex = entry.key;
              final dayLabel = entry.value;
              final isOptimalDay = widget.highlightOptimalTiming && dayIndex == widget.heatmapData.mostActiveDay;

              return Expanded(
                child: Container(
                  height: 24,
                  alignment: Alignment.center,
                  decoration:
                      isOptimalDay
                          ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          )
                          : null,
                  child: Text(
                    dayLabel,
                    style: theme.labelStyle.copyWith(
                      fontWeight: isOptimalDay ? FontWeight.w600 : FontWeight.normal,
                      color: isOptimalDay ? theme.primaryColor : theme.textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCategoryLabelsColumn(List<String> categories) {
    return SizedBox(
      width: 80,
      child: Column(
        children:
            categories.map((category) {
              final isOptimalCategory =
                  widget.highlightOptimalTiming && category == widget.heatmapData.mostActiveCategory;
              final emoji = chartService.getCategoryEmoji(category);

              return Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                  decoration:
                      isOptimalCategory
                          ? BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          )
                          : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          category,
                          style: theme.labelStyle.copyWith(
                            fontSize: 11,
                            fontWeight: isOptimalCategory ? FontWeight.w600 : FontWeight.normal,
                            color: isOptimalCategory ? theme.primaryColor : theme.textColor,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(emoji, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCellsGrid(List<String> categories, List<String> dayLabels) {
    return Column(
      children:
          categories.map((category) {
            return Expanded(
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final cellData = widget.heatmapData.getCellData(dayIndex, category);
                  return Expanded(child: _buildHeatmapCell(cellData, dayIndex, category));
                }),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildHeatmapCell(HeatmapCellData? cellData, int dayIndex, String category) {
    final isSelected = _selectedCell == cellData;
    final isHovered = _hoveredCell == cellData;
    final animationValue = animationController.value;

    // Create default cell data if null
    cellData ??= HeatmapCellData(
      dayOfWeek: dayIndex,
      categoryName: category,
      emoji: chartService.getCategoryEmoji(category),
      activityCount: 0,
      intensity: 0.0,
      baseColor: chartService.getCategoryColor(category, theme),
    );

    return Padding(
      padding: EdgeInsets.all(widget.cellSpacing / 2),
      child: GestureDetector(
        onTap: widget.enableInteraction ? () => _handleCellTap(cellData!) : null,
        onLongPress: widget.enableInteraction ? () => _handleCellLongPress(cellData!) : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredCell = cellData),
          onExit: (_) => setState(() => _hoveredCell = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.cellSize,
            height: widget.cellSize,
            decoration: BoxDecoration(
              color: cellData.intensityColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isSelected || isHovered
                        ? theme.primaryColor
                        : cellData.hasActivity
                        ? cellData.baseColor.withValues(alpha: 0.6)
                        : theme.borderColor,
                width:
                    isSelected
                        ? 3
                        : isHovered
                        ? 2
                        : 1,
              ),
              boxShadow:
                  isSelected || isHovered
                      ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Stack(
              children: [
                // Activity count indicator
                if (cellData.hasActivity)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cellData.activityCount.toString(),
                        style: FTextStyles.body3_13.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cellData.baseColor,
                        ),
                      ),
                    ),
                  ),

                // Optimal timing highlight
                if (widget.highlightOptimalTiming &&
                    dayIndex == widget.heatmapData.mostActiveDay &&
                    category == widget.heatmapData.mostActiveCategory &&
                    cellData.hasActivity)
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SPColors.success100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),

                // Animation overlay
                if (animationValue < 1.0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.backgroundColor.withValues(alpha: 1.0 - animationValue),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('활동 강도', style: theme.labelStyle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('낮음', style: theme.labelStyle.copyWith(fontSize: 11)),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final intensity = (index + 1) / 5;
                    return Expanded(
                      child: Container(
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Color.lerp(SPColors.gray200, theme.primaryColor, intensity),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Text('높음', style: theme.labelStyle.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0회', style: theme.labelStyle.copyWith(fontSize: 10)),
              Text('${widget.heatmapData.maxActivityCount}회+', style: theme.labelStyle.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCellDetails(HeatmapCellData cellData) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cellData.baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cellData.baseColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(cellData.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.heatmapData.dayLabels[cellData.dayOfWeek]} - ${cellData.categoryName}',
                      style: theme.titleStyle.copyWith(fontSize: 14),
                    ),
                    Text(cellData.tooltipText, style: theme.labelStyle.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (cellData.activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('활동 내역: ${cellData.activityDescription}', style: theme.labelStyle.copyWith(fontSize: 11)),
          ],
        ],
      ),
    );
  }

  void _handleCellTap(HeatmapCellData cellData) {
    setState(() {
      _selectedCell = _selectedCell == cellData ? null : cellData;
    });

    if (widget.onCellTap != null) {
      widget.onCellTap!(cellData);
    }
  }

  void _handleCellLongPress(HeatmapCellData cellData) {
    if (widget.onCellLongPress != null) {
      widget.onCellLongPress!(cellData);
    }
  }

  @override
  Widget buildFallback(BuildContext context) {
    if (!widget.heatmapData.hasActivityData) {
      return ChartErrorHandler.createEmptyPlaceholder(
        message: '${widget.heatmapData.type.displayName} 활동 패턴 데이터가 없습니다',
        icon: Icons.grid_view,
      );
    }

    // Create text-based fallback
    final dataMap = <String, String>{};
    for (final category in widget.heatmapData.categories) {
      final totalActivities = widget.heatmapData.getTotalActivitiesForCategory(category);
      final emoji = chartService.getCategoryEmoji(category);
      dataMap['$emoji $category'] = '$totalActivities회';
    }

    return ChartErrorHandler.createTextFallback(dataMap, title: '${widget.heatmapData.type.displayName} 활동 패턴');
  }

  @override
  bool validateData() {
    return widget.heatmapData.categories.isNotEmpty;
  }

  @override
  Map<String, dynamic> getChartData() {
    return {
      'totalCategories': widget.heatmapData.categories.length,
      'totalCells': widget.heatmapData.cells.length,
      'activeCells': widget.heatmapData.cells.where((cell) => cell.hasActivity).length,
      'maxActivityCount': widget.heatmapData.maxActivityCount,
      'maxIntensity': widget.heatmapData.maxIntensity,
      'type': widget.heatmapData.type.name,
      'hasActivityData': widget.heatmapData.hasActivityData,
      'mostActiveDay': widget.heatmapData.mostActiveDay,
      'mostActiveCategory': widget.heatmapData.mostActiveCategory,
    };
  }
}
