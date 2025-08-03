import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Utility class for unified bar chart calculations and data processing
class UnifiedBarChartUtils {
  UnifiedBarChartUtils._(); // Private constructor to prevent instantiation

  /// Calculate percentage for a category within total count
  static double calculatePercentage(int categoryCount, int totalCount) {
    return totalCount > 0 ? (categoryCount / totalCount) * 100 : 0.0;
  }

  /// Calculate segments with proper positioning and minimum width enforcement
  static List<BarSegmentData> calculateSegments({
    required List<CategoryVisualizationData> exerciseCategories,
    required List<CategoryVisualizationData> dietCategories,
    double minSegmentWidth = 5.0,
    bool sortByCount = true,
  }) {
    final allCategories = [...exerciseCategories, ...dietCategories];
    final totalCount = allCategories.fold(0, (sum, item) => sum + item.count);

    if (totalCount == 0) return [];

    // Filter out categories with zero count
    final activeCategories = allCategories.where((cat) => cat.count > 0).toList();

    if (activeCategories.isEmpty) return [];

    // Sort categories if requested (by count descending for better visual hierarchy)
    if (sortByCount) {
      activeCategories.sort((a, b) => b.count.compareTo(a.count));
    }

    final segments = <BarSegmentData>[];
    double currentPosition = 0.0;

    // First pass: calculate raw segments
    final rawSegments = <BarSegmentData>[];
    for (final category in activeCategories) {
      final percentage = calculatePercentage(category.count, totalCount);
      final width = percentage;

      rawSegments.add(
        BarSegmentData(
          category: category,
          percentage: percentage,
          startPosition: 0.0, // Will be adjusted in second pass
          width: width,
          color: _getCategoryColor(category),
          emoji: category.emoji,
          minWidth: minSegmentWidth,
        ),
      );
    }

    // Second pass: adjust for minimum widths and calculate positions
    final adjustedSegments = _adjustSegmentWidths(rawSegments, minSegmentWidth);

    // Third pass: set final positions
    for (final segment in adjustedSegments) {
      final finalSegment = segment.copyWith(startPosition: currentPosition);
      segments.add(finalSegment);
      currentPosition += finalSegment.effectiveWidth;
    }

    return segments;
  }

  /// Adjust segment widths to ensure minimum visibility while maintaining proportions
  static List<BarSegmentData> _adjustSegmentWidths(List<BarSegmentData> segments, double minWidth) {
    if (segments.isEmpty) return segments;

    final adjustedSegments = <BarSegmentData>[];
    double totalMinWidthNeeded = 0.0;
    double totalLargeSegmentWidth = 0.0;

    // Calculate how much space is needed for minimum widths
    for (final segment in segments) {
      if (segment.width < minWidth) {
        totalMinWidthNeeded += minWidth;
      } else {
        totalLargeSegmentWidth += segment.width;
      }
    }

    // If total minimum width exceeds 100%, proportionally reduce all segments
    if (totalMinWidthNeeded > 100.0) {
      final scaleFactor = 100.0 / totalMinWidthNeeded;
      for (final segment in segments) {
        adjustedSegments.add(segment.copyWith(width: minWidth * scaleFactor));
      }
      return adjustedSegments;
    }

    // Calculate available space for large segments after reserving space for small ones
    final availableSpaceForLarge = 100.0 - totalMinWidthNeeded;
    final largeSegmentScaleFactor = totalLargeSegmentWidth > 0 ? availableSpaceForLarge / totalLargeSegmentWidth : 1.0;

    // Apply adjustments
    for (final segment in segments) {
      if (segment.width < minWidth) {
        // Small segments get minimum width
        adjustedSegments.add(segment.copyWith(width: minWidth));
      } else {
        // Large segments get scaled width
        adjustedSegments.add(segment.copyWith(width: segment.width * largeSegmentScaleFactor));
      }
    }

    return adjustedSegments;
  }

  /// Get appropriate color for a category
  static Color _getCategoryColor(CategoryVisualizationData category) {
    // Use existing color if available, otherwise get from color system
    if (category.color != SPColors.gray400) {
      return category.color;
    }

    // Fallback to color system based on category type and name
    switch (category.type) {
      case CategoryType.exercise:
        return SPColors.getExerciseColor(category.categoryName);
      case CategoryType.diet:
        return SPColors.getDietColor(category.categoryName);
    }
  }

  /// Find segment at specific position (for hit testing)
  static BarSegmentData? findSegmentAtPosition(List<BarSegmentData> segments, double position) {
    for (final segment in segments) {
      if (segment.containsPosition(position)) {
        return segment;
      }
    }
    return null;
  }

  /// Calculate optimal bar height based on content
  static double calculateOptimalHeight({
    required int categoryCount,
    double baseHeight = 60.0,
    double maxHeight = 100.0,
    double minHeight = 40.0,
  }) {
    if (categoryCount == 0) return minHeight;

    // Increase height slightly for more categories to improve readability
    final heightMultiplier = 1.0 + (categoryCount - 1) * 0.05;
    final calculatedHeight = baseHeight * heightMultiplier;

    return calculatedHeight.clamp(minHeight, maxHeight);
  }

