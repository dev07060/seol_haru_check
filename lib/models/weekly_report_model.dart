import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for tracking the status of weekly report generation
enum ReportStatus {
  pending,
  generating,
  completed,
  failed;

  /// Convert enum to string for Firestore storage
  String toFirestore() => name;

  /// Create enum from Firestore string
  static ReportStatus fromFirestore(String value) {
    return ReportStatus.values.firstWhere((status) => status.name == value, orElse: () => ReportStatus.pending);
  }
}

/// Model for weekly statistics data
class WeeklyStats {
  final int totalCertifications;
  final int exerciseDays;
  final int dietDays;
  final Map<String, int> exerciseTypes;
  final Map<String, int> exerciseCategories; // 새로운 필드: 운동 세부 카테고리
  final Map<String, int> dietCategories; // 새로운 필드: 식단 세부 카테고리
  final double consistencyScore;

  const WeeklyStats({
    required this.totalCertifications,
    required this.exerciseDays,
    required this.dietDays,
    required this.exerciseTypes,
    required this.exerciseCategories,
    required this.dietCategories,
    required this.consistencyScore,
  });

  /// Create WeeklyStats from Firestore document
  factory WeeklyStats.fromFirestore(Map<String, dynamic> data) {
    return WeeklyStats(
      totalCertifications: data['totalCertifications'] ?? 0,
      exerciseDays: data['exerciseDays'] ?? 0,
      dietDays: data['dietDays'] ?? 0,
      exerciseTypes: Map<String, int>.from(data['exerciseTypes'] ?? {}),
      exerciseCategories: Map<String, int>.from(data['exerciseCategories'] ?? {}),
      dietCategories: Map<String, int>.from(data['dietCategories'] ?? {}),
      consistencyScore: (data['consistencyScore'] ?? 0.0).toDouble(),
    );
  }

  /// Convert WeeklyStats to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'totalCertifications': totalCertifications,
      'exerciseDays': exerciseDays,
      'dietDays': dietDays,
      'exerciseTypes': exerciseTypes,
      'exerciseCategories': exerciseCategories,
      'dietCategories': dietCategories,
      'consistencyScore': consistencyScore,
    };
  }

  /// Create a copy with updated values
  WeeklyStats copyWith({
    int? totalCertifications,
    int? exerciseDays,
    int? dietDays,
    Map<String, int>? exerciseTypes,
    Map<String, int>? exerciseCategories,
    Map<String, int>? dietCategories,
    double? consistencyScore,
  }) {
    return WeeklyStats(
      totalCertifications: totalCertifications ?? this.totalCertifications,
      exerciseDays: exerciseDays ?? this.exerciseDays,
      dietDays: dietDays ?? this.dietDays,
      exerciseTypes: exerciseTypes ?? this.exerciseTypes,
      exerciseCategories: exerciseCategories ?? this.exerciseCategories,
      dietCategories: dietCategories ?? this.dietCategories,
      consistencyScore: consistencyScore ?? this.consistencyScore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyStats &&
        other.totalCertifications == totalCertifications &&
        other.exerciseDays == exerciseDays &&
        other.dietDays == dietDays &&
        other.exerciseTypes.toString() == exerciseTypes.toString() &&
        other.consistencyScore == consistencyScore;
  }

  @override
  int get hashCode {
    return Object.hash(totalCertifications, exerciseDays, dietDays, exerciseTypes, consistencyScore);
  }

  @override
  String toString() {
    return 'WeeklyStats(totalCertifications: $totalCertifications, exerciseDays: $exerciseDays, dietDays: $dietDays, exerciseTypes: $exerciseTypes, consistencyScore: $consistencyScore)';
  }
}

/// Model for AI-generated analysis insights
class AIAnalysis {
  final String exerciseInsights;
  final String dietInsights;
  final String overallAssessment;
  final List<String> strengthAreas;
  final List<String> improvementAreas;

  const AIAnalysis({
    required this.exerciseInsights,
    required this.dietInsights,
    required this.overallAssessment,
    required this.strengthAreas,
    required this.improvementAreas,
  });

  /// Create AIAnalysis from Firestore document
  factory AIAnalysis.fromFirestore(Map<String, dynamic> data) {
    return AIAnalysis(
      exerciseInsights: data['exerciseInsights'] ?? '',
      dietInsights: data['dietInsights'] ?? '',
      overallAssessment: data['overallAssessment'] ?? '',
      strengthAreas: List<String>.from(data['strengthAreas'] ?? []),
      improvementAreas: List<String>.from(data['improvementAreas'] ?? []),
    );
  }

