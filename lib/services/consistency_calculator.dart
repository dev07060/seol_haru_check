import 'dart:math';

import 'package:seol_haru_check/models/weekly_report_model.dart';

/// Service for calculating consistency scores based on user activity patterns
class ConsistencyCalculator {
  /// Calculate consistency score based on weekly stats
  ///
  /// 일관성 점수는 다음 요소들을 고려합니다:
  /// 1. 주간 활동 분포 (매일 꾸준히 vs 몰아서)
  /// 2. 운동과 식단의 균형
  /// 3. 목표 대비 달성률
  /// 4. 활동 패턴의 규칙성
  static double calculateConsistencyScore(WeeklyStats stats) {
    // 기본 점수 계산 요소들
    final activityDistributionScore = _calculateActivityDistribution(stats);
    final balanceScore = _calculateExerciseDietBalance(stats);
    final achievementScore = _calculateAchievementRate(stats);
    final regularityScore = _calculateRegularityScore(stats);

    // 가중 평균으로 최종 점수 계산
    final finalScore =
        (activityDistributionScore * 0.3 + // 30% - 활동 분포
            balanceScore * 0.25 + // 25% - 운동/식단 균형
            achievementScore * 0.25 + // 25% - 목표 달성률
            regularityScore *
                0.2 // 20% - 규칙성
                );

    // 0.0 ~ 1.0 범위로 제한
    return finalScore.clamp(0.0, 1.0);
  }

  /// 활동 분포 점수 계산 (매일 꾸준히 할수록 높은 점수)
  static double _calculateActivityDistribution(WeeklyStats stats) {
    final totalDays = 7.0;
    final activeDays = (stats.exerciseDays + stats.dietDays).toDouble();

    // 활동한 날의 비율
    final activityRatio = (activeDays / (totalDays * 2)).clamp(0.0, 1.0);

    // 매일 활동할수록 높은 점수
    if (activityRatio >= 0.8) return 1.0; // 80% 이상: 매우 일관적
    if (activityRatio >= 0.6) return 0.8; // 60-80%: 일관적
    if (activityRatio >= 0.4) return 0.6; // 40-60%: 보통
    if (activityRatio >= 0.2) return 0.4; // 20-40%: 부족
    return 0.2; // 20% 미만: 매우 부족
  }

  /// 운동과 식단의 균형 점수 계산
  static double _calculateExerciseDietBalance(WeeklyStats stats) {
    if (stats.exerciseDays == 0 && stats.dietDays == 0) return 0.0;

    final totalDays = stats.exerciseDays + stats.dietDays;
    final exerciseRatio = stats.exerciseDays / totalDays;
    final dietRatio = stats.dietDays / totalDays;

    // 이상적인 비율은 운동:식단 = 4:6 또는 5:5
    final idealExerciseRatio = 0.4;
    final idealDietRatio = 0.6;

    final exerciseDeviation = (exerciseRatio - idealExerciseRatio).abs();
    final dietDeviation = (dietRatio - idealDietRatio).abs();

    // 편차가 적을수록 높은 점수
    final balanceScore = 1.0 - ((exerciseDeviation + dietDeviation) / 2);
    return balanceScore.clamp(0.0, 1.0);
  }

  /// 목표 달성률 점수 계산
  static double _calculateAchievementRate(WeeklyStats stats) {
    // 주간 목표: 운동 4일, 식단 6일, 총 인증 10개
    const weeklyExerciseGoal = 4;
    const weeklyDietGoal = 6;
    const weeklyCertificationGoal = 10;

    final exerciseAchievement = (stats.exerciseDays / weeklyExerciseGoal).clamp(0.0, 1.0);
    final dietAchievement = (stats.dietDays / weeklyDietGoal).clamp(0.0, 1.0);
    final certificationAchievement = (stats.totalCertifications / weeklyCertificationGoal).clamp(0.0, 1.0);

    // 평균 달성률
    return (exerciseAchievement + dietAchievement + certificationAchievement) / 3;
  }

