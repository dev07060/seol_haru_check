import 'package:cloud_firestore/cloud_firestore.dart';

/// Exercise metadata extracted from fitness app screenshots and workout images
/// Contains only 4 essential fields to minimize API costs
class ExerciseMetadata {
  /// Type of exercise performed (e.g., "러닝", "웨이트 트레이닝", "요가")
  final String? exerciseType;

  /// Duration of exercise in minutes
  final int? duration;

  /// Time period when exercise was performed ("오전", "오후", "저녁")
  final String? timePeriod;

  /// Exercise intensity level ("낮음", "보통", "높음")
  final String? intensity;

  /// Timestamp when metadata was extracted
  final DateTime extractedAt;

  const ExerciseMetadata({
    this.exerciseType,
    this.duration,
    this.timePeriod,
    this.intensity,
    required this.extractedAt,
  });

  /// Create ExerciseMetadata from Firestore map data
  factory ExerciseMetadata.fromMap(Map<String, dynamic> map) {
    return ExerciseMetadata(
      exerciseType: map['exerciseType'] as String?,
      duration: map['duration'] as int?,
      timePeriod: map['timePeriod'] as String?,
      intensity: map['intensity'] as String?,
      extractedAt: (map['extractedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert ExerciseMetadata to Firestore map data
  Map<String, dynamic> toMap() {
    return {
      'exerciseType': exerciseType,
      'duration': duration,
      'timePeriod': timePeriod,
      'intensity': intensity,
      'extractedAt': Timestamp.fromDate(extractedAt),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseMetadata &&
        other.exerciseType == exerciseType &&
        other.duration == duration &&
        other.timePeriod == timePeriod &&
        other.intensity == intensity &&
        other.extractedAt == extractedAt;
  }

  @override
  int get hashCode {
    return exerciseType.hashCode ^ duration.hashCode ^ timePeriod.hashCode ^ intensity.hashCode ^ extractedAt.hashCode;
  }
}

/// Diet metadata extracted from food photos and meal images
/// Contains essential fields for food identification and analysis
class DietMetadata {
  /// Name of the food/dish (e.g., "김치찌개", "햄버거", "샐러드")
  final String? foodName;

  /// Up to 5 main ingredients identified in the food
  final List<String> mainIngredients;

  /// Food category classification (e.g., "한식", "양식", "간식", "음료")
  final String? foodCategory;

  /// Meal time classification ("아침", "점심", "저녁", "간식")
  final String? mealTime;

  /// Estimated calories for the meal/food item
  final int? estimatedCalories;

  /// Timestamp when metadata was extracted
  final DateTime extractedAt;

  const DietMetadata({
    this.foodName,
    required this.mainIngredients,
    this.foodCategory,
    this.mealTime,
    this.estimatedCalories,
    required this.extractedAt,
  });

  /// Create DietMetadata from Firestore map data
  factory DietMetadata.fromMap(Map<String, dynamic> map) {
    return DietMetadata(
      foodName: map['foodName'] as String?,
      mainIngredients: List<String>.from(map['mainIngredients'] ?? []),
      foodCategory: map['foodCategory'] as String?,
      mealTime: map['mealTime'] as String?,
      estimatedCalories: map['estimatedCalories'] as int?,
      extractedAt: (map['extractedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert DietMetadata to Firestore map data
  Map<String, dynamic> toMap() {
    return {
      'mainIngredients': mainIngredients,
      'foodCategory': foodCategory,
      'mealTime': mealTime,
      'estimatedCalories': estimatedCalories,
      'extractedAt': Timestamp.fromDate(extractedAt),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DietMetadata &&
        _listEquals(other.mainIngredients, mainIngredients) &&
        other.foodCategory == foodCategory &&
        other.mealTime == mealTime &&
        other.estimatedCalories == estimatedCalories &&
        other.extractedAt == extractedAt;
  }

  @override
  int get hashCode {
    return mainIngredients.hashCode ^
        foodCategory.hashCode ^
        mealTime.hashCode ^
        estimatedCalories.hashCode ^
        extractedAt.hashCode;
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Error information for failed metadata extraction attempts
class MetadataError {
  /// Type of error that occurred during extraction
  final String errorType;

  /// Human-readable error message
  final String errorMessage;

  /// Number of retry attempts made
  final int retryCount;

  /// Timestamp of last retry attempt
  final DateTime lastRetryAt;

  /// Whether this extraction can be retried
  final bool canRetry;

  const MetadataError({
    required this.errorType,
    required this.errorMessage,
    required this.retryCount,
    required this.lastRetryAt,
    required this.canRetry,
  });

  /// Create MetadataError from Firestore map data
  factory MetadataError.fromMap(Map<String, dynamic> map) {
    return MetadataError(
      errorType: map['errorType'] as String,
      errorMessage: map['errorMessage'] as String,
      retryCount: map['retryCount'] as int,
      lastRetryAt: (map['lastRetryAt'] as Timestamp).toDate(),
      canRetry: map['canRetry'] as bool,
    );
  }

  /// Convert MetadataError to Firestore map data
  Map<String, dynamic> toMap() {
    return {
      'errorType': errorType,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'lastRetryAt': Timestamp.fromDate(lastRetryAt),
      'canRetry': canRetry,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetadataError &&
        other.errorType == errorType &&
        other.errorMessage == errorMessage &&
        other.retryCount == retryCount &&
        other.lastRetryAt == lastRetryAt &&
        other.canRetry == canRetry;
  }

  @override
  int get hashCode {
    return errorType.hashCode ^ errorMessage.hashCode ^ retryCount.hashCode ^ lastRetryAt.hashCode ^ canRetry.hashCode;
  }
}