  /// Convert AIAnalysis to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'exerciseInsights': exerciseInsights,
      'dietInsights': dietInsights,
      'overallAssessment': overallAssessment,
      'strengthAreas': strengthAreas,
      'improvementAreas': improvementAreas,
    };
  }

  /// Create a copy with updated values
  AIAnalysis copyWith({
    String? exerciseInsights,
    String? dietInsights,
    String? overallAssessment,
    List<String>? strengthAreas,
    List<String>? improvementAreas,
  }) {
    return AIAnalysis(
      exerciseInsights: exerciseInsights ?? this.exerciseInsights,
      dietInsights: dietInsights ?? this.dietInsights,
      overallAssessment: overallAssessment ?? this.overallAssessment,
      strengthAreas: strengthAreas ?? this.strengthAreas,
      improvementAreas: improvementAreas ?? this.improvementAreas,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIAnalysis &&
        other.exerciseInsights == exerciseInsights &&
        other.dietInsights == dietInsights &&
        other.overallAssessment == overallAssessment &&
        other.strengthAreas.toString() == strengthAreas.toString() &&
        other.improvementAreas.toString() == improvementAreas.toString();
  }

  @override
  int get hashCode {
    return Object.hash(exerciseInsights, dietInsights, overallAssessment, strengthAreas, improvementAreas);
  }

  @override
  String toString() {
    return 'AIAnalysis(exerciseInsights: $exerciseInsights, dietInsights: $dietInsights, overallAssessment: $overallAssessment, strengthAreas: $strengthAreas, improvementAreas: $improvementAreas)';
  }
}

/// Main model for weekly AI analysis reports
class WeeklyReport {
  final String id;
  final String userUuid;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final DateTime generatedAt;
  final WeeklyStats stats;
  final AIAnalysis analysis;
  final List<String> recommendations;
  final ReportStatus status;

  const WeeklyReport({
    required this.id,
    required this.userUuid,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.generatedAt,
    required this.stats,
    required this.analysis,
    required this.recommendations,
    required this.status,
  });

  /// Create WeeklyReport from Firestore document
  factory WeeklyReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyReport(
      id: doc.id,
      userUuid: data['userUuid'] ?? '',
      weekStartDate: (data['weekStartDate'] as Timestamp).toDate(),
      weekEndDate: (data['weekEndDate'] as Timestamp).toDate(),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      stats: WeeklyStats.fromFirestore(data['stats'] ?? {}),
      analysis: AIAnalysis.fromFirestore(data['analysis'] ?? {}),
      recommendations: List<String>.from(data['recommendations'] ?? []),
      status: ReportStatus.fromFirestore(data['status'] ?? 'pending'),
    );
  }

  /// Create WeeklyReport from Firestore document data with custom ID
  factory WeeklyReport.fromFirestoreData(String id, Map<String, dynamic> data) {
    return WeeklyReport(
      id: id,
      userUuid: data['userUuid'] ?? '',
      weekStartDate: (data['weekStartDate'] as Timestamp).toDate(),
      weekEndDate: (data['weekEndDate'] as Timestamp).toDate(),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      stats: WeeklyStats.fromFirestore(data['stats'] ?? {}),
      analysis: AIAnalysis.fromFirestore(data['analysis'] ?? {}),
      recommendations: List<String>.from(data['recommendations'] ?? []),
      status: ReportStatus.fromFirestore(data['status'] ?? 'pending'),
    );
  }

  /// Convert WeeklyReport to Firestore document (without ID)
  Map<String, dynamic> toFirestore() {
    return {
      'userUuid': userUuid,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'weekEndDate': Timestamp.fromDate(weekEndDate),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'stats': stats.toFirestore(),
      'analysis': analysis.toFirestore(),
      'recommendations': recommendations,
      'status': status.toFirestore(),
    };
  }

  /// Create a copy with updated values
  WeeklyReport copyWith({
    String? id,
    String? userUuid,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    DateTime? generatedAt,
    WeeklyStats? stats,
    AIAnalysis? analysis,
    List<String>? recommendations,
    ReportStatus? status,
  }) {
    return WeeklyReport(
      id: id ?? this.id,
      userUuid: userUuid ?? this.userUuid,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      generatedAt: generatedAt ?? this.generatedAt,
      stats: stats ?? this.stats,
      analysis: analysis ?? this.analysis,
      recommendations: recommendations ?? this.recommendations,
      status: status ?? this.status,
    );
  }

  /// Check if the report has sufficient data for analysis (3+ days)
  bool get hasSufficientData {
    return stats.exerciseDays + stats.dietDays >= 3;
  }

  /// Get the week identifier string for this report
  String get weekIdentifier {
    return '${weekStartDate.year}-W${_getWeekOfYear(weekStartDate)}';
  }

  /// Calculate week of year for a given date
  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyReport &&
        other.id == id &&
        other.userUuid == userUuid &&
        other.weekStartDate == weekStartDate &&
        other.weekEndDate == weekEndDate &&
        other.generatedAt == generatedAt &&
        other.stats == stats &&
        other.analysis == analysis &&
        other.recommendations.toString() == recommendations.toString() &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, userUuid, weekStartDate, weekEndDate, generatedAt, stats, analysis, recommendations, status);
  }

  @override
  String toString() {
    return 'WeeklyReport(id: $id, userUuid: $userUuid, weekStartDate: $weekStartDate, weekEndDate: $weekEndDate, generatedAt: $generatedAt, stats: $stats, analysis: $analysis, recommendations: $recommendations, status: $status)';
  }
}
