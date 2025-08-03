import 'package:seol_haru_check/models/weekly_report_model.dart';

/// Helper class for creating test data
class TestDataHelper {
  /// Creates a default WeeklyStats for testing
  static WeeklyStats createDefaultWeeklyStats({
    int totalCertifications = 10,
    int exerciseDays = 5,
    int dietDays = 4,
    Map<String, int>? exerciseTypes,
    Map<String, int>? exerciseCategories,
    Map<String, int>? dietCategories,
    double consistencyScore = 0.85,
  }) {
    return WeeklyStats(
      totalCertifications: totalCertifications,
      exerciseDays: exerciseDays,
      dietDays: dietDays,
      exerciseTypes: exerciseTypes ?? {'running': 3, 'swimming': 2},
      exerciseCategories: exerciseCategories ?? {'cardio': 3, 'strength': 2},
      dietCategories: dietCategories ?? {'healthy': 2, 'homemade': 2},
      consistencyScore: consistencyScore,
    );
  }

  /// Creates a default AIAnalysis for testing
  static AIAnalysis createDefaultAIAnalysis({
    String exerciseInsights = 'Test exercise insights',
    String dietInsights = 'Test diet insights',
    String overallAssessment = 'Test overall assessment',
    List<String>? strengthAreas,
    List<String>? improvementAreas,
  }) {
    return AIAnalysis(
      exerciseInsights: exerciseInsights,
      dietInsights: dietInsights,
      overallAssessment: overallAssessment,
      strengthAreas: strengthAreas ?? ['consistency', 'variety'],
      improvementAreas: improvementAreas ?? ['hydration', 'sleep'],
    );
  }

  /// Creates a default WeeklyReport for testing
  static WeeklyReport createDefaultWeeklyReport({
    String id = 'test-report-id',
    String userUuid = 'test-user-uuid',
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    DateTime? generatedAt,
    WeeklyStats? stats,
    AIAnalysis? analysis,
    List<String>? recommendations,
    ReportStatus status = ReportStatus.completed,
  }) {
    final now = DateTime.now();
    final defaultWeekStart = weekStartDate ?? now.subtract(Duration(days: now.weekday % 7));
    final defaultWeekEnd = weekEndDate ?? defaultWeekStart.add(const Duration(days: 6));

    return WeeklyReport(
      id: id,
      userUuid: userUuid,
      weekStartDate: defaultWeekStart,
      weekEndDate: defaultWeekEnd,
      generatedAt: generatedAt ?? now,
      stats: stats ?? createDefaultWeeklyStats(),
      analysis: analysis ?? createDefaultAIAnalysis(),
      recommendations: recommendations ?? ['Test recommendation 1', 'Test recommendation 2'],
      status: status,
    );
  }

  /// Creates mock historical reports for testing
  static List<WeeklyReport> createMockHistoricalReports(int count) {
    final reports = <WeeklyReport>[];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Create varied exercise and diet categories for each week
      final exerciseCategories = <String, int>{
        '근력 운동': (i % 3) + 1,
        '유산소 운동': (i % 4) + 1,
        '스트레칭': (i % 2) + 1,
        '요가': i % 2 == 0 ? 1 : 0,
      };

      final dietCategories = <String, int>{
        '한식': (i % 3) + 2,
        '샐러드': (i % 2) + 1,
        '단백질': (i % 4) + 1,
        '과일': i % 3 == 0 ? 2 : 1,
      };

      final stats = WeeklyStats(
        totalCertifications: 8 + (i % 5),
        exerciseDays: 4 + (i % 3),
        dietDays: 3 + (i % 4),
        exerciseTypes: {'running': i % 3, 'swimming': i % 2},
        exerciseCategories: exerciseCategories,
        dietCategories: dietCategories,
        consistencyScore: 0.6 + (i % 4) * 0.1,
      );

      reports.add(
        WeeklyReport(
          id: 'test-report-$i',
          userUuid: 'test-user-uuid',
          weekStartDate: weekStart,
          weekEndDate: weekEnd,
          generatedAt: weekEnd.add(const Duration(days: 1)),
          stats: stats,
          analysis: createDefaultAIAnalysis(),
          recommendations: ['Test recommendation ${i + 1}'],
          status: ReportStatus.completed,
        ),
      );
    }

    return reports;
  }
}
