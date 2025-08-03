import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';

import '../helpers/test_data_helper.dart';

/// Test helper class for data aggregation and statistics calculation
class DataAggregationHelper {
  /// Calculate weekly statistics from certification data
  static WeeklyStats calculateWeeklyStats({required List<Map<String, dynamic>> certifications}) {
    if (certifications.isEmpty) {
      return TestDataHelper.createDefaultWeeklyStats(
        totalCertifications: 0,
        exerciseDays: 0,
        dietDays: 0,
        exerciseTypes: {},
        consistencyScore: 0.0,
      );
    }

    final exerciseCertifications = certifications.where((cert) => cert['type'] == '운동').toList();

    final dietCertifications = certifications.where((cert) => cert['type'] == '식단').toList();

    // Calculate unique days for each type
    final exerciseDays =
        exerciseCertifications.map((cert) => _getDayOfWeek(cert['createdAt'] as DateTime)).toSet().length;

    final dietDays = dietCertifications.map((cert) => _getDayOfWeek(cert['createdAt'] as DateTime)).toSet().length;

    // Calculate exercise types distribution
    final exerciseTypes = <String, int>{};
    for (final cert in exerciseCertifications) {
      final content = cert['content'] as String;
      final exerciseType = _extractExerciseType(content);
      exerciseTypes[exerciseType] = (exerciseTypes[exerciseType] ?? 0) + 1;
    }

    // Calculate consistency score (0.0 to 1.0)
    // Get unique days across both exercise and diet
    final allDays = <int>{};
    allDays.addAll(exerciseCertifications.map((cert) => _getDayOfWeek(cert['createdAt'] as DateTime)));
    allDays.addAll(dietCertifications.map((cert) => _getDayOfWeek(cert['createdAt'] as DateTime)));
    final consistencyScore = allDays.length / 7.0;

    return WeeklyStats(
      totalCertifications: certifications.length,
      exerciseDays: exerciseDays,
      dietDays: dietDays,
      exerciseTypes: exerciseTypes,
      exerciseCategories: {}, // 테스트용 빈 맵
      dietCategories: {}, // 테스트용 빈 맵
      consistencyScore: consistencyScore,
    );
  }

  /// Extract exercise type from content string
  static String _extractExerciseType(String content) {
    final lowerContent = content.toLowerCase();

    if (lowerContent.contains('달리기') || lowerContent.contains('러닝') || lowerContent.contains('조깅')) {
      return '달리기';
    } else if (lowerContent.contains('수영')) {
      return '수영';
    } else if (lowerContent.contains('요가')) {
      return '요가';
    } else if (lowerContent.contains('헬스') || lowerContent.contains('웨이트') || lowerContent.contains('근력')) {
      return '근력운동';
    } else if (lowerContent.contains('자전거') || lowerContent.contains('사이클')) {
      return '자전거';
    } else if (lowerContent.contains('등산') || lowerContent.contains('하이킹')) {
      return '등산';
    } else if (lowerContent.contains('걷기') || lowerContent.contains('산책')) {
      return '걷기';
    } else {
      return '기타';
    }
  }

  /// Get day of week (0 = Sunday, 6 = Saturday)
  static int _getDayOfWeek(DateTime date) {
    return date.weekday % 7; // Convert to Sunday = 0 format
  }

  /// Check if user has sufficient data for analysis (minimum 3 days)
  static bool hasSufficientData(WeeklyStats stats) {
    return (stats.exerciseDays + stats.dietDays) >= 3;
  }

  /// Calculate improvement suggestions based on stats
  static List<String> calculateImprovementSuggestions(WeeklyStats stats) {
    final suggestions = <String>[];

    if (stats.consistencyScore < 0.5) {
      suggestions.add('일관성을 높이기 위해 매일 조금씩이라도 활동해보세요');
    }

    if (stats.exerciseDays < 3) {
      suggestions.add('주 3회 이상 운동을 목표로 해보세요');
    }

    if (stats.dietDays < 4) {
      suggestions.add('건강한 식단 관리를 더 자주 실천해보세요');
    }

    if (stats.exerciseTypes.length < 2) {
      suggestions.add('다양한 종류의 운동을 시도해보세요');
    }

    if (stats.totalCertifications < 7) {
      suggestions.add('매일 최소 1개의 인증을 목표로 해보세요');
    }

    return suggestions;
  }

