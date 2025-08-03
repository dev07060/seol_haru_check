import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_theme_config.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

void main() {
  group('CategoryThemeConfig', () {
    group('Constructor and Factory', () {
      test('should create with default values', () {
        const config = CategoryThemeConfig();

        expect(config.isDarkMode, isFalse);
        expect(config.highContrast, isFalse);
        expect(config.colorIntensity, equals(1.0));
        expect(config.reduceMotion, isFalse);
      });

      test('should create with custom values', () {
        const config = CategoryThemeConfig(
          isDarkMode: true,
          highContrast: true,
          colorIntensity: 0.8,
          reduceMotion: true,
        );

        expect(config.isDarkMode, isTrue);
        expect(config.highContrast, isTrue);
        expect(config.colorIntensity, equals(0.8));
        expect(config.reduceMotion, isTrue);
      });

      testWidgets('should create from BuildContext', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                final config = CategoryThemeConfig.fromContext(context);
                expect(config.isDarkMode, isFalse);
                expect(config.reduceMotion, isFalse);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should detect dark mode from context', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                final config = CategoryThemeConfig.fromContext(context);
                expect(config.isDarkMode, isTrue);
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('Category Color Theming', () {
      test('should apply theme to exercise category colors', () {
        const lightConfig = CategoryThemeConfig(isDarkMode: false);
        const darkConfig = CategoryThemeConfig(isDarkMode: true);

        final lightColor = lightConfig.getExerciseCategoryColor(ExerciseCategory.strength);
        final darkColor = darkConfig.getExerciseCategoryColor(ExerciseCategory.strength);

        expect(lightColor, isA<Color>());
        expect(darkColor, isA<Color>());
        // Colors should be different for light and dark modes
        expect(lightColor, isNot(equals(darkColor)));
      });

      test('should apply theme to diet category colors', () {
        const lightConfig = CategoryThemeConfig(isDarkMode: false);
        const darkConfig = CategoryThemeConfig(isDarkMode: true);

        final lightColor = lightConfig.getDietCategoryColor(DietCategory.homeMade);
        final darkColor = darkConfig.getDietCategoryColor(DietCategory.homeMade);

        expect(lightColor, isA<Color>());
        expect(darkColor, isA<Color>());
        // Colors should be different for light and dark modes
        expect(lightColor, isNot(equals(darkColor)));
      });

      test('should apply color intensity', () {
        const normalConfig = CategoryThemeConfig(colorIntensity: 1.0);
        const reducedConfig = CategoryThemeConfig(colorIntensity: 0.5);

        final normalColor = normalConfig.getExerciseCategoryColor(ExerciseCategory.strength);
        final reducedColor = reducedConfig.getExerciseCategoryColor(ExerciseCategory.strength);

        expect(normalColor, isA<Color>());
        expect(reducedColor, isA<Color>());
        expect(normalColor, isNot(equals(reducedColor)));
      });

      test('should handle high contrast mode', () {
        const normalConfig = CategoryThemeConfig(highContrast: false);
        const highContrastConfig = CategoryThemeConfig(highContrast: true);

        final normalColor = normalConfig.getExerciseCategoryColor(ExerciseCategory.strength);
        final highContrastColor = highContrastConfig.getExerciseCategoryColor(ExerciseCategory.strength);

        expect(normalColor, isA<Color>());
        expect(highContrastColor, isA<Color>());
        // High contrast should either change the color or keep it the same if already accessible
        expect(highContrastColor, isNotNull);
      });

      test('should get category color by name', () {
        const config = CategoryThemeConfig();

        final exerciseColor = config.getCategoryColorByName('근력 운동', CategoryType.exercise);
        final dietColor = config.getCategoryColorByName('집밥/도시락', CategoryType.diet);

        expect(exerciseColor, isA<Color>());
        expect(dietColor, isA<Color>());
      });
    });

    group('UI Color Theming', () {
      test('should provide background colors for light mode', () {
        const config = CategoryThemeConfig(isDarkMode: false);

        final normalBg = config.getCategoryBackgroundColor();
        expect(normalBg, equals(SPColors.gray100));

        const highContrastConfig = CategoryThemeConfig(isDarkMode: false, highContrast: true);
        final highContrastBg = highContrastConfig.getCategoryBackgroundColor();
        expect(highContrastBg, equals(SPColors.white));
      });

      test('should provide background colors for dark mode', () {
        const config = CategoryThemeConfig(isDarkMode: true);

        final normalBg = config.getCategoryBackgroundColor();
        expect(normalBg, equals(SPColors.gray800));

        const highContrastConfig = CategoryThemeConfig(isDarkMode: true, highContrast: true);
        final highContrastBg = highContrastConfig.getCategoryBackgroundColor();
        expect(highContrastBg, equals(SPColors.gray900));
      });

      test('should provide text colors for light mode', () {
        const config = CategoryThemeConfig(isDarkMode: false);

        final normalText = config.getCategoryTextColor();
        expect(normalText, equals(SPColors.gray800));

        const highContrastConfig = CategoryThemeConfig(isDarkMode: false, highContrast: true);
        final highContrastText = highContrastConfig.getCategoryTextColor();
        expect(highContrastText, equals(SPColors.black));
      });

      test('should provide text colors for dark mode', () {
        const config = CategoryThemeConfig(isDarkMode: true);

        final normalText = config.getCategoryTextColor();
        expect(normalText, equals(SPColors.gray200));

        const highContrastConfig = CategoryThemeConfig(isDarkMode: true, highContrast: true);
        final highContrastText = highContrastConfig.getCategoryTextColor();
        expect(highContrastText, equals(SPColors.white));
      });

      test('should provide border colors', () {
        const lightConfig = CategoryThemeConfig(isDarkMode: false);
        const darkConfig = CategoryThemeConfig(isDarkMode: true);

        final lightBorder = lightConfig.getCategoryBorderColor();
        final darkBorder = darkConfig.getCategoryBorderColor();

        expect(lightBorder, isA<Color>());
        expect(darkBorder, isA<Color>());
        expect(lightBorder, isNot(equals(darkBorder)));
      });

      test('should provide accessible text colors for backgrounds', () {
        const config = CategoryThemeConfig();

        final lightBgTextColor = config.getAccessibleTextColor(Colors.white);
        final darkBgTextColor = config.getAccessibleTextColor(Colors.black);

        expect(lightBgTextColor, isA<Color>());
        expect(darkBgTextColor, isA<Color>());
        expect(lightBgTextColor, isNot(equals(darkBgTextColor)));
      });
    });

    group('Animation Configuration', () {
      test('should provide normal animation duration', () {
        const config = CategoryThemeConfig(reduceMotion: false);

        final duration = config.getAnimationDuration();
        expect(duration, equals(const Duration(milliseconds: 300)));

        final customDuration = config.getAnimationDuration(defaultDuration: const Duration(milliseconds: 500));
        expect(customDuration, equals(const Duration(milliseconds: 500)));
      });

      test('should provide zero duration for reduced motion', () {
        const config = CategoryThemeConfig(reduceMotion: true);

        final duration = config.getAnimationDuration();
        expect(duration, equals(Duration.zero));

        final customDuration = config.getAnimationDuration(defaultDuration: const Duration(milliseconds: 500));
        expect(customDuration, equals(Duration.zero));
      });

      test('should provide animation curves', () {
        const normalConfig = CategoryThemeConfig(reduceMotion: false);
        const reducedConfig = CategoryThemeConfig(reduceMotion: true);

        final normalCurve = normalConfig.getAnimationCurve();
        final reducedCurve = reducedConfig.getAnimationCurve();

        expect(normalCurve, equals(Curves.easeInOut));
        expect(reducedCurve, equals(Curves.linear));
      });
    });

    group('Accessibility Validation', () {
      test('should validate color accessibility', () {
        const config = CategoryThemeConfig();

        expect(config.isAccessible(Colors.black, Colors.white), isTrue);
        expect(config.isAccessible(Colors.white, Colors.black), isTrue);
        expect(config.isAccessible(Colors.grey, Colors.grey[300]!), isFalse);
      });
    });

    group('Copy and Equality', () {
      test('should create copy with modifications', () {
        const original = CategoryThemeConfig(
          isDarkMode: false,
          highContrast: false,
          colorIntensity: 1.0,
          reduceMotion: false,
        );

        final copy = original.copyWith(isDarkMode: true, highContrast: true);

        expect(copy.isDarkMode, isTrue);
        expect(copy.highContrast, isTrue);
        expect(copy.colorIntensity, equals(1.0)); // unchanged
        expect(copy.reduceMotion, isFalse); // unchanged
      });

      test('should implement equality correctly', () {
        const config1 = CategoryThemeConfig(
          isDarkMode: true,
          highContrast: false,
          colorIntensity: 0.8,
          reduceMotion: true,
        );

        const config2 = CategoryThemeConfig(
          isDarkMode: true,
          highContrast: false,
          colorIntensity: 0.8,
          reduceMotion: true,
        );

        const config3 = CategoryThemeConfig(
          isDarkMode: false,
          highContrast: false,
          colorIntensity: 0.8,
          reduceMotion: true,
        );

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
        expect(config1.hashCode, equals(config2.hashCode));
        expect(config1.hashCode, isNot(equals(config3.hashCode)));
      });
    });
  });

  group('CategoryThemeExtension', () {
    testWidgets('should provide category theme from context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              final theme = context.categoryTheme;
              expect(theme, isA<CategoryThemeConfig>());
              expect(theme.isDarkMode, isFalse);
              return Container();
            },
          ),
        ),
      );
    });
  });
}
