import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/charts/category_distribution_chart.dart';
import 'package:seol_haru_check/widgets/report/modals/category_drill_down_modal.dart';

/// Demo widget for testing category drill-down functionality
class CategoryDrillDownDemo extends StatefulWidget {
  const CategoryDrillDownDemo({super.key});

  @override
  State<CategoryDrillDownDemo> createState() => _CategoryDrillDownDemoState();
}

class _CategoryDrillDownDemoState extends State<CategoryDrillDownDemo> {
  late List<CategoryVisualizationData> _exerciseCategoryData;
  late List<CategoryVisualizationData> _dietCategoryData;
  late List<WeeklyReport> _historicalReports;

  @override
  void initState() {
    super.initState();
    _generateMockData();
  }

  void _generateMockData() {
    // Generate mock exercise category data
    _exerciseCategoryData = [
      CategoryVisualizationData(
        categoryName: '근력 운동',
        emoji: '💪',
        count: 5,
        percentage: 0.35,
        color: SPColors.podGreen,
        type: CategoryType.exercise,
        subcategories: [
          const SubcategoryData(
            name: '웨이트 트레이닝',
            count: 3,
            percentage: 0.6,
            description: '덤벨, 바벨을 이용한 근력 운동',
            emoji: '🏋️',
          ),
          const SubcategoryData(
            name: '맨몸 운동',
            count: 2,
            percentage: 0.4,
            description: '푸시업, 스쿼트 등 자체 중량 운동',
            emoji: '🤸',
          ),
        ],
        description: '근육량 증가와 기초대사량 향상을 위한 운동',
      ),
      CategoryVisualizationData(
        categoryName: '유산소 운동',
        emoji: '🏃',
        count: 4,
        percentage: 0.28,
        color: SPColors.podBlue,
        type: CategoryType.exercise,
        subcategories: [
          const SubcategoryData(name: '러닝', count: 2, percentage: 0.5, description: '야외 또는 트레드밀 달리기', emoji: '🏃‍♂️'),
          const SubcategoryData(name: '사이클링', count: 2, percentage: 0.5, description: '자전거 타기', emoji: '🚴'),
        ],
        description: '심폐지구력 향상과 체지방 감소를 위한 운동',
      ),
      CategoryVisualizationData(
        categoryName: '스트레칭/요가',
        emoji: '🧘',
        count: 3,
        percentage: 0.21,
        color: SPColors.podPurple,
        type: CategoryType.exercise,
        subcategories: [
          const SubcategoryData(name: '요가', count: 2, percentage: 0.67, description: '유연성과 균형감각 향상', emoji: '🧘‍♀️'),
          const SubcategoryData(
            name: '스트레칭',
            count: 1,
            percentage: 0.33,
            description: '근육 이완과 관절 가동범위 증가',
            emoji: '🤸‍♀️',
          ),
        ],
        description: '유연성 향상과 근육 이완을 위한 운동',
      ),
      CategoryVisualizationData(
        categoryName: '구기/스포츠',
        emoji: '⚽',
        count: 2,
        percentage: 0.14,
        color: SPColors.podOrange,
        type: CategoryType.exercise,
        subcategories: [
          const SubcategoryData(name: '축구', count: 1, percentage: 0.5, description: '팀 스포츠', emoji: '⚽'),
          const SubcategoryData(name: '테니스', count: 1, percentage: 0.5, description: '라켓 스포츠', emoji: '🎾'),
        ],
        description: '재미와 사회성을 기를 수 있는 운동',
      ),
    ];

    // Generate mock diet category data
    _dietCategoryData = [
      CategoryVisualizationData(
        categoryName: '집밥/도시락',
        emoji: '🍱',
        count: 8,
        percentage: 0.4,
        color: SPColors.podGreen,
        type: CategoryType.diet,
        subcategories: [
          const SubcategoryData(name: '한식', count: 5, percentage: 0.625, description: '전통 한국 음식', emoji: '🍚'),
          const SubcategoryData(name: '도시락', count: 3, percentage: 0.375, description: '직접 준비한 도시락', emoji: '🍱'),
        ],
        description: '영양 균형을 고려한 집에서 만든 음식',
      ),
      CategoryVisualizationData(
        categoryName: '건강식/샐러드',
        emoji: '🥗',
        count: 6,
        percentage: 0.3,
        color: SPColors.podMint,
        type: CategoryType.diet,
        subcategories: [
          const SubcategoryData(name: '그린 샐러드', count: 4, percentage: 0.67, description: '신선한 채소 위주의 샐러드', emoji: '🥬'),
          const SubcategoryData(name: '프로틴 샐러드', count: 2, percentage: 0.33, description: '단백질이 추가된 샐러드', emoji: '🥗'),
        ],
        description: '저칼로리 고영양 건강식',
      ),
      CategoryVisualizationData(
        categoryName: '단백질 위주',
        emoji: '🍗',
        count: 4,
        percentage: 0.2,
        color: SPColors.podBlue,
        type: CategoryType.diet,
        subcategories: [
          const SubcategoryData(name: '닭가슴살', count: 2, percentage: 0.5, description: '저지방 고단백 식품', emoji: '🍗'),
          const SubcategoryData(name: '계란', count: 2, percentage: 0.5, description: '완전 단백질 식품', emoji: '🥚'),
        ],
        description: '근육 생성과 유지를 위한 고단백 식품',
      ),
      CategoryVisualizationData(
        categoryName: '간식/음료',
        emoji: '🍪',
        count: 2,
        percentage: 0.1,
        color: SPColors.podOrange,
        type: CategoryType.diet,
        subcategories: [
          const SubcategoryData(name: '견과류', count: 1, percentage: 0.5, description: '건강한 지방과 단백질', emoji: '🥜'),
          const SubcategoryData(name: '과일', count: 1, percentage: 0.5, description: '비타민과 섬유질', emoji: '🍎'),
        ],
        description: '건강한 간식과 음료',
      ),
    ];

    // Generate mock historical reports
    _historicalReports = List.generate(8, (index) {
      final weekStart = DateTime.now().subtract(Duration(days: (index + 1) * 7));
      return WeeklyReport(
        id: 'report_$index',
        userUuid: 'demo_user',
        weekStartDate: weekStart,
        weekEndDate: weekStart.add(const Duration(days: 6)),
        generatedAt: weekStart,
        stats: WeeklyStats(
          totalCertifications: 10 + (index % 5),
          exerciseDays: 4 + (index % 3),
          dietDays: 6 + (index % 2),
          consistencyScore: 0.7 + (index % 3) * 0.1,
          exerciseCategories: {
            '근력 운동': 3 + (index % 4),
            '유산소 운동': 2 + (index % 3),
            '스트레칭/요가': 1 + (index % 3),
            '구기/스포츠': index % 2,
          },
          dietCategories: {
            '집밥/도시락': 5 + (index % 4),
            '건강식/샐러드': 3 + (index % 3),
            '단백질 위주': 2 + (index % 3),
            '간식/음료': 1 + (index % 2),
          },
          exerciseTypes: {},
        ),
        analysis: AIAnalysis(
          exerciseInsights: 'Mock exercise analysis for week $index',
          dietInsights: 'Mock diet analysis for week $index',
          overallAssessment: 'Mock overall assessment for week $index',
          strengthAreas: ['Mock strength area'],
          improvementAreas: ['Mock improvement area'],
        ),
        recommendations: ['Mock recommendation for week $index'],
        status: ReportStatus.completed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Drill-Down Demo'),
        backgroundColor: SPColors.podGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('운동 카테고리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: CategoryDistributionChart(
                categoryData: _exerciseCategoryData,
                type: CategoryType.exercise,
                historicalReports: _historicalReports,
                enableDrillDown: true,
                showLegend: true,
                enableInteraction: true,
              ),
            ),
            const SizedBox(height: 32),
            const Text('식단 카테고리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: CategoryDistributionChart(
                categoryData: _dietCategoryData,
                type: CategoryType.diet,
                historicalReports: _historicalReports,
                enableDrillDown: true,
                showLegend: true,
                enableInteraction: true,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _showManualDrillDown,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SPColors.podBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('수동으로 드릴다운 열기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualDrillDown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CategoryDrillDownModal(
            categoryData: _exerciseCategoryData.first,
            historicalReports: _historicalReports,
            onGoalSet: (categoryName, goalValue) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$categoryName 목표를 $goalValue회로 설정했습니다'), backgroundColor: SPColors.podGreen),
              );
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
