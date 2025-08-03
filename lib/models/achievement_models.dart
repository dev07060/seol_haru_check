import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Enum for achievement types
enum AchievementType {
  categoryVariety,
  categoryConsistency,
  categoryExploration,
  categoryBalance;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case AchievementType.categoryVariety:
        return '카테고리 다양성';
      case AchievementType.categoryConsistency:
        return '카테고리 일관성';
      case AchievementType.categoryExploration:
        return '카테고리 탐험';
      case AchievementType.categoryBalance:
        return '카테고리 균형';
    }
  }

  /// Get icon for achievement type
  IconData get icon {
    switch (this) {
      case AchievementType.categoryVariety:
        return Icons.diversity_3;
      case AchievementType.categoryConsistency:
        return Icons.trending_up;
      case AchievementType.categoryExploration:
        return Icons.explore;
      case AchievementType.categoryBalance:
        return Icons.balance;
    }
  }

  /// Get color for achievement type
  Color get color {
    switch (this) {
      case AchievementType.categoryVariety:
        return SPColors.podGreen;
      case AchievementType.categoryConsistency:
        return SPColors.podBlue;
      case AchievementType.categoryExploration:
        return SPColors.podOrange;
      case AchievementType.categoryBalance:
        return SPColors.podPurple;
    }
  }
}

/// Enum for achievement rarity levels
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return '일반';
      case AchievementRarity.uncommon:
        return '특별';
      case AchievementRarity.rare:
        return '희귀';
      case AchievementRarity.epic:
        return '영웅';
      case AchievementRarity.legendary:
        return '전설';
    }
  }

  /// Get color for rarity
  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return SPColors.gray600;
      case AchievementRarity.uncommon:
        return SPColors.podGreen;
      case AchievementRarity.rare:
        return SPColors.podBlue;
      case AchievementRarity.epic:
        return SPColors.podPurple;
      case AchievementRarity.legendary:
        return SPColors.podOrange;
    }
  }

  /// Get points for rarity
  int get points {
    switch (this) {
      case AchievementRarity.common:
        return 10;
      case AchievementRarity.uncommon:
        return 25;
      case AchievementRarity.rare:
        return 50;
      case AchievementRarity.epic:
        return 100;
      case AchievementRarity.legendary:
        return 250;
    }
  }
}

/// Model for category-based achievements
class CategoryAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final AchievementRarity rarity;
  final IconData icon;
  final Color color;
  final DateTime achievedAt;
  final int points;
  final Map<String, dynamic> metadata;
  final bool isNew;

  const CategoryAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.color,
    required this.achievedAt,
    required this.points,
    this.metadata = const {},
    this.isNew = true,
  });

  /// Create from map data
  factory CategoryAchievement.fromMap(Map<String, dynamic> map) {
    return CategoryAchievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: AchievementType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => AchievementType.categoryVariety,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (rarity) => rarity.name == map['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      icon: IconData(map['iconCodePoint'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] ?? SPColors.podGreen.value),
      achievedAt: DateTime.parse(map['achievedAt'] ?? DateTime.now().toIso8601String()),
      points: map['points'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      isNew: map['isNew'] ?? true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'rarity': rarity.name,
      'iconCodePoint': icon.codePoint,
      'color': color.value,
      'achievedAt': achievedAt.toIso8601String(),
      'points': points,
      'metadata': metadata,
      'isNew': isNew,
    };
  }

  /// Copy with modifications
  CategoryAchievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    AchievementRarity? rarity,
    IconData? icon,
    Color? color,
    DateTime? achievedAt,
    int? points,
    Map<String, dynamic>? metadata,
    bool? isNew,
  }) {
    return CategoryAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      achievedAt: achievedAt ?? this.achievedAt,
      points: points ?? this.points,
      metadata: metadata ?? this.metadata,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryAchievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.rarity == rarity &&
        other.achievedAt == achievedAt &&
        other.points == points;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        type.hashCode ^
        rarity.hashCode ^
        achievedAt.hashCode ^
        points.hashCode;
  }

  @override
  String toString() {
    return 'CategoryAchievement(id: $id, title: $title, type: $type, rarity: $rarity, points: $points)';
  }
}

