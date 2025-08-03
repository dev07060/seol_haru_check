import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';

import '../helpers/test_data_helper.dart';

void main() {
  group('ReportStatus', () {
    test('should convert enum to string for Firestore storage', () {
      expect(ReportStatus.pending.toFirestore(), 'pending');
      expect(ReportStatus.generating.toFirestore(), 'generating');
      expect(ReportStatus.completed.toFirestore(), 'completed');
      expect(ReportStatus.failed.toFirestore(), 'failed');
    });

    test('should create enum from Firestore string', () {
      expect(ReportStatus.fromFirestore('pending'), ReportStatus.pending);
      expect(ReportStatus.fromFirestore('generating'), ReportStatus.generating);
      expect(ReportStatus.fromFirestore('completed'), ReportStatus.completed);
      expect(ReportStatus.fromFirestore('failed'), ReportStatus.failed);
    });

    test('should return pending for unknown values', () {
      expect(ReportStatus.fromFirestore('unknown'), ReportStatus.pending);
      expect(ReportStatus.fromFirestore(''), ReportStatus.pending);
    });
  });

  group('WeeklyStats', () {
    test('should create WeeklyStats from valid data', () {
      final stats = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );

      expect(stats.totalCertifications, 10);
      expect(stats.exerciseDays, 5);
      expect(stats.dietDays, 4);
      expect(stats.exerciseTypes, {'running': 3, 'swimming': 2});
      expect(stats.consistencyScore, 0.85);
    });

    test('should create WeeklyStats from Firestore document', () {
      final data = {
        'totalCertifications': 8,
        'exerciseDays': 4,
        'dietDays': 3,
        'exerciseTypes': {'yoga': 2, 'cardio': 2},
        'consistencyScore': 0.75,
      };

      final stats = WeeklyStats.fromFirestore(data);

      expect(stats.totalCertifications, 8);
      expect(stats.exerciseDays, 4);
      expect(stats.dietDays, 3);
      expect(stats.exerciseTypes, {'yoga': 2, 'cardio': 2});
      expect(stats.consistencyScore, 0.75);
    });

    test('should handle missing fields with defaults', () {
      final data = <String, dynamic>{};
      final stats = WeeklyStats.fromFirestore(data);

      expect(stats.totalCertifications, 0);
      expect(stats.exerciseDays, 0);
      expect(stats.dietDays, 0);
      expect(stats.exerciseTypes, <String, int>{});
      expect(stats.consistencyScore, 0.0);
    });

    test('should convert WeeklyStats to Firestore document', () {
      final stats = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 12,
        exerciseDays: 6,
        dietDays: 5,
        exerciseTypes: {'weightlifting': 4, 'running': 2},
        consistencyScore: 0.92,
      );

      final firestoreData = stats.toFirestore();

      expect(firestoreData['totalCertifications'], 12);
      expect(firestoreData['exerciseDays'], 6);
      expect(firestoreData['dietDays'], 5);
      expect(firestoreData['exerciseTypes'], {'weightlifting': 4, 'running': 2});
      expect(firestoreData['consistencyScore'], 0.92);
    });

    test('should create copy with updated values', () {
      final original = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 5,
        exerciseDays: 3,
        dietDays: 2,
        exerciseTypes: {'running': 3},
        consistencyScore: 0.6,
      );

      final updated = original.copyWith(totalCertifications: 8, consistencyScore: 0.8);

      expect(updated.totalCertifications, 8);
      expect(updated.exerciseDays, 3); // unchanged
      expect(updated.dietDays, 2); // unchanged
      expect(updated.exerciseTypes, {'running': 3}); // unchanged
      expect(updated.consistencyScore, 0.8);
    });

    test('should implement equality correctly', () {
      final stats1 = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );

      final stats2 = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );

      final stats3 = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 8,
        exerciseDays: 4,
        dietDays: 3,
        exerciseTypes: {'yoga': 2},
        consistencyScore: 0.75,
      );

      expect(stats1, equals(stats2));
      expect(stats1, isNot(equals(stats3)));
    });

    test('should have consistent hashCode', () {
      final stats1 = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );

      final stats2 = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );

      expect(stats1.hashCode, equals(stats2.hashCode));
    });

    test('should have meaningful toString', () {
      final stats = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );

      final string = stats.toString();
      expect(string, contains('WeeklyStats'));
      expect(string, contains('totalCertifications: 10'));
      expect(string, contains('exerciseDays: 5'));
      expect(string, contains('dietDays: 4'));
      expect(string, contains('consistencyScore: 0.85'));
    });
  });

  group('AIAnalysis', () {
    test('should create AIAnalysis from valid data', () {
      const analysis = AIAnalysis(
        exerciseInsights: 'Great exercise consistency',
        dietInsights: 'Balanced nutrition',
        overallAssessment: 'Excellent progress',
        strengthAreas: ['Consistency', 'Variety'],
        improvementAreas: ['Hydration', 'Sleep'],
      );

      expect(analysis.exerciseInsights, 'Great exercise consistency');
      expect(analysis.dietInsights, 'Balanced nutrition');
      expect(analysis.overallAssessment, 'Excellent progress');
      expect(analysis.strengthAreas, ['Consistency', 'Variety']);
      expect(analysis.improvementAreas, ['Hydration', 'Sleep']);
    });

    test('should create AIAnalysis from Firestore document', () {
      final data = {
        'exerciseInsights': 'Good workout routine',
        'dietInsights': 'Needs more vegetables',
        'overallAssessment': 'Making progress',
        'strengthAreas': ['Dedication', 'Timing'],
        'improvementAreas': ['Portion control'],
      };

      final analysis = AIAnalysis.fromFirestore(data);

      expect(analysis.exerciseInsights, 'Good workout routine');
      expect(analysis.dietInsights, 'Needs more vegetables');
      expect(analysis.overallAssessment, 'Making progress');
      expect(analysis.strengthAreas, ['Dedication', 'Timing']);
      expect(analysis.improvementAreas, ['Portion control']);
    });

    test('should handle missing fields with defaults', () {
      final data = <String, dynamic>{};
      final analysis = AIAnalysis.fromFirestore(data);

      expect(analysis.exerciseInsights, '');
      expect(analysis.dietInsights, '');
      expect(analysis.overallAssessment, '');
      expect(analysis.strengthAreas, <String>[]);
      expect(analysis.improvementAreas, <String>[]);
    });

    test('should convert AIAnalysis to Firestore document', () {
      const analysis = AIAnalysis(
        exerciseInsights: 'Consistent workouts',
        dietInsights: 'Healthy choices',
        overallAssessment: 'Great job',
        strengthAreas: ['Motivation', 'Planning'],
        improvementAreas: ['Recovery time'],
      );

      final firestoreData = analysis.toFirestore();

      expect(firestoreData['exerciseInsights'], 'Consistent workouts');
      expect(firestoreData['dietInsights'], 'Healthy choices');
      expect(firestoreData['overallAssessment'], 'Great job');
      expect(firestoreData['strengthAreas'], ['Motivation', 'Planning']);
      expect(firestoreData['improvementAreas'], ['Recovery time']);
    });

    test('should create copy with updated values', () {
      const original = AIAnalysis(
        exerciseInsights: 'Original insights',
        dietInsights: 'Original diet',
        overallAssessment: 'Original assessment',
        strengthAreas: ['Original strength'],
        improvementAreas: ['Original improvement'],
      );

      final updated = original.copyWith(exerciseInsights: 'Updated insights', strengthAreas: ['Updated strength']);

      expect(updated.exerciseInsights, 'Updated insights');
      expect(updated.dietInsights, 'Original diet'); // unchanged
      expect(updated.overallAssessment, 'Original assessment'); // unchanged
      expect(updated.strengthAreas, ['Updated strength']);
      expect(updated.improvementAreas, ['Original improvement']); // unchanged
    });

    test('should implement equality correctly', () {
      const analysis1 = AIAnalysis(
        exerciseInsights: 'Great exercise consistency',
        dietInsights: 'Balanced nutrition',
        overallAssessment: 'Excellent progress',
        strengthAreas: ['Consistency', 'Variety'],
        improvementAreas: ['Hydration', 'Sleep'],
      );

      const analysis2 = AIAnalysis(
        exerciseInsights: 'Great exercise consistency',
        dietInsights: 'Balanced nutrition',
        overallAssessment: 'Excellent progress',
        strengthAreas: ['Consistency', 'Variety'],
        improvementAreas: ['Hydration', 'Sleep'],
      );

      const analysis3 = AIAnalysis(
        exerciseInsights: 'Different insights',
        dietInsights: 'Different diet',
        overallAssessment: 'Different assessment',
        strengthAreas: ['Different strength'],
        improvementAreas: ['Different improvement'],
      );

      expect(analysis1, equals(analysis2));
      expect(analysis1, isNot(equals(analysis3)));
    });
  });

  group('WeeklyReport', () {
    late DateTime testDate;
    late WeeklyStats testStats;
    late AIAnalysis testAnalysis;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
      testStats = TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 10,
        exerciseDays: 5,
        dietDays: 4,
        exerciseTypes: {'running': 3, 'swimming': 2},
        consistencyScore: 0.85,
      );
      testAnalysis = const AIAnalysis(
        exerciseInsights: 'Great exercise consistency',
        dietInsights: 'Balanced nutrition',
        overallAssessment: 'Excellent progress',
        strengthAreas: ['Consistency', 'Variety'],
        improvementAreas: ['Hydration', 'Sleep'],
      );
    });

    test('should create WeeklyReport from valid data', () {
      final report = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Drink more water', 'Get more sleep'],
        status: ReportStatus.completed,
      );

      expect(report.id, 'test-id');
      expect(report.userUuid, 'user-123');
      expect(report.weekStartDate, testDate);
      expect(report.weekEndDate, testDate.add(const Duration(days: 6)));
      expect(report.generatedAt, testDate.add(const Duration(days: 7)));
      expect(report.stats, testStats);
      expect(report.analysis, testAnalysis);
      expect(report.recommendations, ['Drink more water', 'Get more sleep']);
      expect(report.status, ReportStatus.completed);
    });

    test('should convert WeeklyReport to Firestore document', () {
      final report = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Drink more water', 'Get more sleep'],
        status: ReportStatus.completed,
      );

      final firestoreData = report.toFirestore();

      expect(firestoreData['userUuid'], 'user-123');
      expect(firestoreData['weekStartDate'], isA<Timestamp>());
      expect(firestoreData['weekEndDate'], isA<Timestamp>());
      expect(firestoreData['generatedAt'], isA<Timestamp>());
      expect(firestoreData['stats'], isA<Map<String, dynamic>>());
      expect(firestoreData['analysis'], isA<Map<String, dynamic>>());
      expect(firestoreData['recommendations'], ['Drink more water', 'Get more sleep']);
      expect(firestoreData['status'], 'completed');
    });

    test('should create copy with updated values', () {
      final original = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Original recommendation'],
        status: ReportStatus.pending,
      );

      final updated = original.copyWith(status: ReportStatus.completed, recommendations: ['Updated recommendation']);

      expect(updated.id, 'test-id'); // unchanged
      expect(updated.userUuid, 'user-123'); // unchanged
      expect(updated.status, ReportStatus.completed);
      expect(updated.recommendations, ['Updated recommendation']);
    });

    test('should check if report has sufficient data', () {
      final sufficientReport = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 10,
          exerciseDays: 2,
          dietDays: 2, // 2 + 2 = 4 >= 3
          exerciseTypes: {},
          consistencyScore: 0.5,
        ),
        analysis: testAnalysis,
        recommendations: [],
        status: ReportStatus.completed,
      );

      final insufficientReport = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 2,
          exerciseDays: 1,
          dietDays: 1, // 1 + 1 = 2 < 3
          exerciseTypes: {},
          consistencyScore: 0.2,
        ),
        analysis: testAnalysis,
        recommendations: [],
        status: ReportStatus.completed,
      );

      expect(sufficientReport.hasSufficientData, true);
      expect(insufficientReport.hasSufficientData, false);
    });

    test('should generate week identifier correctly', () {
      // Test with a known date (January 15, 2024 is in week 3)
      final report = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: DateTime(2024, 1, 15),
        weekEndDate: DateTime(2024, 1, 21),
        generatedAt: DateTime(2024, 1, 22),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: [],
        status: ReportStatus.completed,
      );

      final weekIdentifier = report.weekIdentifier;
      expect(weekIdentifier, startsWith('2024-W'));
      expect(weekIdentifier.length, greaterThan(6));
    });

    test('should implement equality correctly', () {
      final report1 = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Drink more water'],
        status: ReportStatus.completed,
      );

      final report2 = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Drink more water'],
        status: ReportStatus.completed,
      );

      final report3 = WeeklyReport(
        id: 'different-id',
        userUuid: 'user-456',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Different recommendation'],
        status: ReportStatus.pending,
      );

      expect(report1, equals(report2));
      expect(report1, isNot(equals(report3)));
    });

    test('should have meaningful toString', () {
      final report = WeeklyReport(
        id: 'test-id',
        userUuid: 'user-123',
        weekStartDate: testDate,
        weekEndDate: testDate.add(const Duration(days: 6)),
        generatedAt: testDate.add(const Duration(days: 7)),
        stats: testStats,
        analysis: testAnalysis,
        recommendations: ['Drink more water'],
        status: ReportStatus.completed,
      );

      final string = report.toString();
      expect(string, contains('WeeklyReport'));
      expect(string, contains('id: test-id'));
      expect(string, contains('userUuid: user-123'));
      expect(string, contains('status: ReportStatus.completed'));
    });
  });
}
