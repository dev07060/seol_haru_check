import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/loading/loading_state_manager.dart';
import 'package:seol_haru_check/widgets/loading/progress_indicator.dart';
import 'package:seol_haru_check/widgets/loading/skeleton_loading.dart';

/// Demo page to showcase different loading states and progress indicators
class LoadingDemoPage extends StatefulWidget {
  const LoadingDemoPage({super.key});

  @override
  State<LoadingDemoPage> createState() => _LoadingDemoPageState();
}

class _LoadingDemoPageState extends State<LoadingDemoPage> {
  LoadingStateType _currentState = LoadingStateType.initial;
  double _progress = 0.0;
  int _currentStep = 0;

  final List<String> _progressSteps = ['사용자 데이터 수집 중...', 'AI 분석 진행 중...', '리포트 생성 중...', '최종 검토 중...'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading States Demo'),
        backgroundColor: SPColors.podGreen,
        foregroundColor: SPColors.white,
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: SPColors.gray900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading State Controls',
                  style: FTextStyles.title2_20.copyWith(color: SPColors.textColor(context)),
                ),
                const SizedBox(height: 16),

                // State buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      LoadingStateType.values.map((state) {
                        return ElevatedButton(
                          onPressed: () => _changeState(state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentState == state ? SPColors.podGreen : SPColors.gray200,
                            foregroundColor: _currentState == state ? SPColors.white : SPColors.gray700,
                          ),
                          child: Text(_getStateLabel(state)),
                        );
                      }).toList(),
                ),

                const SizedBox(height: 16),

                // Progress controls
                if (_currentState == LoadingStateType.generating) ...[
                  Text(
                    'Progress: ${(_progress * 100).round()}%',
                    style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
                  ),
                  Slider(
                    value: _progress,
                    onChanged: (value) {
                      setState(() {
                        _progress = value;
                      });
                    },
                    activeColor: SPColors.podGreen,
                  ),
                ],

                if (_currentState == LoadingStateType.processing) ...[
                  Text(
                    'Current Step: ${_currentStep + 1} / ${_progressSteps.length}',
                    style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
                  ),
                  Slider(
                    value: _currentStep.toDouble(),
                    min: 0,
                    max: (_progressSteps.length - 1).toDouble(),
                    divisions: _progressSteps.length - 1,
                    onChanged: (value) {
                      setState(() {
                        _currentStep = value.round();
                      });
                    },
                    activeColor: SPColors.podGreen,
                  ),
                ],
              ],
            ),
          ),

          // Demo Content
          Expanded(
            child: LoadingStateManager(
              state: _currentState,
              config: LoadingStateConfig(
                showSkeleton: _currentState == LoadingStateType.loading,
                showProgress: _currentState == LoadingStateType.generating,
                showSteps: _currentState == LoadingStateType.processing,
                timeout: const Duration(seconds: 10),
                enableTimeout: true,
                showCancelButton:
                    _currentState == LoadingStateType.generating || _currentState == LoadingStateType.processing,
                customMessage: _getCustomMessage(),
                progressSteps: _progressSteps,
              ),
              progress: _progress,
              currentStep: _currentStep,
              errorMessage: 'This is a demo error message for testing purposes.',
              onTimeout: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operation timed out!')));
              },
              onCancel: () {
                setState(() {
                  _currentState = LoadingStateType.initial;
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operation cancelled!')));
              },
              onRetry: () {
                setState(() {
                  _currentState = LoadingStateType.loading;
                  _progress = 0.0;
                  _currentStep = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retrying operation...')));
              },
              child: _buildDemoContent(),
            ),
          ),
        ],
      ),
    );
  }

  void _changeState(LoadingStateType state) {
    setState(() {
      _currentState = state;
      if (state == LoadingStateType.generating) {
        _progress = 0.3; // Start with some progress
      } else if (state == LoadingStateType.processing) {
        _currentStep = 1; // Start with second step
      }
    });
  }

  String _getStateLabel(LoadingStateType state) {
    switch (state) {
      case LoadingStateType.initial:
        return 'Initial';
      case LoadingStateType.loading:
        return 'Loading';
      case LoadingStateType.loadingMore:
        return 'Loading More';
      case LoadingStateType.refreshing:
        return 'Refreshing';
      case LoadingStateType.generating:
        return 'Generating';
      case LoadingStateType.processing:
        return 'Processing';
      case LoadingStateType.timeout:
        return 'Timeout';
      case LoadingStateType.error:
        return 'Error';
      case LoadingStateType.success:
        return 'Success';
    }
  }

  String _getCustomMessage() {
    switch (_currentState) {
      case LoadingStateType.generating:
        return AppStrings.generatingReport;
      case LoadingStateType.processing:
        return AppStrings.processingData;
      case LoadingStateType.refreshing:
        return AppStrings.refreshingData;
      case LoadingStateType.loading:
        return AppStrings.loadingContent;
      default:
        return AppStrings.pleaseWait;
    }
  }

  Widget _buildDemoContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Report Demo Content', style: FTextStyles.title2_20.copyWith(color: SPColors.textColor(context))),
          const SizedBox(height: 16),

          // Sample report cards
          _buildSampleCard('Exercise Analysis', Icons.fitness_center),
          const SizedBox(height: 12),
          _buildSampleCard('Diet Analysis', Icons.restaurant),
          const SizedBox(height: 12),
          _buildSampleCard('Recommendations', Icons.lightbulb),

          const SizedBox(height: 24),

          // Sample statistics
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Days', '7')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Exercise Days', '5')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Diet Days', '6')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Consistency', '85%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: SPColors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: SPColors.podGreen, size: 24),
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
                Text(
                  'This is sample content for the $title section.',
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.podGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: FTextStyles.title2_20.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: FTextStyles.caption_12.copyWith(color: SPColors.gray600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Standalone demo widgets for individual testing
class SkeletonDemo extends StatelessWidget {
  const SkeletonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skeleton Loading Demo'),
        backgroundColor: SPColors.podGreen,
        foregroundColor: SPColors.white,
      ),
      body: const Padding(padding: EdgeInsets.all(16), child: WeeklyReportSkeleton()),
    );
  }
}

