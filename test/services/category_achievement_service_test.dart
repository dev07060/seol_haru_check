import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/category_achievement_service.dart';

void main() {
  group('CategoryAchievementService', () {
    late CategoryAchievementService service;

    setUp(() {
      service = CategoryAchievementService();
    });

    group('Variety Achievements', () {
      test('should detect Well-Rounded Week achievement', () async {
        // Create a report with 5+ categories
        final report = _createMockReport({'근력 운동': 2, '유산소 운동': 1, '스트레칭/요가': 1}, {'집밥/도시락': 3, '건강식/샐러드': 2});

        final achievements = await service.detectAchievements(report, []);

        expect(achievements.any((a) => a.title == '균형잡힌 한 주'), isTrue);
        final wellRoundedAchievement = achievements.firstWhere((a) => a.title == '균형잡힌 한 주');
        expect(wellRoundedAchievement.type, AchievementType.categoryVariety);
        expect(wellRoundedAchievement.points, 25);
      });

      test('should detect Exercise Variety Master achievement', () async {
        // Create a report with 4+ exercise categories
        final report = _createMockReport({'근력 운동': 2, '유산소 운동': 1, '스트레칭/요가': 1, '구기/스포츠': 1}, {'집밥/도시락': 2});

        final achievements = await service.detectAchievements(report, []);

        expect(achievements.any((a) => a.title == '운동 다양성 마스터'), isTrue);
        final varietyAchievement = achievements.firstWhere((a) => a.title == '운동 다양성 마스터');
        expect(varietyAchievement.type, AchievementType.categoryVariety);
        expect(varietyAchievement.rarity, AchievementRarity.rare);
      });

      test('should detect Perfect Variety achievement', () async {
        // Create a report with all categories
        final report = _createMockReport(
          {'근력 운동': 1, '유산소 운동': 1, '스트레칭/요가': 1, '구기/스포츠': 1, '야외 활동': 1, '댄스/무용': 1},
          {'집밥/도시락': 1, '건강식/샐러드': 1, '단백질 위주': 1, '간식/음료': 1, '외식/배달': 1, '영양제/보충제': 1},
        );

        final achievements = await service.detectAchievements(report, []);

        expect(achievements.any((a) => a.title == '완벽한 다양성'), isTrue);
        final perfectAchievement = achievements.firstWhere((a) => a.title == '완벽한 다양성');
        expect(perfectAchievement.rarity, AchievementRarity.legendary);
        expect(perfectAchievement.points, 250);
      });
    });

    group('Consistency Achievements', () {
      test('should detect Consistent Category Champion achievement', () async {
        // Create current report and historical reports with consistent categories
        final currentReport = _createMockReport({'근력 운동': 2, '유산소 운동': 1, '스트레칭/요가': 1}, {'집밥/도시락': 3, '건강식/샐러드': 2});

        final historicalReports = [
          _createMockReport({'근력 운동': 1, '유산소 운동': 2, '스트레칭/요가': 1}, {'집밥/도시락': 2, '건강식/샐러드': 3}),
          _createMockReport({'근력 운동': 3, '유산소 운동': 1, '스트레칭/요가': 2}, {'집밥/도시락': 4, '건강식/샐러드': 1}),
        ];

        final achievements = await service.detectAchievements(currentReport, historicalReports);

        expect(achievements.any((a) => a.title == '일관성 챔피언'), isTrue);
        final consistencyAchievement = achievements.firstWhere((a) => a.title == '일관성 챔피언');
        expect(consistencyAchievement.type, AchievementType.categoryConsistency);
      });
    });

    group('Exploration Achievements', () {
      test('should detect First Time Explorer achievement', () async {
        // Create current report with new category
        final currentReport = _createMockReport(
          {
            '근력 운동': 2,
            '댄스/무용': 1, // New category
          },
          {'집밥/도시락': 3},
        );

        final historicalReports = [
          _createMockReport({'근력 운동': 1}, {'집밥/도시락': 2}),
        ];

        final achievements = await service.detectAchievements(currentReport, historicalReports);

        expect(achievements.any((a) => a.title == '첫 도전자'), isTrue);
        final explorerAchievement = achievements.firstWhere((a) => a.title == '첫 도전자');
        expect(explorerAchievement.type, AchievementType.categoryExploration);
        expect(explorerAchievement.rarity, AchievementRarity.common);
      });

      test('should detect Adventure Seeker achievement', () async {
        // Create current report with 3+ new categories
        final currentReport = _createMockReport(
          {
            '근력 운동': 1,
            '댄스/무용': 1, // New
            '구기/스포츠': 1, // New
            '야외 활동': 1, // New
          },
          {'집밥/도시락': 2},
        );

        final historicalReports = [
          _createMockReport({'근력 운동': 1}, {'집밥/도시락': 2}),
        ];

        final achievements = await service.detectAchievements(currentReport, historicalReports);

        expect(achievements.any((a) => a.title == '모험가'), isTrue);
        final adventureAchievement = achievements.firstWhere((a) => a.title == '모험가');
        expect(adventureAchievement.type, AchievementType.categoryExploration);
        expect(adventureAchievement.rarity, AchievementRarity.rare);
      });
    });

    group('Balance Achievements', () {
      test('should detect Perfect Balance achievement', () async {
        // Create a report with optimal balance
        final report = _createMockReport(
          {'근력 운동': 2, '유산소 운동': 2, '스트레칭/요가': 2},
          {'집밥/도시락': 2, '건강식/샐러드': 2, '단백질 위주': 2},
        );

        final achievements = await service.detectAchievements(report, []);

        expect(achievements.any((a) => a.title == '완벽한 균형'), isTrue);
        final balanceAchievement = achievements.firstWhere((a) => a.title == '완벽한 균형');
        expect(balanceAchievement.type, AchievementType.categoryBalance);
        expect(balanceAchievement.rarity, AchievementRarity.epic);
      });

      test('should detect Health Optimizer achievement', () async {
        // Create a report with optimal exercise/diet ratio
        final report = _createMockReport({'근력 운동': 3, '유산소 운동': 2}, {'집밥/도시락': 4, '건강식/샐러드': 3});

        final achievements = await service.detectAchievements(report, []);

        expect(achievements.any((a) => a.title == '건강 최적화자'), isTrue);
        final optimizerAchievement = achievements.firstWhere((a) => a.title == '건강 최적화자');
        expect(optimizerAchievement.type, AchievementType.categoryBalance);
      });
    });

    group('Achievement Progress', () {
      test('should calculate achievement progress correctly', () async {
        final report = _createMockReport({'근력 운동': 2, '유산소 운동': 1}, {'집밥/도시락': 2});

        final progress = await service.getAchievementProgress(report, []);

        expect(progress.isNotEmpty, isTrue);

        final varietyProgress = progress.firstWhere((p) => p.achievementId == 'well_rounded_week');
        expect(varietyProgress.currentValue, 3); // 2 exercise + 1 diet categories
        expect(varietyProgress.targetValue, 5);
        expect(varietyProgress.progress, 0.6); // 3/5
      });
    });
  });
}

/// Helper function to create mock weekly reports
WeeklyReport _createMockReport(Map<String, int> exerciseCategories, Map<String, int> dietCategories) {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  return WeeklyReport(
    id: 'test_${DateTime.now().millisecondsSinceEpoch}',
    userUuid: 'test_user',
    weekStartDate: weekStart,
    weekEndDate: weekStart.add(const Duration(days: 6)),
    generatedAt: now,
    stats: WeeklyStats(
      totalCertifications:
          exerciseCategories.values.fold(0, (a, b) => a + b) + dietCategories.values.fold(0, (a, b) => a + b),
      exerciseDays: exerciseCategories.isNotEmpty ? 5 : 0,
      dietDays: dietCategories.isNotEmpty ? 6 : 0,
      exerciseTypes: exerciseCategories,
      exerciseCategories: exerciseCategories,
      dietCategories: dietCategories,
      consistencyScore: 0.8,
    ),
    analysis: const AIAnalysis(
      exerciseInsights: 'Test insights',
      dietInsights: 'Test insights',
      overallAssessment: 'Test assessment',
      strengthAreas: ['Test strength'],
      improvementAreas: ['Test improvement'],
    ),
    recommendations: ['Test recommendation'],
    status: ReportStatus.completed,
  );
}
