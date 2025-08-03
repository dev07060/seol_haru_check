import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/certification_model.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/services/consistency_calculator.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// 디버깅 모드에서만 사용되는 가짜 데이터 생성 헬퍼
class DebugDataHelper {
  static const bool _isDebugMode = kDebugMode;
  static final Random _random = Random();

  /// 디버깅 모드인지 확인
  static bool get isDebugMode => _isDebugMode;

  /// 가짜 주간 리포트 생성
  static WeeklyReport generateFakeWeeklyReport({DateTime? weekStart}) {
    if (!_isDebugMode) {
      throw Exception('Debug data can only be generated in debug mode');
    }

    final startDate = weekStart ?? DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final endDate = startDate.add(const Duration(days: 6));

    // 가짜 통계 데이터 생성
    final exerciseDays = _random.nextInt(6) + 2; // 2-7일
    final dietDays = _random.nextInt(6) + 2; // 2-7일
    final totalCertifications = _random.nextInt(15) + 10; // 10-25개

    // Create initial stats without consistency score
    final initialStats = WeeklyStats(
      totalCertifications: totalCertifications,
      exerciseDays: exerciseDays,
      dietDays: dietDays,
      exerciseTypes: {
        '근력 운동': _random.nextInt(8) + 2,
        '유산소 운동': _random.nextInt(6) + 1,
        '스트레칭': _random.nextInt(4) + 1,
      },
      exerciseCategories: {
        '근력 운동': _random.nextInt(8) + 2,
        '유산소 운동': _random.nextInt(6) + 1,
        '스트레칭': _random.nextInt(4) + 1,
        '요가': _random.nextInt(3) + 1,
      },
      dietCategories: {
        '한식': _random.nextInt(6) + 2,
        '샐러드': _random.nextInt(4) + 1,
        '단백질': _random.nextInt(5) + 1,
        '과일': _random.nextInt(3) + 1,
      },
      consistencyScore: 0.0,
    );

    // Calculate actual consistency score
    final calculatedConsistencyScore = ConsistencyCalculator.calculateConsistencyScore(initialStats);

    // Create final stats with calculated consistency score
    final fakeStats = initialStats.copyWith(consistencyScore: calculatedConsistencyScore);

    // 가짜 AI 분석 데이터 생성
    final insights = _generateFakeInsights();
    final fakeAnalysis = AIAnalysis(
      exerciseInsights: insights.isNotEmpty ? insights.first : '운동 분석 데이터가 없습니다.',
      dietInsights: insights.length > 1 ? insights.last : '식단 분석 데이터가 없습니다.',
      overallAssessment: '이번 주는 전반적으로 균형잡힌 활동을 보여주셨습니다.',
      strengthAreas: ['꾸준한 운동 실천', '다양한 식단 시도'],
      improvementAreas: ['주말 활동량 증가', '수분 섭취 늘리기'],
    );

    return WeeklyReport(
      id: 'debug_report_${startDate.millisecondsSinceEpoch}',
      userUuid: 'debug_user',
      weekStartDate: startDate,
      weekEndDate: endDate,
      generatedAt: DateTime.now(),
      stats: fakeStats,
      analysis: fakeAnalysis,
      recommendations: _generateFakeRecommendations(),
      status: ReportStatus.completed,
    );
  }

