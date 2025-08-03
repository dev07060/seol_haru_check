import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying comprehensive category-specific insights
/// Implements requirements 5.3 and 5.4 for actionable recommendations and strength building
class CategoryInsightsSection extends StatefulWidget {
  final List<CategoryVisualizationData> exerciseCategories;
  final List<CategoryVisualizationData> dietCategories;
  final CategoryTrendData? trendData;
  final List<WeeklyReport> historicalReports;
  final VoidCallback? onInsightTap;

  const CategoryInsightsSection({
    super.key,
    required this.exerciseCategories,
    required this.dietCategories,
    this.trendData,
    required this.historicalReports,
    this.onInsightTap,
  });

  @override
  State<CategoryInsightsSection> createState() => _CategoryInsightsSectionState();
}

class _CategoryInsightsSectionState extends State<CategoryInsightsSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;
  final List<CategoryInsight> _insights = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _generateInsights();

    _itemAnimations = List.generate(
      _insights.length,
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

  void _generateInsights() {
    _insights.clear();

    // Generate AI-powered insights based on category data
    _generateImprovementInsights();
    _generateStrengthInsights();
    _generateHabitFormationTips();
    _generateOptimizationSuggestions();
    _generateTrendBasedInsights();

    // Sort insights by priority
    _insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  void _generateImprovementInsights() {
    // Requirement 5.3: Provide specific, actionable recommendations with priority levels
    final allCategories = [...widget.exerciseCategories, ...widget.dietCategories];

    for (final category in allCategories) {
      if (category.count == 0) {
        _insights.add(
          CategoryInsight(
            title: '${category.emoji} ${category.categoryName} 시작해보기',
            description: '새로운 활동을 시작하면 더 균형잡힌 건강 관리가 가능해요',
            type: InsightType.improvement,
            priority: InsightPriority.high,
            category: category,
            actionableSteps: _getStarterSteps(category),
            aiGenerated: true,
          ),
        );
      } else if (category.count < _getHistoricalAverage(category.categoryName, category.type)) {
        _insights.add(
          CategoryInsight(
            title: '${category.emoji} ${category.categoryName} 늘려보기',
            description: '평소보다 적게 하고 계시네요. 조금씩 늘려보는 건 어떨까요?',
            type: InsightType.improvement,
            priority: InsightPriority.medium,
            category: category,
            actionableSteps: _getImprovementSteps(category),
            aiGenerated: true,
          ),
        );
      }
    }
  }

  void _generateStrengthInsights() {
    // Requirement 5.4: Suggest ways to maintain and build upon successful patterns
    final allCategories = [...widget.exerciseCategories, ...widget.dietCategories];

    for (final category in allCategories) {
      final historicalAvg = _getHistoricalAverage(category.categoryName, category.type);

      if (category.count > historicalAvg * 1.2) {
        _insights.add(
          CategoryInsight(
            title: '${category.emoji} ${category.categoryName} 우수한 성과!',
            description: '평소보다 훨씬 잘하고 계시네요! 이 패턴을 유지하는 방법을 알려드릴게요',
            type: InsightType.strength,
            priority: InsightPriority.high,
            category: category,
            actionableSteps: _getStrengthMaintenanceSteps(category),
            aiGenerated: true,
          ),
        );
      } else if (category.count >= historicalAvg) {
        _insights.add(
          CategoryInsight(
            title: '${category.emoji} ${category.categoryName} 꾸준한 실천',
            description: '안정적으로 유지하고 계시네요. 한 단계 더 발전시켜보세요',
            type: InsightType.strength,
            priority: InsightPriority.medium,
            category: category,
            actionableSteps: _getAdvancementSteps(category),
            aiGenerated: true,
          ),
        );
      }
    }
  }

  void _generateHabitFormationTips() {
    final lowConsistencyCategories =
        [
          ...widget.exerciseCategories,
          ...widget.dietCategories,
        ].where((cat) => cat.count > 0 && cat.count < 3).toList();

    for (final category in lowConsistencyCategories) {
      _insights.add(
        CategoryInsight(
          title: '${category.emoji} ${category.categoryName} 습관 만들기',
          description: '꾸준한 습관으로 만들어보세요. 작은 변화가 큰 결과를 만들어요',
          type: InsightType.habit,
          priority: InsightPriority.medium,
          category: category,
          actionableSteps: _getHabitFormationSteps(category),
          aiGenerated: true,
        ),
      );
    }
  }

  void _generateOptimizationSuggestions() {
    // Analyze category balance and suggest optimizations
    final exerciseTotal = widget.exerciseCategories.fold(0, (sum, cat) => sum + cat.count);
    final dietTotal = widget.dietCategories.fold(0, (sum, cat) => sum + cat.count);

    if (exerciseTotal > 0 && dietTotal > 0) {
      final ratio = exerciseTotal / dietTotal;

      if (ratio > 2.0) {
        _insights.add(
          CategoryInsight(
            title: '🍽️ 식단 관리 강화하기',
            description: '운동에 비해 식단 관리가 부족해요. 균형을 맞춰보세요',
            type: InsightType.optimization,
            priority: InsightPriority.high,
            category: null,
            actionableSteps: ['하루 한 끼는 집에서 직접 만들어 드세요', '간식 대신 과일이나 견과류를 선택해보세요', '물 섭취량을 늘려보세요 (하루 8잔 목표)'],
            aiGenerated: true,
          ),
        );
      } else if (ratio < 0.5) {
        _insights.add(
          CategoryInsight(
            title: '💪 운동량 늘리기',
            description: '식단 관리는 잘하고 계시는데 운동이 부족해요',
            type: InsightType.optimization,
            priority: InsightPriority.high,
            category: null,
            actionableSteps: ['하루 10분 산책부터 시작해보세요', '계단 이용하기를 생활화해보세요', '스트레칭을 하루 5분씩 해보세요'],
            aiGenerated: true,
          ),
        );
      }
    }
  }

  void _generateTrendBasedInsights() {
    if (widget.trendData == null) return;

    final trendData = widget.trendData!;

    // Analyze emerging categories
    for (final emergingCategory in trendData.emergingCategories) {
      _insights.add(
        CategoryInsight(
          title: '📈 $emergingCategory 상승 추세',
          description: '최근 $emergingCategory 활동이 늘고 있어요. 이 좋은 흐름을 계속 이어가세요!',
          type: InsightType.trend,
          priority: InsightPriority.medium,
          category: null,
          actionableSteps: ['현재 패턴을 유지하면서 조금씩 늘려보세요', '다양한 방법으로 시도해보세요', '목표를 설정하고 달성해보세요'],
          aiGenerated: true,
        ),
      );
    }

    // Analyze declining categories
    for (final decliningCategory in trendData.decliningCategories) {
      _insights.add(
        CategoryInsight(
          title: '📉 $decliningCategory 관심 필요',
          description: '$decliningCategory 활동이 줄어들고 있어요. 다시 시작해보는 건 어떨까요?',
          type: InsightType.improvement,
          priority: InsightPriority.medium,
          category: null,
          actionableSteps: ['작은 목표부터 다시 시작해보세요', '새로운 방법으로 접근해보세요', '친구나 가족과 함께 해보세요'],
          aiGenerated: true,
        ),
      );
    }
  }

  double _getHistoricalAverage(String categoryName, CategoryType type) {
    if (widget.historicalReports.isEmpty) return 1.0;

    final counts =
        widget.historicalReports.map((report) {
          switch (type) {
            case CategoryType.exercise:
              return report.stats.exerciseCategories[categoryName] ?? 0;
            case CategoryType.diet:
              return report.stats.dietCategories[categoryName] ?? 0;
          }
        }).toList();

    return counts.isEmpty ? 1.0 : counts.reduce((a, b) => a + b) / counts.length;
  }

  List<String> _getStarterSteps(CategoryVisualizationData category) {
    switch (category.categoryName) {
      case '근력 운동':
        return ['팔굽혀펴기 5개부터 시작해보세요', '스쿼트 10개로 하체 운동을 시작해보세요', '플랭크 30초부터 도전해보세요'];
      case '유산소 운동':
        return ['하루 10분 빠르게 걷기부터 시작해보세요', '계단 오르내리기를 해보세요', '좋아하는 음악에 맞춰 춤춰보세요'];
      case '스트레칭/요가':
        return ['아침에 5분 목과 어깨 스트레칭을 해보세요', '잠들기 전 다리 스트레칭을 해보세요', '유튜브 초보자용 요가 영상을 따라해보세요'];
      case '집밥/도시락':
        return ['간단한 계란요리부터 시작해보세요', '밥과 반찬 하나만이라도 직접 만들어보세요', '도시락 싸는 날을 정해보세요'];
      case '건강식/샐러드':
        return ['하루 한 끼는 샐러드로 대체해보세요', '좋아하는 채소 3가지로 시작해보세요', '드레싱을 직접 만들어보세요'];
      default:
        return ['작은 목표부터 설정해보세요', '하루 한 번씩 시도해보세요', '꾸준함이 가장 중요해요'];
    }
  }

  List<String> _getImprovementSteps(CategoryVisualizationData category) {
    return ['이번 주보다 1회 더 시도해보세요', '새로운 방법이나 장소를 시도해보세요', '친구나 가족과 함께 해보세요', '목표를 달성하면 스스로에게 보상을 주세요'];
  }

  List<String> _getStrengthMaintenanceSteps(CategoryVisualizationData category) {
    return ['현재 패턴을 유지하면서 강도를 조금씩 높여보세요', '다양한 변화를 주어 지루함을 피해보세요', '다른 사람들에게 경험을 공유해보세요', '새로운 도전 목표를 설정해보세요'];
  }

  List<String> _getAdvancementSteps(CategoryVisualizationData category) {
    return ['현재보다 10% 더 도전해보세요', '새로운 기술이나 방법을 배워보세요', '더 높은 목표를 설정해보세요', '성과를 기록하고 분석해보세요'];
  }

  List<String> _getHabitFormationSteps(CategoryVisualizationData category) {
    return ['매일 같은 시간에 하는 습관을 만들어보세요', '다른 습관과 연결해서 함께 해보세요', '달력에 체크하며 성취감을 느껴보세요', '21일 연속 도전해보세요'];
  }

  @override
  Widget build(BuildContext context) {
    if (_insights.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      color: SPColors.backgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: SPColors.gray200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: 16),
            _buildInsightsList(),
            if (_insights.length > 3) _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SPColors.podPurple.withValues(alpha: 0.1), SPColors.podPink.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.psychology, size: 20, color: SPColors.podPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 맞춤 인사이트',
                style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
              Text('데이터 기반 개인화 추천', style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: SPColors.podPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_insights.length}개',
            style: FTextStyles.body3_13.copyWith(color: SPColors.podPurple, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsList() {
    final displayInsights = _isExpanded ? _insights : _insights.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          displayInsights.asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;

            return AnimatedBuilder(
              animation: index < _itemAnimations.length ? _itemAnimations[index] : _animationController,
              builder: (context, child) {
                final animation = index < _itemAnimations.length ? _itemAnimations[index] : _animationController;
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - animation.value)),
                  child: Opacity(opacity: animation.value, child: _buildInsightCard(insight)),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildInsightCard(CategoryInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getInsightTypeColor(insight.type).withValues(alpha: 0.05),
            _getInsightTypeColor(insight.type).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getInsightTypeColor(insight.type).withValues(alpha: 0.2), width: 1),
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
                  color: _getInsightTypeColor(insight.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_getInsightTypeIcon(insight.type), color: _getInsightTypeColor(insight.type), size: 20),
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
                            insight.title,
                            style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: SPColors.gray800),
                          ),
                        ),
                        _buildPriorityBadge(insight.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: FTextStyles.body2_14.copyWith(color: SPColors.gray600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (insight.actionableSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: _getInsightTypeColor(insight.type)),
                      const SizedBox(width: 6),
                      Text(
                        '실천 방법',
                        style: FTextStyles.body3_13.copyWith(fontWeight: FontWeight.w600, color: SPColors.gray700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...insight.actionableSteps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: _getInsightTypeColor(insight.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step,
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
          if (insight.aiGenerated) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: SPColors.podPurple),
                const SizedBox(width: 4),
                Text(
                  'AI 생성',
                  style: FTextStyles.body4_12.copyWith(color: SPColors.podPurple, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(InsightPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getPriorityText(priority),
        style: FTextStyles.body4_12.copyWith(color: _getPriorityColor(priority), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? '접기' : '더 보기',
              style: FTextStyles.body2_14.copyWith(color: SPColors.gray700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: SPColors.gray700, size: 20),
          ],
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
          Icon(Icons.psychology_outlined, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text('인사이트 준비 중', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '더 많은 데이터가 쌓이면\n맞춤 인사이트를 제공해드릴게요',
            textAlign: TextAlign.center,
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray500),
          ),
        ],
      ),
    );
  }

  Color _getInsightTypeColor(InsightType type) {
    switch (type) {
      case InsightType.improvement:
        return SPColors.reportOrange;
      case InsightType.strength:
        return SPColors.reportGreen;
      case InsightType.habit:
        return SPColors.reportPurple;
      case InsightType.optimization:
        return SPColors.reportBlue;
      case InsightType.trend:
        return SPColors.reportTeal;
    }
  }

  IconData _getInsightTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.improvement:
        return Icons.trending_up;
      case InsightType.strength:
        return Icons.star;
      case InsightType.habit:
        return Icons.repeat;
      case InsightType.optimization:
        return Icons.tune;
      case InsightType.trend:
        return Icons.analytics;
    }
  }

  Color _getPriorityColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.high:
        return SPColors.danger100;
      case InsightPriority.medium:
        return SPColors.podOrange;
      case InsightPriority.low:
        return SPColors.success100;
    }
  }

  String _getPriorityText(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.high:
        return '중요';
      case InsightPriority.medium:
        return '보통';
      case InsightPriority.low:
        return '참고';
    }
  }
}

/// Model for category insights
class CategoryInsight {
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  final CategoryVisualizationData? category;
  final List<String> actionableSteps;
  final bool aiGenerated;

  const CategoryInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.category,
    this.actionableSteps = const [],
    this.aiGenerated = false,
  });
}

/// Enum for insight types
enum InsightType { improvement, strength, habit, optimization, trend }

/// Enum for insight priority levels
enum InsightPriority { high, medium, low }
