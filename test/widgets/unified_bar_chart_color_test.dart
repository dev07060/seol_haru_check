import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

void main() {
  group('SPColors Enhanced Color and Emoji System Tests', () {
    test('should provide correct exercise colors', () {
      // Test exercise color mapping
      expect(SPColors.getExerciseColor('근력 운동'), equals(SPColors.reportGreen));
      expect(SPColors.getExerciseColor('유산소'), equals(SPColors.reportBlue));
      expect(SPColors.getExerciseColor('스트레칭'), equals(SPColors.reportOrange));
      expect(SPColors.getExerciseColor('요가'), equals(SPColors.reportPurple));
      expect(SPColors.getExerciseColor('수영'), equals(SPColors.reportTeal));
      expect(SPColors.getExerciseColor('자전거'), equals(SPColors.reportIndigo));
      expect(SPColors.getExerciseColor('필라테스'), equals(SPColors.reportAmber));
      expect(SPColors.getExerciseColor('고강도'), equals(SPColors.reportRed));
    });

    test('should provide correct diet colors', () {
      // Test diet color mapping
      expect(SPColors.getDietColor('한식'), equals(SPColors.dietGreen));
      expect(SPColors.getDietColor('샐러드'), equals(SPColors.dietLightGreen));
      expect(SPColors.getDietColor('단백질'), equals(SPColors.dietBrown));
      expect(SPColors.getDietColor('과일'), equals(SPColors.dietRed));
      expect(SPColors.getDietColor('견과류'), equals(SPColors.dietPurple));
      expect(SPColors.getDietColor('유제품'), equals(SPColors.dietBlue));
    });

    test('should provide correct exercise emojis', () {
      // Test exercise emoji mapping
      expect(SPColors.getExerciseEmoji('근력 운동'), equals('💪'));
      expect(SPColors.getExerciseEmoji('유산소'), equals('🏃'));
      expect(SPColors.getExerciseEmoji('스트레칭'), equals('🤸'));
      expect(SPColors.getExerciseEmoji('요가'), equals('🧘'));
      expect(SPColors.getExerciseEmoji('수영'), equals('🏊'));
      expect(SPColors.getExerciseEmoji('자전거'), equals('🚴'));
      expect(SPColors.getExerciseEmoji('필라테스'), equals('🤸‍♀️'));
      expect(SPColors.getExerciseEmoji('고강도'), equals('🔥'));
    });

    test('should provide correct diet emojis', () {
      // Test diet emoji mapping
      expect(SPColors.getDietEmoji('한식'), equals('🍚'));
      expect(SPColors.getDietEmoji('샐러드'), equals('🥗'));
      expect(SPColors.getDietEmoji('단백질'), equals('🍗'));
      expect(SPColors.getDietEmoji('과일'), equals('🍎'));
      expect(SPColors.getDietEmoji('견과류'), equals('🥜'));
      expect(SPColors.getDietEmoji('유제품'), equals('🥛'));
    });

    test('should provide fallback colors and emojis for unknown categories', () {
      // Test fallback behavior
      expect(SPColors.getExerciseColor('unknown category'), equals(SPColors.reportGreen));
      expect(SPColors.getDietColor('unknown category'), equals(SPColors.dietGreen));
      expect(SPColors.getExerciseEmoji('unknown category'), equals('🏃'));
      expect(SPColors.getDietEmoji('unknown category'), equals('🍽️'));
    });

    test('should create CategoryColorEmoji objects correctly', () {
      // Test combined color and emoji functionality
      final exerciseColorEmoji = SPColors.getCategoryColorEmoji('근력 운동', true);
      expect(exerciseColorEmoji.color, equals(SPColors.reportGreen));
      expect(exerciseColorEmoji.emoji, equals('💪'));

      final dietColorEmoji = SPColors.getCategoryColorEmoji('한식', false);
      expect(dietColorEmoji.color, equals(SPColors.dietGreen));
      expect(dietColorEmoji.emoji, equals('🍚'));
    });

    test('should provide accessible color shades', () {
      // Test color shade functionality
      final baseColor = SPColors.reportGreen;
      final darkerShade = SPColors.getDarkerShade(baseColor);
      final lighterShade = SPColors.getLighterShade(baseColor);

      expect(darkerShade, isA<Color>());
      expect(lighterShade, isA<Color>());
      expect(darkerShade, isNot(equals(baseColor)));
      expect(lighterShade, isNot(equals(baseColor)));
    });

    test('should create CategoryVisualizationData with enhanced colors', () {
      // Test that CategoryVisualizationData works with enhanced colors
      final exerciseCategory = CategoryVisualizationData(
        categoryName: '근력 운동',
        emoji: SPColors.getExerciseEmoji('근력 운동'),
        count: 5,
        percentage: 0.5,
        color: SPColors.getExerciseColor('근력 운동'),
        type: CategoryType.exercise,
      );

      expect(exerciseCategory.color, equals(SPColors.reportGreen));
      expect(exerciseCategory.emoji, equals('💪'));
      expect(exerciseCategory.categoryName, equals('근력 운동'));
      expect(exerciseCategory.type, equals(CategoryType.exercise));

      final dietCategory = CategoryVisualizationData(
        categoryName: '한식',
        emoji: SPColors.getDietEmoji('한식'),
        count: 3,
        percentage: 0.3,
        color: SPColors.getDietColor('한식'),
        type: CategoryType.diet,
      );

      expect(dietCategory.color, equals(SPColors.dietGreen));
      expect(dietCategory.emoji, equals('🍚'));
      expect(dietCategory.categoryName, equals('한식'));
      expect(dietCategory.type, equals(CategoryType.diet));
    });

    test('should create BarSegmentData with accessibility features', () {
      // Test BarSegmentData with enhanced color system
      final category = CategoryVisualizationData(
        categoryName: '요가',
        emoji: SPColors.getExerciseEmoji('요가'),
        count: 4,
        percentage: 0.4,
        color: SPColors.getExerciseColor('요가'),
        type: CategoryType.exercise,
      );

      final segment = BarSegmentData(
        category: category,
        percentage: 40.0,
        startPosition: 0.0,
        width: 40.0,
        color: category.color,
        emoji: category.emoji,
      );

      expect(segment.color, equals(SPColors.reportPurple));
      expect(segment.emoji, equals('🧘'));
      expect(segment.darkerColor, isA<Color>());
      expect(segment.lighterColor, isA<Color>());

      // Test accessibility color method
      final accessibleColor = segment.getAccessibleColor(Colors.white);
      expect(accessibleColor, isA<Color>());
    });

    test('should handle case variations in category names', () {
      // Test case insensitive matching
      expect(SPColors.getExerciseColor('근력운동'), equals(SPColors.reportGreen));
      expect(SPColors.getExerciseColor('HIIT'), equals(SPColors.reportRed));
      expect(SPColors.getDietColor('한국음식'), equals(SPColors.dietGreen));
      expect(SPColors.getDietColor('채소'), equals(SPColors.dietLightGreen));
    });
  });
}
