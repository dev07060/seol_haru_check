import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/charts/base_chart_widget.dart';
import 'package:seol_haru_check/widgets/report/charts/chart_error_handler.dart';
import 'package:seol_haru_check/widgets/report/modals/category_drill_down_modal.dart';

/// Interactive pie chart widget for displaying category distribution with emojis and colors
class CategoryDistributionChart extends BaseChartWidget {
  final List<CategoryVisualizationData> categoryData;
  final CategoryType type;
  final bool showLegend;
  final bool enableInteraction;
  final Function(CategoryVisualizationData)? onCategoryTap;
  final double radius;
  final bool showPercentages;
  final bool showCenterText;
  final String? centerText;
  final List<WeeklyReport>? historicalReports;
  final bool enableDrillDown;

  const CategoryDistributionChart({
    super.key,
    required this.categoryData,
    required this.type,
    this.showLegend = true,
    this.enableInteraction = true,
    this.onCategoryTap,
    this.radius = 80.0,
    this.showPercentages = true,
    this.showCenterText = false,
    this.centerText,
    this.historicalReports,
    this.enableDrillDown = true,
    super.theme,
    super.animationConfig,
    super.height,
    super.padding,
    super.title,
    super.showTitle,
  });

  @override
  State<CategoryDistributionChart> createState() => _CategoryDistributionChartState();
}

