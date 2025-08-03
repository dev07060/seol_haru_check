import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/services/category_mapping_service.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Configuration class for category themes with accessibility support
class CategoryThemeConfig {
  final bool isDarkMode;
  final bool highContrast;
  final double colorIntensity;
  final bool reduceMotion;

  const CategoryThemeConfig({
    this.isDarkMode = false,
    this.highContrast = false,
    this.colorIntensity = 1.0,
    this.reduceMotion = false,
  });

  /// Create theme config from BuildContext
  factory CategoryThemeConfig.fromContext(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final mediaQuery = MediaQuery.of(context);

    return CategoryThemeConfig(
      isDarkMode: brightness == Brightness.dark,
      highContrast: mediaQuery.highContrast,
      reduceMotion: mediaQuery.disableAnimations,
      colorIntensity: 1.0,
    );
  }

  /// Get themed color for exercise category
  Color getExerciseCategoryColor(ExerciseCategory category) {
    Color baseColor = CategoryMappingService.instance.getExerciseCategoryColor(category);
    return _applyThemeToColor(baseColor);
  }

  /// Get themed color for diet category
  Color getDietCategoryColor(DietCategory category) {
    Color baseColor = CategoryMappingService.instance.getDietCategoryColor(category);
    return _applyThemeToColor(baseColor);
  }

  /// Get themed color by category name
  Color getCategoryColorByName(String categoryName, CategoryType type) {
    Color baseColor = CategoryMappingService.instance.getCategoryColorByName(categoryName, type);
    return _applyThemeToColor(baseColor);
  }

  /// Apply theme modifications to base color
  Color _applyThemeToColor(Color baseColor) {
    Color themedColor = baseColor;

    // Apply color intensity
    if (colorIntensity != 1.0) {
      themedColor = Color.lerp(isDarkMode ? Colors.black : Colors.white, baseColor, colorIntensity) ?? baseColor;
    }

    // Apply accessibility modifications
    if (highContrast) {
      themedColor = _enhanceContrast(themedColor);
    }

    // Apply dark/light mode adjustments
    themedColor = CategoryMappingService.instance.getAccessibleColor(themedColor, isDarkMode: isDarkMode);

    return themedColor;
  }

  /// Enhance color contrast for accessibility
  Color _enhanceContrast(Color color) {
    final luminance = color.computeLuminance();

    if (isDarkMode) {
      // In dark mode, make colors brighter
      return luminance < 0.5 ? Color.lerp(color, Colors.white, 0.4) ?? color : color;
    } else {
      // In light mode, make colors darker if they're too light
      return luminance > 0.7 ? Color.lerp(color, Colors.black, 0.3) ?? color : color;
    }
  }

  /// Get background color for category items
  Color getCategoryBackgroundColor() {
    if (isDarkMode) {
      return highContrast ? SPColors.gray900 : SPColors.gray800;
    } else {
      return highContrast ? SPColors.white : SPColors.gray100;
    }
  }

  /// Get text color for category labels
  Color getCategoryTextColor() {
    if (isDarkMode) {
      return highContrast ? SPColors.white : SPColors.gray200;
    } else {
      return highContrast ? SPColors.black : SPColors.gray800;
    }
  }

  /// Get border color for category items
  Color getCategoryBorderColor() {
    if (isDarkMode) {
      return highContrast ? SPColors.gray600 : SPColors.gray700;
    } else {
      return highContrast ? SPColors.gray400 : SPColors.gray300;
    }
  }

  /// Get animation duration based on reduce motion preference
  Duration getAnimationDuration({Duration defaultDuration = const Duration(milliseconds: 300)}) {
    return reduceMotion ? Duration.zero : defaultDuration;
  }

  /// Get chart animation curve
  Curve getAnimationCurve() {
    return reduceMotion ? Curves.linear : Curves.easeInOut;
  }

  /// Check if color combination is accessible
  bool isAccessible(Color foreground, Color background) {
    return CategoryMappingService.instance.hasGoodContrast(foreground, background);
  }

  /// Get accessible text color for given background
  Color getAccessibleTextColor(Color backgroundColor) {
    final backgroundLuminance = backgroundColor.computeLuminance();

    // Use white text on dark backgrounds, black text on light backgrounds
    if (backgroundLuminance > 0.5) {
      return highContrast ? SPColors.black : SPColors.gray800;
    } else {
      return highContrast ? SPColors.white : SPColors.gray200;
    }
  }

  /// Create a copy with modified properties
  CategoryThemeConfig copyWith({bool? isDarkMode, bool? highContrast, double? colorIntensity, bool? reduceMotion}) {
    return CategoryThemeConfig(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      highContrast: highContrast ?? this.highContrast,
      colorIntensity: colorIntensity ?? this.colorIntensity,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryThemeConfig &&
        other.isDarkMode == isDarkMode &&
        other.highContrast == highContrast &&
        other.colorIntensity == colorIntensity &&
        other.reduceMotion == reduceMotion;
  }

  @override
  int get hashCode {
    return Object.hash(isDarkMode, highContrast, colorIntensity, reduceMotion);
  }
}

/// Extension to provide category theme utilities
extension CategoryThemeExtension on BuildContext {
  /// Get category theme config from context
  CategoryThemeConfig get categoryTheme => CategoryThemeConfig.fromContext(this);
}