  /// 규칙성 점수 계산 (카테고리 다양성 기반)
  static double _calculateRegularityScore(WeeklyStats stats) {
    // 운동 카테고리 다양성
    final exerciseCategoryCount = stats.exerciseCategories.keys.length;
    final exerciseVariety = min(exerciseCategoryCount / 3.0, 1.0); // 3개 이상이면 만점

    // 식단 카테고리 다양성
    final dietCategoryCount = stats.dietCategories.keys.length;
    final dietVariety = min(dietCategoryCount / 4.0, 1.0); // 4개 이상이면 만점

    // 카테고리별 활동 균등성
    final exerciseBalance = _calculateCategoryBalance(stats.exerciseCategories);
    final dietBalance = _calculateCategoryBalance(stats.dietCategories);

    return (exerciseVariety + dietVariety + exerciseBalance + dietBalance) / 4;
  }

  /// 카테고리별 활동 균등성 계산
  static double _calculateCategoryBalance(Map<String, int> categories) {
    if (categories.isEmpty) return 0.0;

    final values = categories.values.toList();
    if (values.length == 1) return 1.0; // 카테고리가 1개면 균등함

    final total = values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return 0.0;

    // 각 카테고리의 비율 계산
    final ratios = values.map((count) => count / total).toList();

    // 표준편차 계산 (낮을수록 균등함)
    final mean = ratios.fold<double>(0, (sum, ratio) => sum + ratio) / ratios.length;
    final variance = ratios.fold<double>(0, (sum, ratio) => sum + pow(ratio - mean, 2)) / ratios.length;
    final standardDeviation = sqrt(variance);

    // 표준편차를 점수로 변환 (0.2 이하면 만점)
    return (1.0 - (standardDeviation / 0.2)).clamp(0.0, 1.0);
  }

  /// 일관성 점수에 따른 등급 반환
  static String getConsistencyGrade(double score) {
    if (score >= 0.9) return 'S급'; // 90% 이상
    if (score >= 0.8) return 'A급'; // 80-90%
    if (score >= 0.7) return 'B급'; // 70-80%
    if (score >= 0.6) return 'C급'; // 60-70%
    if (score >= 0.5) return 'D급'; // 50-60%
    return 'F급'; // 50% 미만
  }

  /// 일관성 점수에 따른 피드백 메시지
  static String getConsistencyFeedback(double score) {
    if (score >= 0.9) {
      return '완벽한 일관성! 매일 꾸준히 운동과 식단을 관리하고 계시네요. 👏';
    } else if (score >= 0.8) {
      return '훌륭한 일관성! 거의 매일 꾸준히 실천하고 계시네요. 💪';
    } else if (score >= 0.7) {
      return '좋은 일관성! 대부분의 날에 꾸준히 관리하고 계시네요. 😊';
    } else if (score >= 0.6) {
      return '보통 수준의 일관성입니다. 조금 더 꾸준히 해보세요! 📈';
    } else if (score >= 0.5) {
      return '일관성이 부족합니다. 매일 조금씩이라도 실천해보세요. 🎯';
    } else {
      return '일관성을 높여보세요. 작은 목표부터 시작해보는 것은 어떨까요? 🌱';
    }
  }

  /// 일관성 개선을 위한 구체적인 제안
  static List<String> getImprovementSuggestions(WeeklyStats stats) {
    final suggestions = <String>[];

    // 활동 빈도 관련 제안
    if (stats.exerciseDays < 3) {
      suggestions.add('주 3회 이상 운동하기를 목표로 해보세요');
    }
    if (stats.dietDays < 4) {
      suggestions.add('주 4회 이상 건강한 식단을 기록해보세요');
    }

    // 균형 관련 제안
    final totalDays = stats.exerciseDays + stats.dietDays;
    if (totalDays > 0) {
      final exerciseRatio = stats.exerciseDays / totalDays;
      if (exerciseRatio < 0.3) {
        suggestions.add('운동 빈도를 조금 더 늘려보세요');
      } else if (exerciseRatio > 0.7) {
        suggestions.add('식단 관리에도 더 신경써보세요');
      }
    }

    // 다양성 관련 제안
    if (stats.exerciseCategories.keys.length < 2) {
      suggestions.add('다양한 종류의 운동을 시도해보세요');
    }
    if (stats.dietCategories.keys.length < 3) {
      suggestions.add('더 다양한 식단을 기록해보세요');
    }

    return suggestions;
  }
}
