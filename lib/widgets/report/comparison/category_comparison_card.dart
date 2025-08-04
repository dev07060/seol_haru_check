import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for comparing category data between current and previous week
class CategoryComparisonCard extends StatelessWidget {
  final WeeklyReport currentWeek;
  final WeeklyReport? previousWeek;
  final CategoryType categoryType;
  final VoidCallback? onTap;

  const CategoryComparisonCard({
    super.key,
    required this.currentWeek,
    this.previousWeek,
    required this.categoryType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildComparisonContent(context),
              const SizedBox(height: 12),
              _buildDiversityComparison(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(categoryType.icon, size: 20, color: SPColors.gray700),
        const SizedBox(width: 8),
        Text(
          '${categoryType.displayName} 카테고리 비교',
          style: FTextStyles.title4_17.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (onTap != null) Icon(Icons.chevron_right, size: 20, color: SPColors.gray500),
      ],
    );
  }

  Widget _buildComparisonContent(BuildContext context) {
    if (previousWeek == null) {
      return _buildNoComparisonData(context);
    }

    final currentCategories = _getCategoriesForType(currentWeek);
    final previousCategories = _getCategoriesForType(previousWeek!);
    final comparisonData = _generateComparisonData(currentCategories, previousCategories);

    if (comparisonData.isEmpty) {
      return _buildNoComparisonData(context);
    }

    return Column(
      children: [
        _buildComparisonHeader(context),
        const SizedBox(height: 8),
        ...comparisonData.take(5).map((data) => _buildCategoryComparisonRow(context, data)),
        if (comparisonData.length > 5) _buildMoreCategoriesIndicator(context, comparisonData.length - 5),
      ],
    );
  }

  Widget _buildComparisonHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '이번 주',
            style: FTextStyles.body3_13.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Text(
            '지난 주',
            style: FTextStyles.body3_13.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 60),
      ],
    );
  }

  Widget _buildCategoryComparisonRow(BuildContext context, CategoryComparisonData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Category name with emoji
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Text(data.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data.categoryName,
                    style: FTextStyles.body4_12.copyWith(color: SPColors.textColor(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Current week count
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(6)),
              child: Text(
                '${data.currentCount}',
                style: FTextStyles.body3_13.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Previous week count
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(6)),
              child: Text(
                '${data.previousCount}',
                style: FTextStyles.body3_13.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Change indicator
          SizedBox(width: 60, child: _buildChangeIndicator(context, data)),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(BuildContext context, CategoryComparisonData data) {
    final changeType = data.changeType;
    final changePercentage = data.changePercentage;

    Color indicatorColor;
    IconData indicatorIcon;
    String changeText;

    switch (changeType) {
      case CategoryChangeType.increased:
        indicatorColor = SPColors.success100;
        indicatorIcon = Icons.trending_up;
        changeText = '+${changePercentage.toStringAsFixed(0)}%';
        break;
      case CategoryChangeType.decreased:
        indicatorColor = SPColors.danger100;
        indicatorIcon = Icons.trending_down;
        changeText = '${changePercentage.toStringAsFixed(0)}%';
        break;
      case CategoryChangeType.stable:
        indicatorColor = SPColors.gray500;
        indicatorIcon = Icons.trending_flat;
        changeText = '0%';
        break;
      case CategoryChangeType.emerged:
        indicatorColor = SPColors.reportGreen;
        indicatorIcon = Icons.fiber_new;
        changeText = 'NEW';
        break;
      case CategoryChangeType.disappeared:
        indicatorColor = SPColors.gray400;
        indicatorIcon = Icons.remove_circle_outline;
        changeText = '중단';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, size: 12, color: indicatorColor),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              changeText,
              style: FTextStyles.body5_10.copyWith(color: indicatorColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiversityComparison(BuildContext context) {
    final currentDiversity = _calculateDiversityScore(_getCategoriesForType(currentWeek));
    final previousDiversity =
        previousWeek != null ? _calculateDiversityScore(_getCategoriesForType(previousWeek!)) : 0.0;

    final diversityChange = previousWeek != null ? currentDiversity - previousDiversity : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.diversity_3, size: 16, color: SPColors.gray600),
          const SizedBox(width: 8),
          Text('다양성 점수', style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
          const Spacer(),
          _buildDiversityScore(context, currentDiversity),
          if (previousWeek != null) ...[
            const SizedBox(width: 8),
            _buildDiversityChangeIndicator(context, diversityChange),
          ],
        ],
      ),
    );
  }

  Widget _buildDiversityScore(BuildContext context, double score) {
    final scoreText = (score * 100).toStringAsFixed(0);
    Color scoreColor;

    if (score >= 0.8) {
      scoreColor = SPColors.success100;
    } else if (score >= 0.6) {
      scoreColor = SPColors.reportGreen;
    } else if (score >= 0.4) {
      scoreColor = SPColors.reportOrange;
    } else {
      scoreColor = SPColors.danger100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Text('$scoreText점', style: FTextStyles.body3_13.copyWith(color: scoreColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildDiversityChangeIndicator(BuildContext context, double change) {
    if (change.abs() < 0.05) {
      return Icon(Icons.trending_flat, size: 16, color: SPColors.gray500);
    }

    final isPositive = change > 0;
    return Icon(
      isPositive ? Icons.trending_up : Icons.trending_down,
      size: 16,
      color: isPositive ? SPColors.success100 : SPColors.danger100,
    );
  }

  Widget _buildMoreCategoriesIndicator(BuildContext context, int moreCount) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '외 $moreCount개 카테고리',
        style: FTextStyles.body4_12.copyWith(color: SPColors.gray500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNoComparisonData(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(Icons.compare_arrows, size: 32, color: SPColors.gray400),
          const SizedBox(height: 8),
          Text(
            previousWeek == null ? '비교할 이전 주 데이터가 없습니다' : '비교할 카테고리 데이터가 없습니다',
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '다음 주부터 비교 분석을 제공합니다',
            style: FTextStyles.body4_12.copyWith(color: SPColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Map<String, int> _getCategoriesForType(WeeklyReport report) {
    switch (categoryType) {
      case CategoryType.exercise:
        return report.stats.exerciseCategories;
      case CategoryType.diet:
        return report.stats.dietCategories;
    }
  }

  List<CategoryComparisonData> _generateComparisonData(
    Map<String, int> currentCategories,
    Map<String, int> previousCategories,
  ) {
    final comparisonData = <CategoryComparisonData>[];
    final allCategories = <String>{...currentCategories.keys, ...previousCategories.keys};

    for (final categoryName in allCategories) {
      final currentCount = currentCategories[categoryName] ?? 0;
      final previousCount = previousCategories[categoryName] ?? 0;
      final emoji = _getCategoryEmoji(categoryName);

      final changeType = _determineChangeType(currentCount, previousCount);
      final changePercentage = _calculateChangePercentage(currentCount, previousCount);

      comparisonData.add(
        CategoryComparisonData(
          categoryName: categoryName,
          emoji: emoji,
          currentCount: currentCount,
          previousCount: previousCount,
          changeType: changeType,
          changePercentage: changePercentage,
        ),
      );
    }

    // Sort by significance: emerged/disappeared first, then by absolute change
    comparisonData.sort((a, b) {
      if (a.changeType == CategoryChangeType.emerged || a.changeType == CategoryChangeType.disappeared) {
        if (b.changeType != CategoryChangeType.emerged && b.changeType != CategoryChangeType.disappeared) {
          return -1;
        }
      } else if (b.changeType == CategoryChangeType.emerged || b.changeType == CategoryChangeType.disappeared) {
        return 1;
      }

      return b.changePercentage.abs().compareTo(a.changePercentage.abs());
    });

    return comparisonData;
  }

  CategoryChangeType _determineChangeType(int currentCount, int previousCount) {
    if (previousCount == 0 && currentCount > 0) {
      return CategoryChangeType.emerged;
    } else if (previousCount > 0 && currentCount == 0) {
      return CategoryChangeType.disappeared;
    } else if (currentCount > previousCount) {
      return CategoryChangeType.increased;
    } else if (currentCount < previousCount) {
      return CategoryChangeType.decreased;
    } else {
      return CategoryChangeType.stable;
    }
  }

  double _calculateChangePercentage(int currentCount, int previousCount) {
    if (previousCount == 0) {
      return currentCount > 0 ? 100.0 : 0.0;
    }
    return ((currentCount - previousCount) / previousCount) * 100;
  }

  double _calculateDiversityScore(Map<String, int> categories) {
    if (categories.isEmpty) return 0.0;

    final totalCount = categories.values.fold(0, (sum, count) => sum + count);
    if (totalCount == 0) return 0.0;

    // Calculate Shannon diversity index
    double diversity = 0.0;
    for (final count in categories.values) {
      if (count > 0) {
        final proportion = count / totalCount;
        diversity -= proportion * (proportion > 0 ? math.log(proportion) / math.ln2 : 0); // log2
      }
    }

    // Normalize to 0-1 scale (assuming max 8 categories)
    final maxDiversity = math.log(8) / math.ln2; // log2(8)
    return maxDiversity > 0 ? (diversity / maxDiversity).clamp(0.0, 1.0) : 0.0;
  }

  String _getCategoryEmoji(String categoryName) {
    final emojiMap = {
      '근력 운동': '💪',
      '유산소 운동': '🏃',
      '스트레칭/요가': '🧘',
      '구기/스포츠': '⚽',
      '야외 활동': '🏔️',
      '댄스/무용': '💃',
      '집밥/도시락': '🍱',
      '건강식/샐러드': '🥗',
      '단백질 위주': '🍗',
      '간식/음료': '🍪',
      '외식/배달': '🍽️',
      '영양제/보충제': '💊',
    };

    return emojiMap[categoryName] ?? '📊';
  }
}

/// Data model for category comparison
class CategoryComparisonData {
  final String categoryName;
  final String emoji;
  final int currentCount;
  final int previousCount;
  final CategoryChangeType changeType;
  final double changePercentage;

  const CategoryComparisonData({
    required this.categoryName,
    required this.emoji,
    required this.currentCount,
    required this.previousCount,
    required this.changeType,
    required this.changePercentage,
  });
}

/// Enum for category change types
enum CategoryChangeType {
  increased,
  decreased,
  stable,
  emerged,
  disappeared;

  /// Get display name in Korean
  String get displayName {
    switch (this) {
      case CategoryChangeType.increased:
        return '증가';
      case CategoryChangeType.decreased:
        return '감소';
      case CategoryChangeType.stable:
        return '유지';
      case CategoryChangeType.emerged:
        return '신규';
      case CategoryChangeType.disappeared:
        return '중단';
    }
  }

  /// Get description
  String get description {
    switch (this) {
      case CategoryChangeType.increased:
        return '이전 주보다 증가했습니다';
      case CategoryChangeType.decreased:
        return '이전 주보다 감소했습니다';
      case CategoryChangeType.stable:
        return '이전 주와 동일합니다';
      case CategoryChangeType.emerged:
        return '새롭게 시작된 카테고리입니다';
      case CategoryChangeType.disappeared:
        return '이번 주에는 활동하지 않았습니다';
    }
  }
}