class ProgressIndicatorDemo extends StatefulWidget {
  const ProgressIndicatorDemo({super.key});

  @override
  State<ProgressIndicatorDemo> createState() => _ProgressIndicatorDemoState();
}

class _ProgressIndicatorDemoState extends State<ProgressIndicatorDemo> {
  bool _showSteps = true;
  int _currentStep = 0;

  final List<String> _steps = ['데이터 수집 중...', 'AI 분석 진행 중...', '리포트 생성 중...', '마무리 중...'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Indicator Demo'),
        backgroundColor: SPColors.podGreen,
        foregroundColor: SPColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Controls
            Row(
              children: [
                Text('Show Steps: '),
                Switch(
                  value: _showSteps,
                  onChanged: (value) {
                    setState(() {
                      _showSteps = value;
                    });
                  },
                  activeColor: SPColors.podGreen,
                ),
              ],
            ),

            if (_showSteps) ...[
              const SizedBox(height: 16),
              Text('Current Step: ${_currentStep + 1} / ${_steps.length}'),
              Slider(
                value: _currentStep.toDouble(),
                min: 0,
                max: (_steps.length - 1).toDouble(),
                divisions: _steps.length - 1,
                onChanged: (value) {
                  setState(() {
                    _currentStep = value.round();
                  });
                },
                activeColor: SPColors.podGreen,
              ),
            ],

            const SizedBox(height: 32),

            // Progress indicator
            Expanded(
              child: Center(
                child: EnhancedProgressIndicator(
                  message: AppStrings.processingData,
                  showProgress: _showSteps,
                  progressSteps: _showSteps ? _steps : null,
                  currentStep: _currentStep,
                  timeout: const Duration(seconds: 30),
                  showCancelButton: true,
                  onTimeout: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo timeout!')));
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
