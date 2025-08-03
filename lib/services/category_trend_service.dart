import 'dart:math';

import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Model for trend data point
class TrendDataPoint {
  final DateTime date;
  final double value;
  final bool isPredicted;
  final String tooltip;

  const TrendDataPoint({required this.date, required this.value, required this.isPredicted, required this.tooltip});
}

/// Model for category trend line data
class CategoryTrendLineData {
  final String categoryName;
  final String emoji;
  final CategoryType type;
  final Color color;
  final List<TrendDataPoint> dataPoints;
  final bool isVisible;
  final TrendDirection trendDirection;
  final double changePercentage;

  const CategoryTrendLineData({
    required this.categoryName,
    required this.emoji,
    required this.type,
    required this.color,
    required this.dataPoints,
    required this.isVisible,
    required this.trendDirection,
    required this.changePercentage,
  });

  CategoryTrendLineData copyWith({
    String? categoryName,
    String? emoji,
    CategoryType? type,
    Color? color,
    List<TrendDataPoint>? dataPoints,
    bool? isVisible,
    TrendDirection? trendDirection,
    double? changePercentage,
  }) {
    return CategoryTrendLineData(
      categoryName: categoryName ?? this.categoryName,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      color: color ?? this.color,
      dataPoints: dataPoints ?? this.dataPoints,
      isVisible: isVisible ?? this.isVisible,
      trendDirection: trendDirection ?? this.trendDirection,
      changePercentage: changePercentage ?? this.changePercentage,
    );
  }
}

/// Service for generating and managing category trend data
class CategoryTrendService {
  static CategoryTrendService? _instance;
  final Random _random = Random();

  CategoryTrendService._();

  static CategoryTrendService get instance {
    _instance ??= CategoryTrendService._();
    return _instance!;
  }

  /// Generate sample trend data for demonstration
  List<CategoryTrendLineData> generateSampleTrendData({
    required DateTimeRange dateRange,
    int categoryCount = 6,
    bool includePredictions = true,
  }) {
    final trendData = <CategoryTrendLineData>[];
    final exerciseCategories = ExerciseCategory.values.take(categoryCount ~/ 2).toList();
    final dietCategories = DietCategory.values.take(categoryCount - exerciseCategories.length).toList();

    // Generate exercise category trends
    for (int i = 0; i < exerciseCategories.length; i++) {
      final category = exerciseCategories[i];
      final color = _getCategoryColor(i);
      final trendDirection = _getRandomTrendDirection();
      final changePercentage = _generateChangePercentage(trendDirection);

      trendData.add(
        CategoryTrendLineData(
          categoryName: category.displayName,
          emoji: category.emoji,
          type: CategoryType.exercise,
          color: color,
          dataPoints: _generateDataPoints(
            dateRange: dateRange,
            trendDirection: trendDirection,
            includePredictions: includePredictions,
          ),
          isVisible: true,
          trendDirection: trendDirection,
          changePercentage: changePercentage,
        ),
      );
    }

    // Generate diet category trends
    for (int i = 0; i < dietCategories.length; i++) {
      final category = dietCategories[i];
      final color = _getCategoryColor(exerciseCategories.length + i);
      final trendDirection = _getRandomTrendDirection();
      final changePercentage = _generateChangePercentage(trendDirection);

      trendData.add(
        CategoryTrendLineData(
          categoryName: category.displayName,
          emoji: category.emoji,
          type: CategoryType.diet,
          color: color,
          dataPoints: _generateDataPoints(
            dateRange: dateRange,
            trendDirection: trendDirection,
            includePredictions: includePredictions,
          ),
          isVisible: true,
          trendDirection: trendDirection,
          changePercentage: changePercentage,
        ),
      );
    }

    return trendData;
  }

  /// Generate realistic trend data based on actual certification data
  Future<List<CategoryTrendLineData>> generateTrendDataFromCertifications({
    required DateTimeRange dateRange,
    required Map<String, List<DateTime>> categoryData,
    bool includePredictions = true,
  }) async {
    final trendData = <CategoryTrendLineData>[];
    int colorIndex = 0;

    for (final entry in categoryData.entries) {
      final categoryName = entry.key;
      final certificationDates = entry.value;

      // Determine category type and get emoji
      final isExercise = _isExerciseCategory(categoryName);
      final emoji = _getCategoryEmoji(categoryName);
      final color = _getCategoryColor(colorIndex++);

      // Generate data points from certification dates
      final dataPoints = _generateDataPointsFromDates(
        dateRange: dateRange,
        certificationDates: certificationDates,
        includePredictions: includePredictions,
      );

      // Calculate trend direction and change percentage
      final trendAnalysis = _analyzeTrend(dataPoints);

      trendData.add(
        CategoryTrendLineData(
          categoryName: categoryName,
          emoji: emoji,
          type: isExercise ? CategoryType.exercise : CategoryType.diet,
          color: color,
          dataPoints: dataPoints,
          isVisible: true,
          trendDirection: trendAnalysis.direction,
          changePercentage: trendAnalysis.changePercentage,
        ),
      );
    }

    return trendData;
  }