  /// 가짜 운동 카테고리 데이터 생성
  static List<CategoryVisualizationData> generateFakeExerciseCategories() {
    final exerciseTypes = [
      {'name': '근력 운동', 'emoji': '💪', 'color': SPColors.podGreen},
      {'name': '유산소 운동', 'emoji': '🏃', 'color': SPColors.podBlue},
      {'name': '스트레칭', 'emoji': '🧘', 'color': SPColors.podOrange},
      {'name': '요가', 'emoji': '🧘‍♀️', 'color': SPColors.podPurple},
      {'name': '수영', 'emoji': '🏊', 'color': SPColors.podMint},
      {'name': '자전거', 'emoji': '🚴', 'color': SPColors.podPink},
    ];

    final categories = <CategoryVisualizationData>[];
    final totalCount = _random.nextInt(8) + 5; // 5-13개

    for (int i = 0; i < min(exerciseTypes.length, _random.nextInt(4) + 3); i++) {
      final type = exerciseTypes[i];
      final count = _random.nextInt(totalCount ~/ 2) + 1;

      categories.add(
        CategoryVisualizationData(
          categoryName: type['name'] as String,
          emoji: type['emoji'] as String,
          count: count,
          percentage: count / totalCount,
          color: type['color'] as Color,
          type: CategoryType.exercise,
        ),
      );
    }

    return categories;
  }

  /// 가짜 식단 카테고리 데이터 생성
  static List<CategoryVisualizationData> generateFakeDietCategories() {
    final dietTypes = [
      {'name': '한식', 'emoji': '🍚', 'color': SPColors.podGreen},
      {'name': '샐러드', 'emoji': '🥗', 'color': SPColors.podLightGreen},
      {'name': '단백질', 'emoji': '�', 'color': SPColors.podOrange},
      {'name': '과일', 'emoji': '🍎', 'color': SPColors.podPink},
      {'name': '견과류', 'emoji': '🥜', 'color': SPColors.podPurple},
      {'name': '유제품', 'emoji': '�', 'color': SPColors.podBlue},
    ];

    final categories = <CategoryVisualizationData>[];
    final totalCount = _random.nextInt(8) + 5; // 5-13개

    for (int i = 0; i < min(dietTypes.length, _random.nextInt(4) + 3); i++) {
      final type = dietTypes[i];
      final count = _random.nextInt(totalCount ~/ 2) + 1;

      categories.add(
        CategoryVisualizationData(
          categoryName: type['name'] as String,
          emoji: type['emoji'] as String,
          count: count,
          percentage: count / totalCount,
          color: type['color'] as Color,
          type: CategoryType.diet,
        ),
      );
    }

    return categories;
  }

  /// 가짜 성취 데이터 생성
  static List<CategoryAchievement> generateFakeAchievements() {
    final achievements = <CategoryAchievement>[];
    final achievementTypes = [
      {
        'title': '균형잡힌 한 주',
        'description': '운동과 식단을 골고루 실천했습니다!',
        'type': AchievementType.categoryBalance,
        'rarity': AchievementRarity.rare,
      },
      {
        'title': '다양성의 달인',
        'description': '5가지 이상의 운동 카테고리를 시도했습니다!',
        'type': AchievementType.categoryVariety,
        'rarity': AchievementRarity.uncommon,
      },
      {
        'title': '꾸준함의 힘',
        'description': '일주일 내내 꾸준히 인증했습니다!',
        'type': AchievementType.categoryConsistency,
        'rarity': AchievementRarity.epic,
      },
    ];

    for (int i = 0; i < _random.nextInt(3) + 1; i++) {
      final achievement = achievementTypes[i % achievementTypes.length];
      achievements.add(
        CategoryAchievement(
          id: 'debug_achievement_$i',
          title: achievement['title'] as String,
          description: achievement['description'] as String,
          type: achievement['type'] as AchievementType,
          rarity: achievement['rarity'] as AchievementRarity,
          icon: (achievement['type'] as AchievementType).icon,
          color: (achievement['type'] as AchievementType).color,
          achievedAt: DateTime.now().subtract(Duration(days: _random.nextInt(7))),
          points: (achievement['rarity'] as AchievementRarity).points,
          isNew: _random.nextBool(),
        ),
      );
    }

    return achievements;
  }

