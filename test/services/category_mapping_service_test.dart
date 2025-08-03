import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/services/category_mapping_service.dart';

void main() {
  group('CategoryMappingService', () {
    late CategoryMappingService service;

    setUp(() {
      service = CategoryMappingService.instance;
    });

    group('Exercise Category Mapping', () {
      test('should return correct colors for all exercise categories', () {
        for (final category in ExerciseCategory.values) {
          final color = service.getExerciseCategoryColor(category);
          expect(color, isA<Color>());
          expect(color, isNot(equals(Colors.transparent)));
        }
      });

      test('should return correct emojis for all exercise categories', () {
        for (final category in ExerciseCategory.values) {
          final emoji = service.getExerciseCategoryEmoji(category);
          expect(emoji, isNotEmpty);
          expect(emoji, equals(category.emoji));
        }
      });

      test('should return consistent colors for same category', () {
        final color1 = service.getExerciseCategoryColor(ExerciseCategory.strength);
        final color2 = service.getExerciseCategoryColor(ExerciseCategory.strength);
        expect(color1, equals(color2));
      });
    });

    group('Diet Category Mapping', () {
      test('should return correct colors for all diet categories', () {
        for (final category in DietCategory.values) {
          final color = service.getDietCategoryColor(category);
          expect(color, isA<Color>());
          expect(color, isNot(equals(Colors.transparent)));
        }
      });

      test('should return correct emojis for all diet categories', () {
        for (final category in DietCategory.values) {
          final emoji = service.getDietCategoryEmoji(category);
          expect(emoji, isNotEmpty);
          expect(emoji, equals(category.emoji));
        }
      });

      test('should return consistent colors for same category', () {
        final color1 = service.getDietCategoryColor(DietCategory.homeMade);
        final color2 = service.getDietCategoryColor(DietCategory.homeMade);
        expect(color1, equals(color2));
      });
    });

    group('Dynamic Category Handling', () {
      test('should handle known exercise categories by name', () {
        final color = service.getCategoryColorByName('근력 운동', CategoryType.exercise);
        final expectedColor = service.getExerciseCategoryColor(ExerciseCategory.strength);
        expect(color, equals(expectedColor));
      });

      test('should handle known diet categories by name', () {
        final color = service.getCategoryColorByName('집밥/도시락', CategoryType.diet);
        final expectedColor = service.getDietCategoryColor(DietCategory.homeMade);
        expect(color, equals(expectedColor));
      });

      test('should generate fallback colors for unknown categories', () {
        final color1 = service.getCategoryColorByName('Unknown Exercise', CategoryType.exercise);
        final color2 = service.getCategoryColorByName('Unknown Diet', CategoryType.diet);

        expect(color1, isA<Color>());
        expect(color2, isA<Color>());
        expect(color1, isNot(equals(Colors.transparent)));
        expect(color2, isNot(equals(Colors.transparent)));
      });

      test('should generate consistent colors for same unknown category', () {
        final color1 = service.getCategoryColorByName('Custom Exercise', CategoryType.exercise);
        final color2 = service.getCategoryColorByName('Custom Exercise', CategoryType.exercise);
        expect(color1, equals(color2));
      });

      test('should handle known exercise emojis by name', () {
        final emoji = service.getCategoryEmojiByName('근력 운동', CategoryType.exercise);
        expect(emoji, equals('💪'));
      });

      test('should handle known diet emojis by name', () {
        final emoji = service.getCategoryEmojiByName('집밥/도시락', CategoryType.diet);
        expect(emoji, equals('🍱'));
      });

      test('should generate fallback emojis for unknown categories', () {
        final exerciseEmoji = service.getCategoryEmojiByName('Unknown Exercise', CategoryType.exercise);
        final dietEmoji = service.getCategoryEmojiByName('Unknown Diet', CategoryType.diet);

        expect(exerciseEmoji, equals('🏃'));
        expect(dietEmoji, equals('🍽️'));
      });
    });

    group('Accessibility Features', () {
      test('should provide accessible colors for light mode', () {
        final baseColor = service.getExerciseCategoryColor(ExerciseCategory.strength);
        final accessibleColor = service.getAccessibleColor(baseColor, isDarkMode: false);

        expect(accessibleColor, isA<Color>());
        expect(accessibleColor, isNot(equals(Colors.transparent)));
      });

      test('should provide accessible colors for dark mode', () {
        final baseColor = service.getExerciseCategoryColor(ExerciseCategory.strength);
        final accessibleColor = service.getAccessibleColor(baseColor, isDarkMode: true);

        expect(accessibleColor, isA<Color>());
        expect(accessibleColor, isNot(equals(Colors.transparent)));
      });

      test('should validate contrast ratios', () {
        final foreground = Colors.black;
        final background = Colors.white;

        expect(service.hasGoodContrast(foreground, background), isTrue);

        final lowContrast1 = Colors.grey[300]!;
        final lowContrast2 = Colors.grey[400]!;

        expect(service.hasGoodContrast(lowContrast1, lowContrast2), isFalse);
      });
    });

    group('Visualization Data Generation', () {
      test('should generate exercise category visualization data', () {
        final categoryData = {'근력 운동': 5, '유산소 운동': 3, '스트레칭/요가': 2};

        final visualizationData = service.getExerciseCategoryVisualizationData(categoryData);

        expect(visualizationData, hasLength(3));

        final strengthData = visualizationData.firstWhere((data) => data.categoryName == '근력 운동');
        expect(strengthData.count, equals(5));
        expect(strengthData.percentage, equals(0.5)); // 5/10
        expect(strengthData.emoji, equals('💪'));
        expect(strengthData.type, equals(CategoryType.exercise));
      });

      test('should generate diet category visualization data', () {
        final categoryData = {'집밥/도시락': 4, '건강식/샐러드': 2, '단백질 위주': 1};

        final visualizationData = service.getDietCategoryVisualizationData(categoryData);

        expect(visualizationData, hasLength(3));

        final homeMadeData = visualizationData.firstWhere((data) => data.categoryName == '집밥/도시락');
        expect(homeMadeData.count, equals(4));
        expect(homeMadeData.percentage, closeTo(0.571, 0.01)); // 4/7
        expect(homeMadeData.emoji, equals('🍱'));
        expect(homeMadeData.type, equals(CategoryType.diet));
      });

      test('should handle empty category data', () {
        final exerciseData = service.getExerciseCategoryVisualizationData({});
        final dietData = service.getDietCategoryVisualizationData({});

        expect(exerciseData, isEmpty);
        expect(dietData, isEmpty);
      });

      test('should handle single category data', () {
        final categoryData = {'근력 운동': 1};
        final visualizationData = service.getExerciseCategoryVisualizationData(categoryData);

        expect(visualizationData, hasLength(1));
        expect(visualizationData.first.percentage, equals(1.0));
      });
    });

    group('Color Properties', () {
      test('should have different colors for different exercise categories', () {
        final colors = ExerciseCategory.values.map((category) => service.getExerciseCategoryColor(category)).toList();

        // Check that we have some variety in colors (not all the same)
        final uniqueColors = colors.toSet();
        expect(uniqueColors.length, greaterThan(1));
      });

      test('should have different colors for different diet categories', () {
        final colors = DietCategory.values.map((category) => service.getDietCategoryColor(category)).toList();

        // Check that we have some variety in colors (not all the same)
        final uniqueColors = colors.toSet();
        expect(uniqueColors.length, greaterThan(1));
      });

      test('should provide exercise and diet category color maps', () {
        final exerciseColors = service.exerciseCategoryColors;
        final dietColors = service.dietCategoryColors;

        expect(exerciseColors, hasLength(ExerciseCategory.values.length));
        expect(dietColors, hasLength(DietCategory.values.length));

        for (final category in ExerciseCategory.values) {
          expect(exerciseColors.containsKey(category), isTrue);
        }

        for (final category in DietCategory.values) {
          expect(dietColors.containsKey(category), isTrue);
        }
      });
    });
  });
}