/// Model for achievement progress tracking
class AchievementProgress {
  final String achievementId;
  final String title;
  final String description;
  final AchievementType type;
  final int currentValue;
  final int targetValue;
  final double progress;
  final bool isCompleted;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  const AchievementProgress({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.type,
    required this.currentValue,
    required this.targetValue,
    required this.progress,
    required this.isCompleted,
    this.completedAt,
    this.metadata = const {},
  });

  /// Create from map data
  factory AchievementProgress.fromMap(Map<String, dynamic> map) {
    return AchievementProgress(
      achievementId: map['achievementId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: AchievementType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => AchievementType.categoryVariety,
      ),
      currentValue: map['currentValue'] ?? 0,
      targetValue: map['targetValue'] ?? 1,
      progress: (map['progress'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'title': title,
      'description': description,
      'type': type.name,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'progress': progress,
      'isCompleted': isCompleted,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Get progress percentage (0-100)
  double get progressPercentage => (progress * 100).clamp(0, 100);

  /// Get remaining value to complete
  int get remainingValue => (targetValue - currentValue).clamp(0, targetValue);

  /// Copy with modifications
  AchievementProgress copyWith({
    String? achievementId,
    String? title,
    String? description,
    AchievementType? type,
    int? currentValue,
    int? targetValue,
    double? progress,
    bool? isCompleted,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AchievementProgress(
      achievementId: achievementId ?? this.achievementId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AchievementProgress(id: $achievementId, title: $title, progress: ${progressPercentage.toStringAsFixed(1)}%, completed: $isCompleted)';
  }
}

/// Model for achievement milestone tracking
class AchievementMilestone {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int level;
  final int requiredValue;
  final AchievementRarity rarity;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.level,
    required this.requiredValue,
    required this.rarity,
    required this.points,
    required this.isUnlocked,
    this.unlockedAt,
  });

  /// Create from map data
  factory AchievementMilestone.fromMap(Map<String, dynamic> map) {
    return AchievementMilestone(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: AchievementType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => AchievementType.categoryVariety,
      ),
      level: map['level'] ?? 1,
      requiredValue: map['requiredValue'] ?? 1,
      rarity: AchievementRarity.values.firstWhere(
        (rarity) => rarity.name == map['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      points: map['points'] ?? 0,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'level': level,
      'requiredValue': requiredValue,
      'rarity': rarity.name,
      'points': points,
      'isUnlocked': isUnlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AchievementMilestone(id: $id, title: $title, level: $level, unlocked: $isUnlocked)';
  }
}

/// Model for category balance metrics used in achievements
class CategoryBalanceMetrics {
  final double exerciseBalance;
  final double dietBalance;
  final double overallBalance;
  final Map<String, double> categoryDistribution;
  final double diversityScore;
  final int totalCategories;
  final int activeCategories;

  const CategoryBalanceMetrics({
    required this.exerciseBalance,
    required this.dietBalance,
    required this.overallBalance,
    required this.categoryDistribution,
    required this.diversityScore,
    required this.totalCategories,
    required this.activeCategories,
  });

  /// Create empty balance metrics
  factory CategoryBalanceMetrics.empty() {
    return const CategoryBalanceMetrics(
      exerciseBalance: 0.0,
      dietBalance: 0.0,
      overallBalance: 0.0,
      categoryDistribution: {},
      diversityScore: 0.0,
      totalCategories: 0,
      activeCategories: 0,
    );
  }

  /// Check if balance is optimal (>= 0.7)
  bool get isOptimalBalance => overallBalance >= 0.7;

  /// Check if diversity is high (>= 0.8)
  bool get isHighDiversity => diversityScore >= 0.8;

  /// Get balance level description
  String get balanceDescription {
    if (overallBalance >= 0.9) {
      return '완벽한 균형';
    } else if (overallBalance >= 0.7) {
      return '좋은 균형';
    } else if (overallBalance >= 0.5) {
      return '보통 균형';
    } else {
      return '불균형';
    }
  }

  @override
  String toString() {
    return 'CategoryBalanceMetrics(overallBalance: ${overallBalance.toStringAsFixed(2)}, diversityScore: ${diversityScore.toStringAsFixed(2)}, activeCategories: $activeCategories)';
  }
}
