import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/unified_bar_chart.dart';

/// Widget that displays exercise analysis insights from AI with enhanced visualizations
class ExerciseAnalysisSection extends StatelessWidget {
  final AIAnalysis analysis;
  final WeeklyStats? stats;
  final CategoryTrendData? categoryTrends;
  final List<CategoryVisualizationData>? exerciseCategoryData;
  final List<WeeklyReport>? historicalReports;

  const ExerciseAnalysisSection({
    super.key,
    required this.analysis,
    this.stats,
    this.categoryTrends,
    this.exerciseCategoryData,
    this.historicalReports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.gray200),
        boxShadow: [
          BoxShadow(color: SPColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SPColors.podGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fitness_center, size: 20, color: SPColors.podGreen),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.exerciseAnalysis,
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Enhanced category distribution chart
            if (exerciseCategoryData?.isNotEmpty == true) ...[
              _buildCategoryDistributionSection(context),
              const SizedBox(height: 16),
            ],

            // Category trends with indicators
            if (categoryTrends?.exerciseCategoryTrends.isNotEmpty == true) ...[
              _buildCategoryTrendsSection(context),
              const SizedBox(height: 16),
            ],

            // Category balance scoring
            if (exerciseCategoryData?.isNotEmpty == true) ...[
              _buildCategoryBalanceSection(context),
              const SizedBox(height: 16),
            ],

            // Exercise insights
            if (analysis.exerciseInsights.isNotEmpty) ...[
              _buildInsightCard(context, '운동 패턴 분석', analysis.exerciseInsights, SPColors.podGreen),
              const SizedBox(height: 12),
            ],

            // Strength areas for exercise
            if (analysis.strengthAreas.isNotEmpty) ...[_buildStrengthAreas(context), const SizedBox(height: 12)],

            // Improvement areas for exercise
            if (analysis.improvementAreas.isNotEmpty) ...[_buildImprovementAreas(context)],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, String title, String content, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(content, style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStrengthAreas(BuildContext context) {
    // Filter strength areas that are exercise-related
    final exerciseStrengths = analysis.strengthAreas.where((area) => _isExerciseRelated(area)).toList();

    if (exerciseStrengths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.thumb_up_outlined, size: 16, color: SPColors.success100),
            const SizedBox(width: 8),
            Text(
              '운동 강점',
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...exerciseStrengths.map(
          (strength) => _buildListItem(context, strength, SPColors.success100, Icons.check_circle_outline),
        ),
      ],
    );
  }

  Widget _buildImprovementAreas(BuildContext context) {
    // Filter improvement areas that are exercise-related
    final exerciseImprovements = analysis.improvementAreas.where((area) => _isExerciseRelated(area)).toList();

    if (exerciseImprovements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: SPColors.podOrange),
            const SizedBox(width: 8),
            Text(
              '운동 개선점',
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...exerciseImprovements.map(
          (improvement) => _buildListItem(context, improvement, SPColors.podOrange, Icons.arrow_upward),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), height: 1.4)),
          ),
        ],
      ),
    );
  }

  /// Build enhanced category distribution section with interactive chart
  Widget _buildCategoryDistributionSection(BuildContext context) {
    if (exerciseCategoryData?.isEmpty != false) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.podGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.podGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 16, color: SPColors.podGreen),
              const SizedBox(width: 8),
              Text(
                '운동 카테고리 분포',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: UnifiedBarChart(
              exerciseData: exerciseCategoryData!,
              dietData: const [], // Only show exercise data in exercise section
              height: 60,
              showLegend: false, // We'll show our own legend below
              enableInteraction: true,
              onCategoryTap: (category) => _onCategoryTap(context, category),
            ),
          ),
        ],
      ),
    );
  }

  /// Build category trends section with up/down arrows
  Widget _buildCategoryTrendsSection(BuildContext context) {
    if (categoryTrends?.exerciseCategoryTrends.isEmpty != false) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.gray600,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: SPColors.podBlue),
              const SizedBox(width: 8),
              Text(
                '카테고리 트렌드',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                categoryTrends!.exerciseCategoryTrends.entries.map((entry) {
                  final categoryName = entry.key;
                  final trend = entry.value;
                  final changePercentage = categoryTrends!.getChangePercentageForCategory(categoryName);

                  return _buildTrendIndicator(context, categoryName, trend, changePercentage);
                }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build category balance section with scoring
  Widget _buildCategoryBalanceSection(BuildContext context) {
    if (exerciseCategoryData?.isEmpty != false) return const SizedBox.shrink();

    final balanceScore = _calculateCategoryBalanceScore();
    final recommendations = _generateCategoryRecommendations();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.podOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.podOrange.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, size: 16, color: SPColors.podOrange),
              const SizedBox(width: 8),
              Text(
                '카테고리 균형도',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _buildBalanceScoreIndicator(context, balanceScore),
            ],
          ),
          const SizedBox(height: 12),
          _buildBalanceVisualization(context, balanceScore),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCategoryRecommendations(context, recommendations),
          ],
        ],
      ),
    );
  }

  /// Build trend indicator with arrow and percentage
  Widget _buildTrendIndicator(
    BuildContext context,
    String categoryName,
    TrendDirection trend,
    double changePercentage,
  ) {
    // Find the emoji for this category
    String emoji = '💪'; // Default emoji
    try {
      final category = ExerciseCategory.values.firstWhere((cat) => cat.displayName == categoryName);
      emoji = category.emoji;
    } catch (e) {
      // Use default emoji if category not found
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: trend.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trend.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Icon(trend.icon, size: 14, color: trend.color),
          const SizedBox(width: 4),
          Text(
            '${changePercentage.abs().toStringAsFixed(0)}%',
            style: FTextStyles.caption_12.copyWith(color: trend.color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Build balance score indicator
  Widget _buildBalanceScoreIndicator(BuildContext context, double score) {
    Color scoreColor;
    String scoreText;

    if (score >= 0.8) {
      scoreColor = SPColors.success100;
      scoreText = '우수';
    } else if (score >= 0.6) {
      scoreColor = SPColors.podGreen;
      scoreText = '양호';
    } else if (score >= 0.4) {
      scoreColor = SPColors.podOrange;
      scoreText = '보통';
    } else {
      scoreColor = SPColors.danger100;
      scoreText = '개선 필요';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(scoreText, style: FTextStyles.body2_14.copyWith(color: scoreColor, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text(
            '${(score * 100).toStringAsFixed(0)}점',
            style: FTextStyles.caption_12.copyWith(color: scoreColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Build balance visualization
  Widget _buildBalanceVisualization(BuildContext context, double score) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: score,
          backgroundColor: SPColors.gray200,
          valueColor: AlwaysStoppedAnimation<Color>(score >= 0.6 ? SPColors.success100 : SPColors.podOrange),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('단조로움', style: FTextStyles.caption_12.copyWith(color: SPColors.gray600)),
            Text('균형잡힘', style: FTextStyles.caption_12.copyWith(color: SPColors.gray600)),
          ],
        ),
      ],
    );
  }

  /// Build category recommendations
  Widget _buildCategoryRecommendations(BuildContext context, List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '균형 개선 제안',
          style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...recommendations.map(
          (recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: SPColors.podOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate category balance score (0.0 to 1.0)
  double _calculateCategoryBalanceScore() {
    if (exerciseCategoryData?.isEmpty != false) return 0.0;

    final categories = exerciseCategoryData!;
    final totalCount = categories.fold(0, (sum, category) => sum + category.count);

    if (totalCount == 0) return 0.0;

    // Calculate diversity using Shannon entropy
    double entropy = 0.0;
    for (final category in categories) {
      if (category.count > 0) {
        final probability = category.count / totalCount;
        entropy -= probability * (probability > 0 ? math.log(probability) / math.ln2 : 0); // log2
      }
    }

    // Normalize entropy to 0-1 scale
    final maxEntropy = math.log(categories.length.toDouble()) / math.ln2; // log2 of number of categories
    final normalizedEntropy = maxEntropy > 0 ? entropy / maxEntropy : 0.0;

    // Consider both diversity and distribution evenness
    final evenness = _calculateDistributionEvenness(categories);

    return (normalizedEntropy * 0.7 + evenness * 0.3).clamp(0.0, 1.0);
  }

  /// Calculate distribution evenness
  double _calculateDistributionEvenness(List<CategoryVisualizationData> categories) {
    if (categories.length <= 1) return 1.0;

    final counts = categories.map((c) => c.count).toList();
    final mean = counts.fold(0, (sum, count) => sum + count) / counts.length;

    if (mean == 0) return 0.0;

    // Calculate coefficient of variation (lower is more even)
    final variance = counts.fold(0.0, (sum, count) => sum + ((count - mean) * (count - mean))) / counts.length;
    final standardDeviation = math.sqrt(variance);
    final coefficientOfVariation = standardDeviation / mean;

    // Convert to evenness score (higher is more even)
    return (1.0 / (1.0 + coefficientOfVariation)).clamp(0.0, 1.0);
  }

  /// Generate category-specific recommendations
  List<String> _generateCategoryRecommendations() {
    if (exerciseCategoryData?.isEmpty != false) return [];

    final recommendations = <String>[];
    final categories = exerciseCategoryData!;
    final totalCount = categories.fold(0, (sum, category) => sum + category.count);

    if (totalCount == 0) return recommendations;

    // Find dominant category
    final dominantCategory = categories.reduce((a, b) => a.count > b.count ? a : b);
    final dominantPercentage = dominantCategory.count / totalCount;

    if (dominantPercentage > 0.7) {
      recommendations.add('${dominantCategory.categoryName} 위주의 운동보다 다양한 운동을 시도해보세요');
    }

    // Check for missing important categories
    final hasCardio = categories.any((c) => c.categoryName.contains('유산소'));
    final hasStrength = categories.any((c) => c.categoryName.contains('근력'));
    final hasFlexibility = categories.any((c) => c.categoryName.contains('스트레칭') || c.categoryName.contains('요가'));

    if (!hasCardio) {
      recommendations.add('심폐 건강을 위해 유산소 운동을 추가해보세요');
    }
    if (!hasStrength) {
      recommendations.add('근력 향상을 위해 웨이트 트레이닝을 시도해보세요');
    }
    if (!hasFlexibility) {
      recommendations.add('유연성 향상을 위해 스트레칭이나 요가를 추가해보세요');
    }

    // Check for low activity categories
    final lowActivityCategories = categories.where((c) => c.count == 1).toList();
    if (lowActivityCategories.length > 2) {
      recommendations.add('시작한 운동들을 꾸준히 이어가보세요');
    }

    return recommendations.take(3).toList(); // Limit to 3 recommendations
  }

  /// Handle category tap for detailed view
  void _onCategoryTap(BuildContext context, CategoryVisualizationData category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${category.emoji} ${category.categoryName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번 주 활동: ${category.count}회'),
                Text('전체 비율: ${category.formattedPercentage}'),
                if (categoryTrends != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('트렌드: '),
                      Icon(
                        categoryTrends!.getTrendForCategory(category.categoryName, CategoryType.exercise)?.icon ??
                            Icons.trending_flat,
                        size: 16,
                        color:
                            categoryTrends!.getTrendForCategory(category.categoryName, CategoryType.exercise)?.color ??
                            SPColors.gray600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        categoryTrends!
                                .getTrendForCategory(category.categoryName, CategoryType.exercise)
                                ?.displayName ??
                            '변화 없음',
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          ),
    );
  }

  /// Helper method to determine if a strength/improvement area is exercise-related
  bool _isExerciseRelated(String text) {
    final exerciseKeywords = [
      '운동',
      '헬스',
      '피트니스',
      '근력',
      '유산소',
      '스트레칭',
      '요가',
      '필라테스',
      '러닝',
      '조깅',
      '걷기',
      '수영',
      '자전거',
      '등산',
      '클라이밍',
      '테니스',
      '배드민턴',
      '축구',
      '농구',
      '배구',
      '골프',
      '복싱',
      '태권도',
      '무술',
      '웨이트',
      '덤벨',
      '바벨',
      '머신',
      '홈트',
      '체력',
      '근육',
      '지구력',
      '유연성',
      '균형',
      '코어',
      '하체',
      '상체',
      '전신',
      '인터벌',
      '서킷',
    ];

    return exerciseKeywords.any((keyword) => text.contains(keyword));
  }
}
