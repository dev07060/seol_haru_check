import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/comparison/category_comparison_card.dart';

/// Demo page for CategoryComparisonCard widget
class CategoryComparisonCardDemo extends StatefulWidget {
  const CategoryComparisonCardDemo({super.key});

  @override
  State<CategoryComparisonCardDemo> createState() => _CategoryComparisonCardDemoState();
}

class _CategoryComparisonCardDemoState extends State<CategoryComparisonCardDemo> {
  late WeeklyReport currentWeekReport;
  late WeeklyReport previousWeekReport;
  bool showPreviousWeek = true;

  @override
  void initState() {
    super.initState();
    _generateSampleData();
  }

  void _generateSampleData() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = previousWeekStart.add(const Duration(days: 6));

    // Current week data with diverse categories
    currentWeekReport = WeeklyReport(
      id: 'current_week',
      userUuid: 'demo_user',
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      generatedAt: now,
      stats: const WeeklyStats(
        totalCertifications: 12,
        exerciseDays: 5,
        dietDays: 6,
        exerciseTypes: {'근력 운동': 3, '유산소 운동': 2, '스트레칭/요가': 2},
        exerciseCategories: {
          '근력 운동': 4,
          '유산소 운동': 3,
          '스트레칭/요가': 2,
          '구기/스포츠': 1,
          '댄스/무용': 1, // New category this week
        },
        dietCategories: {
          '집밥/도시락': 5,
          '건강식/샐러드': 4,
          '단백질 위주': 3,
          '간식/음료': 2,
          '영양제/보충제': 2, // New category this week
        },
        consistencyScore: 0.85,
      ),
      analysis: const AIAnalysis(
        exerciseInsights: 'Sample exercise insights',
        dietInsights: 'Sample diet insights',
        overallAssessment: 'Sample assessment',
        strengthAreas: ['Consistency', 'Variety'],
        improvementAreas: ['Intensity'],
      ),
      recommendations: ['Sample recommendation'],
      status: ReportStatus.completed,
    );

    // Previous week data with some different categories
    previousWeekReport = WeeklyReport(
      id: 'previous_week',
      userUuid: 'demo_user',
      weekStartDate: previousWeekStart,
      weekEndDate: previousWeekEnd,
      generatedAt: now.subtract(const Duration(days: 7)),
      stats: const WeeklyStats(
        totalCertifications: 10,
        exerciseDays: 4,
        dietDays: 5,
        exerciseTypes: {'근력 운동': 4, '유산소 운동': 1, '스트레칭/요가': 3},
        exerciseCategories: {
          '근력 운동': 5, // Decreased this week
          '유산소 운동': 2, // Increased this week
          '스트레칭/요가': 3, // Decreased this week
          '구기/스포츠': 2, // Decreased this week
          '야외 활동': 1, // Disappeared this week
        },
        dietCategories: {
          '집밥/도시락': 4, // Increased this week
          '건강식/샐러드': 3, // Increased this week
          '단백질 위주': 4, // Decreased this week
          '간식/음료': 3, // Decreased this week
          '외식/배달': 2, // Disappeared this week
        },
        consistencyScore: 0.72,
      ),
      analysis: const AIAnalysis(
        exerciseInsights: 'Previous exercise insights',
        dietInsights: 'Previous diet insights',
        overallAssessment: 'Previous assessment',
        strengthAreas: ['Consistency'],
        improvementAreas: ['Variety', 'Intensity'],
      ),
      recommendations: ['Previous recommendation'],
      status: ReportStatus.completed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SPColors.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Category Comparison Demo',
          style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context)),
        ),
        backgroundColor: SPColors.backgroundColor(context),
        elevation: 0,
        actions: [
          Switch(
            value: showPreviousWeek,
            onChanged: (value) {
              setState(() {
                showPreviousWeek = value;
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDemoInfo(context),
            const SizedBox(height: 24),
            _buildExerciseComparison(context),
            const SizedBox(height: 16),
            _buildDietComparison(context),
            const SizedBox(height: 24),
            _buildFeatureHighlights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.podBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.podBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: SPColors.podBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'CategoryComparisonCard Demo',
                style: FTextStyles.title4_17.copyWith(color: SPColors.podBlue, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '이 데모는 주간 카테고리 비교 카드의 기능을 보여줍니다. '
            '스위치를 사용하여 이전 주 데이터 유무에 따른 표시 차이를 확인할 수 있습니다.',
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
          ),
          const SizedBox(height: 8),
          Text(
            '• 카테고리별 증감 표시\n'
            '• 신규/중단 카테고리 하이라이트\n'
            '• 다양성 점수 비교\n'
            '• 색상 코딩된 변화 지표',
            style: FTextStyles.body3_13.copyWith(color: SPColors.gray600),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 카테고리 비교',
          style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CategoryComparisonCard(
          currentWeek: currentWeekReport,
          previousWeek: showPreviousWeek ? previousWeekReport : null,
          categoryType: CategoryType.exercise,
          onTap: () {
            _showDetailDialog(context, '운동 카테고리 상세 분석');
          },
        ),
      ],
    );
  }

  Widget _buildDietComparison(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '식단 카테고리 비교',
          style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CategoryComparisonCard(
          currentWeek: currentWeekReport,
          previousWeek: showPreviousWeek ? previousWeekReport : null,
          categoryType: CategoryType.diet,
          onTap: () {
            _showDetailDialog(context, '식단 카테고리 상세 분석');
          },
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주요 기능',
            style: FTextStyles.title4_17.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(context, Icons.trending_up, '변화 지표', '각 카테고리의 증감을 색상과 아이콘으로 표시', SPColors.success100),
          _buildFeatureItem(context, Icons.fiber_new, '신규/중단 하이라이트', '새로 시작하거나 중단된 카테고리를 특별히 표시', SPColors.podGreen),
          _buildFeatureItem(context, Icons.diversity_3, '다양성 점수', 'Shannon 다양성 지수를 기반으로 한 활동 다양성 측정', SPColors.podBlue),
          _buildFeatureItem(context, Icons.compare_arrows, '직관적 비교', '이번 주와 지난 주 데이터를 나란히 비교 표시', SPColors.podOrange),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(description, style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title, style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context))),
            content: Text(
              '실제 구현에서는 여기에 상세한 카테고리 분석 정보가 표시됩니다.',
              style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인', style: FTextStyles.body2_14.copyWith(color: SPColors.podBlue)),
              ),
            ],
          ),
    );
  }
}
