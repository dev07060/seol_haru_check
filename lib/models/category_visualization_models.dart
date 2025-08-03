import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/services/category_mapping_service.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Enum for category types used in visualization
enum CategoryType {
  exercise,
  diet;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case CategoryType.exercise:
        return '운동';
      case CategoryType.diet:
        return '식단';
    }
  }

  /// Get icon for category type
  IconData get icon {
    switch (this) {
      case CategoryType.exercise:
        return Icons.fitness_center;
      case CategoryType.diet:
        return Icons.restaurant;
    }
  }
}

/// Enum for trend direction indicators
enum TrendDirection {
  up,
  down,
  stable;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case TrendDirection.up:
        return '증가';
      case TrendDirection.down:
        return '감소';
      case TrendDirection.stable:
        return '유지';
    }
  }

  /// Get icon for trend direction
  IconData get icon {
    switch (this) {
      case TrendDirection.up:
        return Icons.trending_up;
      case TrendDirection.down:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  /// Get color for trend direction
  Color get color {
    switch (this) {
      case TrendDirection.up:
        return SPColors.success100;
      case TrendDirection.down:
        return SPColors.danger100;
      case TrendDirection.stable:
        return SPColors.gray600;
    }
  }
}

/// Model for subcategory data in hierarchical displays
class SubcategoryData {
  final String name;
  final int count;
  final double percentage;
  final String? description;
  final String? emoji;

  const SubcategoryData({
    required this.name,
    required this.count,
    required this.percentage,
    this.description,
    this.emoji,
  });

  /// Create from map data
  factory SubcategoryData.fromMap(Map<String, dynamic> map) {
    return SubcategoryData(
      name: map['name'] ?? '',
      count: map['count'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      description: map['description'],
      emoji: map['emoji'],
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'count': count,
      'percentage': percentage,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
    };
  }

  /// Copy with modifications
  SubcategoryData copyWith({String? name, int? count, double? percentage, String? description, String? emoji}) {
    return SubcategoryData(
      name: name ?? this.name,
      count: count ?? this.count,
      percentage: percentage ?? this.percentage,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubcategoryData &&
        other.name == name &&
        other.count == count &&
        other.percentage == percentage &&
        other.description == description &&
        other.emoji == emoji;
  }

  @override
  int get hashCode {
    return name.hashCode ^ count.hashCode ^ percentage.hashCode ^ description.hashCode ^ emoji.hashCode;
  }

  @override
  String toString() {
    return 'SubcategoryData(name: $name, count: $count, percentage: $percentage, description: $description, emoji: $emoji)';
  }
}

/// Model for category visualization data with emoji and color support
class CategoryVisualizationData {
  final String categoryName;
  final String emoji;
  final int count;
  final double percentage;
  final Color color;
  final CategoryType type;
  final List<SubcategoryData> subcategories;
  final String? description;
  final bool isActive;

  const CategoryVisualizationData({
    required this.categoryName,
    required this.emoji,
    required this.count,
    required this.percentage,
    required this.color,
    required this.type,
    this.subcategories = const [],
    this.description,
    this.isActive = true,
  });

  /// Create from exercise category
  factory CategoryVisualizationData.fromExerciseCategory(
    ExerciseCategory category,
    int count,
    double percentage,
    Color color, {
    List<SubcategoryData> subcategories = const [],
    String? description,
    bool isActive = true,
  }) {
    return CategoryVisualizationData(
      categoryName: category.displayName,
      emoji: category.emoji,
      count: count,
      percentage: percentage,
      color: color,
      type: CategoryType.exercise,
      subcategories: subcategories,
      description: description,
      isActive: isActive,
    );
  }

  /// Create from diet category
  factory CategoryVisualizationData.fromDietCategory(
    DietCategory category,
    int count,
    double percentage,
    Color color, {
    List<SubcategoryData> subcategories = const [],
    String? description,
    bool isActive = true,
  }) {
    return CategoryVisualizationData(
      categoryName: category.displayName,
      emoji: category.emoji,
      count: count,
      percentage: percentage,
      color: color,
      type: CategoryType.diet,
      subcategories: subcategories,
      description: description,
      isActive: isActive,
    );
  }

  /// Create from map data
  factory CategoryVisualizationData.fromMap(Map<String, dynamic> map) {
    return CategoryVisualizationData(
      categoryName: map['categoryName'] ?? '',
      emoji: map['emoji'] ?? '',
      count: map['count'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      // ignore: deprecated_member_use
      color: Color(map['color'] ?? SPColors.gray400.value),
      type: CategoryType.values.firstWhere((type) => type.name == map['type'], orElse: () => CategoryType.exercise),
      subcategories:
          (map['subcategories'] as List<dynamic>?)?.map((item) => SubcategoryData.fromMap(item)).toList() ?? [],
      description: map['description'],
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'emoji': emoji,
      'count': count,
      'percentage': percentage,
      // ignore: deprecated_member_use
      'color': color.value,
      'type': type.name,
      'subcategories': subcategories.map((sub) => sub.toMap()).toList(),
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  /// Get total subcategory count
  int get totalSubcategoryCount {
    return subcategories.fold(0, (sum, sub) => sum + sub.count);
  }

  /// Check if has subcategories
  bool get hasSubcategories => subcategories.isNotEmpty;

  /// Get formatted percentage string
  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }

  /// Get display text with emoji
  String get displayText {
    return '$emoji $categoryName';
  }

  /// Copy with modifications
  CategoryVisualizationData copyWith({
    String? categoryName,
    String? emoji,
    int? count,
    double? percentage,
    Color? color,
    CategoryType? type,
    List<SubcategoryData>? subcategories,
    String? description,
    bool? isActive,
  }) {
    return CategoryVisualizationData(
      categoryName: categoryName ?? this.categoryName,
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      percentage: percentage ?? this.percentage,
      color: color ?? this.color,
      type: type ?? this.type,
      subcategories: subcategories ?? this.subcategories,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryVisualizationData &&
        other.categoryName == categoryName &&
        other.emoji == emoji &&
        other.count == count &&
        other.percentage == percentage &&
        other.color == color &&
        other.type == type &&
        other.subcategories == subcategories &&
        other.description == description &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return categoryName.hashCode ^
        emoji.hashCode ^
        count.hashCode ^
        percentage.hashCode ^
        color.hashCode ^
        type.hashCode ^
        subcategories.hashCode ^
        description.hashCode ^
        isActive.hashCode;
  }

  @override
  String toString() {
    return 'CategoryVisualizationData(categoryName: $categoryName, emoji: $emoji, count: $count, percentage: $percentage, type: $type, subcategories: ${subcategories.length})';
  }
}

/// Model for category trend analysis data
class CategoryTrendData {
  final Map<String, TrendDirection> exerciseCategoryTrends;
  final Map<String, TrendDirection> dietCategoryTrends;
  final Map<String, double> categoryChangePercentages;
  final List<String> emergingCategories;
  final List<String> decliningCategories;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryTrendData({
    required this.exerciseCategoryTrends,
    required this.dietCategoryTrends,
    required this.categoryChangePercentages,
    required this.emergingCategories,
    required this.decliningCategories,
    required this.analysisDate,
    this.weeksAnalyzed = 4,
  });

  /// Create empty trend data
  factory CategoryTrendData.empty() {
    return CategoryTrendData(
      exerciseCategoryTrends: {},
      dietCategoryTrends: {},
      categoryChangePercentages: {},
      emergingCategories: [],
      decliningCategories: [],
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }

  /// Create from map data
  factory CategoryTrendData.fromMap(Map<String, dynamic> map) {
    return CategoryTrendData(
      exerciseCategoryTrends: Map<String, TrendDirection>.from(
        (map['exerciseCategoryTrends'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                TrendDirection.values.firstWhere((trend) => trend.name == value, orElse: () => TrendDirection.stable),
              ),
            ) ??
            {},
      ),
      dietCategoryTrends: Map<String, TrendDirection>.from(
        (map['dietCategoryTrends'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                TrendDirection.values.firstWhere((trend) => trend.name == value, orElse: () => TrendDirection.stable),
              ),
            ) ??
            {},
      ),
      categoryChangePercentages: Map<String, double>.from(
        (map['categoryChangePercentages'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
      emergingCategories: List<String>.from(map['emergingCategories'] ?? []),
      decliningCategories: List<String>.from(map['decliningCategories'] ?? []),
      analysisDate: DateTime.parse(map['analysisDate'] ?? DateTime.now().toIso8601String()),
      weeksAnalyzed: map['weeksAnalyzed'] ?? 4,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'exerciseCategoryTrends': exerciseCategoryTrends.map((key, value) => MapEntry(key, value.name)),
      'dietCategoryTrends': dietCategoryTrends.map((key, value) => MapEntry(key, value.name)),
      'categoryChangePercentages': categoryChangePercentages,
      'emergingCategories': emergingCategories,
      'decliningCategories': decliningCategories,
      'analysisDate': analysisDate.toIso8601String(),
      'weeksAnalyzed': weeksAnalyzed,
    };
  }

  /// Get trend for specific category
  TrendDirection? getTrendForCategory(String categoryName, CategoryType type) {
    switch (type) {
      case CategoryType.exercise:
        return exerciseCategoryTrends[categoryName];
      case CategoryType.diet:
        return dietCategoryTrends[categoryName];
    }
  }

  /// Get change percentage for category
  double getChangePercentageForCategory(String categoryName) {
    return categoryChangePercentages[categoryName] ?? 0.0;
  }

  /// Check if category is emerging
  bool isCategoryEmerging(String categoryName) {
    return emergingCategories.contains(categoryName);
  }

  /// Check if category is declining
  bool isCategoryDeclining(String categoryName) {
    return decliningCategories.contains(categoryName);
  }

  /// Get all trending categories (both emerging and declining)
  List<String> get allTrendingCategories {
    return [...emergingCategories, ...decliningCategories];
  }

  /// Get total categories analyzed
  int get totalCategoriesAnalyzed {
    return exerciseCategoryTrends.length + dietCategoryTrends.length;
  }

  /// Check if has trend data
  bool get hasTrendData {
    return exerciseCategoryTrends.isNotEmpty || dietCategoryTrends.isNotEmpty;
  }

  /// Copy with modifications
  CategoryTrendData copyWith({
    Map<String, TrendDirection>? exerciseCategoryTrends,
    Map<String, TrendDirection>? dietCategoryTrends,
    Map<String, double>? categoryChangePercentages,
    List<String>? emergingCategories,
    List<String>? decliningCategories,
    DateTime? analysisDate,
    int? weeksAnalyzed,
  }) {
    return CategoryTrendData(
      exerciseCategoryTrends: exerciseCategoryTrends ?? this.exerciseCategoryTrends,
      dietCategoryTrends: dietCategoryTrends ?? this.dietCategoryTrends,
      categoryChangePercentages: categoryChangePercentages ?? this.categoryChangePercentages,
      emergingCategories: emergingCategories ?? this.emergingCategories,
      decliningCategories: decliningCategories ?? this.decliningCategories,
      analysisDate: analysisDate ?? this.analysisDate,
      weeksAnalyzed: weeksAnalyzed ?? this.weeksAnalyzed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryTrendData &&
        other.exerciseCategoryTrends == exerciseCategoryTrends &&
        other.dietCategoryTrends == dietCategoryTrends &&
        other.categoryChangePercentages == categoryChangePercentages &&
        other.emergingCategories == emergingCategories &&
        other.decliningCategories == decliningCategories &&
        other.analysisDate == analysisDate &&
        other.weeksAnalyzed == weeksAnalyzed;
  }

  @override
  int get hashCode {
    return exerciseCategoryTrends.hashCode ^
        dietCategoryTrends.hashCode ^
        categoryChangePercentages.hashCode ^
        emergingCategories.hashCode ^
        decliningCategories.hashCode ^
        analysisDate.hashCode ^
        weeksAnalyzed.hashCode;
  }

  @override
  String toString() {
    return 'CategoryTrendData(exerciseTrends: ${exerciseCategoryTrends.length}, dietTrends: ${dietCategoryTrends.length}, emerging: ${emergingCategories.length}, declining: ${decliningCategories.length}, weeksAnalyzed: $weeksAnalyzed)';
  }
}

/// Model for detailed category trend analysis
class CategoryTrendAnalysis {
  final Map<String, CategoryTrendMetrics> exerciseCategoryTrends;
  final Map<String, CategoryTrendMetrics> dietCategoryTrends;
  final TrendDirection overallTrendDirection;
  final double trendStrength;
  final double analysisConfidence;
  final double trendVelocity;
  final int weeksAnalyzed;
  final DateTime analysisDate;

  const CategoryTrendAnalysis({
    required this.exerciseCategoryTrends,
    required this.dietCategoryTrends,
    required this.overallTrendDirection,
    required this.trendStrength,
    required this.analysisConfidence,
    required this.trendVelocity,
    required this.weeksAnalyzed,
    required this.analysisDate,
  });

  /// Create empty trend analysis
  factory CategoryTrendAnalysis.empty() {
    return CategoryTrendAnalysis(
      exerciseCategoryTrends: {},
      dietCategoryTrends: {},
      overallTrendDirection: TrendDirection.stable,
      trendStrength: 0.0,
      analysisConfidence: 0.0,
      trendVelocity: 0.0,
      weeksAnalyzed: 0,
      analysisDate: DateTime.now(),
    );
  }

  /// Get all category trends combined
  Map<String, CategoryTrendMetrics> get allCategoryTrends {
    return {...exerciseCategoryTrends, ...dietCategoryTrends};
  }

  /// Check if has sufficient data for analysis
  bool get hasSufficientData => weeksAnalyzed >= 2;

  /// Get trending up categories
  List<String> get trendingUpCategories {
    return allCategoryTrends.entries
        .where((entry) => entry.value.direction == TrendDirection.up)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get trending down categories
  List<String> get trendingDownCategories {
    return allCategoryTrends.entries
        .where((entry) => entry.value.direction == TrendDirection.down)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Model for individual category trend metrics
class CategoryTrendMetrics {
  final String categoryName;
  final CategoryType categoryType;
  final TrendDirection direction;
  final double changePercentage;
  final double trendStrength;
  final double volatility;
  final double momentum;
  final int currentValue;
  final int previousValue;
  final double historicalAverage;

  const CategoryTrendMetrics({
    required this.categoryName,
    required this.categoryType,
    required this.direction,
    required this.changePercentage,
    required this.trendStrength,
    required this.volatility,
    required this.momentum,
    required this.currentValue,
    required this.previousValue,
    required this.historicalAverage,
  });

  /// Create stable trend metrics
  factory CategoryTrendMetrics.stable(String categoryName, CategoryType type) {
    return CategoryTrendMetrics(
      categoryName: categoryName,
      categoryType: type,
      direction: TrendDirection.stable,
      changePercentage: 0.0,
      trendStrength: 0.0,
      volatility: 0.0,
      momentum: 0.0,
      currentValue: 0,
      previousValue: 0,
      historicalAverage: 0.0,
    );
  }

  /// Check if trend is significant
  bool get isSignificantTrend => trendStrength > 0.5 && changePercentage.abs() > 20;

  /// Get trend description
  String get trendDescription {
    if (direction == TrendDirection.stable) {
      return '안정적';
    } else if (direction == TrendDirection.up) {
      return '증가 추세 (+${changePercentage.toStringAsFixed(1)}%)';
    } else {
      return '감소 추세 (${changePercentage.toStringAsFixed(1)}%)';
    }
  }
}

/// Model for category emergence analysis
class CategoryEmergenceAnalysis {
  final List<EmergingCategory> emergingCategories;
  final List<DecliningCategory> decliningCategories;
  final Map<String, CategoryLifecycle> lifecyclePatterns;
  final double emergenceConfidence;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryEmergenceAnalysis({
    required this.emergingCategories,
    required this.decliningCategories,
    required this.lifecyclePatterns,
    required this.emergenceConfidence,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  /// Create empty emergence analysis
  factory CategoryEmergenceAnalysis.empty() {
    return CategoryEmergenceAnalysis(
      emergingCategories: [],
      decliningCategories: [],
      lifecyclePatterns: {},
      emergenceConfidence: 0.0,
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }

  /// Check if has emergence patterns
  bool get hasEmergencePatterns => emergingCategories.isNotEmpty || decliningCategories.isNotEmpty;

  /// Get total categories in transition
  int get totalCategoriesInTransition => emergingCategories.length + decliningCategories.length;
}

/// Model for emerging category
class EmergingCategory {
  final String categoryName;
  final CategoryType categoryType;
  final int currentCount;
  final double historicalAverage;
  final double emergenceStrength;
  final bool isNewCategory;
  final int weeksActive;

  const EmergingCategory({
    required this.categoryName,
    required this.categoryType,
    required this.currentCount,
    required this.historicalAverage,
    required this.emergenceStrength,
    required this.isNewCategory,
    required this.weeksActive,
  });

  /// Get emergence description
  String get emergenceDescription {
    if (isNewCategory) {
      return '$categoryName이(가) 새롭게 시작되었습니다';
    } else {
      return '$categoryName이(가) ${(emergenceStrength * 100).toStringAsFixed(0)}% 증가했습니다';
    }
  }
}

/// Model for declining category
class DecliningCategory {
  final String categoryName;
  final CategoryType categoryType;
  final int currentCount;
  final double historicalAverage;
  final double declineStrength;
  final bool hasDisappeared;
  final int weeksInactive;

  const DecliningCategory({
    required this.categoryName,
    required this.categoryType,
    required this.currentCount,
    required this.historicalAverage,
    required this.declineStrength,
    required this.hasDisappeared,
    required this.weeksInactive,
  });

  /// Get decline description
  String get declineDescription {
    if (hasDisappeared) {
      return '$categoryName 활동이 중단되었습니다';
    } else {
      return '$categoryName이(가) ${(declineStrength * 100).toStringAsFixed(0)}% 감소했습니다';
    }
  }
}

/// Enum for category lifecycle stages
enum CategoryLifecycleStage {
  experimental,
  developing,
  mature,
  declining,
  dormant;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case CategoryLifecycleStage.experimental:
        return '실험적';
      case CategoryLifecycleStage.developing:
        return '발전 중';
      case CategoryLifecycleStage.mature:
        return '성숙';
      case CategoryLifecycleStage.declining:
        return '감소 중';
      case CategoryLifecycleStage.dormant:
        return '휴면';
    }
  }

  /// Get description
  String get description {
    switch (this) {
      case CategoryLifecycleStage.experimental:
        return '가끔씩 시도해보는 단계';
      case CategoryLifecycleStage.developing:
        return '꾸준히 늘려가는 단계';
      case CategoryLifecycleStage.mature:
        return '안정적으로 유지하는 단계';
      case CategoryLifecycleStage.declining:
        return '점차 줄어드는 단계';
      case CategoryLifecycleStage.dormant:
        return '현재 하지 않는 단계';
    }
  }
}

/// Model for category lifecycle
class CategoryLifecycle {
  final String categoryName;
  final CategoryType categoryType;
  final CategoryLifecycleStage stage;
  final int activeWeeks;
  final int totalWeeks;
  final double activityRatio;
  final int peakCount;
  final int currentCount;

  const CategoryLifecycle({
    required this.categoryName,
    required this.categoryType,
    required this.stage,
    required this.activeWeeks,
    required this.totalWeeks,
    required this.activityRatio,
    required this.peakCount,
    required this.currentCount,
  });

  /// Get lifecycle description
  String get lifecycleDescription {
    return '$categoryName: ${stage.displayName} (${(activityRatio * 100).toStringAsFixed(0)}% 활동률)';
  }

  /// Check if category is active
  bool get isActive => currentCount > 0;

  /// Check if category is at peak
  bool get isAtPeak => currentCount >= peakCount * 0.9;
}

/// Model for category preference patterns
class CategoryPreferencePatterns {
  final Map<String, PreferenceMetrics> exercisePreferences;
  final Map<String, PreferenceMetrics> dietPreferences;
  final Map<String, SeasonalPattern> seasonalPatterns;
  final PreferenceStabilityMetrics preferenceStability;
  final List<PreferenceCluster> preferenceClusters;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryPreferencePatterns({
    required this.exercisePreferences,
    required this.dietPreferences,
    required this.seasonalPatterns,
    required this.preferenceStability,
    required this.preferenceClusters,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  /// Create empty preference patterns
  factory CategoryPreferencePatterns.empty() {
    return CategoryPreferencePatterns(
      exercisePreferences: {},
      dietPreferences: {},
      seasonalPatterns: {},
      preferenceStability: PreferenceStabilityMetrics.empty(),
      preferenceClusters: [],
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }

  /// Get all preferences combined
  Map<String, PreferenceMetrics> get allPreferences {
    return {...exercisePreferences, ...dietPreferences};
  }

  /// Get top preferences by intensity
  List<PreferenceMetrics> getTopPreferences(int count) {
    final allPrefs = allPreferences.values.toList();
    allPrefs.sort((a, b) => b.intensity.compareTo(a.intensity));
    return allPrefs.take(count).toList();
  }
}

/// Model for preference metrics
class PreferenceMetrics {
  final String categoryName;
  final CategoryType categoryType;
  final int totalCount;
  final int frequency;
  final double consistency;
  final double intensity;
  final int currentCount;
  final double historicalAverage;

  const PreferenceMetrics({
    required this.categoryName,
    required this.categoryType,
    required this.totalCount,
    required this.frequency,
    required this.consistency,
    required this.intensity,
    required this.currentCount,
    required this.historicalAverage,
  });

  /// Get preference strength (0-1)
  double get preferenceStrength => (consistency + intensity) / 2;

  /// Get preference description
  String get preferenceDescription {
    if (preferenceStrength > 0.8) {
      return '$categoryName을(를) 매우 선호합니다';
    } else if (preferenceStrength > 0.6) {
      return '$categoryName을(를) 선호합니다';
    } else if (preferenceStrength > 0.4) {
      return '$categoryName을(를) 가끔 선택합니다';
    } else {
      return '$categoryName을(를) 드물게 선택합니다';
    }
  }
}

/// Model for seasonal pattern
class SeasonalPattern {
  final String categoryName;
  final CategoryType categoryType;
  final Map<int, double> monthlyIntensity; // month -> intensity
  final String patternDescription;
  final double seasonalStrength;

  const SeasonalPattern({
    required this.categoryName,
    required this.categoryType,
    required this.monthlyIntensity,
    required this.patternDescription,
    required this.seasonalStrength,
  });
}

/// Model for preference stability metrics
class PreferenceStabilityMetrics {
  final double overallStability;
  final double exerciseStability;
  final double dietStability;
  final TrendDirection stabilityTrend;
  final int weeksAnalyzed;

  const PreferenceStabilityMetrics({
    required this.overallStability,
    required this.exerciseStability,
    required this.dietStability,
    required this.stabilityTrend,
    required this.weeksAnalyzed,
  });

  /// Create empty stability metrics
  factory PreferenceStabilityMetrics.empty() {
    return const PreferenceStabilityMetrics(
      overallStability: 0.0,
      exerciseStability: 0.0,
      dietStability: 0.0,
      stabilityTrend: TrendDirection.stable,
      weeksAnalyzed: 0,
    );
  }

  /// Get stability description
  String get stabilityDescription {
    if (overallStability > 0.8) {
      return '매우 안정적인 선호 패턴';
    } else if (overallStability > 0.6) {
      return '안정적인 선호 패턴';
    } else if (overallStability > 0.4) {
      return '변화하는 선호 패턴';
    } else {
      return '불안정한 선호 패턴';
    }
  }
}

/// Model for preference cluster
class PreferenceCluster {
  final String name;
  final List<String> categories;
  final CategoryType categoryType;
  final double strength;
  final double consistency;

  const PreferenceCluster({
    required this.name,
    required this.categories,
    required this.categoryType,
    required this.strength,
    required this.consistency,
  });

  /// Get cluster description
  String get clusterDescription {
    return '$name: ${categories.join(', ')} (강도: ${(strength * 100).toStringAsFixed(0)}%)';
  }
}

/// Model for unified bar chart data that combines exercise and diet categories
class UnifiedBarData {
  final List<CategoryVisualizationData> exerciseCategories;
  final List<CategoryVisualizationData> dietCategories;
  final int totalCount;
  final List<BarSegmentData> segments;

  UnifiedBarData({required this.exerciseCategories, required this.dietCategories})
    : totalCount =
          exerciseCategories.fold(0, (sum, item) => sum + item.count) +
          dietCategories.fold(0, (sum, item) => sum + item.count),
      segments = _calculateSegments(exerciseCategories, dietCategories);

  /// Calculate percentage for a specific category
  double getPercentage(CategoryVisualizationData category) {
    return totalCount > 0 ? (category.count / totalCount) * 100 : 0.0;
  }

  /// Get all categories combined
  List<CategoryVisualizationData> get allCategories {
    return [...exerciseCategories, ...dietCategories];
  }

  /// Check if has any data
  bool get hasData => totalCount > 0;

  /// Check if has exercise data
  bool get hasExerciseData => exerciseCategories.isNotEmpty && exerciseCategories.any((cat) => cat.count > 0);

  /// Check if has diet data
  bool get hasDietData => dietCategories.isNotEmpty && dietCategories.any((cat) => cat.count > 0);

  /// Get exercise total count
  int get exerciseTotalCount => exerciseCategories.fold(0, (sum, item) => sum + item.count);

  /// Get diet total count
  int get dietTotalCount => dietCategories.fold(0, (sum, item) => sum + item.count);

  /// Get exercise percentage of total
  double get exercisePercentage => totalCount > 0 ? (exerciseTotalCount / totalCount) * 100 : 0.0;

  /// Get diet percentage of total
  double get dietPercentage => totalCount > 0 ? (dietTotalCount / totalCount) * 100 : 0.0;

  /// Calculate segments for bar chart rendering
  static List<BarSegmentData> _calculateSegments(
    List<CategoryVisualizationData> exerciseCategories,
    List<CategoryVisualizationData> dietCategories,
  ) {
    final allCategories = [...exerciseCategories, ...dietCategories];
    final totalCount = allCategories.fold(0, (sum, item) => sum + item.count);

    if (totalCount == 0) return [];

    final segments = <BarSegmentData>[];
    double currentPosition = 0.0;

    // Sort categories by count (descending) for better visual hierarchy
    allCategories.sort((a, b) => b.count.compareTo(a.count));

    for (final category in allCategories) {
      if (category.count > 0) {
        final percentage = (category.count / totalCount) * 100;
        final width = percentage; // Width as percentage

        segments.add(
          BarSegmentData(
            category: category,
            percentage: percentage,
            startPosition: currentPosition,
            width: width,
            color: category.color,
            emoji: category.emoji,
          ),
        );

        currentPosition += width;
      }
    }

    return segments;
  }

  /// Create empty unified bar data
  factory UnifiedBarData.empty() {
    return UnifiedBarData(exerciseCategories: [], dietCategories: []);
  }

  /// Copy with modifications
  UnifiedBarData copyWith({
    List<CategoryVisualizationData>? exerciseCategories,
    List<CategoryVisualizationData>? dietCategories,
  }) {
    return UnifiedBarData(
      exerciseCategories: exerciseCategories ?? this.exerciseCategories,
      dietCategories: dietCategories ?? this.dietCategories,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedBarData &&
        other.exerciseCategories == exerciseCategories &&
        other.dietCategories == dietCategories;
  }

  @override
  int get hashCode {
    return exerciseCategories.hashCode ^ dietCategories.hashCode;
  }

  @override
  String toString() {
    return 'UnifiedBarData(exerciseCategories: ${exerciseCategories.length}, dietCategories: ${dietCategories.length}, totalCount: $totalCount)';
  }
}

/// Model for individual bar segment data with position and size calculations
class BarSegmentData {
  final CategoryVisualizationData category;
  final double percentage;
  final double startPosition;
  final double width;
  final Color color;
  final String emoji;
  final double minWidth;

  const BarSegmentData({
    required this.category,
    required this.percentage,
    required this.startPosition,
    required this.width,
    required this.color,
    required this.emoji,
    this.minWidth = 5.0, // Minimum 5% width for visibility
  });

  /// Get effective width (ensuring minimum width for small segments)
  double get effectiveWidth => width < minWidth ? minWidth : width;

  /// Get end position
  double get endPosition => startPosition + effectiveWidth;

  /// Check if segment is small (less than minimum width)
  bool get isSmallSegment => width < minWidth;

  /// Get display text for segment
  String get displayText => '$emoji ${category.categoryName}';

  /// Get formatted percentage string
  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  /// Get category type
  CategoryType get categoryType => category.type;

  /// Check if segment is exercise type
  bool get isExercise => category.type == CategoryType.exercise;

  /// Check if segment is diet type
  bool get isDiet => category.type == CategoryType.diet;

  /// Get segment bounds for hit testing
  bool containsPosition(double position) {
    return position >= startPosition && position <= endPosition;
  }

  /// Get darker color for hover/selection states with enhanced accessibility
  Color get darkerColor {
    return SPColors.getDarkerShade(color, 0.2);
  }

  /// Get lighter color for subtle effects
  Color get lighterColor {
    return SPColors.getLighterShade(color, 0.2);
  }

  /// Get color with enhanced contrast for accessibility (4.5:1 ratio)
  Color getAccessibleColor(Color backgroundColor) {
    // Check if current color has sufficient contrast
    if (_hasGoodContrast(color, backgroundColor)) {
      return color;
    }

    // If not, return a darker or lighter version that meets contrast requirements
    final colorLuminance = color.computeLuminance();
    final backgroundLuminance = backgroundColor.computeLuminance();

    if (backgroundLuminance > 0.5) {
      // Light background - use darker color
      return SPColors.getDarkerShade(color, 0.4);
    } else {
      // Dark background - use lighter color
      return SPColors.getLighterShade(color, 0.4);
    }
  }

  /// Check if color has sufficient contrast ratio (4.5:1 for WCAG AA)
  bool _hasGoodContrast(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;

    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= 4.5;
  }

  /// Copy with modifications
  BarSegmentData copyWith({
    CategoryVisualizationData? category,
    double? percentage,
    double? startPosition,
    double? width,
    Color? color,
    String? emoji,
    double? minWidth,
  }) {
    return BarSegmentData(
      category: category ?? this.category,
      percentage: percentage ?? this.percentage,
      startPosition: startPosition ?? this.startPosition,
      width: width ?? this.width,
      color: color ?? this.color,
      emoji: emoji ?? this.emoji,
      minWidth: minWidth ?? this.minWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarSegmentData &&
        other.category == category &&
        other.percentage == percentage &&
        other.startPosition == startPosition &&
        other.width == width &&
        other.color == color &&
        other.emoji == emoji &&
        other.minWidth == minWidth;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        percentage.hashCode ^
        startPosition.hashCode ^
        width.hashCode ^
        color.hashCode ^
        emoji.hashCode ^
        minWidth.hashCode;
  }

  @override
  String toString() {
    return 'BarSegmentData(category: ${category.categoryName}, percentage: ${percentage.toStringAsFixed(1)}%, position: ${startPosition.toStringAsFixed(1)}-${endPosition.toStringAsFixed(1)})';
  }
}

/// Model for category diversity analysis
class CategoryDiversityAnalysis {
  final double currentDiversityScore;
  final TrendDirection diversityTrend;
  final List<DiversityRecommendation> recommendations;
  final DiversityBalance diversityBalance;
  final List<DiversityPattern> diversityPatterns;
  final OptimalDiversityTargets optimalTargets;
  final DateTime analysisDate;
  final int weeksAnalyzed;

  const CategoryDiversityAnalysis({
    required this.currentDiversityScore,
    required this.diversityTrend,
    required this.recommendations,
    required this.diversityBalance,
    required this.diversityPatterns,
    required this.optimalTargets,
    required this.analysisDate,
    required this.weeksAnalyzed,
  });

  /// Create empty diversity analysis
  factory CategoryDiversityAnalysis.empty() {
    return CategoryDiversityAnalysis(
      currentDiversityScore: 0.0,
      diversityTrend: TrendDirection.stable,
      recommendations: [],
      diversityBalance: DiversityBalance.empty(),
      diversityPatterns: [],
      optimalTargets: OptimalDiversityTargets.empty(),
      analysisDate: DateTime.now(),
      weeksAnalyzed: 0,
    );
  }

  /// Get diversity level description
  String get diversityLevelDescription {
    if (currentDiversityScore > 0.8) {
      return '매우 다양한 활동';
    } else if (currentDiversityScore > 0.6) {
      return '다양한 활동';
    } else if (currentDiversityScore > 0.4) {
      return '보통 수준의 다양성';
    } else if (currentDiversityScore > 0.2) {
      return '제한적인 다양성';
    } else {
      return '단조로운 활동';
    }
  }

  /// Get high priority recommendations
  List<DiversityRecommendation> get highPriorityRecommendations {
    return recommendations.where((r) => r.priority == RecommendationPriority.high).toList();
  }
}

/// Enum for diversity recommendation type
enum DiversityRecommendationType {
  addCategory,
  balanceCategories,
  increaseFrequency,
  maintainDiversity;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case DiversityRecommendationType.addCategory:
        return '카테고리 추가';
      case DiversityRecommendationType.balanceCategories:
        return '카테고리 균형';
      case DiversityRecommendationType.increaseFrequency:
        return '빈도 증가';
      case DiversityRecommendationType.maintainDiversity:
        return '다양성 유지';
    }
  }
}

/// Enum for recommendation priority
enum RecommendationPriority {
  low,
  medium,
  high;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case RecommendationPriority.low:
        return '낮음';
      case RecommendationPriority.medium:
        return '보통';
      case RecommendationPriority.high:
        return '높음';
    }
  }
}

/// Model for diversity recommendation
class DiversityRecommendation {
  final DiversityRecommendationType type;
  final String categoryName;
  final CategoryType categoryType;
  final RecommendationPriority priority;
  final String reason;
  final double expectedImpact;

  const DiversityRecommendation({
    required this.type,
    required this.categoryName,
    required this.categoryType,
    required this.priority,
    required this.reason,
    required this.expectedImpact,
  });

  /// Get recommendation description
  String get recommendationDescription {
    return '${type.displayName}: $reason (예상 효과: ${(expectedImpact * 100).toStringAsFixed(0)}%)';
  }
}

/// Model for diversity balance
class DiversityBalance {
  final double overallBalance;
  final double exerciseBalance;
  final double dietBalance;
  final double balanceScore;

  const DiversityBalance({
    required this.overallBalance,
    required this.exerciseBalance,
    required this.dietBalance,
    required this.balanceScore,
  });

  /// Create empty diversity balance
  factory DiversityBalance.empty() {
    return const DiversityBalance(overallBalance: 0.0, exerciseBalance: 0.0, dietBalance: 0.0, balanceScore: 0.0);
  }

  /// Get balance description
  String get balanceDescription {
    if (balanceScore > 0.8) {
      return '매우 균형잡힌 활동';
    } else if (balanceScore > 0.6) {
      return '균형잡힌 활동';
    } else if (balanceScore > 0.4) {
      return '보통 수준의 균형';
    } else {
      return '불균형한 활동';
    }
  }
}

/// Enum for diversity pattern type
enum DiversityPatternType {
  increasing,
  decreasing,
  stable,
  cyclical;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case DiversityPatternType.increasing:
        return '증가 패턴';
      case DiversityPatternType.decreasing:
        return '감소 패턴';
      case DiversityPatternType.stable:
        return '안정 패턴';
      case DiversityPatternType.cyclical:
        return '주기적 패턴';
    }
  }
}

/// Model for diversity pattern
class DiversityPattern {
  final DiversityPatternType type;
  final double strength;
  final String description;
  final int weeksObserved;

  const DiversityPattern({
    required this.type,
    required this.strength,
    required this.description,
    required this.weeksObserved,
  });

  /// Get pattern description
  String get patternDescription {
    return '${type.displayName}: $description (강도: ${(strength * 100).toStringAsFixed(0)}%)';
  }
}

/// Model for optimal diversity targets
class OptimalDiversityTargets {
  final double currentScore;
  final double shortTermTarget;
  final double longTermTarget;
  final int optimalExerciseCategories;
  final int optimalDietCategories;
  final double targetBalance;

  const OptimalDiversityTargets({
    required this.currentScore,
    required this.shortTermTarget,
    required this.longTermTarget,
    required this.optimalExerciseCategories,
    required this.optimalDietCategories,
    required this.targetBalance,
  });

  /// Create empty optimal targets
  factory OptimalDiversityTargets.empty() {
    return const OptimalDiversityTargets(
      currentScore: 0.0,
      shortTermTarget: 0.0,
      longTermTarget: 0.0,
      optimalExerciseCategories: 0,
      optimalDietCategories: 0,
      targetBalance: 0.0,
    );
  }

  /// Get progress to short term target
  double get shortTermProgress => shortTermTarget > 0 ? currentScore / shortTermTarget : 0.0;

  /// Get progress to long term target
  double get longTermProgress => longTermTarget > 0 ? currentScore / longTermTarget : 0.0;

  /// Get target description
  String get targetDescription {
    return '단기 목표: ${(shortTermTarget * 100).toStringAsFixed(0)}%, 장기 목표: ${(longTermTarget * 100).toStringAsFixed(0)}%';
  }
}

/// Utility class for category color management
/// @deprecated Use CategoryMappingService instead
class CategoryColorUtils {
  CategoryColorUtils._();

  /// Get color for exercise category
  /// @deprecated Use CategoryMappingService.instance.getExerciseCategoryColor instead
  static Color getExerciseCategoryColor(ExerciseCategory category) {
    return CategoryMappingService.instance.getExerciseCategoryColor(category);
  }

  /// Get color for diet category
  /// @deprecated Use CategoryMappingService.instance.getDietCategoryColor instead
  static Color getDietCategoryColor(DietCategory category) {
    return CategoryMappingService.instance.getDietCategoryColor(category);
  }

  /// Get color by category name and type
  /// @deprecated Use CategoryMappingService.instance.getCategoryColorByName instead
  static Color getCategoryColor(String categoryName, CategoryType type) {
    return CategoryMappingService.instance.getCategoryColorByName(categoryName, type);
  }

  /// Get color by index
  static Color getCategoryColorByIndex(int index) {
    const colors = [
      SPColors.podGreen,
      SPColors.podBlue,
      SPColors.podOrange,
      SPColors.podPurple,
      SPColors.podPink,
      SPColors.podMint,
      SPColors.podLightGreen,
    ];
    return colors[index % colors.length];
  }

  /// Get all available category colors
  static List<Color> get allCategoryColors => const [
    SPColors.podGreen,
    SPColors.podBlue,
    SPColors.podOrange,
    SPColors.podPurple,
    SPColors.podPink,
    SPColors.podMint,
    SPColors.podLightGreen,
  ];

  /// Generate gradient colors for category
  static List<Color> getCategoryGradient(Color baseColor) {
    return [baseColor, Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor];
  }

  /// Get contrasting text color for background
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
