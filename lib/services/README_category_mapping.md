# Category Color and Emoji Mapping System

This document explains how to use the new category color and emoji mapping system implemented for enhanced report visualization.

## Overview

The category mapping system provides consistent colors and emojis for exercise and diet categories, with support for theming, accessibility, and dynamic categories.

## Core Components

### 1. CategoryMappingService

The main service that handles color and emoji mapping for categories.

```dart
import 'package:seol_haru_check/services/category_mapping_service.dart';

final service = CategoryMappingService.instance;

// Get colors for known categories
final strengthColor = service.getExerciseCategoryColor(ExerciseCategory.strength);
final homeMadeColor = service.getDietCategoryColor(DietCategory.homeMade);

// Get colors by name (handles unknown categories too)
final exerciseColor = service.getCategoryColorByName('근력 운동', CategoryType.exercise);
final dietColor = service.getCategoryColorByName('집밥/도시락', CategoryType.diet);

// Get emojis
final strengthEmoji = service.getExerciseCategoryEmoji(ExerciseCategory.strength); // 💪
final homeMadeEmoji = service.getDietCategoryEmoji(DietCategory.homeMade); // 🍱
```

### 2. CategoryThemeConfig

Provides theme-aware color management with accessibility support.

```dart
import 'package:seol_haru_check/models/category_theme_config.dart';

// Create theme config from context
final theme = CategoryThemeConfig.fromContext(context);

// Or create manually
const theme = CategoryThemeConfig(
  isDarkMode: true,
  highContrast: true,
  colorIntensity: 0.8,
  reduceMotion: true,
);

// Get themed colors
final themedColor = theme.getExerciseCategoryColor(ExerciseCategory.strength);
final backgroundcolor = theme.getCategoryBackgroundColor();
final textColor = theme.getCategoryTextColor();
```

### 3. Category Extensions

Convenient extensions for easier usage throughout the app.

```dart
import 'package:seol_haru_check/extensions/category_extensions.dart';

// Direct color access
final color = ExerciseCategory.strength.color;
final themedColor = ExerciseCategory.strength.getThemedColor(theme);

// Create visualization data
final data = ExerciseCategory.strength.toVisualizationData(
  count: 5,
  percentage: 0.5,
);

// String extensions
final category = '근력 운동'.asExerciseCategory; // ExerciseCategory.strength
final isKnown = '근력 운동'.isKnownExerciseCategory; // true

// List extensions
final exerciseOnly = categoryList.exerciseCategories;
final topCategories = categoryList.topByCount(3);
final themedList = categoryList.withTheme(theme);
```

## Usage Examples

### Basic Color Mapping

```dart
// Get color for a specific exercise category
final strengthColor = CategoryMappingService.instance
    .getExerciseCategoryColor(ExerciseCategory.strength);

// Use in a widget
Container(
  color: strengthColor,
  child: Text('💪 근력 운동'),
)
```

### Theme-Aware Colors

```dart
Widget buildCategoryChip(BuildContext context, ExerciseCategory category) {
  final theme = context.categoryTheme;
  final color = theme.getExerciseCategoryColor(category);
  final textColor = theme.getAccessibleTextColor(color);
  
  return Chip(
    backgroundColor: color,
    label: Text(
      category.displayText,
      style: TextStyle(color: textColor),
    ),
  );
}
```

### Visualization Data Generation

```dart
// From raw category data
final categoryData = {
  '근력 운동': 5,
  '유산소 운동': 3,
  '스트레칭/요가': 2,
};

final visualizationData = CategoryMappingService.instance
    .getExerciseCategoryVisualizationData(categoryData);

// Use in charts
PieChart(
  data: visualizationData.map((data) => PieChartSectionData(
    value: data.count.toDouble(),
    color: data.color,
    title: data.emoji,
  )).toList(),
)
```

### Dynamic Category Handling

```dart
// The system automatically handles unknown categories
final unknownColor = CategoryMappingService.instance
    .getCategoryColorByName('Custom Exercise', CategoryType.exercise);
// Returns a consistent fallback color based on the name hash

final unknownEmoji = CategoryMappingService.instance
    .getCategoryEmojiByName('Custom Exercise', CategoryType.exercise);
// Returns '🏃' (default exercise emoji)
```

## Accessibility Features

### High Contrast Support

```dart
const highContrastTheme = CategoryThemeConfig(
  highContrast: true,
  isDarkMode: false,
);

final accessibleColor = highContrastTheme.getExerciseCategoryColor(
  ExerciseCategory.strength,
);
```

### Contrast Validation

```dart
final service = CategoryMappingService.instance;
final hasGoodContrast = service.hasGoodContrast(
  foregroundColor,
  backgroundColor,
); // Returns true if contrast ratio >= 4.5:1
```

### Reduced Motion

```dart
const reducedMotionTheme = CategoryThemeConfig(reduceMotion: true);

final animationDuration = reducedMotionTheme.getAnimationDuration();
// Returns Duration.zero when reduceMotion is true

final animationCurve = reducedMotionTheme.getAnimationCurve();
// Returns Curves.linear when reduceMotion is true
```

## Color Palettes

### Exercise Categories
- **근력 운동** (Strength): Red (#FF6B6B) 💪
- **유산소 운동** (Cardio): Teal (#4ECDC4) 🏃
- **스트레칭/요가** (Flexibility): Blue (#45B7D1) 🧘
- **구기/스포츠** (Sports): Orange (#FF9F43) ⚽
- **야외 활동** (Outdoor): Green (#96CEB4) 🏔️
- **댄스/무용** (Dance): Plum (#DDA0DD) 💃

### Diet Categories
- **집밥/도시락** (Home Made): Yellow (#FFD93D) 🍱
- **건강식/샐러드** (Healthy): Green (#6BCF7F) 🥗
- **단백질 위주** (Protein): Orange (#FF8A65) 🍗
- **간식/음료** (Snack): Purple (#BA68C8) 🍪
- **외식/배달** (Dining): Blue (#42A5F5) 🍽️
- **영양제/보충제** (Supplement): Cyan (#26C6DA) 💊

## Best Practices

1. **Always use the theme-aware methods** when building UI components
2. **Check contrast ratios** for accessibility compliance
3. **Use extensions** for cleaner, more readable code
4. **Handle unknown categories gracefully** - the system provides fallbacks
5. **Consider reduced motion preferences** in animations
6. **Test with different themes** (light/dark, high contrast)

## Integration with Charts

The system is designed to work seamlessly with chart libraries:

```dart
// For pie charts
final pieData = visualizationData.map((data) => PieChartSectionData(
  value: data.percentage,
  color: data.color,
  title: data.emoji,
  titleStyle: TextStyle(
    color: theme.getAccessibleTextColor(data.color),
  ),
)).toList();

// For bar charts
final barData = visualizationData.map((data) => BarChartGroupData(
  x: data.categoryName.hashCode,
  barRods: [
    BarChartRodData(
      toY: data.count.toDouble(),
      color: data.color,
    ),
  ],
)).toList();
```

This system ensures consistent, accessible, and theme-aware category visualization throughout the application.