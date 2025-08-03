import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying category-specific recommendations and tips
class CategoryRecommendationsSection extends StatefulWidget {
  final CategoryVisualizationData categoryData;
  final List<WeeklyReport> historicalReports;

  const CategoryRecommendationsSection({super.key, required this.categoryData, required this.historicalReports});

  @override
  State<CategoryRecommendationsSection> createState() => _CategoryRecommendationsSectionState();
}

class _CategoryRecommendationsSectionState extends State<CategoryRecommendationsSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;
  final List<CategoryRecommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    _generateRecommendations();

    _itemAnimations = List.generate(
      _recommendations.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, (index * 0.1) + 0.6, curve: Curves.easeOutCubic),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateRecommendations() {
    _recommendations.clear();

    final categoryName = widget.categoryData.categoryName;
    final categoryType = widget.categoryData.type;
    final currentCount = widget.categoryData.count;

    // Analyze historical data
    final historicalCounts =
        widget.historicalReports.map((report) {
          if (categoryType == CategoryType.exercise) {
            return report.stats.exerciseCategories[categoryName] ?? 0;
          } else {
            return report.stats.dietCategories[categoryName] ?? 0;
          }
        }).toList();

    // Generate recommendations based on category and performance
    if (categoryType == CategoryType.exercise) {
      _generateExerciseRecommendations(categoryName, currentCount, historicalCounts);
    } else {
      _generateDietRecommendations(categoryName, currentCount, historicalCounts);
    }

    // Add general recommendations
    _addGeneralRecommendations(currentCount, historicalCounts);
  }

  void _generateExerciseRecommendations(String categoryName, int currentCount, List<int> historicalCounts) {
    switch (categoryName) {
      case '근력 운동':
        _recommendations.addAll([
          CategoryRecommendation(
            title: '점진적 부하 증가',
            description: '매주 조금씩 무게나 횟수를 늘려보세요. 근력 향상에 도움이 됩니다.',
            icon: Icons.fitness_center,
            priority: RecommendationPriority.high,
            actionable: true,
            tips: ['이번 주보다 5% 더 무거운 무게로 도전해보세요', '같은 무게라면 반복 횟수를 2-3회 늘려보세요', '새로운 운동 동작을 하나씩 추가해보세요'],
          ),
          CategoryRecommendation(
            title: '충분한 휴식',
            description: '근육 회복을 위해 운동 간 48시간 휴식을 권장합니다.',
            icon: Icons.bedtime,
            priority: RecommendationPriority.medium,
            actionable: true,
            tips: ['같은 근육군은 하루 걸러 운동하세요', '충분한 수면(7-8시간)을 취하세요', '운동 후 스트레칭을 잊지 마세요'],
          ),
        ]);
        break;

      case '유산소 운동':
        _recommendations.addAll([
          CategoryRecommendation(
            title: '심박수 관리',
            description: '목표 심박수 구간에서 운동하면 더 효과적입니다.',
            icon: Icons.favorite,
            priority: RecommendationPriority.high,
            actionable: true,
            tips: ['최대심박수의 60-70%에서 운동해보세요', '운동 강도를 점진적으로 높여보세요', '15-20분부터 시작해서 시간을 늘려가세요'],
          ),
          CategoryRecommendation(
            title: '다양한 운동 시도',
            description: '지루함을 피하고 전신 발달을 위해 다양한 유산소 운동을 해보세요.',
            icon: Icons.directions_run,
            priority: RecommendationPriority.medium,
            actionable: true,
            tips: ['걷기, 달리기, 자전거를 번갈아 해보세요', '계단 오르기나 등산도 좋은 유산소 운동입니다', '음악에 맞춰 춤추는 것도 재미있는 유산소 운동이에요'],
          ),
        ]);
        break;

      case '스트레칭/요가':
        _recommendations.addAll([
          CategoryRecommendation(
            title: '일관성 유지',
            description: '매일 조금씩이라도 꾸준히 하는 것이 중요합니다.',
            icon: Icons.self_improvement,
            priority: RecommendationPriority.high,
            actionable: true,
            tips: ['아침에 5분 스트레칭으로 하루를 시작해보세요', '잠들기 전 10분 요가로 하루를 마무리해보세요', '업무 중간중간 목과 어깨 스트레칭을 해보세요'],
          ),
        ]);
        break;

      default:
        _recommendations.add(
          CategoryRecommendation(
            title: '꾸준한 실천',
            description: '$categoryName을(를) 꾸준히 실천하고 계시네요!',
            icon: Icons.sports,
            priority: RecommendationPriority.medium,
            actionable: false,
            tips: ['현재 패턴을 유지하면서 조금씩 강도를 높여보세요', '새로운 변화를 주어 지루함을 피해보세요'],
          ),
        );
    }
  }

  void _generateDietRecommendations(String categoryName, int currentCount, List<int> historicalCounts) {
    switch (categoryName) {
      case '집밥/도시락':
        _recommendations.addAll([
          CategoryRecommendation(
            title: '영양 균형',
            description: '탄수화물, 단백질, 채소를 균형있게 구성해보세요.',
            icon: Icons.restaurant,
            priority: RecommendationPriority.high,
            actionable: true,
            tips: ['한 끼에 3-4가지 색깔의 채소를 포함해보세요', '단백질은 손바닥 크기만큼 섭취하세요', '현미나 잡곡밥으로 바꿔보세요'],
          ),
          CategoryRecommendation(
            title: '식단 다양성',
            description: '다양한 재료와 조리법으로 영양소를 골고루 섭취하세요.',
            icon: Icons.kitchen,
            priority: RecommendationPriority.medium,
            actionable: true,
            tips: ['일주일에 새로운 채소 하나씩 시도해보세요', '조리법을 바꿔보세요 (찜, 구이, 볶음 등)', '제철 식재료를 활용해보세요'],
          ),
        ]);
        break;

      case '건강식/샐러드':
        _recommendations.addAll([
          CategoryRecommendation(
            title: '단백질 보충',
            description: '샐러드에 충분한 단백질을 추가하여 포만감을 높이세요.',
            icon: Icons.eco,
            priority: RecommendationPriority.high,
            actionable: true,
            tips: ['닭가슴살, 계란, 두부 등을 추가해보세요', '견과류나 씨앗류로 건강한 지방을 보충하세요', '아보카도로 포만감을 높여보세요'],
          ),
        ]);
        break;

      case '단백질 위주':
        _recommendations.addAll([
          CategoryRecommendation(
            title: '탄수화물 균형',
            description: '단백질과 함께 적절한 탄수화물도 섭취하세요.',
            icon: Icons.fitness_center,
            priority: RecommendationPriority.medium,
            actionable: true,
            tips: ['운동 전후에는 탄수화물을 함께 섭취하세요', '현미, 고구마 등 복합탄수화물을 선택하세요', '채소와 함께 섭취하여 소화를 도와주세요'],
          ),
        ]);
        break;

      default:
        _recommendations.add(
          CategoryRecommendation(
            title: '균형잡힌 식단',
            description: '$categoryName을(를) 적절히 섭취하고 계시네요!',
            icon: Icons.restaurant_menu,
            priority: RecommendationPriority.medium,
            actionable: false,
            tips: ['다른 영양소와의 균형을 고려해보세요', '적절한 양을 유지하는 것이 중요합니다'],
          ),
        );
    }
  }

  void _addGeneralRecommendations(int currentCount, List<int> historicalCounts) {
    if (historicalCounts.isNotEmpty) {
      final average = historicalCounts.fold<double>(0, (sum, count) => sum + count) / historicalCounts.length;

      if (currentCount > average * 1.2) {
        _recommendations.add(
          CategoryRecommendation(
            title: '훌륭한 성과!',
            description: '평소보다 더 많이 실천하고 계시네요. 이 패턴을 유지해보세요.',
            icon: Icons.celebration,
            priority: RecommendationPriority.low,
            actionable: false,
            tips: ['현재의 좋은 습관을 계속 유지하세요', '과도하지 않은 선에서 꾸준히 실천하세요'],
          ),
        );
      } else if (currentCount < average * 0.8) {
        _recommendations.add(
          CategoryRecommendation(
            title: '다시 시작해보세요',
            description: '평소보다 조금 줄어들었네요. 작은 목표부터 다시 시작해보세요.',
            icon: Icons.refresh,
            priority: RecommendationPriority.high,
            actionable: true,
            tips: ['작은 목표부터 설정해보세요', '하루에 한 번씩이라도 시도해보세요', '습관을 만들기 위해 같은 시간에 해보세요'],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 16),
        ..._recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final recommendation = entry.value;

          return AnimatedBuilder(
            animation: _itemAnimations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
                child: Opacity(opacity: _itemAnimations[index].value, child: _buildRecommendationCard(recommendation)),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.lightbulb, color: widget.categoryData.color, size: 20),
        const SizedBox(width: 8),
        Text(
          '맞춤 추천',
          style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.categoryData.color),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.categoryData.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_recommendations.length}개',
            style: FTextStyles.body3_13.copyWith(color: widget.categoryData.color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(CategoryRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPriorityColor(recommendation.priority).withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPriorityColor(recommendation.priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(recommendation.icon, color: _getPriorityColor(recommendation.priority), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommendation.title,
                            style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: SPColors.gray800),
                          ),
                        ),
                        _buildPriorityBadge(recommendation.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation.description,
                      style: FTextStyles.body2_14.copyWith(color: SPColors.gray600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recommendation.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '실천 팁',
                    style: FTextStyles.body3_13.copyWith(fontWeight: FontWeight.w600, color: SPColors.gray700),
                  ),
                  const SizedBox(height: 8),
                  ...recommendation.tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(color: widget.categoryData.color, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: FTextStyles.body3_13.copyWith(color: SPColors.gray600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(RecommendationPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getPriorityText(priority),
        style: FTextStyles.body3_13.copyWith(
          color: _getPriorityColor(priority),
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text(
            '추천사항이 없습니다',
            style: FTextStyles.body1_16.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '더 많은 데이터가 쌓이면\n맞춤 추천을 제공해드릴게요',
            textAlign: TextAlign.center,
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray500),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return SPColors.danger100;
      case RecommendationPriority.medium:
        return SPColors.podOrange;
      case RecommendationPriority.low:
        return SPColors.success100;
    }
  }

  String _getPriorityText(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high:
        return '중요';
      case RecommendationPriority.medium:
        return '보통';
      case RecommendationPriority.low:
        return '참고';
    }
  }
}

/// Model for category recommendations
class CategoryRecommendation {
  final String title;
  final String description;
  final IconData icon;
  final RecommendationPriority priority;
  final bool actionable;
  final List<String> tips;

  const CategoryRecommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
    required this.actionable,
    this.tips = const [],
  });
}

/// Enum for recommendation priority
enum RecommendationPriority { high, medium, low }