  /// Calculate strength areas based on stats
  static List<String> calculateStrengthAreas(WeeklyStats stats) {
    final strengths = <String>[];

    if (stats.consistencyScore >= 0.8) {
      strengths.add('뛰어난 일관성');
    } else if (stats.consistencyScore >= 0.6) {
      strengths.add('좋은 일관성');
    }

    if (stats.exerciseDays >= 5) {
      strengths.add('충분한 운동 빈도');
    } else if (stats.exerciseDays >= 3) {
      strengths.add('적절한 운동 빈도');
    }

    if (stats.dietDays >= 5) {
      strengths.add('우수한 식단 관리');
    } else if (stats.dietDays >= 3) {
      strengths.add('양호한 식단 관리');
    }

    if (stats.exerciseTypes.length >= 3) {
      strengths.add('다양한 운동 종류');
    } else if (stats.exerciseTypes.length >= 2) {
      strengths.add('적절한 운동 다양성');
    }

    if (stats.totalCertifications >= 14) {
      strengths.add('높은 활동량');
    } else if (stats.totalCertifications >= 10) {
      strengths.add('충분한 활동량');
    }

    return strengths.isNotEmpty ? strengths : ['꾸준한 노력'];
  }

  /// Generate overall assessment based on stats
  static String generateOverallAssessment(WeeklyStats stats) {
    if (!hasSufficientData(stats)) {
      return '분석을 위한 데이터가 부족합니다. 더 많은 인증을 통해 개인화된 분석을 받아보세요.';
    }

    if (stats.consistencyScore >= 0.8 && stats.totalCertifications >= 12) {
      return '훌륭합니다! 매우 일관되고 활발한 건강 관리를 하고 계시네요.';
    } else if (stats.consistencyScore >= 0.6 && stats.totalCertifications >= 8) {
      return '잘하고 계십니다! 꾸준한 노력이 보이며, 조금 더 일관성을 높이면 더욱 좋을 것 같아요.';
    } else if (stats.consistencyScore >= 0.4 && stats.totalCertifications >= 5) {
      return '좋은 시작입니다! 건강 관리에 관심을 가지고 실천하고 계시네요. 조금 더 꾸준히 해보세요.';
    } else {
      return '건강 관리를 시작하신 것을 축하드립니다! 작은 변화부터 시작해서 점차 늘려가보세요.';
    }
  }
}

