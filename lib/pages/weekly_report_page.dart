import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/helpers/debug_data_helper.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/weekly_report_model.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/router.dart';
import 'package:seol_haru_check/services/visualization_data_service.dart';
import 'package:seol_haru_check/shared/components/f_app_bar.dart';
import 'package:seol_haru_check/shared/components/f_scaffold.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/debug/debug_settings_dialog.dart';
import 'package:seol_haru_check/widgets/in_app_notification_widget.dart';
import 'package:seol_haru_check/widgets/loading/loading_state_manager.dart';
import 'package:seol_haru_check/widgets/report/achievements/weekly_achievements_section.dart';
import 'package:seol_haru_check/widgets/report/animations/animation_showcase.dart';
import 'package:seol_haru_check/widgets/report/charts/category_distribution_chart.dart';
import 'package:seol_haru_check/widgets/report/comparison/category_comparison_card.dart';
import 'package:seol_haru_check/widgets/report/diet_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/exercise_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/historical_reports_section.dart';
import 'package:seol_haru_check/widgets/report/recommendations_section.dart';
import 'package:seol_haru_check/widgets/report/report_summary_card.dart';
import 'package:seol_haru_check/widgets/report/sections/category_insights_section.dart';

// Provider for visualization data service
final visualizationDataServiceProvider = Provider<VisualizationDataService>((ref) {
  return VisualizationDataService();
});