  /// Generate data points for a given date range and trend direction
  List<TrendDataPoint> _generateDataPoints({
    required DateTimeRange dateRange,
    required TrendDirection trendDirection,
    bool includePredictions = true,
  }) {
    final dataPoints = <TrendDataPoint>[];
    final daysDiff = dateRange.duration.inDays;
    final interval = daysDiff > 30 ? 7 : 1; // Weekly for long ranges, daily for short

    double baseValue = 2 + _random.nextDouble() * 3; // Start with 2-5 base value
    double trendMultiplier = _getTrendMultiplier(trendDirection);

    DateTime currentDate = dateRange.start;
    while (currentDate.isBefore(dateRange.end) || currentDate.isAtSameMomentAs(dateRange.end)) {
      // Add some randomness to the trend
      final randomFactor = 0.8 + _random.nextDouble() * 0.4; // 0.8 to 1.2
      final value = (baseValue * randomFactor).clamp(0, 20);

      dataPoints.add(
        TrendDataPoint(date: currentDate, value: value.toDouble(), isPredicted: false, tooltip: '${value.toInt()}개'),
      );

      // Update base value for next point
      baseValue += trendMultiplier * (0.5 + _random.nextDouble() * 0.5);
      baseValue = baseValue.clamp(0, 15);

      currentDate = currentDate.add(Duration(days: interval));
    }

    // Add prediction points if enabled
    if (includePredictions && dataPoints.isNotEmpty) {
      final predictionPoints = _generatePredictionPoints(
        lastDataPoint: dataPoints.last,
        trendDirection: trendDirection,
        daysToPredict: 14,
      );
      dataPoints.addAll(predictionPoints);
    }

    return dataPoints;
  }

  /// Generate data points from actual certification dates
  List<TrendDataPoint> _generateDataPointsFromDates({
    required DateTimeRange dateRange,
    required List<DateTime> certificationDates,
    bool includePredictions = true,
  }) {
    final dataPoints = <TrendDataPoint>[];
    final daysDiff = dateRange.duration.inDays;
    final interval = daysDiff > 30 ? 7 : 1;

    DateTime currentDate = dateRange.start;
    while (currentDate.isBefore(dateRange.end) || currentDate.isAtSameMomentAs(dateRange.end)) {
      final endDate = currentDate.add(Duration(days: interval));

      // Count certifications in this interval
      final count =
          certificationDates.where((date) {
            return date.isAfter(currentDate.subtract(const Duration(days: 1))) && date.isBefore(endDate);
          }).length;

      dataPoints.add(
        TrendDataPoint(date: currentDate, value: count.toDouble(), isPredicted: false, tooltip: '$count개'),
      );

      currentDate = endDate;
    }

    // Add predictions if enabled
    if (includePredictions && dataPoints.length >= 3) {
      final trendAnalysis = _analyzeTrend(dataPoints);
      final predictionPoints = _generatePredictionPoints(
        lastDataPoint: dataPoints.last,
        trendDirection: trendAnalysis.direction,
        daysToPredict: 14,
      );
      dataPoints.addAll(predictionPoints);
    }

    return dataPoints;
  }

  /// Generate prediction points based on trend analysis
  List<TrendDataPoint> _generatePredictionPoints({
    required TrendDataPoint lastDataPoint,
    required TrendDirection trendDirection,
    int daysToPredict = 14,
  }) {
    final predictionPoints = <TrendDataPoint>[];
    final trendMultiplier = _getTrendMultiplier(trendDirection) * 0.5; // Reduce prediction intensity

    double currentValue = lastDataPoint.value;
    DateTime currentDate = lastDataPoint.date.add(const Duration(days: 7));

    for (int i = 0; i < (daysToPredict / 7).ceil(); i++) {
      currentValue += trendMultiplier * (0.7 + _random.nextDouble() * 0.3);
      currentValue = currentValue.clamp(0, 12);

      predictionPoints.add(
        TrendDataPoint(
          date: currentDate,
          value: currentValue,
          isPredicted: true,
          tooltip: '예측: ${currentValue.toInt()}개',
        ),
      );

      currentDate = currentDate.add(const Duration(days: 7));
    }

    return predictionPoints;
  }

