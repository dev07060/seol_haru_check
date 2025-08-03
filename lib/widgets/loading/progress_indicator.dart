import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Enhanced progress indicator with timeout handling and progress updates
class EnhancedProgressIndicator extends StatefulWidget {
  const EnhancedProgressIndicator({
    super.key,
    required this.message,
    this.progress,
    this.showProgress = false,
    this.timeout = const Duration(minutes: 2),
    this.onTimeout,
    this.onCancel,
    this.showCancelButton = false,
    this.progressSteps,
    this.currentStep = 0,
  });

  final String message;
  final double? progress;
  final bool showProgress;
  final Duration timeout;
  final VoidCallback? onTimeout;
  final VoidCallback? onCancel;
  final bool showCancelButton;
  final List<String>? progressSteps;
  final int currentStep;

  @override
  State<EnhancedProgressIndicator> createState() => _EnhancedProgressIndicatorState();
}

class _EnhancedProgressIndicatorState extends State<EnhancedProgressIndicator> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timeoutTimer;
  Timer? _progressTimer;

  double _currentProgress = 0.0;
  int _currentStepIndex = 0;
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _fadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();

    _startTimeoutTimer();
    _startProgressSimulation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _timeoutTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted && !_isTimedOut) {
        setState(() {
          _isTimedOut = true;
        });
        widget.onTimeout?.call();
      }
    });
  }

  void _startProgressSimulation() {
    if (!widget.showProgress && widget.progressSteps == null) return;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (widget.progressSteps != null) {
          // Step-based progress
          if (_currentStepIndex < widget.progressSteps!.length - 1) {
            _currentStepIndex++;
          }
        } else {
          // Continuous progress simulation
          if (_currentProgress < 0.9) {
            _currentProgress += 0.05;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isTimedOut) ...[_buildTimeoutContent()] else ...[_buildProgressContent()],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated progress indicator
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: SPColors.podGreen.withValues(alpha: 0.1)),
                child:
                    widget.showProgress && widget.progress != null
                        ? CircularProgressIndicator(
                          value: widget.progress,
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(SPColors.podGreen),
                          backgroundColor: SPColors.gray200,
                        )
                        : const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(SPColors.podGreen),
                        ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Progress message
        Text(
          widget.message,
          style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Progress steps or percentage
        if (widget.progressSteps != null) ...[
          _buildStepProgress(),
        ] else if (widget.showProgress) ...[
          _buildPercentageProgress(),
        ],

        const SizedBox(height: 16),

        // Estimated time remaining
        Text(
          _getEstimatedTimeText(),
          style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
          textAlign: TextAlign.center,
        ),

        if (widget.showCancelButton) ...[
          const SizedBox(height: 20),
          TextButton(
            onPressed: widget.onCancel,
            child: Text(AppStrings.cancel, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
          ),
        ],
      ],
    );
  }

  Widget _buildStepProgress() {
    final steps = widget.progressSteps!;
    final currentIndex = widget.currentStep.clamp(0, steps.length - 1);

    return Column(
      children: [
        // Step indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(steps.length, (index) {
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent ? SPColors.podGreen : SPColors.gray300,
                  ),
                ),
                if (index < steps.length - 1) ...[
                  Container(width: 20, height: 2, color: isCompleted ? SPColors.podGreen : SPColors.gray300),
                ],
              ],
            );
          }),
        ),

        const SizedBox(height: 12),

        // Current step text
        Text(
          steps[currentIndex],
          style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
          textAlign: TextAlign.center,
        ),

        // Step counter
        Text('${currentIndex + 1} / ${steps.length}', style: FTextStyles.caption_12.copyWith(color: SPColors.gray500)),
      ],
    );
  }

  Widget _buildPercentageProgress() {
    final progress = widget.progress ?? _currentProgress;
    final percentage = (progress * 100).round();

    return Column(
      children: [
        // Progress bar
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: SPColors.gray200),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: SPColors.podGreen),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Percentage text
        Text(
          '$percentage%',
          style: FTextStyles.body2_14.copyWith(color: SPColors.gray700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTimeoutContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 48, color: SPColors.danger100),

        const SizedBox(height: 16),

        Text(
          AppStrings.timeoutError,
          style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          AppStrings.tryAgainLater,
          style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: widget.onCancel,
              child: Text(AppStrings.cancel, style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
            ),

            const SizedBox(width: 16),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isTimedOut = false;
                  _currentProgress = 0.0;
                  _currentStepIndex = 0;
                });
                _startTimeoutTimer();
                _startProgressSimulation();
              },
              style: ElevatedButton.styleFrom(backgroundColor: SPColors.podGreen, foregroundColor: SPColors.white),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      ],
    );
  }

  String _getEstimatedTimeText() {
    if (_isTimedOut) return '';

    final elapsed = DateTime.now().millisecondsSinceEpoch;
    final remaining = widget.timeout.inSeconds - (elapsed ~/ 1000);

    if (remaining <= 0) return '';

    if (remaining > 60) {
      final minutes = remaining ~/ 60;
      return '예상 시간: $minutes분 이내';
    } else {
      return '예상 시간: $remaining초 이내';
    }
  }
}

/// Simple loading indicator with timeout
class TimeoutAwareLoading extends StatefulWidget {
  const TimeoutAwareLoading({
    super.key,
    required this.message,
    this.timeout = const Duration(minutes: 2),
    this.onTimeout,
  });

  final String message;
  final Duration timeout;
  final VoidCallback? onTimeout;

  @override
  State<TimeoutAwareLoading> createState() => _TimeoutAwareLoadingState();
}

class _TimeoutAwareLoadingState extends State<TimeoutAwareLoading> {
  Timer? _timeoutTimer;
  bool _isTimedOut = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted) {
        setState(() {
          _isTimedOut = true;
        });
        widget.onTimeout?.call();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isTimedOut) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 48, color: SPColors.danger100),
          const SizedBox(height: 16),
          Text(
            AppStrings.timeoutError,
            style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(SPColors.podGreen)),
        const SizedBox(height: 16),
        Text(
          widget.message,
          style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
