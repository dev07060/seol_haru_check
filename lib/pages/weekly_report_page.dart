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
import 'package:seol_haru_check/widgets/report/exercise_analysis_section.dart';
import 'package:seol_haru_check/widgets/report/historical_reports_section.dart';
import 'package:seol_haru_check/widgets/report/recommendations_section.dart';
import 'package:seol_haru_check/widgets/report/report_summary_card.dart';

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

          // Exercise analysis section (hidden in release mode - incomplete)
          if (kDebugMode) ...[
            ExerciseAnalysisSection(
              analysis: report.analysis,
              stats: report.stats,
              categoryTrends: _categoryTrends,
              exerciseCategoryData: _visualizationData?.exerciseCategoryData,
              historicalReports: ref.read(weeklyReportProvider).reports,
            ),
            const SizedBox(height: 16),
          ],

          // Diet analysis section
          // TODO: This section is unavailable due to insufficient data collection methods.
          // DietAnalysisSection(
          //   analysis: report.analysis,
          //   stats: report.stats,
          //   categoryTrends: _categoryTrends,
          //   dietCategoryData: _visualizationData?.dietCategoryData,
          //   historicalReports: ref.read(weeklyReportProvider).reports,
          // ),
          // const SizedBox(height: 16),

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
}
