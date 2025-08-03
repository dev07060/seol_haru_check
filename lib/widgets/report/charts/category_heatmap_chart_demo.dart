import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/services/chart_foundation_service.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/report/charts/category_heatmap_chart.dart';

/// Demo page for CategoryHeatmapChart widget
class CategoryHeatmapChartDemo extends StatefulWidget {
  const CategoryHeatmapChartDemo({super.key});

  @override
  State<CategoryHeatmapChartDemo> createState() => _CategoryHeatmapChartDemoState();
}

class _CategoryHeatmapChartDemoState extends State<CategoryHeatmapChartDemo> {
  late CategoryHeatmapData _exerciseHeatmapData;
  late CategoryHeatmapData _dietHeatmapData;
  CategoryType _selectedType = CategoryType.exercise;
  HeatmapCellData? _selectedCell;

  @override
  void initState() {
    super.initState();
    _generateDemoData();
  }

  void _generateDemoData() {
    final chartService = ChartFoundationService.instance;

    // Exercise categories
    final exerciseCategories = ['근력 운동', '유산소 운동', '스트레칭/요가', '구기/스포츠', '야외 활동'];
    final exerciseCells = <HeatmapCellData>[];

    for (int categoryIndex = 0; categoryIndex < exerciseCategories.length; categoryIndex++) {
      final category = exerciseCategories[categoryIndex];
      final baseColor = chartService.getCategoryColor(category, ChartTheme.light());
      final emoji = chartService.getCategoryEmoji(category);

      for (int day = 0; day < 7; day++) {
        // Create varied activity patterns
        int activityCount = 0;
        List<String> activities = [];

        // Simulate realistic patterns
        if (category == '근력 운동') {
          // Strength training typically on specific days
          if (day == 1 || day == 3 || day == 5) {
            // Tue, Thu, Sat
            activityCount = (day == 3) ? 3 : 2; // More on Thursday
            activities = ['벤치프레스', '스쿼트', '데드리프트'].take(activityCount).toList();
          }
        } else if (category == '유산소 운동') {
          // Cardio more frequent but lighter
          if (day != 6) {
            // Not on Sunday
            activityCount = (day == 0 || day == 2 || day == 4) ? 2 : 1; // More on Mon, Wed, Fri
            activities = ['러닝', '사이클링', '수영'].take(activityCount).toList();
          }
        } else if (category == '스트레칭/요가') {
          // Daily light activity
          activityCount = 1;
          activities = ['요가', '스트레칭'];
        } else if (category == '구기/스포츠') {
          // Weekend focused
          if (day == 5 || day == 6) {
            // Sat, Sun
            activityCount = day == 5 ? 2 : 3; // More on Sunday
            activities = ['축구', '농구', '테니스'].take(activityCount).toList();
          }
        } else if (category == '야외 활동') {
          // Weekend activity
          if (day == 6) {
            // Sunday
            activityCount = 2;
            activities = ['등산', '자전거'];
          }
        }

        final intensity = activityCount > 0 ? (activityCount / 3.0).clamp(0.0, 1.0) : 0.0;

        exerciseCells.add(
          HeatmapCellData(
            dayOfWeek: day,
            categoryName: category,
            emoji: emoji,
            activityCount: activityCount,
            intensity: intensity,
            baseColor: baseColor,
            activities: activities,
            lastActivity: activityCount > 0 ? DateTime.now().subtract(Duration(days: 6 - day)) : null,
          ),
        );
      }
    }

    _exerciseHeatmapData = CategoryHeatmapData(
      cells: exerciseCells,
      categories: exerciseCategories,
      dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
      maxActivityCount: 3,
      maxIntensity: 1.0,
      type: CategoryType.exercise,
      dateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
    );

    // Diet categories
    final dietCategories = ['집밥/도시락', '건강식/샐러드', '단백질 위주', '간식/음료', '외식/배달'];
    final dietCells = <HeatmapCellData>[];

    for (int categoryIndex = 0; categoryIndex < dietCategories.length; categoryIndex++) {
      final category = dietCategories[categoryIndex];
      final baseColor = chartService.getCategoryColor(category, ChartTheme.light());
      final emoji = chartService.getCategoryEmoji(category);

      for (int day = 0; day < 7; day++) {
        int activityCount = 0;
        List<String> activities = [];

        // Simulate realistic diet patterns
        if (category == '집밥/도시락') {
          // Weekday focused
          if (day < 5) {
            // Mon-Fri
            activityCount = 2; // Lunch and dinner
            activities = ['도시락', '집밥'];
          } else {
            activityCount = 1; // Weekend lighter
            activities = ['집밥'];
          }
        } else if (category == '건강식/샐러드') {
          // Consistent healthy eating
          activityCount = day < 5 ? 1 : 0; // Weekdays only
          activities = ['샐러드'];
        } else if (category == '단백질 위주') {
          // Post-workout focused
          if (day == 1 || day == 3 || day == 5) {
            // Workout days
            activityCount = 2;
            activities = ['닭가슴살', '프로틴'];
          }
        } else if (category == '간식/음료') {
          // Daily but varied
          activityCount = day < 5 ? 1 : 2; // More on weekends
          activities = day < 5 ? ['커피'] : ['커피', '디저트'];
        } else if (category == '외식/배달') {
          // Weekend focused
          if (day == 5 || day == 6) {
            // Sat, Sun
            activityCount = day == 5 ? 1 : 2; // More on Sunday
            activities = day == 5 ? ['외식'] : ['외식', '배달'];
          }
        }

        final intensity = activityCount > 0 ? (activityCount / 2.0).clamp(0.0, 1.0) : 0.0;

        dietCells.add(
          HeatmapCellData(
            dayOfWeek: day,
            categoryName: category,
            emoji: emoji,
            activityCount: activityCount,
            intensity: intensity,
            baseColor: baseColor,
            activities: activities,
            lastActivity: activityCount > 0 ? DateTime.now().subtract(Duration(days: 6 - day)) : null,
          ),
        );
      }
    }

    _dietHeatmapData = CategoryHeatmapData(
      cells: dietCells,
      categories: dietCategories,
      dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
      maxActivityCount: 2,
      maxIntensity: 1.0,
      type: CategoryType.diet,
      dateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Heatmap Chart Demo'),
        backgroundColor: SPColors.podGreen,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildHeatmapChart(),
            const SizedBox(height: 20),
            _buildInsights(),
            const SizedBox(height: 20),
            _buildFeaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('카테고리 타입 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children:
                CategoryType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () => setState(() => _selectedType = type),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? SPColors.podGreen : SPColors.white,
                          foregroundColor: isSelected ? Colors.black : SPColors.gray700,
                          elevation: isSelected ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(type.icon, size: 18), const SizedBox(width: 4), Text(type.displayName)],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapChart() {
    final heatmapData = _selectedType == CategoryType.exercise ? _exerciseHeatmapData : _dietHeatmapData;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: CategoryHeatmapChart(
        heatmapData: heatmapData,
        title: '${_selectedType.displayName} 활동 패턴 히트맵',
        showTitle: true,
        enableInteraction: true,
        showIntensityLegend: true,
        showCategoryLabels: true,
        showDayLabels: true,
        highlightOptimalTiming: true,
        onCellTap: (cellData) {
          setState(() {
            _selectedCell = cellData;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(cellData.tooltipText), duration: const Duration(seconds: 2)));
        },
        onCellLongPress: (cellData) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('${cellData.emoji} ${cellData.categoryName}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('요일: ${heatmapData.dayLabels[cellData.dayOfWeek]}'),
                      Text('활동 횟수: ${cellData.activityCount}회'),
                      Text('강도: ${(cellData.intensity * 100).toInt()}%'),
                      if (cellData.activities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('활동 내역:', style: TextStyle(fontWeight: FontWeight.w600)),
                        ...cellData.activities.map((activity) => Text('• $activity')),
                      ],
                      if (cellData.lastActivity != null) ...[
                        const SizedBox(height: 8),
                        Text('마지막 활동: ${_formatDate(cellData.lastActivity!)}'),
                      ],
                    ],
                  ),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
                ),
          );
        },
        theme: ChartTheme.fromContext(context),
        animationConfig: const AnimationConfig(
          duration: Duration(milliseconds: 1200),
          enableStagger: true,
          staggerDelay: Duration(milliseconds: 50),
        ),
      ),
    );
  }

  Widget _buildInsights() {
    final heatmapData = _selectedType == CategoryType.exercise ? _exerciseHeatmapData : _dietHeatmapData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_selectedType.displayName} 패턴 분석', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildInsightRow('가장 활발한 요일', heatmapData.dayLabels[heatmapData.mostActiveDay], Icons.calendar_today),
          _buildInsightRow('가장 활발한 카테고리', heatmapData.mostActiveCategory, Icons.star),
          _buildInsightRow(
            '총 활동 횟수',
            '${heatmapData.cells.fold(0, (sum, cell) => sum + cell.activityCount)}회',
            Icons.fitness_center,
          ),
          _buildInsightRow(
            '활성 셀 비율',
            '${((heatmapData.cells.where((cell) => cell.hasActivity).length / heatmapData.cells.length) * 100).toInt()}%',
            Icons.grid_view,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SPColors.gray600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: SPColors.gray700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('주요 기능', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildFeatureItem('📊', '히트맵 시각화', '요일별 카테고리 활동 강도를 색상으로 표현'),
          _buildFeatureItem('🎯', '최적 타이밍 하이라이트', '가장 활발한 요일과 카테고리를 강조 표시'),
          _buildFeatureItem('👆', '인터랙티브 셀', '탭하여 상세 정보 확인, 길게 눌러 상세 다이얼로그'),
          _buildFeatureItem('📈', '강도 범례', '활동 강도를 시각적으로 이해할 수 있는 범례'),
          _buildFeatureItem('🎨', '카테고리별 색상', '각 카테고리마다 고유한 색상과 이모지'),
          _buildFeatureItem('📱', '반응형 디자인', '다양한 화면 크기에 최적화된 레이아웃'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: TextStyle(fontSize: 12, color: SPColors.gray600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }
}