void main() {
  group('DataAggregationHelper', () {
    group('calculateWeeklyStats', () {
      test('should calculate stats correctly with mixed certifications', () {
        // Arrange
        final certifications = [
          {
            'type': '운동',
            'content': '달리기 30분',
            'createdAt': DateTime(2024, 1, 15), // Monday
          },
          {
            'type': '운동',
            'content': '헬스장에서 근력운동',
            'createdAt': DateTime(2024, 1, 15), // Monday (same day)
          },
          {
            'type': '식단',
            'content': '건강한 아침식사',
            'createdAt': DateTime(2024, 1, 15), // Monday
          },
          {
            'type': '운동',
            'content': '수영 1시간',
            'createdAt': DateTime(2024, 1, 16), // Tuesday
          },
          {
            'type': '식단',
            'content': '균형잡힌 점심',
            'createdAt': DateTime(2024, 1, 17), // Wednesday
          },
          {
            'type': '운동',
            'content': '요가 클래스',
            'createdAt': DateTime(2024, 1, 18), // Thursday
          },
        ];

        // Act
        final stats = DataAggregationHelper.calculateWeeklyStats(certifications: certifications);

        // Assert
        expect(stats.totalCertifications, 6);
        expect(stats.exerciseDays, 3); // Monday, Tuesday, Thursday
        expect(stats.dietDays, 2); // Monday, Wednesday
        expect(stats.exerciseTypes['달리기'], 1);
        expect(stats.exerciseTypes['근력운동'], 1);
        expect(stats.exerciseTypes['수영'], 1);
        expect(stats.exerciseTypes['요가'], 1);
        expect(stats.consistencyScore, closeTo(4 / 7, 0.01)); // 4 unique days out of 7
      });

      test('should handle empty certifications', () {
        // Act
        final stats = DataAggregationHelper.calculateWeeklyStats(certifications: []);

        // Assert
        expect(stats.totalCertifications, 0);
        expect(stats.exerciseDays, 0);
        expect(stats.dietDays, 0);
        expect(stats.exerciseTypes, isEmpty);
        expect(stats.consistencyScore, 0.0);
      });

      test('should handle only exercise certifications', () {
        // Arrange
        final certifications = [
          {
            'type': '운동',
            'content': '달리기 30분',
            'createdAt': DateTime(2024, 1, 15), // Monday
          },
          {
            'type': '운동',
            'content': '달리기 45분',
            'createdAt': DateTime(2024, 1, 16), // Tuesday
          },
          {
            'type': '운동',
            'content': '수영 1시간',
            'createdAt': DateTime(2024, 1, 17), // Wednesday
          },
        ];

        // Act
        final stats = DataAggregationHelper.calculateWeeklyStats(certifications: certifications);

        // Assert
        expect(stats.totalCertifications, 3);
        expect(stats.exerciseDays, 3);
        expect(stats.dietDays, 0);
        expect(stats.exerciseTypes['달리기'], 2);
        expect(stats.exerciseTypes['수영'], 1);
        expect(stats.consistencyScore, closeTo(3 / 7, 0.01));
      });

      test('should handle only diet certifications', () {
        // Arrange
        final certifications = [
          {
            'type': '식단',
            'content': '건강한 아침식사',
            'createdAt': DateTime(2024, 1, 15), // Monday
          },
          {
            'type': '식단',
            'content': '균형잡힌 점심',
            'createdAt': DateTime(2024, 1, 16), // Tuesday
          },
          {
            'type': '식단',
            'content': '가벼운 저녁',
            'createdAt': DateTime(2024, 1, 17), // Wednesday
          },
        ];

        // Act
        final stats = DataAggregationHelper.calculateWeeklyStats(certifications: certifications);

        // Assert
        expect(stats.totalCertifications, 3);
        expect(stats.exerciseDays, 0);
        expect(stats.dietDays, 3);
        expect(stats.exerciseTypes, isEmpty);
        expect(stats.consistencyScore, closeTo(3 / 7, 0.01));
      });

      test('should handle multiple certifications on same day', () {
        // Arrange
        final certifications = [
          {
            'type': '운동',
            'content': '달리기 30분',
            'createdAt': DateTime(2024, 1, 15, 8, 0), // Monday morning
          },
          {
            'type': '식단',
            'content': '건강한 아침식사',
            'createdAt': DateTime(2024, 1, 15, 9, 0), // Monday morning
          },
          {
            'type': '운동',
            'content': '헬스장 운동',
            'createdAt': DateTime(2024, 1, 15, 18, 0), // Monday evening
          },
          {
            'type': '식단',
            'content': '균형잡힌 저녁',
            'createdAt': DateTime(2024, 1, 15, 19, 0), // Monday evening
          },
        ];

        // Act
        final stats = DataAggregationHelper.calculateWeeklyStats(certifications: certifications);

        // Assert
        expect(stats.totalCertifications, 4);
        expect(stats.exerciseDays, 1); // Only Monday
        expect(stats.dietDays, 1); // Only Monday
        expect(stats.consistencyScore, closeTo(1 / 7, 0.01)); // Only 1 unique day
      });
    });

    group('_extractExerciseType', () {
      test('should extract running type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('달리기 30분'), '달리기');
        expect(DataAggregationHelper._extractExerciseType('러닝 1시간'), '달리기');
        expect(DataAggregationHelper._extractExerciseType('조깅했어요'), '달리기');
      });

      test('should extract swimming type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('수영 1시간'), '수영');
        expect(DataAggregationHelper._extractExerciseType('수영장에서 운동'), '수영');
      });

      test('should extract yoga type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('요가 클래스'), '요가');
        expect(DataAggregationHelper._extractExerciseType('요가 수업 참여'), '요가');
      });

      test('should extract weight training type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('헬스장에서 운동'), '근력운동');
        expect(DataAggregationHelper._extractExerciseType('웨이트 트레이닝'), '근력운동');
        expect(DataAggregationHelper._extractExerciseType('근력운동 1시간'), '근력운동');
      });

      test('should extract cycling type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('자전거 타기'), '자전거');
        expect(DataAggregationHelper._extractExerciseType('사이클링'), '자전거');
      });

      test('should extract hiking type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('등산 2시간'), '등산');
        expect(DataAggregationHelper._extractExerciseType('하이킹'), '등산');
      });

      test('should extract walking type correctly', () {
        expect(DataAggregationHelper._extractExerciseType('걷기 운동'), '걷기');
        expect(DataAggregationHelper._extractExerciseType('산책 1시간'), '걷기');
      });

      test('should return other for unknown types', () {
        expect(DataAggregationHelper._extractExerciseType('특별한 운동'), '기타');
        expect(DataAggregationHelper._extractExerciseType('새로운 스포츠'), '기타');
      });
    });

    group('hasSufficientData', () {
      test('should return true for sufficient data', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 10,
          exerciseDays: 2,
          dietDays: 2, // 2 + 2 = 4 >= 3
          exerciseTypes: {},
          consistencyScore: 0.5,
        );

        expect(DataAggregationHelper.hasSufficientData(stats), true);
      });

      test('should return false for insufficient data', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 5,
          exerciseDays: 1,
          dietDays: 1, // 1 + 1 = 2 < 3
          exerciseTypes: {},
          consistencyScore: 0.2,
        );

        expect(DataAggregationHelper.hasSufficientData(stats), false);
      });

      test('should return true for exactly 3 days', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 6,
          exerciseDays: 3,
          dietDays: 0, // 3 + 0 = 3 >= 3
          exerciseTypes: {},
          consistencyScore: 0.4,
        );

        expect(DataAggregationHelper.hasSufficientData(stats), true);
      });
    });

    group('calculateImprovementSuggestions', () {
      test('should suggest consistency improvement for low score', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 3,
          exerciseDays: 1,
          dietDays: 1,
          exerciseTypes: {'달리기': 1},
          consistencyScore: 0.3, // < 0.5
        );

        final suggestions = DataAggregationHelper.calculateImprovementSuggestions(stats);

        expect(suggestions, contains('일관성을 높이기 위해 매일 조금씩이라도 활동해보세요'));
      });

      test('should suggest more exercise for low exercise days', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 5,
          exerciseDays: 2, // < 3
          dietDays: 3,
          exerciseTypes: {'달리기': 2},
          consistencyScore: 0.6,
        );

        final suggestions = DataAggregationHelper.calculateImprovementSuggestions(stats);

        expect(suggestions, contains('주 3회 이상 운동을 목표로 해보세요'));
      });

      test('should suggest better diet management for low diet days', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 6,
          exerciseDays: 4,
          dietDays: 2, // < 4
          exerciseTypes: {'달리기': 2, '수영': 2},
          consistencyScore: 0.7,
        );

        final suggestions = DataAggregationHelper.calculateImprovementSuggestions(stats);

        expect(suggestions, contains('건강한 식단 관리를 더 자주 실천해보세요'));
      });

      test('should suggest exercise variety for limited types', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 8,
          exerciseDays: 4,
          dietDays: 4,
          exerciseTypes: {'달리기': 4}, // only 1 type < 2
          consistencyScore: 0.8,
        );

        final suggestions = DataAggregationHelper.calculateImprovementSuggestions(stats);

        expect(suggestions, contains('다양한 종류의 운동을 시도해보세요'));
      });

      test('should suggest daily certification for low total', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 5, // < 7
          exerciseDays: 3,
          dietDays: 4,
          exerciseTypes: {'달리기': 2, '수영': 1},
          consistencyScore: 0.8,
        );

        final suggestions = DataAggregationHelper.calculateImprovementSuggestions(stats);

        expect(suggestions, contains('매일 최소 1개의 인증을 목표로 해보세요'));
      });

      test('should return empty suggestions for excellent stats', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 15,
          exerciseDays: 5,
          dietDays: 6,
          exerciseTypes: {'달리기': 3, '수영': 2, '요가': 2},
          consistencyScore: 0.9,
        );

        final suggestions = DataAggregationHelper.calculateImprovementSuggestions(stats);

        expect(suggestions, isEmpty);
      });
    });

    group('calculateStrengthAreas', () {
      test('should identify excellent consistency', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 14,
          exerciseDays: 6,
          dietDays: 6,
          exerciseTypes: {'달리기': 3, '수영': 3},
          consistencyScore: 0.85, // >= 0.8
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('뛰어난 일관성'));
      });

      test('should identify good consistency', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 10,
          exerciseDays: 4,
          dietDays: 4,
          exerciseTypes: {'달리기': 2, '수영': 2},
          consistencyScore: 0.7, // >= 0.6 but < 0.8
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('좋은 일관성'));
      });

      test('should identify sufficient exercise frequency', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 12,
          exerciseDays: 5, // >= 5
          dietDays: 4,
          exerciseTypes: {'달리기': 3, '수영': 2},
          consistencyScore: 0.8,
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('충분한 운동 빈도'));
      });

      test('should identify appropriate exercise frequency', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 8,
          exerciseDays: 4, // >= 3 but < 5
          dietDays: 3,
          exerciseTypes: {'달리기': 2, '수영': 2},
          consistencyScore: 0.7,
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('적절한 운동 빈도'));
      });

      test('should identify excellent diet management', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 12,
          exerciseDays: 4,
          dietDays: 6, // >= 5
          exerciseTypes: {'달리기': 2, '수영': 2},
          consistencyScore: 0.8,
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('우수한 식단 관리'));
      });

      test('should identify diverse exercise types', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 10,
          exerciseDays: 5,
          dietDays: 3,
          exerciseTypes: {'달리기': 2, '수영': 2, '요가': 1}, // 3 types >= 3
          consistencyScore: 0.7,
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('다양한 운동 종류'));
      });

      test('should identify high activity level', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 16, // >= 14
          exerciseDays: 6,
          dietDays: 6,
          exerciseTypes: {'달리기': 4, '수영': 2},
          consistencyScore: 0.9,
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('높은 활동량'));
      });

      test('should return default strength for poor stats', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 3,
          exerciseDays: 1,
          dietDays: 1,
          exerciseTypes: {'달리기': 1},
          consistencyScore: 0.3,
        );

        final strengths = DataAggregationHelper.calculateStrengthAreas(stats);

        expect(strengths, contains('꾸준한 노력'));
      });
    });

    group('generateOverallAssessment', () {
      test('should return insufficient data message for low data', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 2,
          exerciseDays: 1,
          dietDays: 1, // 1 + 1 = 2 < 3
          exerciseTypes: {'달리기': 1},
          consistencyScore: 0.2,
        );

        final assessment = DataAggregationHelper.generateOverallAssessment(stats);

        expect(assessment, contains('분석을 위한 데이터가 부족합니다'));
      });

      test('should return excellent assessment for high performance', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 15, // >= 12
          exerciseDays: 6,
          dietDays: 6,
          exerciseTypes: {'달리기': 4, '수영': 2},
          consistencyScore: 0.85, // >= 0.8
        );

        final assessment = DataAggregationHelper.generateOverallAssessment(stats);

        expect(assessment, contains('훌륭합니다'));
        expect(assessment, contains('매우 일관되고 활발한'));
      });

      test('should return good assessment for decent performance', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 10, // >= 8
          exerciseDays: 4,
          dietDays: 3,
          exerciseTypes: {'달리기': 3, '수영': 1},
          consistencyScore: 0.7, // >= 0.6
        );

        final assessment = DataAggregationHelper.generateOverallAssessment(stats);

        expect(assessment, contains('잘하고 계십니다'));
        expect(assessment, contains('꾸준한 노력'));
      });

      test('should return encouraging assessment for moderate performance', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 6, // >= 5
          exerciseDays: 3,
          dietDays: 2,
          exerciseTypes: {'달리기': 2, '요가': 1},
          consistencyScore: 0.5, // >= 0.4
        );

        final assessment = DataAggregationHelper.generateOverallAssessment(stats);

        expect(assessment, contains('좋은 시작입니다'));
        expect(assessment, contains('건강 관리에 관심'));
      });

      test('should return beginner assessment for low performance', () {
        final stats = TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: 3, // < 5
          exerciseDays: 2,
          dietDays: 1,
          exerciseTypes: {'달리기': 2},
          consistencyScore: 0.3, // < 0.4
        );

        final assessment = DataAggregationHelper.generateOverallAssessment(stats);

        expect(assessment, contains('건강 관리를 시작하신 것을 축하'));
        expect(assessment, contains('작은 변화부터'));
      });
    });
  });
}
