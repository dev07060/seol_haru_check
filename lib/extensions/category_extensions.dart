import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_theme_config.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/services/category_mapping_service.dart';

/// Extensions for easier category color and emoji access
extension ExerciseCategoryExtensions on ExerciseCategory {
  /// Get themed color for this exercise category
  Color getThemedColor(CategoryThemeConfig theme) {
    return theme.getExerciseCategoryColor(this);
  }

  /// Get color for this exercise category
  Color get color => CategoryMappingService.instance.getExerciseCategoryColor(this);

  /// Get visualization data for this category
  CategoryVisualizationData toVisualizationData({
    required int count,
    required double percentage,
    Color? customColor,
    List<SubcategoryData> subcategories = const [],
    String? description,
    bool isActive = true,
  }) {
    return CategoryVisualizationData.fromExerciseCategory(
      this,
      count,
      percentage,
      customColor ?? color,
      subcategories: subcategories,
      description: description,
      isActive: isActive,
    );
  }
}

extension DietCategoryExtensions on DietCategory {
  /// Get themed color for this diet category
  Color getThemedColor(CategoryThemeConfig theme) {
    return theme.getDietCategoryColor(this);
  }

  /// Get color for this diet category
  Color get color => CategoryMappingService.instance.getDietCategoryColor(this);

  /// Get visualization data for this category
  CategoryVisualizationData toVisualizationData({
    required int count,
    required double percentage,
    Color? customColor,
    List<SubcategoryData> subcategories = const [],
    String? description,
    bool isActive = true,
  }) {
    return CategoryVisualizationData.fromDietCategory(
      this,
      count,
      percentage,
      customColor ?? color,
      subcategories: subcategories,
      description: description,
      isActive: isActive,
    );
  }
}

/// Extensions for category type utilities
extension CategoryTypeExtensions on CategoryType {
  /// Get all categories for this type
  List<String> get allCategoryNames {
    switch (this) {
      case CategoryType.exercise:
        return ExerciseCategory.values.map((e) => e.displayName).toList();
      case CategoryType.diet:
        return DietCategory.values.map((e) => e.displayName).toList();
    }
  }

  /// Get all category emojis for this type
  List<String> get allCategoryEmojis {
    switch (this) {
      case CategoryType.exercise:
        return ExerciseCategory.values.map((e) => e.emoji).toList();
      case CategoryType.diet:
        return DietCategory.values.map((e) => e.emoji).toList();
    }
  }

  /// Get color for category by name
  Color getCategoryColor(String categoryName, {CategoryThemeConfig? theme}) {
    if (theme != null) {
      return theme.getCategoryColorByName(categoryName, this);
    }
    return CategoryMappingService.instance.getCategoryColorByName(categoryName, this);
  }

  /// Get emoji for category by name
  String getCategoryEmoji(String categoryName) {
    return CategoryMappingService.instance.getCategoryEmojiByName(categoryName, this);
  }

  /// Create visualization data list from category data map
  List<CategoryVisualizationData> createVisualizationData(Map<String, int> categoryData) {
    switch (this) {
      case CategoryType.exercise:
        return CategoryMappingService.instance.getExerciseCategoryVisualizationData(categoryData);
      case CategoryType.diet:
        return CategoryMappingService.instance.getDietCategoryVisualizationData(categoryData);
    }
  }
}

/// Extensions for string category names
extension CategoryNameExtensions on String {
  /// Try to get exercise category from display name
  ExerciseCategory? get asExerciseCategory {
    try {
      return ExerciseCategory.fromDisplayName(this);
    } catch (e) {
      return null;
    }
  }

  /// Try to get diet category from display name
  DietCategory? get asDietCategory {
    try {
      return DietCategory.fromDisplayName(this);
    } catch (e) {
      return null;
    }
  }