  /// Validate unified bar data
  static ValidationResult validateUnifiedBarData(UnifiedBarData data) {
    if (!data.hasData) {
      return ValidationResult.error('카테고리 데이터가 없습니다');
    }

    if (data.totalCount == 0) {
      return ValidationResult.error('총 개수가 0입니다');
    }

    // Check for invalid percentages
    for (final category in data.allCategories) {
      final percentage = data.getPercentage(category);
      if (percentage < 0 || percentage > 100) {
        return ValidationResult.error('잘못된 퍼센티지 값: ${percentage.toStringAsFixed(1)}%');
      }
    }

    // Check for duplicate categories
    final categoryNames = data.allCategories.map((cat) => cat.categoryName).toList();
    final uniqueNames = categoryNames.toSet();
    if (categoryNames.length != uniqueNames.length) {
      return ValidationResult.error('중복된 카테고리가 있습니다');
    }

    return ValidationResult.success();
  }

  /// Create sample data for testing
  static UnifiedBarData createSampleData() {
    final exerciseCategories = [
      CategoryVisualizationData(
        categoryName: '근력 운동',
        emoji: '💪',
        count: 8,
        percentage: 0.0, // Will be calculated
        color: SPColors.reportGreen,
        type: CategoryType.exercise,
      ),
      CategoryVisualizationData(
        categoryName: '유산소',
        emoji: '🏃',
        count: 5,
        percentage: 0.0,
        color: SPColors.reportBlue,
        type: CategoryType.exercise,
      ),
      CategoryVisualizationData(
        categoryName: '스트레칭',
        emoji: '🧘',
        count: 3,
        percentage: 0.0,
        color: SPColors.reportOrange,
        type: CategoryType.exercise,
      ),
    ];

    final dietCategories = [
      CategoryVisualizationData(
        categoryName: '한식',
        emoji: '🍚',
        count: 6,
        percentage: 0.0,
        color: SPColors.dietGreen,
        type: CategoryType.diet,
      ),
      CategoryVisualizationData(
        categoryName: '샐러드',
        emoji: '🥗',
        count: 4,
        percentage: 0.0,
        color: SPColors.dietLightGreen,
        type: CategoryType.diet,
      ),
    ];

    return UnifiedBarData(exerciseCategories: exerciseCategories, dietCategories: dietCategories);
  }

  /// Calculate category distribution summary
  static CategoryDistributionSummary calculateDistributionSummary(UnifiedBarData data) {
    return CategoryDistributionSummary(
      totalCategories: data.allCategories.length,
      exerciseCategories: data.exerciseCategories.length,
      dietCategories: data.dietCategories.length,
      totalCount: data.totalCount,
      exerciseCount: data.exerciseTotalCount,
      dietCount: data.dietTotalCount,
      exercisePercentage: data.exercisePercentage,
      dietPercentage: data.dietPercentage,
      dominantType: data.exerciseTotalCount > data.dietTotalCount ? CategoryType.exercise : CategoryType.diet,
      diversityScore: _calculateDiversityScore(data),
    );
  }

  /// Calculate diversity score (0-1, higher is more diverse)
  static double _calculateDiversityScore(UnifiedBarData data) {
    if (data.totalCount == 0) return 0.0;

    final categories = data.allCategories.where((cat) => cat.count > 0).toList();
    if (categories.length <= 1) return 0.0;

    // Shannon diversity index adapted for category distribution
    double entropy = 0.0;
    for (final category in categories) {
      final proportion = category.count / data.totalCount;
      if (proportion > 0) {
        entropy -= proportion * (math.log(proportion) / math.ln2);
      }
    }

    // Normalize to 0-1 scale
    final maxEntropy = math.log(categories.length) / math.ln2;
    return maxEntropy > 0 ? entropy / maxEntropy : 0.0;
  }
}

/// Validation result for data validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.success() => const ValidationResult._(true, null);
  factory ValidationResult.error(String message) => ValidationResult._(false, message);

  @override
  String toString() {
    return isValid ? 'Valid' : 'Error: $errorMessage';
  }
}

/// Summary of category distribution for analysis
class CategoryDistributionSummary {
  final int totalCategories;
  final int exerciseCategories;
  final int dietCategories;
  final int totalCount;
  final int exerciseCount;
  final int dietCount;
  final double exercisePercentage;
  final double dietPercentage;
  final CategoryType dominantType;
  final double diversityScore;

  const CategoryDistributionSummary({
    required this.totalCategories,
    required this.exerciseCategories,
    required this.dietCategories,
    required this.totalCount,
    required this.exerciseCount,
    required this.dietCount,
    required this.exercisePercentage,
    required this.dietPercentage,
    required this.dominantType,
    required this.diversityScore,
  });

  /// Get diversity level description
  String get diversityLevelDescription {
    if (diversityScore > 0.8) {
      return '매우 다양한 활동';
    } else if (diversityScore > 0.6) {
      return '다양한 활동';
    } else if (diversityScore > 0.4) {
      return '보통 수준의 다양성';
    } else if (diversityScore > 0.2) {
      return '제한적인 다양성';
    } else {
      return '단조로운 활동';
    }
  }

  /// Get balance description
  String get balanceDescription {
    final difference = (exercisePercentage - dietPercentage).abs();
    if (difference < 10) {
      return '균형잡힌 운동-식단 비율';
    } else if (dominantType == CategoryType.exercise) {
      return '운동 중심 활동';
    } else {
      return '식단 중심 활동';
    }
  }

  @override
  String toString() {
    return 'CategoryDistributionSummary(total: $totalCategories, exercise: $exerciseCategories, diet: $dietCategories, diversity: ${(diversityScore * 100).toStringAsFixed(1)}%)';
  }
}
