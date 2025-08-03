import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

void main() {
  group('CategoryType', () {
    test('should have correct display names', () {
      expect(CategoryType.exercise.displayName, equals('운동'));
      expect(CategoryType.diet.displayName, equals('식단'));
    });

    test('should have correct icons', () {
      expect(CategoryType.exercise.icon, equals(Icons.fitness_center));
      expect(CategoryType.diet.icon, equals(Icons.restaurant));
    });
  });

  group('TrendDirection', () {
    test('should have correct display names', () {
      expect(TrendDirection.up.displayName, equals('증가'));
      expect(TrendDirection.down.displayName, equals('감소'));
      expect(TrendDirection.stable.displayName, equals('유지'));
    });

    test('should have correct icons', () {
      expect(TrendDirection.up.icon, equals(Icons.trending_up));
      expect(TrendDirection.down.icon, equals(Icons.trending_down));
      expect(TrendDirection.stable.icon, equals(Icons.trending_flat));
    });

    test('should have correct colors', () {
      expect(TrendDirection.up.color, equals(SPColors.success100));
      expect(TrendDirection.down.color, equals(SPColors.danger100));
      expect(TrendDirection.stable.color, equals(SPColors.gray600));
    });
  });

  group('SubcategoryData', () {
    test('should create instance with required fields', () {
      const subcategory = SubcategoryData(name: 'Test Subcategory', count: 5, percentage: 25.0);

      expect(subcategory.name, equals('Test Subcategory'));
      expect(subcategory.count, equals(5));
      expect(subcategory.percentage, equals(25.0));
      expect(subcategory.description, isNull);
      expect(subcategory.emoji, isNull);
    });

    test('should create instance with all fields', () {
      const subcategory = SubcategoryData(
        name: 'Test Subcategory',
        count: 5,
        percentage: 25.0,
        description: 'Test description',
        emoji: '🏃',
      );

      expect(subcategory.name, equals('Test Subcategory'));
      expect(subcategory.count, equals(5));
      expect(subcategory.percentage, equals(25.0));
      expect(subcategory.description, equals('Test description'));
      expect(subcategory.emoji, equals('🏃'));
    });

    test('should create from map', () {
      final map = {
        'name': 'Test Subcategory',
        'count': 5,
        'percentage': 25.0,
        'description': 'Test description',
        'emoji': '🏃',
      };

      final subcategory = SubcategoryData.fromMap(map);

      expect(subcategory.name, equals('Test Subcategory'));
      expect(subcategory.count, equals(5));
      expect(subcategory.percentage, equals(25.0));
      expect(subcategory.description, equals('Test description'));
      expect(subcategory.emoji, equals('🏃'));
    });

    test('should convert to map', () {
      const subcategory = SubcategoryData(
        name: 'Test Subcategory',
        count: 5,
        percentage: 25.0,
        description: 'Test description',
        emoji: '🏃',
      );

      final map = subcategory.toMap();

      expect(map['name'], equals('Test Subcategory'));
      expect(map['count'], equals(5));
      expect(map['percentage'], equals(25.0));
      expect(map['description'], equals('Test description'));
      expect(map['emoji'], equals('🏃'));
    });

    test('should copy with modifications', () {
      const original = SubcategoryData(name: 'Original', count: 5, percentage: 25.0);

      final modified = original.copyWith(name: 'Modified', count: 10);

      expect(modified.name, equals('Modified'));
      expect(modified.count, equals(10));
      expect(modified.percentage, equals(25.0)); // unchanged
    });

    test('should implement equality correctly', () {
      const subcategory1 = SubcategoryData(name: 'Test', count: 5, percentage: 25.0);

      const subcategory2 = SubcategoryData(name: 'Test', count: 5, percentage: 25.0);

      const subcategory3 = SubcategoryData(name: 'Different', count: 5, percentage: 25.0);

      expect(subcategory1, equals(subcategory2));
      expect(subcategory1, isNot(equals(subcategory3)));
    });
  });

  group('CategoryVisualizationData', () {
    test('should create instance with required fields', () {
      const category = CategoryVisualizationData(
        categoryName: 'Test Category',
        emoji: '🏃',
        count: 10,
        percentage: 50.0,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
      );

      expect(category.categoryName, equals('Test Category'));
      expect(category.emoji, equals('🏃'));
      expect(category.count, equals(10));
      expect(category.percentage, equals(50.0));
      expect(category.color, equals(SPColors.podGreen));
      expect(category.type, equals(CategoryType.exercise));
      expect(category.subcategories, isEmpty);
      expect(category.isActive, isTrue);
    });

    test('should create from exercise category', () {
      final category = CategoryVisualizationData.fromExerciseCategory(
        ExerciseCategory.cardio,
        10,
        50.0,
        SPColors.podBlue,
      );

      expect(category.categoryName, equals('유산소 운동'));
      expect(category.emoji, equals('🏃'));
      expect(category.count, equals(10));
      expect(category.percentage, equals(50.0));
      expect(category.color, equals(SPColors.podBlue));
      expect(category.type, equals(CategoryType.exercise));
    });

    test('should create from diet category', () {
      final category = CategoryVisualizationData.fromDietCategory(DietCategory.healthy, 5, 25.0, SPColors.podGreen);

      expect(category.categoryName, equals('건강식/샐러드'));
      expect(category.emoji, equals('🥗'));
      expect(category.count, equals(5));
      expect(category.percentage, equals(25.0));
      expect(category.color, equals(SPColors.podGreen));
      expect(category.type, equals(CategoryType.diet));
    });

    test('should create from map', () {
      final map = {
        'categoryName': 'Test Category',
        'emoji': '🏃',
        'count': 10,
        'percentage': 50.0,
        'color': SPColors.podGreen.value,
        'type': 'exercise',
        'subcategories': [],
        'isActive': true,
      };

      final category = CategoryVisualizationData.fromMap(map);

      expect(category.categoryName, equals('Test Category'));
      expect(category.emoji, equals('🏃'));
      expect(category.count, equals(10));
      expect(category.percentage, equals(50.0));
      expect(category.color, equals(SPColors.podGreen));
      expect(category.type, equals(CategoryType.exercise));
      expect(category.isActive, isTrue);
    });

    test('should convert to map', () {
      const category = CategoryVisualizationData(
        categoryName: 'Test Category',
        emoji: '🏃',
        count: 10,
        percentage: 50.0,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
      );

      final map = category.toMap();

      expect(map['categoryName'], equals('Test Category'));
      expect(map['emoji'], equals('🏃'));
      expect(map['count'], equals(10));
      expect(map['percentage'], equals(50.0));
      expect(map['color'], equals(SPColors.podGreen.value));
      expect(map['type'], equals('exercise'));
      expect(map['isActive'], isTrue);
    });

    test('should calculate total subcategory count', () {
      const category = CategoryVisualizationData(
        categoryName: 'Test Category',
        emoji: '🏃',
        count: 10,
        percentage: 50.0,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
        subcategories: [
          SubcategoryData(name: 'Sub1', count: 3, percentage: 15.0),
          SubcategoryData(name: 'Sub2', count: 7, percentage: 35.0),
        ],
      );

      expect(category.totalSubcategoryCount, equals(10));
      expect(category.hasSubcategories, isTrue);
    });

    test('should format percentage correctly', () {
      const category = CategoryVisualizationData(
        categoryName: 'Test Category',
        emoji: '🏃',
        count: 10,
        percentage: 33.333,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
      );

      expect(category.formattedPercentage, equals('33.3%'));
    });

    test('should create display text with emoji', () {
      const category = CategoryVisualizationData(
        categoryName: 'Test Category',
        emoji: '🏃',
        count: 10,
        percentage: 50.0,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
      );

      expect(category.displayText, equals('🏃 Test Category'));
    });

    test('should copy with modifications', () {
      const original = CategoryVisualizationData(
        categoryName: 'Original',
        emoji: '🏃',
        count: 10,
        percentage: 50.0,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
      );

      final modified = original.copyWith(categoryName: 'Modified', count: 20);

      expect(modified.categoryName, equals('Modified'));
      expect(modified.count, equals(20));
      expect(modified.percentage, equals(50.0)); // unchanged
      expect(modified.emoji, equals('🏃')); // unchanged
    });
  });

  group('CategoryTrendData', () {
    test('should create instance with required fields', () {
      final trendData = CategoryTrendData(
        exerciseCategoryTrends: {'운동1': TrendDirection.up},
        dietCategoryTrends: {'식단1': TrendDirection.down},
        categoryChangePercentages: {'운동1': 10.0, '식단1': -5.0},
        emergingCategories: ['운동1'],
        decliningCategories: ['식단1'],
        analysisDate: DateTime(2024, 1, 1),
      );

      expect(trendData.exerciseCategoryTrends['운동1'], equals(TrendDirection.up));
      expect(trendData.dietCategoryTrends['식단1'], equals(TrendDirection.down));
      expect(trendData.categoryChangePercentages['운동1'], equals(10.0));
      expect(trendData.emergingCategories, contains('운동1'));
      expect(trendData.decliningCategories, contains('식단1'));
      expect(trendData.weeksAnalyzed, equals(4)); // default value
    });

    test('should create empty trend data', () {
      final emptyTrend = CategoryTrendData.empty();

      expect(emptyTrend.exerciseCategoryTrends, isEmpty);
      expect(emptyTrend.dietCategoryTrends, isEmpty);
      expect(emptyTrend.categoryChangePercentages, isEmpty);
      expect(emptyTrend.emergingCategories, isEmpty);
      expect(emptyTrend.decliningCategories, isEmpty);
      expect(emptyTrend.weeksAnalyzed, equals(0));
    });

    test('should create from map', () {
      final map = {
        'exerciseCategoryTrends': {'운동1': 'up'},
        'dietCategoryTrends': {'식단1': 'down'},
        'categoryChangePercentages': {'운동1': 10.0, '식단1': -5.0},
        'emergingCategories': ['운동1'],
        'decliningCategories': ['식단1'],
        'analysisDate': '2024-01-01T00:00:00.000',
        'weeksAnalyzed': 4,
      };

      final trendData = CategoryTrendData.fromMap(map);

      expect(trendData.exerciseCategoryTrends['운동1'], equals(TrendDirection.up));
      expect(trendData.dietCategoryTrends['식단1'], equals(TrendDirection.down));
      expect(trendData.categoryChangePercentages['운동1'], equals(10.0));
      expect(trendData.emergingCategories, contains('운동1'));
      expect(trendData.decliningCategories, contains('식단1'));
      expect(trendData.weeksAnalyzed, equals(4));
    });

    test('should convert to map', () {
      final trendData = CategoryTrendData(
        exerciseCategoryTrends: {'운동1': TrendDirection.up},
        dietCategoryTrends: {'식단1': TrendDirection.down},
        categoryChangePercentages: {'운동1': 10.0, '식단1': -5.0},
        emergingCategories: ['운동1'],
        decliningCategories: ['식단1'],
        analysisDate: DateTime(2024, 1, 1),
      );

      final map = trendData.toMap();

      expect(map['exerciseCategoryTrends']['운동1'], equals('up'));
      expect(map['dietCategoryTrends']['식단1'], equals('down'));
      expect(map['categoryChangePercentages']['운동1'], equals(10.0));
      expect(map['emergingCategories'], contains('운동1'));
      expect(map['decliningCategories'], contains('식단1'));
    });

    test('should get trend for specific category', () {
      final trendData = CategoryTrendData(
        exerciseCategoryTrends: {'운동1': TrendDirection.up},
        dietCategoryTrends: {'식단1': TrendDirection.down},
        categoryChangePercentages: {},
        emergingCategories: [],
        decliningCategories: [],
        analysisDate: DateTime.now(),
      );

      expect(trendData.getTrendForCategory('운동1', CategoryType.exercise), equals(TrendDirection.up));
      expect(trendData.getTrendForCategory('식단1', CategoryType.diet), equals(TrendDirection.down));
      expect(trendData.getTrendForCategory('없는카테고리', CategoryType.exercise), isNull);
    });

    test('should check category status correctly', () {
      final trendData = CategoryTrendData(
        exerciseCategoryTrends: {},
        dietCategoryTrends: {},
        categoryChangePercentages: {'운동1': 10.0, '식단1': -5.0},
        emergingCategories: ['운동1'],
        decliningCategories: ['식단1'],
        analysisDate: DateTime.now(),
      );

      expect(trendData.isCategoryEmerging('운동1'), isTrue);
      expect(trendData.isCategoryDeclining('식단1'), isTrue);
      expect(trendData.isCategoryEmerging('식단1'), isFalse);
      expect(trendData.getChangePercentageForCategory('운동1'), equals(10.0));
      expect(trendData.getChangePercentageForCategory('없는카테고리'), equals(0.0));
    });

    test('should calculate totals correctly', () {
      final trendData = CategoryTrendData(
        exerciseCategoryTrends: {'운동1': TrendDirection.up, '운동2': TrendDirection.stable},
        dietCategoryTrends: {'식단1': TrendDirection.down},
        categoryChangePercentages: {},
        emergingCategories: ['운동1'],
        decliningCategories: ['식단1'],
        analysisDate: DateTime.now(),
      );

      expect(trendData.totalCategoriesAnalyzed, equals(3));
      expect(trendData.allTrendingCategories, hasLength(2));
      expect(trendData.hasTrendData, isTrue);
    });

    test('should copy with modifications', () {
      final original = CategoryTrendData(
        exerciseCategoryTrends: {'운동1': TrendDirection.up},
        dietCategoryTrends: {},
        categoryChangePercentages: {},
        emergingCategories: [],
        decliningCategories: [],
        analysisDate: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(dietCategoryTrends: {'식단1': TrendDirection.down}, weeksAnalyzed: 8);

      expect(modified.exerciseCategoryTrends['운동1'], equals(TrendDirection.up)); // unchanged
      expect(modified.dietCategoryTrends['식단1'], equals(TrendDirection.down)); // changed
      expect(modified.weeksAnalyzed, equals(8)); // changed
    });
  });

  group('CategoryColorUtils', () {
    test('should get exercise category colors', () {
      final strengthColor = CategoryColorUtils.getExerciseCategoryColor(ExerciseCategory.strength);
      final cardioColor = CategoryColorUtils.getExerciseCategoryColor(ExerciseCategory.cardio);

      expect(strengthColor, isA<Color>());
      expect(cardioColor, isA<Color>());
      expect(strengthColor, isNot(equals(cardioColor)));
    });

    test('should get diet category colors', () {
      final homeMadeColor = CategoryColorUtils.getDietCategoryColor(DietCategory.homeMade);
      final healthyColor = CategoryColorUtils.getDietCategoryColor(DietCategory.healthy);

      expect(homeMadeColor, isA<Color>());
      expect(healthyColor, isA<Color>());
      expect(homeMadeColor, isNot(equals(healthyColor)));
    });

    test('should get category color by name and type', () {
      final exerciseColor = CategoryColorUtils.getCategoryColor('근력 운동', CategoryType.exercise);
      final dietColor = CategoryColorUtils.getCategoryColor('집밥/도시락', CategoryType.diet);

      expect(exerciseColor, isA<Color>());
      expect(dietColor, isA<Color>());
    });

    test('should handle unknown category names gracefully', () {
      final unknownExerciseColor = CategoryColorUtils.getCategoryColor('알 수 없는 운동', CategoryType.exercise);
      final unknownDietColor = CategoryColorUtils.getCategoryColor('알 수 없는 식단', CategoryType.diet);

      expect(unknownExerciseColor, isA<Color>());
      expect(unknownDietColor, isA<Color>());
    });

    test('should get color by index', () {
      final color0 = CategoryColorUtils.getCategoryColorByIndex(0);
      final color1 = CategoryColorUtils.getCategoryColorByIndex(1);
      final colorWrapped = CategoryColorUtils.getCategoryColorByIndex(100); // should wrap around

      expect(color0, isA<Color>());
      expect(color1, isA<Color>());
      expect(colorWrapped, isA<Color>());
      expect(color0, isNot(equals(color1)));
    });

    test('should generate gradient colors', () {
      const baseColor = SPColors.podGreen;
      final gradient = CategoryColorUtils.getCategoryGradient(baseColor);

      expect(gradient, hasLength(2));
      expect(gradient[0], equals(baseColor));
      expect(gradient[1], isNot(equals(baseColor)));
    });

    test('should get contrasting text color', () {
      final lightTextColor = CategoryColorUtils.getContrastingTextColor(Colors.white);
      final darkTextColor = CategoryColorUtils.getContrastingTextColor(Colors.black);

      expect(lightTextColor, equals(Colors.black));
      expect(darkTextColor, equals(Colors.white));
    });

    test('should provide all category colors', () {
      final allColors = CategoryColorUtils.allCategoryColors;

      expect(allColors, isNotEmpty);
      expect(allColors, contains(SPColors.podGreen));
      expect(allColors, contains(SPColors.podBlue));
    });
  });
}
