import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/extensions/category_extensions.dart';
import 'package:seol_haru_check/models/category_theme_config.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';

void main() {
  group('ExerciseCategoryExtensions', () {
    test('should get color for exercise category', () {
      final color = ExerciseCategory.strength.color;
      expect(color, isA<Color>());
      expect(color, isNot(equals(Colors.transparent)));
    });

    test('should get themed color for exercise category', () {
      const theme = CategoryThemeConfig(isDarkMode: true);
      final color = ExerciseCategory.strength.getThemedColor(theme);
      expect(color, isA<Color>());
      expect(color, isNot(equals(Colors.transparent)));
    });

    test('should create visualization data', () {
      final data = ExerciseCategory.strength.toVisualizationData(count: 5, percentage: 0.5);

      expect(data.categoryName, equals('근력 운동'));
      expect(data.emoji, equals('💪'));
      expect(data.count, equals(5));
      expect(data.percentage, equals(0.5));
      expect(data.type, equals(CategoryType.exercise));
    });
  });

  group('DietCategoryExtensions', () {
    test('should get color for diet category', () {
      final color = DietCategory.homeMade.color;
      expect(color, isA<Color>());
      expect(color, isNot(equals(Colors.transparent)));
    });

    test('should get themed color for diet category', () {
      const theme = CategoryThemeConfig(isDarkMode: true);
      final color = DietCategory.homeMade.getThemedColor(theme);
      expect(color, isA<Color>());
      expect(color, isNot(equals(Colors.transparent)));
    });

    test('should create visualization data', () {
      final data = DietCategory.homeMade.toVisualizationData(count: 3, percentage: 0.3);

      expect(data.categoryName, equals('집밥/도시락'));
      expect(data.emoji, equals('🍱'));
      expect(data.count, equals(3));
      expect(data.percentage, equals(0.3));
      expect(data.type, equals(CategoryType.diet));
    });
  });

  group('CategoryTypeExtensions', () {
    test('should get all exercise category names', () {
      final names = CategoryType.exercise.allCategoryNames;
      expect(names, contains('근력 운동'));
      expect(names, contains('유산소 운동'));
      expect(names.length, equals(ExerciseCategory.values.length));
    });

    test('should get all diet category names', () {
      final names = CategoryType.diet.allCategoryNames;
      expect(names, contains('집밥/도시락'));
      expect(names, contains('건강식/샐러드'));
      expect(names.length, equals(DietCategory.values.length));
    });

    test('should get all exercise category emojis', () {
      final emojis = CategoryType.exercise.allCategoryEmojis;
      expect(emojis, contains('💪'));
      expect(emojis, contains('🏃'));
      expect(emojis.length, equals(ExerciseCategory.values.length));
    });

    test('should get all diet category emojis', () {
      final emojis = CategoryType.diet.allCategoryEmojis;
      expect(emojis, contains('🍱'));
      expect(emojis, contains('🥗'));
      expect(emojis.length, equals(DietCategory.values.length));
    });

    test('should get category color by name', () {
      final color = CategoryType.exercise.getCategoryColor('근력 운동');
      expect(color, isA<Color>());
      expect(color, isNot(equals(Colors.transparent)));
    });

    test('should get category emoji by name', () {
      final emoji = CategoryType.exercise.getCategoryEmoji('근력 운동');
      expect(emoji, equals('💪'));
    });

    test('should create visualization data from map', () {
      final categoryData = {'근력 운동': 5, '유산소 운동': 3};

      final visualizationData = CategoryType.exercise.createVisualizationData(categoryData);
      expect(visualizationData, hasLength(2));

      final strengthData = visualizationData.firstWhere((data) => data.categoryName == '근력 운동');
      expect(strengthData.count, equals(5));
      expect(strengthData.emoji, equals('💪'));
    });
  });

  group('CategoryNameExtensions', () {
    test('should convert to exercise category', () {
      final category = '근력 운동'.asExerciseCategory;
      expect(category, equals(ExerciseCategory.strength));
    });

    test('should convert to diet category', () {
      final category = '집밥/도시락'.asDietCategory;
      expect(category, equals(DietCategory.homeMade));
    });

    test('should return null for unknown exercise category', () {
      final category = 'Unknown Exercise'.asExerciseCategory;
      expect(category, isNull);
    });

    test('should return null for unknown diet category', () {
      final category = 'Unknown Diet'.asDietCategory;
      expect(category, isNull);
    });

    test('should check if known exercise category', () {
      expect('근력 운동'.isKnownExerciseCategory, isTrue);
      expect('Unknown Exercise'.isKnownExerciseCategory, isFalse);
    });

    test('should check if known diet category', () {
      expect('집밥/도시락'.isKnownDietCategory, isTrue);
      expect('Unknown Diet'.isKnownDietCategory, isFalse);
    });

    test('should get category color by name', () {
      final color = '근력 운동'.getCategoryColor(CategoryType.exercise);
      expect(color, isA<Color>());
      expect(color, isNot(equals(Colors.transparent)));
    });

    test('should get category emoji by name', () {
      final emoji = '근력 운동'.getCategoryEmoji(CategoryType.exercise);
      expect(emoji, equals('💪'));
    });
  });

  group('CategoryVisualizationDataExtensions', () {
    late CategoryVisualizationData testData;

    setUp(() {
      testData = CategoryVisualizationData(
        categoryName: '근력 운동',
        emoji: '💪',
        count: 5,
        percentage: 0.5,
        color: Colors.red,
        type: CategoryType.exercise,
      );
    });

    test('should apply theme', () {
      const theme = CategoryThemeConfig(isDarkMode: true);
      final themedData = testData.withTheme(theme);

      expect(themedData.categoryName, equals(testData.categoryName));
      expect(themedData.count, equals(testData.count));
      expect(themedData.color, isNot(equals(testData.color))); // Should be different due to theming
    });

    test('should get display text with count', () {
      final text = testData.displayTextWithCount;
      expect(text, equals('💪 근력 운동 (5)'));
    });

    test('should get display text with percentage', () {
      final text = testData.displayTextWithPercentage;
      expect(text, equals('💪 근력 운동 (50.0%)'));
    });

    test('should get display text with details', () {
      final text = testData.displayTextWithDetails;
      expect(text, equals('💪 근력 운동 (5, 50.0%)'));
    });

    test('should check if above average', () {
      final allCategories = [
        testData, // 50%
        CategoryVisualizationData(
          categoryName: '유산소 운동',
          emoji: '🏃',
          count: 2,
          percentage: 0.2,
          color: Colors.blue,
          type: CategoryType.exercise,
        ), // 20%
        CategoryVisualizationData(
          categoryName: '스트레칭/요가',
          emoji: '🧘',
          count: 3,
          percentage: 0.3,
          color: Colors.green,
          type: CategoryType.exercise,
        ), // 30%
      ];
      // Average: (50 + 20 + 30) / 3 = 33.33%

      expect(testData.isAboveAverage(allCategories), isTrue);
      expect(allCategories[1].isAboveAverage(allCategories), isFalse);
    });

    test('should get rank among categories', () {
      final allCategories = [
        CategoryVisualizationData(
          categoryName: '유산소 운동',
          emoji: '🏃',
          count: 2,
          percentage: 0.2,
          color: Colors.blue,
          type: CategoryType.exercise,
        ),
        testData, // count: 5
        CategoryVisualizationData(
          categoryName: '스트레칭/요가',
          emoji: '🧘',
          count: 3,
          percentage: 0.3,
          color: Colors.green,
          type: CategoryType.exercise,
        ),
      ];

      expect(testData.getRank(allCategories), equals(1)); // Highest count
    });
  });

  group('CategoryVisualizationDataListExtensions', () {
    late List<CategoryVisualizationData> testList;

    setUp(() {
      testList = [
        CategoryVisualizationData(
          categoryName: '근력 운동',
          emoji: '💪',
          count: 5,
          percentage: 0.5,
          color: Colors.red,
          type: CategoryType.exercise,
        ),
        CategoryVisualizationData(
          categoryName: '집밥/도시락',
          emoji: '🍱',
          count: 3,
          percentage: 0.3,
          color: Colors.yellow,
          type: CategoryType.diet,
        ),
        CategoryVisualizationData(
          categoryName: '유산소 운동',
          emoji: '🏃',
          count: 2,
          percentage: 0.2,
          color: Colors.blue,
          type: CategoryType.exercise,
          isActive: false,
        ),
      ];
    });

    test('should filter exercise categories', () {
      final exerciseCategories = testList.exerciseCategories;
      expect(exerciseCategories, hasLength(2));
      expect(exerciseCategories.every((data) => data.type == CategoryType.exercise), isTrue);
    });

    test('should filter diet categories', () {
      final dietCategories = testList.dietCategories;
      expect(dietCategories, hasLength(1));
      expect(dietCategories.every((data) => data.type == CategoryType.diet), isTrue);
    });

    test('should filter active categories', () {
      final activeCategories = testList.activeCategories;
      expect(activeCategories, hasLength(2));
      expect(activeCategories.every((data) => data.isActive), isTrue);
    });

    test('should sort by count', () {
      final sorted = testList.sortedByCount;
      expect(sorted[0].count, equals(5));
      expect(sorted[1].count, equals(3));
      expect(sorted[2].count, equals(2));
    });

    test('should sort by percentage', () {
      final sorted = testList.sortedByPercentage;
      expect(sorted[0].percentage, equals(0.5));
      expect(sorted[1].percentage, equals(0.3));
      expect(sorted[2].percentage, equals(0.2));
    });

    test('should sort by name', () {
      final sorted = testList.sortedByName;
      expect(sorted[0].categoryName, equals('근력 운동'));
      expect(sorted[1].categoryName, equals('유산소 운동'));
      expect(sorted[2].categoryName, equals('집밥/도시락'));
    });

    test('should get top categories by count', () {
      final top2 = testList.topByCount(2);
      expect(top2, hasLength(2));
      expect(top2[0].count, equals(5));
      expect(top2[1].count, equals(3));
    });

    test('should get top categories by percentage', () {
      final top2 = testList.topByPercentage(2);
      expect(top2, hasLength(2));
      expect(top2[0].percentage, equals(0.5));
      expect(top2[1].percentage, equals(0.3));
    });

    test('should get total count', () {
      final total = testList.totalCount;
      expect(total, equals(10)); // 5 + 3 + 2
    });

    test('should filter by count threshold', () {
      final filtered = testList.withCountAbove(2);
      expect(filtered, hasLength(2));
      expect(filtered.every((data) => data.count > 2), isTrue);
    });

    test('should filter by percentage threshold', () {
      final filtered = testList.withPercentageAbove(0.25);
      expect(filtered, hasLength(2));
      expect(filtered.every((data) => data.percentage > 0.25), isTrue);
    });

    test('should apply theme to all categories', () {
      const theme = CategoryThemeConfig(isDarkMode: true);
      final themed = testList.withTheme(theme);

      expect(themed, hasLength(testList.length));
      // Colors should be different due to theming
      for (int i = 0; i < themed.length; i++) {
        expect(themed[i].categoryName, equals(testList[i].categoryName));
        expect(themed[i].count, equals(testList[i].count));
      }
    });
  });
}