  /// Analyze trend from data points
  TrendAnalysisResult _analyzeTrend(List<TrendDataPoint> dataPoints) {
    if (dataPoints.length < 2) {
      return TrendAnalysisResult(direction: TrendDirection.stable, changePercentage: 0.0);
    }

    // Calculate trend using linear regression or simple comparison
    final firstHalf = dataPoints.take(dataPoints.length ~/ 2).toList();
    final secondHalf = dataPoints.skip(dataPoints.length ~/ 2).toList();

    final firstAvg = firstHalf.map((p) => p.value).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.map((p) => p.value).reduce((a, b) => a + b) / secondHalf.length;

    final changePercentage = firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0.0;

    TrendDirection direction;
    if (changePercentage > 10) {
      direction = TrendDirection.up;
    } else if (changePercentage < -10) {
      direction = TrendDirection.down;
    } else {
      direction = TrendDirection.stable;
    }

    return TrendAnalysisResult(direction: direction, changePercentage: changePercentage);
  }

  /// Get trend multiplier based on direction
  double _getTrendMultiplier(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.up:
        return 0.3 + _random.nextDouble() * 0.4; // 0.3 to 0.7
      case TrendDirection.down:
        return -0.2 - _random.nextDouble() * 0.3; // -0.2 to -0.5
      case TrendDirection.stable:
        return (-0.1 + _random.nextDouble() * 0.2); // -0.1 to 0.1
    }
  }

  /// Get random trend direction
  TrendDirection _getRandomTrendDirection() {
    final directions = TrendDirection.values;
    return directions[_random.nextInt(directions.length)];
  }

  /// Generate change percentage based on trend direction
  double _generateChangePercentage(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.up:
        return 15 + _random.nextDouble() * 35; // 15% to 50%
      case TrendDirection.down:
        return -10 - _random.nextDouble() * 25; // -10% to -35%
      case TrendDirection.stable:
        return -5 + _random.nextDouble() * 10; // -5% to 5%
    }
  }

  /// Get category color by index
  Color _getCategoryColor(int index) {
    final colors = [
      SPColors.reportGreen,
      SPColors.reportBlue,
      SPColors.reportOrange,
      SPColors.reportPurple,
      SPColors.reportRed,
      SPColors.reportTeal,
      SPColors.reportIndigo,
    ];
    return colors[index % colors.length];
  }

  /// Check if category is exercise-related
  bool _isExerciseCategory(String categoryName) {
    final exerciseKeywords = ['운동', '헬스', '요가', '러닝', '수영', '축구', '농구', '테니스', '골프'];
    return exerciseKeywords.any((keyword) => categoryName.contains(keyword));
  }

  /// Get category emoji
  String _getCategoryEmoji(String categoryName) {
    return SPColors.getExerciseEmoji(categoryName);
  }

  /// Filter trend data by category type
  List<CategoryTrendLineData> filterByType(List<CategoryTrendLineData> trendData, CategoryType? type) {
    if (type == null) return trendData;
    return trendData.where((data) => data.type == type).toList();
  }

  /// Get popular categories (top trending up)
  List<CategoryTrendLineData> getPopularCategories(List<CategoryTrendLineData> trendData, {int limit = 3}) {
    final upTrending = trendData.where((data) => data.trendDirection == TrendDirection.up).toList();

    upTrending.sort((a, b) => b.changePercentage.compareTo(a.changePercentage));
    return upTrending.take(limit).toList();
  }

  /// Get declining categories
  List<CategoryTrendLineData> getDecliningCategories(List<CategoryTrendLineData> trendData, {int limit = 3}) {
    final downTrending = trendData.where((data) => data.trendDirection == TrendDirection.down).toList();

    downTrending.sort((a, b) => a.changePercentage.compareTo(b.changePercentage));
    return downTrending.take(limit).toList();
  }
}

/// Result of trend analysis
class TrendAnalysisResult {
  final TrendDirection direction;
  final double changePercentage;

  const TrendAnalysisResult({required this.direction, required this.changePercentage});
}