/// Main screen for displaying weekly AI analysis reports
class WeeklyReportPage extends ConsumerStatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  ConsumerState<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends ConsumerState<WeeklyReportPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Visualization data state
  VisualizationData? _visualizationData;
  CategoryTrendData? _categoryTrends;

  // Category navigation and filtering state
  CategoryType? _selectedCategoryFilter;
  bool _showCategoryInsights = true;
  bool _showCategoryComparison = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize animations
    _fadeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode && DebugDataHelper.isDebugMode) {
        // 디버깅 모드에서는 가짜 데이터 로드
        ref.read(weeklyReportProvider.notifier).loadDebugCurrentWeekReport();
      } else {
        // 실제 데이터 로드
        _refreshData();
      }
      // Mark new report notification as read when page is viewed
      ref.read(weeklyReportProvider.notifier).markNewReportAsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more reports when near bottom
      final notifier = ref.read(weeklyReportProvider.notifier);
      if (notifier.hasMoreReports) {
        notifier.loadMoreReports();
      }
    }
  }

  Future<void> _refreshData() async {
    final notifier = ref.read(weeklyReportProvider.notifier);

    if (kDebugMode && DebugDataHelper.isDebugMode) {
      // 디버깅 모드에서는 가짜 데이터 새로고침
      await notifier.loadDebugReports();
    } else {
      // 실제 데이터 새로고침
      await notifier.refresh();
    }

    // Fetch visualization data for current report
    await _fetchVisualizationData();

    // Trigger fade animation when data is loaded
    if (mounted) {
      _fadeController.forward();
    }
  }

  /// Fetch visualization data for the current report
  Future<void> _fetchVisualizationData() async {
    final state = ref.read(weeklyReportProvider);
    if (state.currentReport == null) return;

    try {
      final visualizationService = ref.read(visualizationDataServiceProvider);

      // Process current report data
      final visualizationData = await visualizationService.processWeeklyData(state.currentReport!);

      // Calculate category trends with historical data
      final categoryTrends = await visualizationService.calculateCategoryTrends(
        state.currentReport!,
        state.reports.where((r) => r.id != state.currentReport!.id).toList(),
      );

      if (mounted) {
        setState(() {
          _visualizationData = visualizationData;
          _categoryTrends = categoryTrends;
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weeklyReportProvider);

    return FScaffold(
      backgroundColor: SPColors.backgroundColor(context),
      appBar: FAppBar.back(
        context,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutePath.myFeed.relativePath);
          }
        },
        title: AppStrings.weeklyReport,
        actions: kDebugMode ? [_buildDebugMenu()] : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: SPColors.podGreen,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Notification permission banner
            SliverToBoxAdapter(child: NotificationPermissionBanner()),

            // Current week report section with animation
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder:
                    (context, child) =>
                        FadeTransition(opacity: _fadeAnimation, child: _buildCurrentReportSection(state)),
              ),
            ),

            // Historical reports section
            const SliverToBoxAdapter(child: HistoricalReportsSection()),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentReportSection(WeeklyReportState state) {
    // Determine loading state type
    LoadingStateType loadingStateType = LoadingStateType.initial;

    if (state.hasTimedOut) {
      loadingStateType = LoadingStateType.timeout;
    } else if (state.error != null) {
      loadingStateType = LoadingStateType.error;
    } else if (state.isGenerating) {
      loadingStateType = LoadingStateType.generating;
    } else if (state.isProcessing) {
      loadingStateType = LoadingStateType.processing;
    } else if (state.isRefreshing) {
      loadingStateType = LoadingStateType.refreshing;
    } else if (state.isLoading && state.currentReport == null) {
      loadingStateType = LoadingStateType.loading;
    } else if (state.currentReport != null) {
      loadingStateType = LoadingStateType.success;
    }

    // Configure loading state
    final config = LoadingStateConfig(
      showSkeleton: state.isLoading && state.currentReport == null,
      showProgress: state.isGenerating || state.isProcessing,
      showSteps: state.isProcessing,
      timeout: const Duration(minutes: 3),
      enableTimeout: true,
      showCancelButton: state.isGenerating || state.isProcessing,
      customMessage: _getLoadingMessage(state),
      progressSteps: state.progressSteps,
    );

    return LoadingStateManager(
      state: loadingStateType,
      config: config,
      progress: state.progress,
      currentStep: state.currentStep,
      errorMessage: state.error,
      onTimeout: () => ref.read(weeklyReportProvider.notifier).handleTimeout(),
      onCancel: () => ref.read(weeklyReportProvider.notifier).cancelOperations(),
      onRetry: () => _handleRetry(state),
      child: state.currentReport != null ? _buildReportContent(state.currentReport!) : _buildEmptyState(),
    );
  }

  String _getLoadingMessage(WeeklyReportState state) {
    if (state.isGenerating) {
      return AppStrings.generatingReport;
    } else if (state.isProcessing) {
      return AppStrings.processingData;
    } else if (state.isRefreshing) {
      return AppStrings.refreshingData;
    } else if (state.isLoading) {
      return AppStrings.loadingContent;
    }
    return AppStrings.reportGenerating;
  }

  void _handleRetry(WeeklyReportState state) {
    final notifier = ref.read(weeklyReportProvider.notifier);

    if (state.hasTimedOut) {
      notifier.resetTimeoutAndRetry();
    }

    if (state.lastException != null && notifier.canRetry) {
      notifier.retryLastOperation();
    } else {
      notifier.fetchCurrentReport();
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text(
            AppStrings.noReportYet,
            style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.needMoreCertifications,
            style: FTextStyles.body1_16.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.keepItUp,
            style: FTextStyles.body1_16.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(WeeklyReport report) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          _buildReportHeader(report),
          const SizedBox(height: 16),

          // Report summary card
          ReportSummaryCard(report: report, historicalReports: ref.read(weeklyReportProvider).reports),
          const SizedBox(height: 16),

          // Weekly achievements section (hidden in release mode - incomplete)
          if (kDebugMode) ...[
            const WeeklyAchievementsSection(showCelebration: true, showProgress: true),
            const SizedBox(height: 16),
          ],

          // Category navigation and filtering
          _buildCategoryNavigationBar(context),
          const SizedBox(height: 16),

          // Enhanced category visualizations section
          _buildCategoryVisualizationsSection(context, report),
          const SizedBox(height: 16),

          // Category comparison section
          if (_showCategoryComparison && ref.read(weeklyReportProvider).reports.length > 1) ...[
            _buildCategoryComparisonSection(context, report),
            const SizedBox(height: 16),
          ],

          // Exercise analysis section with enhanced category features
          if (_selectedCategoryFilter == null || _selectedCategoryFilter == CategoryType.exercise) ...[
            ExerciseAnalysisSection(
              analysis: report.analysis,
              stats: report.stats,
              categoryTrends: _categoryTrends,
              exerciseCategoryData: _visualizationData?.exerciseCategoryData,
              historicalReports: ref.read(weeklyReportProvider).reports,
            ),
            const SizedBox(height: 16),
          ],

          // Diet analysis section with enhanced category features
          if (_selectedCategoryFilter == null || _selectedCategoryFilter == CategoryType.diet) ...[
            DietAnalysisSection(
              analysis: report.analysis,
              stats: report.stats,
              categoryTrends: _categoryTrends,
              dietCategoryData: _visualizationData?.dietCategoryData,
              historicalReports: ref.read(weeklyReportProvider).reports,
            ),
            const SizedBox(height: 16),
          ],

          // Category insights section
          if (_showCategoryInsights && _visualizationData?.hasSufficientData == true) ...[
            CategoryInsightsSection(
              exerciseCategories: _visualizationData?.exerciseCategoryData ?? [],
              dietCategories: _visualizationData?.dietCategoryData ?? [],
              trendData: _categoryTrends,
              historicalReports: ref.read(weeklyReportProvider).reports,
              onInsightTap: () => _showCategoryOnboarding(context),
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations section
          RecommendationsSection(recommendations: report.recommendations),
        ],
      ),
    );
  }

  Widget _buildReportHeader(WeeklyReport report) {
    final dateFormat = DateFormat('M월 d일', 'ko_KR');
    final weekRange = '${dateFormat.format(report.weekStartDate)} - ${dateFormat.format(report.weekEndDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.thisWeekReport,
          style: FTextStyles.title2_20.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(weekRange, style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
        if (report.status == ReportStatus.generating) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(SPColors.podGreen),
                ),
              ),
              const SizedBox(width: 8),
              Text(AppStrings.reportGenerating, style: FTextStyles.body2_14.copyWith(color: SPColors.podGreen)),
            ],
          ),
        ],
      ],
    );
  }

  /// 디버깅 모드에서만 표시되는 메뉴 버튼
  Widget _buildDebugMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.bug_report, color: SPColors.podOrange),
      tooltip: 'Debug Menu',
      onSelected: (value) async {
        final notifier = ref.read(weeklyReportProvider.notifier);

        switch (value) {
          case 'settings':
            showDebugSettingsDialog(context);
            break;
          case 'load_current':
            await notifier.loadDebugCurrentWeekReport();
            break;
          case 'load_history':
            await notifier.loadDebugReports();
            break;
          case 'generate':
            await notifier.generateDebugReport();
            break;
          case 'clear':
            await _clearDebugData();
            break;
          case 'showcase':
            _showAnimationShowcase();
            break;
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('디버그 설정')]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'load_current',
              child: Row(children: [Icon(Icons.today, size: 20), SizedBox(width: 8), Text('현재 주 리포트')]),
            ),
            const PopupMenuItem(
              value: 'load_history',
              child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 8), Text('히스토리 리포트')]),
            ),
            const PopupMenuItem(
              value: 'generate',
              child: Row(children: [Icon(Icons.auto_awesome, size: 20), SizedBox(width: 8), Text('새 리포트 생성')]),
            ),
            const PopupMenuItem(
              value: 'showcase',
              child: Row(children: [Icon(Icons.animation, size: 20), SizedBox(width: 8), Text('애니메이션 쇼케이스')]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('데이터 초기화', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
    );
  }

  /// 디버깅 데이터 초기화
  Future<void> _clearDebugData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('데이터 초기화'),
            content: const Text('디버깅 데이터를 모두 초기화하시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('초기화'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // 상태 초기화 (실제 구현에서는 notifier에 clear 메서드 추가 필요)
      ref.invalidate(weeklyReportProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('디버깅 데이터가 초기화되었습니다.'), backgroundColor: SPColors.podGreen));
      }
    }
  }

  /// 애니메이션 쇼케이스 표시
  void _showAnimationShowcase() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnimationShowcase()));
  }

  /// Build category navigation bar for filtering
  Widget _buildCategoryNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: SPColors.podBlue),
              const SizedBox(width: 8),
              Text(
                '카테고리 필터',
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Toggle buttons for insights and comparison
              Row(
                children: [
                  _buildToggleButton(
                    context,
                    '인사이트',
                    _showCategoryInsights,
                    (value) => setState(() => _showCategoryInsights = value),
                  ),
                  const SizedBox(width: 8),
                  _buildToggleButton(
                    context,
                    '비교',
                    _showCategoryComparison,
                    (value) => setState(() => _showCategoryComparison = value),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category filter chips
          Wrap(
            spacing: 8,
            children: [
              _buildCategoryFilterChip(context, null, '전체'),
              _buildCategoryFilterChip(context, CategoryType.exercise, '운동'),
              _buildCategoryFilterChip(context, CategoryType.diet, '식단'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build toggle button for navigation options
  Widget _buildToggleButton(BuildContext context, String label, bool isSelected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? SPColors.podBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? SPColors.podBlue : SPColors.gray300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 14,
              color: isSelected ? SPColors.podBlue : SPColors.gray600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: FTextStyles.caption_12.copyWith(
                color: isSelected ? SPColors.podBlue : SPColors.gray600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category filter chip
  Widget _buildCategoryFilterChip(BuildContext context, CategoryType? type, String label) {
    final isSelected = _selectedCategoryFilter == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryFilter = isSelected ? null : type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SPColors.podGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? SPColors.podGreen : SPColors.gray300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type != null) ...[
              Icon(type.icon, size: 14, color: isSelected ? Colors.white : SPColors.gray600),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: FTextStyles.body2_14.copyWith(
                color: isSelected ? Colors.white : SPColors.gray600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build enhanced category visualizations section
  Widget _buildCategoryVisualizationsSection(BuildContext context, WeeklyReport report) {
    if (_visualizationData?.hasSufficientData != true) {
      return _buildEmptyCategoryVisualizationState(context);
    }

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
                    color: SPColors.podBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.analytics, size: 20, color: SPColors.podBlue),
                ),
                const SizedBox(width: 12),
                Text(
                  '카테고리 분석',
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '총 ${_visualizationData!.totalCategoriesCount}개 카테고리',
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category distribution charts
            if (_selectedCategoryFilter == null || _selectedCategoryFilter == CategoryType.exercise) ...[
              if (_visualizationData!.exerciseCategoryData.isNotEmpty) ...[
                _buildCategoryDistributionCard(
                  context,
                  '운동 카테고리 분포',
                  _visualizationData!.exerciseCategoryData,
                  CategoryType.exercise,
                ),
                const SizedBox(height: 16),
              ],
            ],

            if (_selectedCategoryFilter == null || _selectedCategoryFilter == CategoryType.diet) ...[
              if (_visualizationData!.dietCategoryData.isNotEmpty) ...[
                _buildCategoryDistributionCard(
                  context,
                  '식단 카테고리 분포',
                  _visualizationData!.dietCategoryData,
                  CategoryType.diet,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Build category distribution card
  Widget _buildCategoryDistributionCard(
    BuildContext context,
    String title,
    List<CategoryVisualizationData> categoryData,
    CategoryType type,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            type == CategoryType.exercise
                ? SPColors.podGreen.withValues(alpha: 0.05)
                : SPColors.podOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              type == CategoryType.exercise
                  ? SPColors.podGreen.withValues(alpha: 0.1)
                  : SPColors.podOrange.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, size: 16, color: type == CategoryType.exercise ? SPColors.podGreen : SPColors.podOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CategoryDistributionChart(
              categoryData: categoryData,
              type: type,
              showLegend: true,
              enableInteraction: true,
              onCategoryTap: (category) => _showCategoryDetail(context, category),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty category visualization state
  Widget _buildEmptyCategoryVisualizationState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text(
            '카테고리 분석 준비 중',
            style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '더 많은 인증을 추가하면 상세한 카테고리 분석을 볼 수 있어요',
            style: FTextStyles.body1_16.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build category comparison section
  Widget _buildCategoryComparisonSection(BuildContext context, WeeklyReport report) {
    final historicalReports = ref.read(weeklyReportProvider).reports;
    final previousReport = historicalReports.isNotEmpty ? historicalReports.first : null;

    if (previousReport == null) return const SizedBox.shrink();

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
                  child: Icon(Icons.compare_arrows, size: 20, color: SPColors.podOrange),
                ),
                const SizedBox(width: 12),
                Text(
                  '주간 비교',
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category comparison cards
            if (_selectedCategoryFilter == null || _selectedCategoryFilter == CategoryType.exercise) ...[
              CategoryComparisonCard(
                currentWeek: report,
                previousWeek: previousReport,
                categoryType: CategoryType.exercise,
                onTap: () => _showDetailedComparison(context, CategoryType.exercise),
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedCategoryFilter == null || _selectedCategoryFilter == CategoryType.diet) ...[
              CategoryComparisonCard(
                currentWeek: report,
                previousWeek: previousReport,
                categoryType: CategoryType.diet,
                onTap: () => _showDetailedComparison(context, CategoryType.diet),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show category detail modal
  void _showCategoryDetail(BuildContext context, CategoryVisualizationData category) {
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
                if (category.description != null) ...[const SizedBox(height: 8), Text(category.description!)],
                if (_categoryTrends != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('트렌드: '),
                      Icon(
                        _categoryTrends!.getTrendForCategory(category.categoryName, category.type)?.icon ??
                            Icons.trending_flat,
                        size: 16,
                        color:
                            _categoryTrends!.getTrendForCategory(category.categoryName, category.type)?.color ??
                            SPColors.gray600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _categoryTrends!.getTrendForCategory(category.categoryName, category.type)?.displayName ??
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

  /// Show detailed comparison modal
  void _showDetailedComparison(BuildContext context, CategoryType type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${type.displayName} 상세 비교'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${type.displayName} 카테고리의 상세한 주간 비교 분석입니다.'),
                  const SizedBox(height: 16),
                  // Add detailed comparison content here
                  Text('구현 예정: 상세 비교 차트 및 분석'),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인'))],
          ),
    );
  }

  /// Show category-focused user onboarding
  void _showCategoryOnboarding(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('카테고리 기반 건강 관리'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카테고리별로 활동을 분석하여 더 균형잡힌 건강 관리를 도와드려요!',
                    style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context)),
                  ),
                  const SizedBox(height: 16),
                  _buildOnboardingItem(context, '💪', '운동 카테고리', '근력, 유산소, 스트레칭 등 다양한 운동을 균형있게 해보세요'),
                  const SizedBox(height: 12),
                  _buildOnboardingItem(context, '🍽️', '식단 카테고리', '집밥, 건강식, 외식 등 식단의 다양성을 관리해보세요'),
                  const SizedBox(height: 12),
                  _buildOnboardingItem(context, '📈', '트렌드 분석', '주간별 변화를 추적하여 개선점을 찾아보세요'),
                  const SizedBox(height: 12),
                  _buildOnboardingItem(context, '🎯', '맞춤 추천', 'AI가 분석한 개인별 맞춤 건강 관리 팁을 받아보세요'),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('시작하기'))],
          ),
    );
  }

  /// Build onboarding item
  Widget _buildOnboardingItem(BuildContext context, String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(description, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
            ],
          ),
        ),
      ],
    );
  }
}
