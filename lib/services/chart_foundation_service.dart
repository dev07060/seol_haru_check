import 'dart:developer';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Foundation service for chart configuration and utilities
class ChartFoundationService {
  static ChartFoundationService? _instance;

  ChartFoundationService._();

  static ChartFoundationService get instance {
    _instance ??= ChartFoundationService._();
    return _instance!;
  }

  /// Get common fl_chart grid data configuration
  FlGridData getGridData(ChartTheme theme, {bool show = true}) {
    return FlGridData(
      show: show,
      drawVerticalLine: true,
      drawHorizontalLine: true,
      horizontalInterval: 1,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(color: theme.gridColor, strokeWidth: 1);
      },
      getDrawingVerticalLine: (value) {
        return FlLine(color: theme.gridColor, strokeWidth: 1);
      },
    );
  }

  /// Get common fl_chart border data configuration
  FlBorderData getBorderData(ChartTheme theme, {bool show = true}) {
    return FlBorderData(show: show, border: Border.all(color: theme.borderColor, width: 1));
  }

  /// Get common fl_chart titles data configuration
  FlTitlesData getTitlesData(
    ChartTheme theme, {
    bool showLeftTitles = true,
    bool showBottomTitles = true,
    bool showTopTitles = false,
    bool showRightTitles = false,
    Widget Function(double, TitleMeta)? leftTitleBuilder,
    Widget Function(double, TitleMeta)? bottomTitleBuilder,
  }) {
    return FlTitlesData(
      show: true,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: showLeftTitles,
          getTitlesWidget:
              leftTitleBuilder ??
              (value, meta) {
                return Text(value.toInt().toString(), style: theme.labelStyle);
              },
          reservedSize: 40,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: showBottomTitles,
          getTitlesWidget:
              bottomTitleBuilder ??
              (value, meta) {
                return Text(value.toInt().toString(), style: theme.labelStyle);
              },
          reservedSize: 32,
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: showTopTitles)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: showRightTitles)),
    );
  }

  /// Get common touch data configuration for line charts
  LineTouchData getLineTouchData(
    ChartTheme theme, {
    bool enabled = true,
    Function(FlTouchEvent, LineTouchResponse?)? touchCallback,
  }) {
    return LineTouchData(
      enabled: enabled,
      touchCallback: touchCallback,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => theme.primaryColor.withOpacity(0.9),
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            return LineTooltipItem(touchedSpot.y.toStringAsFixed(1), theme.tooltipStyle);
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
    );
  }

  /// Get common touch data configuration for bar charts
  BarTouchData getBarTouchData(
    ChartTheme theme, {
    bool enabled = true,
    Function(FlTouchEvent, BarTouchResponse?)? touchCallback,
  }) {
    return BarTouchData(
      enabled: enabled,
      touchCallback: touchCallback,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => theme.primaryColor.withOpacity(0.9),
        tooltipRoundedRadius: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(rod.toY.toStringAsFixed(1), theme.tooltipStyle);
        },
      ),
      handleBuiltInTouches: true,
    );
  }

  /// Get common touch data configuration for pie charts
  PieTouchData getPieTouchData(
    ChartTheme theme, {
    bool enabled = true,
    Function(FlTouchEvent, PieTouchResponse?)? touchCallback,
  }) {
    return PieTouchData(enabled: enabled, touchCallback: touchCallback);
  }

  /// Create gradient for chart backgrounds
  LinearGradient createChartGradient(
    Color startColor,
    Color endColor, {
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return LinearGradient(begin: begin, end: end, colors: [startColor, endColor]);
  }

  /// Validate chart data and return processed data or throw error
  Map<String, dynamic> validateAndProcessChartData(
    Map<String, dynamic> rawData, {
    required String chartType,
    List<String>? requiredKeys,
  }) {
    try {
      // Check if data is empty
      if (rawData.isEmpty) {
        throw ChartError(type: ChartErrorType.dataProcessing, message: 'Chart data is empty for $chartType');
      }

      // Check required keys
      if (requiredKeys != null) {
        for (String key in requiredKeys) {
          if (!rawData.containsKey(key)) {
            throw ChartError(type: ChartErrorType.dataProcessing, message: 'Missing required key: $key for $chartType');
          }
        }
      }

      // Process and clean data
      Map<String, dynamic> processedData = {};

      for (var entry in rawData.entries) {
        if (entry.value is num) {
          // Ensure numeric values are valid
          if (entry.value.isNaN || entry.value.isInfinite) {
            log('[ChartFoundation] Invalid numeric value for ${entry.key}: ${entry.value}');
            processedData[entry.key] = 0;
          } else {
            processedData[entry.key] = entry.value;
          }
        } else {
          processedData[entry.key] = entry.value;
        }
      }

      return processedData;
    } catch (e) {
      log('[ChartFoundation] Data validation failed for $chartType: $e');
      rethrow;
    }
  }

  /// Get category color by name with fallback
  Color getCategoryColor(String categoryName, ChartTheme theme) {
    // Define category-specific colors
    final categoryColorMap = {
      // Exercise categories
      '근력 운동': SPColors.podGreen,
      '유산소 운동': SPColors.podBlue,
      '스트레칭/요가': SPColors.podPurple,
      '구기/스포츠': SPColors.podOrange,
      '야외 활동': SPColors.podMint,
      '댄스/무용': SPColors.podPink,

      // Diet categories
      '집밥/도시락': SPColors.podGreen,
      '건강식/샐러드': SPColors.podMint,
      '단백질 위주': SPColors.podBlue,
      '간식/음료': SPColors.podOrange,
      '외식/배달': SPColors.podPink,
      '영양제/보충제': SPColors.podPurple,
    };

    return categoryColorMap[categoryName] ?? theme.getCategoryColor(categoryName.hashCode);
  }

  /// Get category emoji by name
  String getCategoryEmoji(String categoryName) {
    final categoryEmojiMap = {
      // Exercise categories
      '근력 운동': '💪',
      '유산소 운동': '🏃',
      '스트레칭/요가': '🧘',
      '구기/스포츠': '⚽',
      '야외 활동': '🏔️',
      '댄스/무용': '💃',

      // Diet categories
      '집밥/도시락': '🍱',
      '건강식/샐러드': '🥗',
      '단백질 위주': '🍗',
      '간식/음료': '🍪',
      '외식/배달': '🍽️',
      '영양제/보충제': '💊',
    };

    return categoryEmojiMap[categoryName] ?? '📊';
  }

  /// Create animation controller with proper disposal
  AnimationController createAnimationController(TickerProvider vsync, AnimationConfig config) {
    return AnimationController(duration: config.duration, vsync: vsync);
  }

  /// Create staggered animation for multiple chart elements
  List<Animation<double>> createStaggeredAnimations(
    AnimationController controller,
    int itemCount,
    AnimationConfig config,
  ) {
    if (!config.enableStagger || itemCount <= 1) {
      return List.generate(
        itemCount,
        (index) =>
            Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: controller, curve: config.curve)),
      );
    }

    List<Animation<double>> animations = [];
    final staggerInterval = config.staggerDelay.inMilliseconds / config.duration.inMilliseconds;

    for (int i = 0; i < itemCount; i++) {
      final start = i * staggerInterval;
      final end = (start + (1.0 - start)).clamp(0.0, 1.0);

      animations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: controller, curve: Interval(start, end, curve: config.curve))),
      );
    }

    return animations;
  }
}