  /// Get category color by name (requires category type)
  Color getCategoryColor(CategoryType type, {CategoryThemeConfig? theme}) {
    return type.getCategoryColor(this, theme: theme);
  }

  /// Get category emoji by name (requires category type)
  String getCategoryEmoji(CategoryType type) {
    return type.getCategoryEmoji(this);
  }

  /// Check if this is a known exercise category
  bool get isKnownExerciseCategory => asExerciseCategory != null;

  /// Check if this is a known diet category
  bool get isKnownDietCategory => asDietCategory != null;
}

/// Extensions for category visualization data
extension CategoryVisualizationDataExtensions on CategoryVisualizationData {
  /// Get themed version of this visualization data
  CategoryVisualizationData withTheme(CategoryThemeConfig theme) {
    return copyWith(color: theme.getCategoryColorByName(categoryName, type));
  }

  /// Get display text with count
  String get displayTextWithCount => '$displayText ($count)';

  /// Get display text with percentage
  String get displayTextWithPercentage => '$displayText ($formattedPercentage)';

  /// Get display text with count and percentage
  String get displayTextWithDetails => '$displayText ($count, $formattedPercentage)';

  /// Check if this category is above average
  bool isAboveAverage(List<CategoryVisualizationData> allCategories) {
    if (allCategories.isEmpty) return false;
    final averagePercentage =
        allCategories.map((data) => data.percentage).reduce((a, b) => a + b) / allCategories.length;
    return percentage > averagePercentage;
  }

  /// Get rank among all categories (1-based)
  int getRank(List<CategoryVisualizationData> allCategories) {
    final sortedCategories = List<CategoryVisualizationData>.from(allCategories)
      ..sort((a, b) => b.count.compareTo(a.count));
    return sortedCategories.indexOf(this) + 1;
  }
}

/// Extensions for lists of category visualization data
extension CategoryVisualizationDataListExtensions on List<CategoryVisualizationData> {
  /// Get only exercise categories
  List<CategoryVisualizationData> get exerciseCategories =>
      where((data) => data.type == CategoryType.exercise).toList();

  /// Get only diet categories
  List<CategoryVisualizationData> get dietCategories => where((data) => data.type == CategoryType.diet).toList();

  /// Get only active categories
  List<CategoryVisualizationData> get activeCategories => where((data) => data.isActive).toList();

  /// Sort by count (descending)
  List<CategoryVisualizationData> get sortedByCount {
    final sorted = List<CategoryVisualizationData>.from(this);
    sorted.sort((a, b) => b.count.compareTo(a.count));
    return sorted;
  }

  /// Sort by percentage (descending)
  List<CategoryVisualizationData> get sortedByPercentage {
    final sorted = List<CategoryVisualizationData>.from(this);
    sorted.sort((a, b) => b.percentage.compareTo(a.percentage));
    return sorted;
  }

  /// Sort by category name (alphabetical)
  List<CategoryVisualizationData> get sortedByName {
    final sorted = List<CategoryVisualizationData>.from(this);
    sorted.sort((a, b) => a.categoryName.compareTo(b.categoryName));
    return sorted;
  }

  /// Get top N categories by count
  List<CategoryVisualizationData> topByCount(int n) => sortedByCount.take(n).toList();

  /// Get top N categories by percentage
  List<CategoryVisualizationData> topByPercentage(int n) => sortedByPercentage.take(n).toList();

  /// Get total count across all categories
  int get totalCount => fold(0, (sum, data) => sum + data.count);

  /// Get categories with count above threshold
  List<CategoryVisualizationData> withCountAbove(int threshold) => where((data) => data.count > threshold).toList();

  /// Get categories with percentage above threshold
  List<CategoryVisualizationData> withPercentageAbove(double threshold) =>
      where((data) => data.percentage > threshold).toList();

  /// Apply theme to all categories
  List<CategoryVisualizationData> withTheme(CategoryThemeConfig theme) => map((data) => data.withTheme(theme)).toList();
}
