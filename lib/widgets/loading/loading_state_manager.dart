import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/loading/progress_indicator.dart';
import 'package:seol_haru_check/widgets/loading/skeleton_loading.dart';

/// Enum for different loading states
enum LoadingStateType { initial, loading, loadingMore, refreshing, generating, processing, timeout, error, success }

/// Configuration for loading states
class LoadingStateConfig {
  const LoadingStateConfig({
    this.showSkeleton = false,
    this.showProgress = false,
    this.showSteps = false,
    this.timeout = const Duration(minutes: 2),
    this.enableTimeout = true,
    this.showCancelButton = false,
    this.customMessage,
    this.progressSteps,
  });

  final bool showSkeleton;
  final bool showProgress;
  final bool showSteps;
  final Duration timeout;
  final bool enableTimeout;
  final bool showCancelButton;
  final String? customMessage;
  final List<String>? progressSteps;
}

/// Comprehensive loading state manager for weekly reports
class LoadingStateManager extends StatefulWidget {
  const LoadingStateManager({
    super.key,
    required this.state,
    required this.child,
    this.config = const LoadingStateConfig(),
    this.onTimeout,
    this.onCancel,
    this.onRetry,
    this.progress,
    this.currentStep = 0,
    this.errorMessage,
  });

  final LoadingStateType state;
  final Widget child;
  final LoadingStateConfig config;
  final VoidCallback? onTimeout;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final double? progress;
  final int currentStep;
  final String? errorMessage;

  @override
  State<LoadingStateManager> createState() => _LoadingStateManagerState();
}

class _LoadingStateManagerState extends State<LoadingStateManager> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _startAnimations();
  }

  @override
  void didUpdateWidget(LoadingStateManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildStateWidget());
  }

  Widget _buildStateWidget() {
    switch (widget.state) {
      case LoadingStateType.initial:
        return widget.child;

      case LoadingStateType.loading:
        return _buildLoadingWidget();

      case LoadingStateType.loadingMore:
        return _buildLoadingMoreWidget();

      case LoadingStateType.refreshing:
        return _buildRefreshingWidget();

      case LoadingStateType.generating:
        return _buildGeneratingWidget();

      case LoadingStateType.processing:
        return _buildProcessingWidget();

      case LoadingStateType.timeout:
        return _buildTimeoutWidget();

      case LoadingStateType.error:
        return _buildErrorWidget();

      case LoadingStateType.success:
        return widget.child;
    }
  }

  Widget _buildLoadingWidget() {
    if (widget.config.showSkeleton) {
      return FadeTransition(opacity: _fadeAnimation, child: const WeeklyReportSkeleton());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(SPColors.podGreen)),
                const SizedBox(height: 16),
                Text(
                  widget.config.customMessage ?? AppStrings.reportGenerating,
                  style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreWidget() {
    return Column(
      children: [
        widget.child,
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(SPColors.podGreen),
                ),
              ),
              const SizedBox(width: 12),
              Text(AppStrings.loadingMore, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshingWidget() {
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: SPColors.podGreen.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(SPColors.podGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.syncingData,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingWidget() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: EnhancedProgressIndicator(
            message: widget.config.customMessage ?? AppStrings.reportGenerating,
            progress: widget.progress,
            showProgress: widget.config.showProgress,
            timeout: widget.config.timeout,
            onTimeout: widget.onTimeout,
            onCancel: widget.onCancel,
            showCancelButton: widget.config.showCancelButton,
            progressSteps: widget.config.progressSteps,
            currentStep: widget.currentStep,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingWidget() {
    final steps = widget.config.progressSteps ?? ['사용자 데이터 수집 중...', 'AI 분석 진행 중...', '리포트 생성 중...', '최종 검토 중...'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: EnhancedProgressIndicator(
            message: widget.config.customMessage ?? '주간 분석을 처리하고 있습니다',
            showProgress: widget.config.showSteps,
            timeout: widget.config.timeout,
            onTimeout: widget.onTimeout,
            onCancel: widget.onCancel,
            showCancelButton: widget.config.showCancelButton,
            progressSteps: steps,
            currentStep: widget.currentStep,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeoutWidget() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 64, color: SPColors.danger100),
                const SizedBox(height: 24),
                Text(
                  AppStrings.timeoutError,
                  style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '리포트 생성이 예상보다 오래 걸리고 있습니다.\n잠시 후 다시 시도해주세요.',
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: widget.onCancel,
                      child: Text(AppStrings.cancel, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: widget.onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SPColors.podGreen,
                        foregroundColor: SPColors.white,
                      ),
                      child: Text(AppStrings.retry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: SPColors.danger100),
                const SizedBox(height: 24),
                Text(
                  AppStrings.errorOccurred,
                  style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.errorMessage ?? AppStrings.unexpectedError,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(backgroundColor: SPColors.podGreen, foregroundColor: SPColors.white),
                  child: Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget for inline loading states
class InlineLoadingIndicator extends StatelessWidget {
  const InlineLoadingIndicator({super.key, required this.message, this.size = 16.0, this.color});

  final String message;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color ?? SPColors.podGreen),
          ),
        ),
        const SizedBox(width: 8),
        Text(message, style: FTextStyles.body2_14.copyWith(color: color ?? SPColors.gray600)),
      ],
    );
  }
}

/// Pulse loading animation for buttons
class PulseLoadingButton extends StatefulWidget {
  const PulseLoadingButton({super.key, required this.child, required this.isLoading, this.onPressed});

  final Widget child;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<PulseLoadingButton> createState() => _PulseLoadingButtonState();
}

class _PulseLoadingButtonState extends State<PulseLoadingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseLoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return ElevatedButton(onPressed: widget.onPressed, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(backgroundColor: SPColors.gray300),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(SPColors.white),
                  ),
                ),
                const SizedBox(width: 8),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}
