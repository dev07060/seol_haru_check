import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Service for managing category colors, emojis, and theme configurations
class CategoryMappingService {
  CategoryMappingService._();

  static final CategoryMappingService _instance = CategoryMappingService._();
  static CategoryMappingService get instance => _instance;

  // Exercise category color mapping
  static const Map<ExerciseCategory, Color> _exerciseCategoryColors = {
    ExerciseCategory.strength: Color(0xFFFF6B6B), // Red for strength
    ExerciseCategory.cardio: Color(0xFF4ECDC4), // Teal for cardio
    ExerciseCategory.flexibility: Color(0xFF45B7D1), // Blue for flexibility
    ExerciseCategory.sports: Color(0xFFFF9F43), // Orange for sports
    ExerciseCategory.outdoor: Color(0xFF96CEB4), // Green for outdoor
    ExerciseCategory.dance: Color(0xFFDDA0DD), // Plum for dance
  };

  // Diet category color mapping
  static const Map<DietCategory, Color> _dietCategoryColors = {
    DietCategory.homeMade: Color(0xFFFFD93D), // Yellow for home made
    DietCategory.healthy: Color(0xFF6BCF7F), // Green for healthy
    DietCategory.protein: Color(0xFFFF8A65), // Orange for protein
    DietCategory.snack: Color(0xFFBA68C8), // Purple for snacks
    DietCategory.dining: Color(0xFF42A5F5), // Blue for dining
    DietCategory.supplement: Color(0xFF26C6DA), // Cyan for supplements
  };

  // Fallback colors for dynamic categories
  static const List<Color> _fallbackColors = [
    SPColors.podGreen,
    SPColors.podBlue,
    SPColors.podOrange,
    SPColors.podPurple,
    SPColors.podPink,
    SPColors.podMint,
    Color(0xFF81C784), // Light Green
    Color(0xFF64B5F6), // Light Blue
    Color(0xFFFFB74D), // Light Orange
    Color(0xFFAED581), // Light Lime
  ];

  /// Get color for exercise category
  Color getExerciseCategoryColor(ExerciseCategory category) {
    return _exerciseCategoryColors[category] ?? SPColors.gray500;
  }

  /// Get color for diet category
  Color getDietCategoryColor(DietCategory category) {
    return _dietCategoryColors[category] ?? SPColors.gray500;
  }

  /// Get emoji for exercise category
  String getExerciseCategoryEmoji(ExerciseCategory category) {
    return category.emoji;
  }

  /// Get emoji for diet category
  String getDietCategoryEmoji(DietCategory category) {
    return category.emoji;
  }

  /// Get color for category by name using enhanced SPColors system
  Color getCategoryColorByName(String categoryName, CategoryType type) {
    switch (type) {
      case CategoryType.exercise:
        // Use enhanced SPColors system for exercise categories
        return SPColors.getExerciseColor(categoryName);
      case CategoryType.diet:
        // Use enhanced SPColors system for diet categories
        return SPColors.getDietColor(categoryName);
    }
  }

  /// Get emoji for category by name using enhanced SPColors system
  String getCategoryEmojiByName(String categoryName, CategoryType type) {
    switch (type) {
      case CategoryType.exercise:
        // Use enhanced SPColors system for exercise emojis
        return SPColors.getExerciseEmoji(categoryName);
      case CategoryType.diet:
        // Use enhanced SPColors system for diet emojis
        return SPColors.getDietEmoji(categoryName);
    }
  }

  /// Generate color for dynamic/unknown categories
  Color _generateDynamicColor(String categoryName) {
    final hash = categoryName.hashCode;
    final index = hash.abs() % _fallbackColors.length;
    return _fallbackColors[index];
  }

  /// Generate emoji for dynamic/unknown categories
  String _generateDynamicEmoji(CategoryType type) {
    switch (type) {
      case CategoryType.exercise:
        return '🏃'; // Default exercise emoji
      case CategoryType.diet:
        return '🍽️'; // Default diet emoji
    }
  }

  /// Get all exercise category colors
  Map<ExerciseCategory, Color> get exerciseCategoryColors => _exerciseCategoryColors;

  /// Get all diet category colors
  Map<DietCategory, Color> get dietCategoryColors => _dietCategoryColors;

  /// Get accessible color variant for better contrast
  Color getAccessibleColor(Color baseColor, {required bool isDarkMode}) {
    if (isDarkMode) {
      // Lighten color for dark mode
      return Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor;
    } else {
      // Darken color for light mode if needed for better contrast
      final luminance = baseColor.computeLuminance();
      if (luminance > 0.7) {
        return Color.lerp(baseColor, Colors.black, 0.2) ?? baseColor;
      }
      return baseColor;
    }
  }

  /// Check if color has sufficient contrast ratio
  bool hasGoodContrast(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;

    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= 4.5; // WCAG AA standard
  }

  /// Get category visualization data for exercise categories
  List<CategoryVisualizationData> getExerciseCategoryVisualizationData(Map<String, int> categoryData) {
    final total = categoryData.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return [];

    return categoryData.entries.map((entry) {
      final categoryName = entry.key;
      final count = entry.value;
      final percentage = count / total;

      return CategoryVisualizationData(
        categoryName: categoryName,
        emoji: getCategoryEmojiByName(categoryName, CategoryType.exercise),
        count: count,
        percentage: percentage,
        color: getCategoryColorByName(categoryName, CategoryType.exercise),
        type: CategoryType.exercise,
      );
    }).toList();
  }

  /// Get category visualization data for diet categories
  List<CategoryVisualizationData> getDietCategoryVisualizationData(Map<String, int> categoryData) {
    final total = categoryData.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return [];

    return categoryData.entries.map((entry) {
      final categoryName = entry.key;
      final count = entry.value;
      final percentage = count / total;

      return CategoryVisualizationData(
        categoryName: categoryName,
        emoji: getCategoryEmojiByName(categoryName, CategoryType.diet),
        count: count,
        percentage: percentage,
        color: getCategoryColorByName(categoryName, CategoryType.diet),
        type: CategoryType.diet,
      );
    }).toList();
  }
}
