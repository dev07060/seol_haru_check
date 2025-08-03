import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/unified_bar_chart_utils.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

void main() {
  group('UnifiedBarChartUtils', () {
    group('calculatePercentage', () {
      test('should calculate correct percentage', () {
        expect(UnifiedBarChartUtils.calculatePercentage(25, 100), 25.0);
        expect(UnifiedBarChartUtils.calculatePercentage(1, 3), closeTo(33.33, 0.01));
        expect(UnifiedBarChartUtils.calculatePercentage(0, 100), 0.0);
      });

      test('should handle zero total count', () {
        expect(UnifiedBarChartUtils.calculatePercentage(10, 0), 0.0);
      });
    });

    group('calculateSegments', () {
      late List<CategoryVisualizationData> exerciseCategories;
      late List<CategoryVisualizationData> dietCategories;

      setUp(() {
        exerciseCategories = [
          CategoryVisualizationData(
            categoryName: '근력 운동',
            emoji: '💪',
            count: 8,
            percentage: 0.0,
            color: SPColors.reportGreen,
            type: CategoryType.exercise,
          ),
          CategoryVisualizationData(
            categoryName: '유산소',
            emoji: '🏃',
            count: 2,
            percentage: 0.0,
            color: SPColors.reportBlue,
            type: CategoryType.exercise,
          ),
        ];

        dietCategories = [
          CategoryVisualizationData(
            categoryName: '한식',
            emoji: '🍚',
            count: 6,
            percentage: 0.0,
            color: SPColors.dietGreen,
            type: CategoryType.diet,
          ),
          CategoryVisualizationData(
            categoryName: '샐러드',
            emoji: '🥗',
            count: 4,
            percentage: 0.0,
            color: SPColors.dietLightGreen,
            type: CategoryType.diet,
          ),
        ];
      });

      test('should calculate segments with correct percentages', () {
        final segments = UnifiedBarChartUtils.calculateSegments(
          exerciseCategories: exerciseCategories,
          dietCategories: dietCategories,
        );

        expect(segments.length, 4);

        // Total count is 20, so percentages should be:
        // 근력 운동: 8/20 = 40%
        // 한식: 6/20 = 30%
        // 샐러드: 4/20 = 20%
        // 유산소: 2/20 = 10%

        final sortedSegments = segments..sort((a, b) => b.percentage.compareTo(a.percentage));
        expect(sortedSegments[0].percentage, 40.0);
        expect(sortedSegments[1].percentage, 30.0);
        expect(sortedSegments[2].percentage, 20.0);
        expect(sortedSegments[3].percentage, 10.0);
      });

      test('should handle empty categories', () {
        final segments = UnifiedBarChartUtils.calculateSegments(exerciseCategories: [], dietCategories: []);

        expect(segments.isEmpty, true);
      });

      test('should filter out zero count categories', () {
        final categoriesWithZero = [
          ...exerciseCategories,
          CategoryVisualizationData(
            categoryName: '요가',
            emoji: '🧘',
            count: 0,
            percentage: 0.0,
            color: SPColors.reportPurple,
            type: CategoryType.exercise,
          ),
        ];

        final segments = UnifiedBarChartUtils.calculateSegments(
          exerciseCategories: categoriesWithZero,
          dietCategories: dietCategories,
        );

        expect(segments.length, 4); // Should not include zero count category
        expect(segments.any((s) => s.category.categoryName == '요가'), false);
      });

      test('should enforce minimum segment width', () {
        final smallCategories = [
          CategoryVisualizationData(
            categoryName: '작은 카테고리',
            emoji: '🔸',
            count: 1,
            percentage: 0.0,
            color: SPColors.reportGreen,
            type: CategoryType.exercise,
          ),
        ];

        final largeCategories = [
          CategoryVisualizationData(
            categoryName: '큰 카테고리',
            emoji: '🔶',
            count: 99,
            percentage: 0.0,
            color: SPColors.dietGreen,
            type: CategoryType.diet,
          ),
        ];

        final segments = UnifiedBarChartUtils.calculateSegments(
          exerciseCategories: smallCategories,
          dietCategories: largeCategories,
          minSegmentWidth: 5.0,
        );

        expect(segments.length, 2);

        // Small segment should have minimum width
        final smallSegment = segments.firstWhere((s) => s.category.categoryName == '작은 카테고리');
        expect(smallSegment.effectiveWidth, 5.0);
      });

      test('should calculate correct positions', () {
        final segments = UnifiedBarChartUtils.calculateSegments(
          exerciseCategories: exerciseCategories,
          dietCategories: dietCategories,
        );

        // Verify positions are sequential and don't overlap
        segments.sort((a, b) => a.startPosition.compareTo(b.startPosition));

        for (int i = 1; i < segments.length; i++) {
          expect(segments[i].startPosition, closeTo(segments[i - 1].endPosition, 0.01));
        }

        // Total width should be approximately 100%
        final totalWidth = segments.fold(0.0, (sum, seg) => sum + seg.effectiveWidth);
        expect(totalWidth, closeTo(100.0, 1.0));
      });
    });

    group('findSegmentAtPosition', () {
      test('should find correct segment at position', () {
        final segments = [
          BarSegmentData(
            category: CategoryVisualizationData(
              categoryName: 'Test',
              emoji: '🔸',
              count: 10,
              percentage: 50.0,
              color: SPColors.reportGreen,
              type: CategoryType.exercise,
            ),
            percentage: 50.0,
            startPosition: 0.0,
            width: 50.0,
            color: SPColors.reportGreen,
            emoji: '🔸',
          ),
          BarSegmentData(
            category: CategoryVisualizationData(
              categoryName: 'Test2',
              emoji: '🔶',
              count: 10,
              percentage: 50.0,
              color: SPColors.dietGreen,
              type: CategoryType.diet,
            ),
            percentage: 50.0,
            startPosition: 50.0,
            width: 50.0,
            color: SPColors.dietGreen,
            emoji: '🔶',
          ),
        ];

        final segment1 = UnifiedBarChartUtils.findSegmentAtPosition(segments, 25.0);
        expect(segment1?.category.categoryName, 'Test');

        final segment2 = UnifiedBarChartUtils.findSegmentAtPosition(segments, 75.0);
        expect(segment2?.category.categoryName, 'Test2');

        final noSegment = UnifiedBarChartUtils.findSegmentAtPosition(segments, 150.0);
        expect(noSegment, null);
      });
    });

    group('validateUnifiedBarData', () {
      test('should validate correct data', () {
        final data = UnifiedBarChartUtils.createSampleData();
        final result = UnifiedBarChartUtils.validateUnifiedBarData(data);

        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should reject empty data', () {
        final data = UnifiedBarData.empty();
        final result = UnifiedBarChartUtils.validateUnifiedBarData(data);

        expect(result.isValid, false);
        expect(result.errorMessage, '카테고리 데이터가 없습니다');
      });
    });

    group('calculateOptimalHeight', () {
      test('should calculate appropriate height based on category count', () {
        expect(UnifiedBarChartUtils.calculateOptimalHeight(categoryCount: 0), 40.0);
        expect(UnifiedBarChartUtils.calculateOptimalHeight(categoryCount: 1), 60.0);
        expect(UnifiedBarChartUtils.calculateOptimalHeight(categoryCount: 5), 72.0);
      });

      test('should respect min and max height limits', () {
        final height = UnifiedBarChartUtils.calculateOptimalHeight(categoryCount: 100, maxHeight: 80.0);
        expect(height, 80.0);
      });
    });

    group('calculateDistributionSummary', () {
      test('should calculate correct distribution summary', () {
        final data = UnifiedBarChartUtils.createSampleData();
        final summary = UnifiedBarChartUtils.calculateDistributionSummary(data);

        expect(summary.totalCategories, 5);
        expect(summary.exerciseCategories, 3);
        expect(summary.dietCategories, 2);
        expect(summary.totalCount, 26); // 8+5+3+6+4
        expect(summary.exerciseCount, 16); // 8+5+3
        expect(summary.dietCount, 10); // 6+4
        expect(summary.dominantType, CategoryType.exercise);
        expect(summary.diversityScore, greaterThan(0.0));
      });
    });
  });

  group('UnifiedBarData', () {
    test('should calculate total count correctly', () {
      final data = UnifiedBarChartUtils.createSampleData();
      expect(data.totalCount, 26); // 8+5+3+6+4
    });

    test('should calculate percentages correctly', () {
      final data = UnifiedBarChartUtils.createSampleData();
      final firstExercise = data.exerciseCategories.first;
      final percentage = data.getPercentage(firstExercise);

      expect(percentage, closeTo(30.77, 0.01)); // 8/26 * 100
    });

    test('should identify data availability correctly', () {
      final data = UnifiedBarChartUtils.createSampleData();
      expect(data.hasData, true);
      expect(data.hasExerciseData, true);
      expect(data.hasDietData, true);

      final emptyData = UnifiedBarData.empty();
      expect(emptyData.hasData, false);
      expect(emptyData.hasExerciseData, false);
      expect(emptyData.hasDietData, false);
    });

    test('should calculate segments automatically', () {
      final data = UnifiedBarChartUtils.createSampleData();
      expect(data.segments.length, 5);

      // Verify segments are sorted by count (descending)
      for (int i = 1; i < data.segments.length; i++) {
        expect(data.segments[i - 1].category.count, greaterThanOrEqualTo(data.segments[i].category.count));
      }
    });
  });

  group('BarSegmentData', () {
    late BarSegmentData segment;

    setUp(() {
      segment = BarSegmentData(
        category: CategoryVisualizationData(
          categoryName: 'Test Category',
          emoji: '🔸',
          count: 10,
          percentage: 25.0,
          color: SPColors.reportGreen,
          type: CategoryType.exercise,
        ),
        percentage: 25.0,
        startPosition: 10.0,
        width: 25.0,
        color: SPColors.reportGreen,
        emoji: '🔸',
      );
    });

    test('should calculate end position correctly', () {
      expect(segment.endPosition, 35.0); // 10.0 + 25.0
    });

    test('should detect position containment', () {
      expect(segment.containsPosition(15.0), true);
      expect(segment.containsPosition(35.0), true);
      expect(segment.containsPosition(5.0), false);
      expect(segment.containsPosition(40.0), false);
    });

    test('should identify small segments', () {
      final smallSegment = segment.copyWith(width: 3.0);
      expect(smallSegment.isSmallSegment, true);
      expect(smallSegment.effectiveWidth, 5.0); // minimum width

      expect(segment.isSmallSegment, false);
      expect(segment.effectiveWidth, 25.0); // original width
    });

    test('should provide correct display information', () {
      expect(segment.displayText, '🔸 Test Category');
      expect(segment.formattedPercentage, '25.0%');
      expect(segment.isExercise, true);
      expect(segment.isDiet, false);
    });

    test('should generate color variations', () {
      final darkerColor = segment.darkerColor;
      final lighterColor = segment.lighterColor;

      expect(darkerColor, isNot(equals(segment.color)));
      expect(lighterColor, isNot(equals(segment.color)));
    });
  });
}
