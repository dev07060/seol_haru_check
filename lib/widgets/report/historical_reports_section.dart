import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/services/consistency_calculator.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/loading/loading_state_manager.dart';
import 'package:seol_haru_check/widgets/loading/skeleton_loading.dart';
import 'package:seol_haru_check/widgets/report/charts/category_preference_evolution_chart.dart';
import 'package:seol_haru_check/widgets/report/charts/category_progress_tracker.dart';
import 'package:seol_haru_check/widgets/report/charts/category_seasonality_chart.dart';
import 'package:seol_haru_check/widgets/report/charts/category_trend_line_chart.dart';
import 'package:seol_haru_check/widgets/report/diet_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/exercise_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/recommendations_section.dart';
import 'package:seol_haru_check/widgets/report/report_summary_card.dart';
import 'package:seol_haru_check/widgets/report/week_picker_dialog.dart';

/// Widget for displaying and navigating historical weekly reports
class HistoricalReportsSection extends ConsumerStatefulWidget {
  const HistoricalReportsSection({super.key});

  @override
  ConsumerState<HistoricalReportsSection> createState() => _HistoricalReportsSectionState();
}

class _HistoricalReportsSectionState extends ConsumerState<HistoricalReportsSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _listFadeAnimation;

  bool _isLoadingSpecificReport = false;
  bool _showCategoryTrends = false;
  final List<String> _selectedExerciseCategories = [];
  final List<String> _selectedDietCategories = [];

  @override
  void initState() {
    super.initState();

    // Modal animation controller
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    // List animation controller for smooth transitions
    _listAnimationController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _listFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _listAnimationController, curve: Curves.easeInOut));

    // Start list animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<DateTime> _getEarliestReportDate() async {
    final state = ref.read(weeklyReportProvider);
    if (state.reports.isNotEmpty) {
      return state.reports.last.weekStartDate;
    }

    // Fetch from service if not available in state
    try {
      final service = ref.read(weeklyReportServiceProvider);
      final currentUser = ref.read(authStateChangesProvider).value;
      if (currentUser != null) {
        final earliestDate = await service.getEarliestReportDate(currentUser.uid);
        return earliestDate ?? DateTime.now().subtract(const Duration(days: 90));
      }
    } catch (e) {
      // Fallback to 3 months ago
    }

    return DateTime.now().subtract(const Duration(days: 90));
  }

  Future<void> _showWeekPicker() async {
    final earliestDate = await _getEarliestReportDate();

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => WeekPickerDialog(
              initialDate: DateTime.now(),
              earliestDate: earliestDate,
              onWeekSelected: _navigateToWeek,
            ),
      );
    }
  }

  Future<void> _navigateToWeek(DateTime weekStart) async {
    setState(() {
      _isLoadingSpecificReport = true;
    });

    // Add smooth loading transition
    _listAnimationController.reverse();

    try {
      final notifier = ref.read(weeklyReportProvider.notifier);
      final report = await notifier.fetchReportByWeek(weekStart);

      if (report != null) {
        // Smooth transition to show report
        await _listAnimationController.forward();
        _animationController.forward();

        // Show the report in a modal with enhanced animation
        _showReportModal(report);
      } else {
        // Restore list animation even if no report found
        await _listAnimationController.forward();
        _showNoReportSnackBar(weekStart);
      }
    } catch (e) {
      // Restore list animation on error
      await _listAnimationController.forward();
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoadingSpecificReport = false;
      });
    }
  }

  void _showNoReportSnackBar(DateTime weekStart) {
    final dateFormat = DateFormat('M월 d일', 'ko_KR');
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekRange = '${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$weekRange ${AppStrings.weekOf}에 ${AppStrings.noReportForWeek}'),
        backgroundColor: SPColors.reportOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: SPColors.danger100,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showReportModal(WeeklyReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: _animationController,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => AnimatedBuilder(
                  animation: _animationController,
                  builder:
                      (context, child) => FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            decoration: BoxDecoration(
                              color: SPColors.backgroundColor(context),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                  color: SPColors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Handle bar with animation
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 8),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: SPColors.gray300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),

                                // Header with enhanced animation
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: _buildReportHeader(report),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _animationController.reverse().then((_) {
                                            Navigator.of(context).pop();
                                            _animationController.reset();
                                          });
                                        },
                                        icon: Icon(Icons.close, color: SPColors.textColor(context)),
                                        tooltip: AppStrings.closeTooltip,
                                      ),
                                    ],
                                  ),
                                ),

                                // Content with staggered animations
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: [
                                        _buildAnimatedReportContent(ReportSummaryCard(report: report), 0),
                                        const SizedBox(height: 16),
                                        _buildAnimatedReportContent(
                                          ExerciseAnalysisSection(
                                            analysis: report.analysis,
                                            stats: report.stats,
                                            categoryTrends: null, // Historical reports don't need trend data
                                            exerciseCategoryData: null, // Historical reports use basic display
                                            historicalReports: null,
                                          ),
                                          1,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildAnimatedReportContent(
                                          DietAnalysisSection(analysis: report.analysis, stats: report.stats),
                                          2,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildAnimatedReportContent(
                                          RecommendationsSection(recommendations: report.recommendations),
                                          3,
                                        ),
                                        const SizedBox(height: 32),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ),
          ),
    );
  }

  Widget _buildAnimatedReportContent(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final delay = index * 0.1;
        final animationValue = Curves.easeOutCubic.transform(
          (((_animationController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0)),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(opacity: animationValue, child: child),
        );
      },
    );
  }

  Widget _buildReportHeader(WeeklyReport report) {
    final dateFormat = DateFormat('M월 d일', 'ko_KR');
    final weekRange = '${dateFormat.format(report.weekStartDate)} - ${dateFormat.format(report.weekEndDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weekRange,
          style: FTextStyles.title2_20.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('${AppStrings.weekOf} 리포트', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weeklyReportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with date picker button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.previousWeeks,
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isLoadingSpecificReport ? null : _showWeekPicker,
                icon:
                    _isLoadingSpecificReport
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(SPColors.reportGreen),
                          ),
                        )
                        : Icon(Icons.calendar_today, size: 16, color: SPColors.reportGreen),
                label: Text(
                  AppStrings.selectDate,
                  style: FTextStyles.body2_14.copyWith(
                    color: _isLoadingSpecificReport ? SPColors.gray400 : SPColors.reportGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _isLoadingSpecificReport ? SPColors.gray300 : SPColors.reportGreen.withValues(alpha: .3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Category trends toggle button
        if (state.reports.length >= 3) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '카테고리 트렌드 분석',
                    style: FTextStyles.body1_16.copyWith(
                      color: SPColors.textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _showCategoryTrends,
                  onChanged: (value) {
                    setState(() {
                      _showCategoryTrends = value;
                    });
                  },
                  activeColor: SPColors.reportGreen,
                ),
              ],
            ),
          ),
        ],

        // Category trend visualizations
        if (_showCategoryTrends && state.reports.length >= 3) ...[_buildCategoryTrendSection(state.reports)],

        // Historical reports list with enhanced animations
        AnimatedBuilder(
          animation: _listFadeAnimation,
          builder: (context, child) {
            if (state.isLoading && state.reports.isEmpty) {
              return _buildLoadingState();
            }

            if (state.reports.isNotEmpty) {
              return FadeTransition(
                opacity: _listFadeAnimation,
                child: Column(
                  children:
                      state.reports.asMap().entries.map((entry) {
                        final index = entry.key;
                        final report = entry.value;
                        return _buildAnimatedHistoricalReportCard(report, index);
                      }).toList(),
                ),
              );
            } else if (!state.isLoading) {
              return FadeTransition(opacity: _listFadeAnimation, child: _buildEmptyHistoricalState());
            }

            return const SizedBox.shrink();
          },
        ),

        // Loading more indicator
        if (state.isLoadingMore)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: InlineLoadingIndicator(message: AppStrings.loadingMore),
          ),

        // No more reports indicator
        if (!ref.read(weeklyReportProvider.notifier).hasMoreReports && state.reports.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(AppStrings.noMoreReports, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SkeletonCard(height: 120, width: double.infinity),
        );
      }),
    );
  }

  Widget _buildEmptyHistoricalState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: SPColors.gray400),
            const SizedBox(height: 16),
            Text('아직 이전 리포트가 없습니다', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
            const SizedBox(height: 8),
            Text(
              '주간 리포트는 일요일~토요일 단위로 생성됩니다\n최소 3일 이상 활동 시 리포트가 만들어져요',
              style: FTextStyles.body2_14.copyWith(color: SPColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHistoricalReportCard(WeeklyReport report, int index) {
    return AnimatedBuilder(
      animation: _listFadeAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationValue = Curves.easeOutCubic.transform(
          (((_listFadeAnimation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0)),
        );

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(opacity: animationValue, child: _buildHistoricalReportCard(report)),
        );
      },
    );
  }

  Widget _buildCategoryTrendSection(List<WeeklyReport> reports) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.gray200),
        boxShadow: [
          BoxShadow(color: SPColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            '카테고리 트렌드 분석',
            style: FTextStyles.title2_20.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('시간에 따른 운동과 식단 카테고리의 변화를 분석합니다', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
          const SizedBox(height: 24),

          // Exercise category trends
          CategoryTrendLineChart(
            historicalReports: reports,
            categoryType: CategoryType.exercise,
            selectedCategories: _selectedExerciseCategories,
            onCategoryToggle: (categoryName) {
              setState(() {
                if (_selectedExerciseCategories.contains(categoryName)) {
                  _selectedExerciseCategories.remove(categoryName);
                } else {
                  _selectedExerciseCategories.add(categoryName);
                }
              });
            },
            height: 280,
          ),

          const SizedBox(height: 32),

          // Diet category trends
          CategoryTrendLineChart(
            historicalReports: reports,
            categoryType: CategoryType.diet,
            selectedCategories: _selectedDietCategories,
            onCategoryToggle: (categoryName) {
              setState(() {
                if (_selectedDietCategories.contains(categoryName)) {
                  _selectedDietCategories.remove(categoryName);
                } else {
                  _selectedDietCategories.add(categoryName);
                }
              });
            },
            height: 280,
          ),

          const SizedBox(height: 32),

          // Exercise preference evolution
          CategoryPreferenceEvolutionChart(
            historicalReports: reports,
            categoryType: CategoryType.exercise,
            height: 250,
          ),

          const SizedBox(height: 32),

          // Diet preference evolution
          CategoryPreferenceEvolutionChart(historicalReports: reports, categoryType: CategoryType.diet, height: 250),

          // Show seasonality analysis only if we have enough data (6+ months)
          if (reports.length >= 24) ...[
            const SizedBox(height: 32),

            CategorySeasonalityChart(historicalReports: reports, categoryType: CategoryType.exercise, height: 300),

            const SizedBox(height: 32),

            CategorySeasonalityChart(historicalReports: reports, categoryType: CategoryType.diet, height: 300),
          ],

          // Show progress tracking if we have enough data (8+ weeks)
          if (reports.length >= 8) ...[
            const SizedBox(height: 32),

            CategoryProgressTracker(historicalReports: reports, categoryType: CategoryType.exercise, monthsToShow: 6),

            const SizedBox(height: 24),

            CategoryProgressTracker(historicalReports: reports, categoryType: CategoryType.diet, monthsToShow: 6),
          ],
        ],
      ),
    );
  }

  /// Format consistency score to prevent unrealistic values
  String _formatConsistencyScore(double score) {
    // Clamp the score to reasonable range (0-100%)
    final clampedScore = (score * 100).clamp(0, 100);
    return clampedScore.toInt().toString();
  }

  /// Get recalculated consistency score for historical reports
  double _getRecalculatedConsistencyScore(WeeklyReport report) {
    return ConsistencyCalculator.calculateConsistencyScore(report.stats);
  }

  Widget _buildHistoricalReportCard(WeeklyReport report) {
    final dateFormat = DateFormat('M월 d일', 'ko_KR');
    final weekRange = '${dateFormat.format(report.weekStartDate)} - ${dateFormat.format(report.weekEndDate)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        color: SPColors.backgroundColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SPColors.gray200, width: 1),
        ),
        child: InkWell(
          onTap: () => _showReportModal(report),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Report icon with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SPColors.reportGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.analytics_outlined, color: SPColors.reportGreen, size: 20),
                ),
                const SizedBox(width: 12),

                // Report info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekRange,
                        style: FTextStyles.body1_16.copyWith(
                          color: SPColors.textColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '총 ${report.stats.totalCertifications}개 인증 • ${report.stats.exerciseDays}일 운동 • ${report.stats.dietDays}일 식단',
                        style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                      ),
                      if (report.stats.consistencyScore > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14,
                              color:
                                  _getRecalculatedConsistencyScore(report) >= 0.7
                                      ? SPColors.reportGreen
                                      : _getRecalculatedConsistencyScore(report) >= 0.4
                                      ? SPColors.reportOrange
                                      : SPColors.danger100,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '일관성 ${_formatConsistencyScore(_getRecalculatedConsistencyScore(report))}%',
                              style: FTextStyles.body2_14.copyWith(
                                color:
                                    _getRecalculatedConsistencyScore(report) >= 0.7
                                        ? SPColors.reportGreen
                                        : _getRecalculatedConsistencyScore(report) >= 0.4
                                        ? SPColors.reportOrange
                                        : SPColors.danger100,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron icon with subtle animation
                AnimatedRotation(
                  turns: 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right, color: SPColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
