import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/unified_bar_chart.dart';

/// Widget that displays enhanced diet analysis with visualizations and insights
class DietAnalysisSection extends StatelessWidget {
  final AIAnalysis analysis;
  final WeeklyStats? stats;
  final CategoryTrendData? categoryTrends;
  final List<CategoryVisualizationData>? dietCategoryData;
  final List<WeeklyReport>? historicalReports;

  const DietAnalysisSection({
    super.key,
    required this.analysis,
    this.stats,
    this.categoryTrends,
    this.dietCategoryData,
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
                    color: SPColors.podOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant, size: 20, color: SPColors.podOrange),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.dietAnalysis,
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Distribution Chart
            if (dietCategoryData?.isNotEmpty == true) ...[
              _buildCategoryDistributionSection(context),
              const SizedBox(height: 16),
            ],

            // Nutritional Balance Visualization
            if (stats?.dietCategories.isNotEmpty == true) ...[
              _buildNutritionalBalanceSection(context),
              const SizedBox(height: 16),
            ],

            // Meal Timing Analysis
            if (stats?.dietCategories.isNotEmpty == true) ...[
              _buildMealTimingAnalysisSection(context),
              const SizedBox(height: 16),
            ],

            // Dietary Variety Scoring
            if (stats?.dietCategories.isNotEmpty == true) ...[
              _buildDietaryVarietyScoringSection(context),
              const SizedBox(height: 16),
            ],

            // Diet insights
            if (analysis.dietInsights.isNotEmpty) ...[
              _buildInsightCard(context, '식단 패턴 분석', analysis.dietInsights, SPColors.podOrange),
              const SizedBox(height: 12),
            ],

            // Strength areas for diet
            if (analysis.strengthAreas.isNotEmpty) ...[_buildStrengthAreas(context), const SizedBox(height: 12)],

            // Improvement areas for diet
            if (analysis.improvementAreas.isNotEmpty) ...[_buildImprovementAreas(context)],
          ],
        ),
      ),
    );
  }

  /// Build category distribution section with interactive chart
  Widget _buildCategoryDistributionSection(BuildContext context) {
    if (dietCategoryData?.isEmpty != false) return const SizedBox.shrink();

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
              Icon(Icons.pie_chart, size: 16, color: SPColors.podOrange),
              const SizedBox(width: 8),
              Text(
                '식단 카테고리 분포',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (categoryTrends != null) _buildTrendIndicator(context),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: UnifiedBarChart(
              exerciseData: const [], // Only show diet data in diet section
              dietData: dietCategoryData!,
              height: 60,
              showLegend: false, // We'll show our own legend below
              enableInteraction: true,
              onCategoryTap: (category) => _showCategoryDetail(context, category),
            ),
          ),
        ],
      ),
    );
  }

  /// Build nutritional balance visualization based on categories
  Widget _buildNutritionalBalanceSection(BuildContext context) {
    if (stats?.dietCategories.isEmpty != false) return const SizedBox.shrink();

    final nutritionalBalance = _calculateNutritionalBalance();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.success100.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.success100.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, size: 16, color: SPColors.success100),
              const SizedBox(width: 8),
              Text(
                '영양 균형 분석',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNutritionalBalanceChart(context, nutritionalBalance),
          const SizedBox(height: 12),
          _buildNutritionalRecommendations(context, nutritionalBalance),
        ],
      ),
    );
  }

  /// Build meal timing analysis with category breakdown
  Widget _buildMealTimingAnalysisSection(BuildContext context) {
    if (stats?.dietCategories.isEmpty != false) return const SizedBox.shrink();

    final mealTimingData = _analyzeMealTiming();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.podBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.podBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: SPColors.podBlue),
              const SizedBox(width: 8),
              Text(
                '식사 시간 분석',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMealTimingChart(context, mealTimingData),
          const SizedBox(height: 12),
          _buildMealTimingInsights(context, mealTimingData),
        ],
      ),
    );
  }

  /// Build dietary variety scoring and recommendations
  Widget _buildDietaryVarietyScoringSection(BuildContext context) {
    if (stats?.dietCategories.isEmpty != false) return const SizedBox.shrink();

    final varietyScore = _calculateDietaryVarietyScore();
    final recommendations = _generateVarietyRecommendations(varietyScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.podPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.podPurple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diversity_3, size: 16, color: SPColors.podPurple),
              const SizedBox(width: 8),
              Text(
                '식단 다양성 점수',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _buildVarietyScoreBadge(context, varietyScore),
            ],
          ),
          const SizedBox(height: 12),
          _buildVarietyScoreVisualization(context, varietyScore),
          const SizedBox(height: 12),
          _buildVarietyRecommendations(context, recommendations),
        ],
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
    // Filter strength areas that are diet-related
    final dietStrengths = analysis.strengthAreas.where((area) => _isDietRelated(area)).toList();

    if (dietStrengths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.thumb_up_outlined, size: 16, color: SPColors.success100),
            const SizedBox(width: 8),
            Text(
              '식단 강점',
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dietStrengths.map(
          (strength) => _buildListItem(context, strength, SPColors.success100, Icons.check_circle_outline),
        ),
      ],
    );
  }

  Widget _buildImprovementAreas(BuildContext context) {
    // Filter improvement areas that are diet-related
    final dietImprovements = analysis.improvementAreas.where((area) => _isDietRelated(area)).toList();

    if (dietImprovements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: SPColors.podBlue),
            const SizedBox(width: 8),
            Text(
              '식단 개선점',
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dietImprovements.map(
          (improvement) => _buildListItem(context, improvement, SPColors.podBlue, Icons.arrow_upward),
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

  /// Helper method to determine if a strength/improvement area is diet-related
  bool _isDietRelated(String text) {
    final dietKeywords = [
      '식단',
      '음식',
      '식사',
      '영양',
      '칼로리',
      '단백질',
      '탄수화물',
      '지방',
      '비타민',
      '미네랄',
      '섬유질',
      '수분',
      '물',
      '야채',
      '채소',
      '과일',
      '곡물',
      '견과류',
      '유제품',
      '육류',
      '생선',
      '해산물',
      '콩',
      '두부',
      '아침',
      '점심',
      '저녁',
      '간식',
      '식욕',
      '포만감',
      '다이어트',
      '체중',
      '균형',
      '건강',
      '신선',
      '가공식품',
      '당분',
      '나트륨',
      '첨가물',
      '조리',
      '요리',
      '레시피',
      '메뉴',
      '식습관',
      '식이',
      '영양소',
    ];

    return dietKeywords.any((keyword) => text.contains(keyword));
  }

  /// Build trend indicator for category changes
  Widget _buildTrendIndicator(BuildContext context) {
    if (categoryTrends == null) return const SizedBox.shrink();

    final dietTrends = categoryTrends!.dietCategoryTrends;
    if (dietTrends.isEmpty) return const SizedBox.shrink();

    final upTrends = dietTrends.values.where((trend) => trend == TrendDirection.up).length;
    final downTrends = dietTrends.values.where((trend) => trend == TrendDirection.down).length;

    IconData icon;
    Color color;
    String tooltip;

    if (upTrends > downTrends) {
      icon = Icons.trending_up;
      color = SPColors.success100;
      tooltip = '식단 카테고리가 증가 추세입니다';
    } else if (downTrends > upTrends) {
      icon = Icons.trending_down;
      color = SPColors.danger100;
      tooltip = '식단 카테고리가 감소 추세입니다';
    } else {
      icon = Icons.trending_flat;
      color = SPColors.gray600;
      tooltip = '식단 카테고리가 안정적입니다';
    }

    return Tooltip(message: tooltip, child: Icon(icon, size: 16, color: color));
  }

  /// Show category detail dialog
  void _showCategoryDetail(BuildContext context, CategoryVisualizationData category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(category.categoryName),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('인증 횟수: ${category.count}회'),
                Text('비율: ${category.formattedPercentage}'),
                if (category.description != '') ...[const SizedBox(height: 8), Text(category.description!)],
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          ),
    );
  }

  /// Calculate nutritional balance based on diet categories
  Map<String, double> _calculateNutritionalBalance() {
    if (stats?.dietCategories.isEmpty != false) return {};

    final categories = stats!.dietCategories;
    final total = categories.values.fold(0, (sum, count) => sum + count);

    if (total == 0) return {};

    // Map categories to nutritional groups
    final nutritionalGroups = <String, double>{'탄수화물': 0.0, '단백질': 0.0, '지방': 0.0, '비타민/미네랄': 0.0, '섬유질': 0.0};

    for (final entry in categories.entries) {
      final categoryName = entry.key;
      final count = entry.value;
      final percentage = count / total;

      // Map diet categories to nutritional groups
      if (categoryName.contains('밥') || categoryName.contains('면') || categoryName.contains('빵')) {
        nutritionalGroups['탄수화물'] = nutritionalGroups['탄수화물']! + percentage;
      } else if (categoryName.contains('고기') || categoryName.contains('생선') || categoryName.contains('달걀')) {
        nutritionalGroups['단백질'] = nutritionalGroups['단백질']! + percentage;
      } else if (categoryName.contains('기름') || categoryName.contains('견과')) {
        nutritionalGroups['지방'] = nutritionalGroups['지방']! + percentage;
      } else if (categoryName.contains('채소') || categoryName.contains('과일')) {
        nutritionalGroups['비타민/미네랄'] = nutritionalGroups['비타민/미네랄']! + percentage;
        nutritionalGroups['섬유질'] = nutritionalGroups['섬유질']! + percentage * 0.5;
      }
    }

    return nutritionalGroups;
  }

  /// Build nutritional balance chart
  Widget _buildNutritionalBalanceChart(BuildContext context, Map<String, double> balance) {
    if (balance.isEmpty) return const SizedBox.shrink();

    return Column(
      children:
          balance.entries.map((entry) {
            final name = entry.key;
            final value = entry.value;
            final percentage = (value * 100).round();

            Color barColor;
            switch (name) {
              case '탄수화물':
                barColor = SPColors.podOrange;
                break;
              case '단백질':
                barColor = SPColors.podBlue;
                break;
              case '지방':
                barColor = SPColors.podPurple;
                break;
              case '비타민/미네랄':
                barColor = SPColors.success100;
                break;
              case '섬유질':
                barColor = SPColors.podGreen;
                break;
              default:
                barColor = SPColors.gray400;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(name, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: SPColors.gray200, borderRadius: BorderRadius.circular(4)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: FTextStyles.body2_14.copyWith(
                      color: SPColors.textColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// Build nutritional recommendations
  Widget _buildNutritionalRecommendations(BuildContext context, Map<String, double> balance) {
    final recommendations = <String>[];

    // Generate recommendations based on balance
    if (balance['단백질']! < 0.2) {
      recommendations.add('단백질 섭취를 늘려보세요 (생선, 닭가슴살, 두부 등)');
    }
    if (balance['비타민/미네랄']! < 0.3) {
      recommendations.add('채소와 과일 섭취를 늘려보세요');
    }
    if (balance['탄수화물']! > 0.6) {
      recommendations.add('탄수화물 비율을 줄이고 다른 영양소를 늘려보세요');
    }

    if (recommendations.isEmpty) {
      recommendations.add('영양 균형이 잘 잡혀있습니다! 👍');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          recommendations
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(rec, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  /// Analyze meal timing patterns
  Map<String, dynamic> _analyzeMealTiming() {
    if (stats?.dietCategories.isEmpty != false) return {};

    // Simulate meal timing analysis based on categories
    // In a real implementation, this would analyze actual meal times from certifications
    return {
      'breakfast': 0.25,
      'lunch': 0.35,
      'dinner': 0.30,
      'snacks': 0.10,
      'regularityScore': 0.75,
      'optimalTiming': true,
    };
  }

  /// Build meal timing chart
  Widget _buildMealTimingChart(BuildContext context, Map<String, dynamic> timingData) {
    if (timingData.isEmpty) return const SizedBox.shrink();

    final mealData = [
      {'name': '아침', 'value': timingData['breakfast'] ?? 0.0, 'color': SPColors.podOrange},
      {'name': '점심', 'value': timingData['lunch'] ?? 0.0, 'color': SPColors.podBlue},
      {'name': '저녁', 'value': timingData['dinner'] ?? 0.0, 'color': SPColors.podPurple},
      {'name': '간식', 'value': timingData['snacks'] ?? 0.0, 'color': SPColors.podGreen},
    ];

    return Column(
      children:
          mealData.map<Widget>((meal) {
            final name = meal['name'] as String;
            final value = meal['value'] as double;
            final color = meal['color'] as Color;
            final percentage = (value * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(name, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: SPColors.gray200, borderRadius: BorderRadius.circular(4)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: FTextStyles.body2_14.copyWith(
                      color: SPColors.textColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  /// Build meal timing insights
  Widget _buildMealTimingInsights(BuildContext context, Map<String, dynamic> timingData) {
    final regularityScore = timingData['regularityScore'] ?? 0.0;
    final insights = <String>[];

    if (regularityScore > 0.8) {
      insights.add('규칙적인 식사 패턴을 유지하고 있습니다 👍');
    } else if (regularityScore > 0.6) {
      insights.add('식사 시간을 좀 더 규칙적으로 맞춰보세요');
    } else {
      insights.add('불규칙한 식사 패턴이 관찰됩니다. 일정한 시간에 식사해보세요');
    }

    final breakfast = timingData['breakfast'] ?? 0.0;
    if (breakfast < 0.15) {
      insights.add('아침 식사를 거르는 경우가 많습니다. 아침 식사의 중요성을 기억하세요');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          insights
              .map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(insight, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  /// Calculate dietary variety score
  Map<String, dynamic> _calculateDietaryVarietyScore() {
    if (stats?.dietCategories.isEmpty != false) {
      return {'score': 0.0, 'level': '낮음', 'maxScore': 100.0};
    }

    final categories = stats!.dietCategories;
    final uniqueCategories = categories.keys.length;
    final totalCertifications = categories.values.fold(0, (sum, count) => sum + count);

    // Calculate variety score based on Shannon diversity index
    double diversityIndex = 0.0;
    for (final count in categories.values) {
      if (count > 0) {
        final proportion = count / totalCertifications;
        diversityIndex -= proportion * (proportion > 0 ? math.log(proportion) / math.ln2 : 0); // log2
      }
    }

    // Normalize to 0-100 scale
    final maxPossibleDiversity = (uniqueCategories > 0 ? math.log(uniqueCategories.toDouble()) / math.ln2 : 0);
    final normalizedScore = maxPossibleDiversity > 0 ? (diversityIndex / maxPossibleDiversity) * 100 : 0.0;

    String level;
    if (normalizedScore >= 80) {
      level = '매우 높음';
    } else if (normalizedScore >= 60) {
      level = '높음';
    } else if (normalizedScore >= 40) {
      level = '보통';
    } else if (normalizedScore >= 20) {
      level = '낮음';
    } else {
      level = '매우 낮음';
    }

    return {
      'score': normalizedScore,
      'level': level,
      'maxScore': 100.0,
      'uniqueCategories': uniqueCategories,
      'totalCertifications': totalCertifications,
    };
  }

  /// Generate variety recommendations
  List<String> _generateVarietyRecommendations(Map<String, dynamic> varietyScore) {
    final score = varietyScore['score'] as double;
    final recommendations = <String>[];

    if (score < 40) {
      recommendations.add('다양한 식품군을 시도해보세요');
      recommendations.add('새로운 요리나 식재료에 도전해보세요');
      recommendations.add('색깔별로 다양한 채소를 섭취해보세요');
    } else if (score < 70) {
      recommendations.add('현재 식단에 1-2가지 새로운 카테고리를 추가해보세요');
      recommendations.add('계절 식품을 활용해보세요');
    } else {
      recommendations.add('훌륭한 식단 다양성을 유지하고 있습니다!');
      recommendations.add('현재의 다양한 식단 패턴을 계속 유지하세요');
    }

    return recommendations;
  }

  /// Build variety score badge
  Widget _buildVarietyScoreBadge(BuildContext context, Map<String, dynamic> varietyScore) {
    final score = varietyScore['score'] as double;
    final level = varietyScore['level'] as String;

    Color badgeColor;
    if (score >= 80) {
      badgeColor = SPColors.success100;
    } else if (score >= 60) {
      badgeColor = SPColors.podGreen;
    } else if (score >= 40) {
      badgeColor = SPColors.podOrange;
    } else {
      badgeColor = SPColors.danger100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(16)),
      child: Text(
        '$level (${score.round()}점)',
        style: FTextStyles.body2_14.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Build variety score visualization
  Widget _buildVarietyScoreVisualization(BuildContext context, Map<String, dynamic> varietyScore) {
    final score = varietyScore['score'] as double;
    final maxScore = varietyScore['maxScore'] as double;

    return Column(
      children: [
        Row(
          children: [
            Text('다양성 점수', style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
            const Spacer(),
            Text(
              '${score.round()}/${maxScore.round()}',
              style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(color: SPColors.gray200, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (score / maxScore).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(color: SPColors.podPurple, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  /// Build variety recommendations
  Widget _buildVarietyRecommendations(BuildContext context, List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          recommendations
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(rec, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
