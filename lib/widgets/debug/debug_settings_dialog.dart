import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/providers/weekly_report_provider.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/animations/animation_showcase.dart';

/// 디버깅 모드에서만 사용되는 설정 다이얼로그
class DebugSettingsDialog extends ConsumerStatefulWidget {
  const DebugSettingsDialog({super.key});

  @override
  ConsumerState<DebugSettingsDialog> createState() => _DebugSettingsDialogState();
}

class _DebugSettingsDialogState extends ConsumerState<DebugSettingsDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(weeklyReportProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: SPColors.podOrange),
          const SizedBox(width: 8),
          Text('Debug Settings', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 상태 정보
            _buildStatusSection(state),
            const SizedBox(height: 16),

            // 데이터 로딩 섹션
            _buildDataSection(),
            const SizedBox(height: 16),

            // 애니메이션 테스트 섹션
            _buildAnimationSection(),
            const SizedBox(height: 16),

            // 유틸리티 섹션
            _buildUtilitySection(),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기'))],
    );
  }

  Widget _buildStatusSection(WeeklyReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('현재 상태', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusItem('리포트 수', '${state.reports.length}개'),
              _buildStatusItem('현재 리포트', state.currentReport != null ? '있음' : '없음'),
              _buildStatusItem('로딩 중', state.isLoading ? '예' : '아니오'),
              _buildStatusItem('생성 중', state.isGenerating ? '예' : '아니오'),
              if (state.error != null) _buildStatusItem('오류', state.error!, isError: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FTextStyles.body3_13),
          Text(
            value,
            style: FTextStyles.body3_13.copyWith(
              color: isError ? Colors.red : SPColors.gray600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('데이터 관리', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton('현재 주 로드', Icons.today, SPColors.podGreen, () => _loadDebugData('current')),
            _buildActionButton('히스토리 로드', Icons.history, SPColors.podBlue, () => _loadDebugData('history')),
            _buildActionButton('새 리포트 생성', Icons.auto_awesome, SPColors.podPurple, () => _loadDebugData('generate')),
            _buildActionButton('데이터 초기화', Icons.clear_all, Colors.red, () => _clearData()),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('애니메이션 테스트', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton('애니메이션 쇼케이스', Icons.animation, SPColors.podOrange, () => _showAnimationShowcase()),
            _buildActionButton('차트 애니메이션', Icons.bar_chart, SPColors.podMint, () => _testChartAnimations()),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('유틸리티', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton('상태 새로고침', Icons.refresh, SPColors.gray600, () => _refreshState()),
            _buildActionButton('로그 출력', Icons.terminal, SPColors.gray600, () => _printDebugInfo()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: FTextStyles.body3_13),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _loadDebugData(String type) async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(weeklyReportProvider.notifier);

      switch (type) {
        case 'current':
          await notifier.loadDebugCurrentWeekReport();
          break;
        case 'history':
          await notifier.loadDebugReports();
          break;
        case 'generate':
          await notifier.generateDebugReport();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$type 데이터가 로드되었습니다.'), backgroundColor: SPColors.podGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 중 오류: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('데이터 초기화'),
            content: const Text('모든 디버깅 데이터를 초기화하시겠습니까?'),
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
      ref.invalidate(weeklyReportProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('데이터가 초기화되었습니다.'), backgroundColor: SPColors.podGreen));
      }
    }
  }

  void _showAnimationShowcase() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AnimationShowcase()));
  }

  void _testChartAnimations() {
    // 차트 애니메이션 테스트 로직
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('차트 애니메이션 테스트가 시작됩니다.'), backgroundColor: SPColors.podMint));
  }

  void _refreshState() {
    ref.invalidate(weeklyReportProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('상태가 새로고침되었습니다.'), backgroundColor: SPColors.podGreen));
  }

  void _printDebugInfo() {
    final state = ref.read(weeklyReportProvider);
    debugPrint('=== Debug Info ===');
    debugPrint('Reports count: ${state.reports.length}');
    debugPrint('Current report: ${state.currentReport?.id}');
    debugPrint('Is loading: ${state.isLoading}');
    debugPrint('Is generating: ${state.isGenerating}');
    debugPrint('Error: ${state.error}');
    debugPrint('==================');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('디버그 정보가 콘솔에 출력되었습니다.'), backgroundColor: SPColors.gray600));
  }
}

/// 디버깅 설정 다이얼로그를 표시하는 헬퍼 함수
void showDebugSettingsDialog(BuildContext context) {
  if (!kDebugMode) return;

  showDialog(context: context, builder: (context) => const DebugSettingsDialog());
}