class _CategoryDistributionChartState extends BaseChartState<CategoryDistributionChart> {
  int _touchedIndex = -1;
  late List<CategoryVisualizationData> _previousData;
  bool _isTransitioning = false;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _previousData = widget.categoryData;
  }

  @override
  void didUpdateWidget(CategoryDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryData != oldWidget.categoryData) {
      setState(() {
        _previousData = oldWidget.categoryData;
        _isTransitioning = true;
      });

      // Reset animation for smooth transition
      animationController.reset();
      animationController.forward();

      // Stop transition after animation completes
      Future.delayed(animationConfig.morphDuration, () {
        if (mounted) {
          setState(() {
            _isTransitioning = false;
          });
        }
      });
    }
  }

  @override
  Widget buildChart(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return ChartErrorHandler.createEmptyPlaceholder(
        message: '${widget.type.displayName} 데이터가 없습니다',
        icon: widget.type.icon,
      );
    }

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(flex: widget.showLegend ? 3 : 1, child: _buildPieChart()),
            if (widget.showLegend) ...[const SizedBox(height: 16), Expanded(flex: 2, child: _buildLegend())],
          ],
        );
      },
    );
  }

  Widget _buildPieChart() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              enabled: widget.enableInteraction,
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                if (!widget.enableInteraction) return;

                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });

                // Handle tap callback
                if (event is FlTapUpEvent && _touchedIndex >= 0 && _touchedIndex < widget.categoryData.length) {
                  final categoryData = widget.categoryData[_touchedIndex];

                  // Trigger particle effect on tap
                  if (animationConfig.enableParticles) {
                    setState(() {
                      _showParticles = true;
                    });

                    // Auto-hide particles after delay
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted) {
                        setState(() {
                          _showParticles = false;
                        });
                      }
                    });
                  }

                  if (widget.onCategoryTap != null) {
                    widget.onCategoryTap!(categoryData);
                  } else if (widget.enableDrillDown && widget.historicalReports != null) {
                    _showCategoryDrillDown(categoryData);
                  }
                }
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: widget.showCenterText ? 40 : 0,
            sections: _buildPieSections(),
          ),
        ),
        if (widget.showCenterText) _buildCenterText(),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return widget.categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = index == _touchedIndex;
      final animationValue =
          animationConfig.enableStagger ? _getStaggeredAnimationValue(index) : animationController.value;

      // Enhanced animation with bounce effect
      final bounceValue =
          animationConfig.enableBounce
              ? 1.0 + (animationConfig.bounceIntensity * _getBounceAnimationValue(index))
              : 1.0;

      return PieChartSectionData(
        color: category.color,
        value: category.count.toDouble() * animationValue,
        title: widget.showPercentages ? category.formattedPercentage : '',
        radius: (widget.radius + (isTouched ? 10 : 0)) * animationValue * bounceValue,
        titleStyle: theme.labelStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 14 : 12,
        ),
        titlePositionPercentageOffset: 0.6,
        badgeWidget: isTouched ? _buildBadge(category) : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildBadge(CategoryVisualizationData category) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: category.color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 0)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${category.count}',
            style: FTextStyles.body3_13.copyWith(color: category.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterText() {
    final totalCount = widget.categoryData.fold<int>(0, (sum, category) => sum + category.count);
    final displayText = widget.centerText ?? '$totalCount\n${widget.type.displayName}';

    return AnimatedOpacity(
      opacity: animationController.value,
      duration: animationConfig.duration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText.split('\n').first,
            style: theme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryColor),
          ),
          if (displayText.contains('\n'))
            Text(displayText.split('\n').last, style: theme.labelStyle.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children:
            widget.categoryData.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final animationValue =
                  animationConfig.enableStagger ? _getStaggeredAnimationValue(index) : animationController.value;

              return AnimatedOpacity(
                opacity: animationValue,
                duration: Duration(
                  milliseconds:
                      animationConfig.duration.inMilliseconds +
                      (animationConfig.enableStagger ? index * animationConfig.staggerDelay.inMilliseconds : 0),
                ),
                child: GestureDetector(
                  onTap:
                      widget.enableInteraction
                          ? () {
                            // Trigger particle effect on tap
                            if (animationConfig.enableParticles) {
                              setState(() {
                                _showParticles = true;
                              });

                              // Auto-hide particles after delay
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                if (mounted) {
                                  setState(() {
                                    _showParticles = false;
                                  });
                                }
                              });
                            }

                            if (widget.onCategoryTap != null) {
                              widget.onCategoryTap!(category);
                            } else if (widget.enableDrillDown && widget.historicalReports != null) {
                              _showCategoryDrillDown(category);
                            }
                          }
                          : null,
                  child: AnimatedContainer(
                    duration: animationConfig.colorTransitionDuration,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: index == _touchedIndex ? category.color.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: index == _touchedIndex ? category.color : Colors.transparent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: animationConfig.colorTransitionDuration,
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(category.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            category.categoryName,
                            style: theme.labelStyle.copyWith(
                              fontWeight: index == _touchedIndex ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: animationConfig.colorTransitionDuration,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${category.count}',
                            style: theme.labelStyle.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: category.color,
                            ),
                          ),
                        ),
                        if (widget.showPercentages) ...[
                          const SizedBox(width: 4),
                          Text(
                            category.formattedPercentage,
                            style: theme.labelStyle.copyWith(
                              fontSize: 11,
                              color: theme.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  double _getStaggeredAnimationValue(int index) {
    final staggerProgress = (animationController.value * widget.categoryData.length - index).clamp(0.0, 1.0);
    return animationConfig.curve.transform(staggerProgress);
  }

  double _getBounceAnimationValue(int index) {
    if (!animationConfig.enableBounce) return 0.0;

    final bounceStart = 0.6 + (index * 0.05);
    final bounceEnd = bounceStart + 0.3;

    if (animationController.value < bounceStart) return 0.0;
    if (animationController.value > bounceEnd) return 0.0;

    final bounceProgress = (animationController.value - bounceStart) / (bounceEnd - bounceStart);
    return Curves.elasticOut.transform(bounceProgress);
  }

  @override
  Widget buildFallback(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return ChartErrorHandler.createEmptyPlaceholder(
        message: '${widget.type.displayName} 데이터가 없습니다',
        icon: widget.type.icon,
      );
    }

    // Create text-based fallback
    final dataMap = <String, String>{};
    for (final category in widget.categoryData) {
      dataMap['${category.emoji} ${category.categoryName}'] = '${category.count}개 (${category.formattedPercentage})';
    }

    return ChartErrorHandler.createTextFallback(dataMap, title: '${widget.type.displayName} 분포');
  }

  @override
  bool validateData() {
    return widget.categoryData.isNotEmpty && widget.categoryData.any((category) => category.count > 0);
  }

  @override
  Map<String, dynamic> getChartData() {
    return {
      'type': widget.type.name,
      'categories': widget.categoryData.length,
      'totalCount': widget.categoryData.fold<int>(0, (sum, category) => sum + category.count),
      'hasValidData': validateData(),
    };
  }

  void _showCategoryDrillDown(CategoryVisualizationData categoryData) {
    if (widget.historicalReports == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CategoryDrillDownModal(
            categoryData: categoryData,
            historicalReports: widget.historicalReports!,
            onGoalSet: (categoryName, goalValue) {
              // Handle goal setting - this could be passed as a callback
              // For now, just close the modal
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
