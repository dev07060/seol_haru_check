import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for category goal setting and tracking
class CategoryGoalSection extends StatefulWidget {
  final CategoryVisualizationData categoryData;
  final List<WeeklyReport> historicalReports;
  final Function(String categoryName, int goalValue)? onGoalSet;

  const CategoryGoalSection({super.key, required this.categoryData, required this.historicalReports, this.onGoalSet});

  @override
  State<CategoryGoalSection> createState() => _CategoryGoalSectionState();
}

class _CategoryGoalSectionState extends State<CategoryGoalSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _goalController = TextEditingController();
  int _currentGoal = 0;
  int _suggestedGoal = 0;
  bool _isEditingGoal = false;
  bool _goalAchieved = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _calculateGoals();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _calculateGoals() {
    // Calculate suggested goal based on historical data
    if (widget.historicalReports.isNotEmpty) {
      final categoryName = widget.categoryData.categoryName;
      final categoryType = widget.categoryData.type;

      final historicalCounts =
          widget.historicalReports.map((report) {
            if (categoryType == CategoryType.exercise) {
              return report.stats.exerciseCategories[categoryName] ?? 0;
            } else {
              return report.stats.dietCategories[categoryName] ?? 0;
            }
          }).toList();

      final average = historicalCounts.fold<double>(0, (sum, count) => sum + count) / historicalCounts.length;
      final maxCount = historicalCounts.fold<int>(0, (max, count) => count > max ? count : max);

      // Suggest a goal that's 20% higher than average but not more than max + 1
      _suggestedGoal = ((average * 1.2).ceil()).clamp(1, maxCount + 1);
    } else {
      // Default suggestion for new categories
      _suggestedGoal = widget.categoryData.type == CategoryType.exercise ? 3 : 5;
    }

    // Set current goal (this would normally come from user preferences/database)
    _currentGoal = _suggestedGoal;
    _goalController.text = _currentGoal.toString();

    // Check if current week's goal is achieved
    _goalAchieved = widget.categoryData.count >= _currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: _buildContent()),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 20),
        _buildCurrentGoalCard(),
        const SizedBox(height: 16),
        _buildProgressCard(),
        const SizedBox(height: 16),
        _buildGoalSuggestions(),
        const SizedBox(height: 16),
        _buildGoalHistory(),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.flag, color: widget.categoryData.color, size: 20),
        const SizedBox(width: 8),
        Text(
          '목표 설정',
          style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.categoryData.color),
        ),
        const Spacer(),
        if (_goalAchieved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SPColors.success100.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: SPColors.success100),
                const SizedBox(width: 4),
                Text(
                  '달성',
                  style: FTextStyles.body3_13.copyWith(color: SPColors.success100, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.categoryData.color.withValues(alpha: 0.1), widget.categoryData.color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.categoryData.color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.categoryData.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(child: Text(widget.categoryData.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('이번 주 목표', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (!_isEditingGoal) ...[
                          Text(
                            '$_currentGoal회',
                            style: FTextStyles.title1_24.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.categoryData.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isEditingGoal = true),
                            child: Icon(Icons.edit, size: 20, color: widget.categoryData.color),
                          ),
                        ] else ...[
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _goalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              style: FTextStyles.title1_24.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.categoryData.color,
                              ),
                              decoration: InputDecoration(
                                border: UnderlineInputBorder(borderSide: BorderSide(color: widget.categoryData.color)),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: widget.categoryData.color, width: 2),
                                ),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onSubmitted: _saveGoal,
                              autofocus: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _saveGoal,
                            child: Icon(Icons.check, size: 20, color: SPColors.success100),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _cancelGoalEdit,
                            child: Icon(Icons.close, size: 20, color: SPColors.danger100),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(label: '현재', value: '${widget.categoryData.count}회', color: SPColors.gray700),
              ),
              Container(width: 1, height: 30, color: SPColors.gray300),
              Expanded(
                child: _buildStatItem(
                  label: '남은 목표',
                  value: '${(_currentGoal - widget.categoryData.count).clamp(0, _currentGoal)}회',
                  color: widget.categoryData.color,
                ),
              ),
              Container(width: 1, height: 30, color: SPColors.gray300),
              Expanded(
                child: _buildStatItem(
                  label: '달성률',
                  value: '${((widget.categoryData.count / _currentGoal) * 100).clamp(0, 100).toInt()}%',
                  color: _goalAchieved ? SPColors.success100 : SPColors.podOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(value, style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
      ],
    );
  }

  Widget _buildProgressCard() {
    final progress = (widget.categoryData.count / _currentGoal).clamp(0.0, 1.0);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('진행 상황', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: SPColors.gray800)),
              Text(
                '${widget.categoryData.count} / $_currentGoal',
                style: FTextStyles.body2_14.copyWith(color: widget.categoryData.color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: SPColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _goalAchieved ? SPColors.success100 : widget.categoryData.color,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getProgressMessage(progress),
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: widget.categoryData.color, size: 20),
              const SizedBox(width: 8),
              Text(
                '목표 제안',
                style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.categoryData.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: _getGoalSuggestions().map((goal) => _buildGoalChip(goal)).toList()),
        ],
      ),
    );
  }

  Widget _buildGoalChip(int goal) {
    final isSelected = goal == _currentGoal;
    final isRecommended = goal == _suggestedGoal;

    return GestureDetector(
      onTap: () => _setGoal(goal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.categoryData.color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? widget.categoryData.color : SPColors.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$goal회',
              style: FTextStyles.body2_14.copyWith(
                color: isSelected ? widget.categoryData.color : SPColors.gray700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isRecommended) ...[const SizedBox(width: 4), Icon(Icons.star, size: 14, color: SPColors.podOrange)],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalHistory() {
    if (widget.historicalReports.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              Icon(Icons.history, color: widget.categoryData.color, size: 20),
              const SizedBox(width: 8),
              Text(
                '최근 기록',
                style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.categoryData.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHistoryChart(),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    final recentReports = widget.historicalReports.take(4).toList();
    final categoryName = widget.categoryData.categoryName;
    final categoryType = widget.categoryData.type;

    return Row(
      children:
          recentReports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;

            int count = 0;
            if (categoryType == CategoryType.exercise) {
              count = report.stats.exerciseCategories[categoryName] ?? 0;
            } else {
              count = report.stats.dietCategories[categoryName] ?? 0;
            }

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < recentReports.length - 1 ? 8 : 0),
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.categoryData.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: (count / 7 * 40).clamp(2.0, 40.0),
                          decoration: BoxDecoration(
                            color: widget.categoryData.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$count회',
                      style: FTextStyles.body3_13.copyWith(color: SPColors.gray700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recentReports.length - index}주전',
                      style: FTextStyles.body3_13.copyWith(color: SPColors.gray500, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  List<int> _getGoalSuggestions() {
    final suggestions = <int>{};

    // Add current goal
    suggestions.add(_currentGoal);

    // Add suggested goal
    suggestions.add(_suggestedGoal);

    // Add some common goals based on category type
    if (widget.categoryData.type == CategoryType.exercise) {
      suggestions.addAll([1, 2, 3, 4, 5, 7]);
    } else {
      suggestions.addAll([3, 5, 7, 10, 14]);
    }

    // Remove goals that are too high (more than 14)
    suggestions.removeWhere((goal) => goal > 14);

    final sortedSuggestions = suggestions.toList()..sort();
    return sortedSuggestions;
  }

  String _getProgressMessage(double progress) {
    if (progress >= 1.0) {
      return '🎉 목표를 달성했습니다! 훌륭해요!';
    } else if (progress >= 0.8) {
      return '거의 다 왔어요! 조금만 더 힘내세요!';
    } else if (progress >= 0.5) {
      return '절반을 넘었네요! 좋은 페이스입니다!';
    } else if (progress >= 0.2) {
      return '좋은 시작이에요! 꾸준히 해보세요!';
    } else {
      return '이제 시작해보세요! 작은 걸음부터 천천히!';
    }
  }

  void _setGoal(int goal) {
    setState(() {
      _currentGoal = goal;
      _goalController.text = goal.toString();
      _goalAchieved = widget.categoryData.count >= _currentGoal;
    });

    if (widget.onGoalSet != null) {
      widget.onGoalSet!(widget.categoryData.categoryName, goal);
    }
  }

  void _saveGoal([String? value]) {
    final goalText = value ?? _goalController.text;
    final goal = int.tryParse(goalText);

    if (goal != null && goal > 0 && goal <= 99) {
      _setGoal(goal);
    } else {
      _goalController.text = _currentGoal.toString();
    }

    setState(() => _isEditingGoal = false);
  }

  void _cancelGoalEdit() {
    _goalController.text = _currentGoal.toString();
    setState(() => _isEditingGoal = false);
  }
}