  /// 가짜 인사이트 생성
  static List<String> _generateFakeInsights() {
    final insights = [
      '이번 주는 운동 다양성이 지난 주보다 20% 증가했습니다.',
      '근력 운동을 가장 많이 하셨네요! 균형을 위해 유산소 운동도 추가해보세요.',
      '주말에 운동량이 줄어드는 패턴이 보입니다.',
      '식단 인증이 꾸준히 이어지고 있어 좋습니다!',
      '스트레칭을 꾸준히 하고 계시는군요. 근육 회복에 도움이 됩니다.',
    ];

    final selectedInsights = <String>[];
    final count = _random.nextInt(3) + 2; // 2-4개

    for (int i = 0; i < count; i++) {
      selectedInsights.add(insights[_random.nextInt(insights.length)]);
    }

    return selectedInsights;
  }

  /// 가짜 추천사항 생성
  static List<String> _generateFakeRecommendations() {
    final recommendations = [
      '다음 주에는 요가나 필라테스를 시도해보세요.',
      '단백질 섭취를 늘려보시는 것을 추천합니다.',
      '주말에도 꾸준한 운동 루틴을 유지해보세요.',
      '수분 섭취량을 늘려보시면 좋겠습니다.',
      '충분한 휴식과 함께 운동 강도를 조절해보세요.',
    ];

    final selectedRecommendations = <String>[];
    final count = _random.nextInt(3) + 2; // 2-4개

    for (int i = 0; i < count; i++) {
      selectedRecommendations.add(recommendations[_random.nextInt(recommendations.length)]);
    }

    return selectedRecommendations;
  }

  /// 가짜 인증 데이터 생성
  static List<Certification> generateFakeCertifications({
    required DateTime startDate,
    required DateTime endDate,
    int? count,
  }) {
    if (!_isDebugMode) {
      throw Exception('Debug data can only be generated in debug mode');
    }

    final certifications = <Certification>[];
    final totalCount = count ?? (_random.nextInt(15) + 10); // 10-25개

    for (int i = 0; i < totalCount; i++) {
      final isExercise = _random.nextBool();
      final date = _generateRandomDateBetween(startDate, endDate);

      certifications.add(
        Certification(
          docId: 'debug_cert_$i',
          uuid: 'debug_user',
          nickname: 'Debug User',
          type: isExercise ? CertificationType.exercise : CertificationType.diet,
          content: _generateRandomContent(isExercise),
          photoUrl: 'https://via.placeholder.com/300x200?text=${isExercise ? 'Exercise' : 'Diet'}',
          createdAt: date,
        ),
      );
    }

    return certifications;
  }

  /// 랜덤 날짜 생성
  static DateTime _generateRandomDateBetween(DateTime start, DateTime end) {
    final difference = end.difference(start).inDays;
    final randomDays = _random.nextInt(difference + 1);
    final randomHour = _random.nextInt(24);
    final randomMinute = _random.nextInt(60);

    return start.add(Duration(days: randomDays, hours: randomHour, minutes: randomMinute));
  }

  /// 랜덤 컨텐츠 생성
  static String _generateRandomContent(bool isExercise) {
    if (isExercise) {
      final exercises = ['30분 런닝 완료!', '헬스장에서 근력 운동', '홈트레이닝으로 스쿼트 100개', '요가 수업 참여', '수영 1시간', '자전거 타기 45분'];
      return exercises[_random.nextInt(exercises.length)];
    } else {
      final diets = ['건강한 샐러드로 점심', '단백질 위주의 저녁 식사', '과일과 견과류 간식', '현미밥과 채소 반찬', '그릭 요거트와 베리', '닭가슴살 샐러드'];
      return diets[_random.nextInt(diets.length)];
    }
  }

  /// 여러 주간 리포트 생성 (히스토리용)
  static List<WeeklyReport> generateFakeWeeklyReports({int count = 4}) {
    if (!_isDebugMode) {
      throw Exception('Debug data can only be generated in debug mode');
    }

    final reports = <WeeklyReport>[];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7 + now.weekday - 1));
      reports.add(generateFakeWeeklyReport(weekStart: weekStart));
    }

    return reports;
  }
}
