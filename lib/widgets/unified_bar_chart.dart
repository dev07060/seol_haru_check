import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Unified bar chart widget that displays exercise and diet categories in a single horizontal bar
class UnifiedBarChart extends StatefulWidget {
  /// Exercise category data
  final List<CategoryVisualizationData> exerciseData;

  /// Diet category data
  final List<CategoryVisualizationData> dietData;

  /// Height of the bar chart
  final double height;

  /// Whether to show legend
  final bool showLegend;

  /// Whether to enable user interaction
  final bool enableInteraction;

  /// Callback when a category is tapped
  final Function(CategoryVisualizationData)? onCategoryTap;

  /// Animation configuration
  final AnimationConfig? animationConfig;

  /// Minimum segment width percentage for small categories
  final double minSegmentWidth;

  /// Whether to sort categories by count
  final bool sortByCount;

  /// Custom padding around the chart
  final EdgeInsets? padding;

  /// Border radius for the bar
  final double borderRadius;

  const UnifiedBarChart({
    super.key,
    required this.exerciseData,
    required this.dietData,
    this.height = 60.0,
    this.showLegend = true,
    this.enableInteraction = true,
    this.onCategoryTap,
    this.animationConfig,
    this.minSegmentWidth = 5.0,
    this.sortByCount = true,
    this.padding,
    this.borderRadius = 8.0,
  });

  @override
  State<UnifiedBarChart> createState() => _UnifiedBarChartState();
}

class _UnifiedBarChartState extends State<UnifiedBarChart> with TickerProviderStateMixin {
  /// Animation controller for entry animation
  late AnimationController _animationController;

  /// Animation for bar filling effect
  late Animation<double> _fillAnimation;

  /// Currently highlighted segment (for hover/touch effects)
  BarSegmentData? _highlightedSegment;

  /// Currently tapped segment (for touch feedback)
  BarSegmentData? _tappedSegment;

  /// Unified bar data calculated from input
  late UnifiedBarData _barData;

  /// Animation configuration
  late AnimationConfig _animationConfig;

  /// Animation controller for highlight effects
  late AnimationController _highlightAnimationController;

  /// Animation for highlight scaling effect
  late Animation<double> _highlightScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimationConfig();
    _initializeAnimations();
    _calculateBarData();
  }

  @override
  void didUpdateWidget(UnifiedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recalculate data if input changed
    if (oldWidget.exerciseData != widget.exerciseData ||
        oldWidget.dietData != widget.dietData ||
        oldWidget.minSegmentWidth != widget.minSegmentWidth ||
        oldWidget.sortByCount != widget.sortByCount) {
      _calculateBarData();

      // Restart animation if data changed
      _animationController.reset();
      _animationController.forward();
    }

    // Update animation config if changed
    if (oldWidget.animationConfig != widget.animationConfig) {
      _initializeAnimationConfig();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _highlightAnimationController.dispose();
    super.dispose();
  }

  /// Initialize animation configuration
  void _initializeAnimationConfig() {
    _animationConfig = widget.animationConfig ?? const AnimationConfig();
  }

  /// Initialize animations
  void _initializeAnimations() {
    _animationController = AnimationController(duration: _animationConfig.duration, vsync: this);

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: _animationConfig.curve));

    // Initialize highlight animation controller
    _highlightAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _highlightScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _highlightAnimationController, curve: Curves.easeInOut));

    // Start entry animation
    _animationController.forward();
  }

  /// Calculate unified bar data from input
  void _calculateBarData() {
    _barData = UnifiedBarData(exerciseCategories: widget.exerciseData, dietCategories: widget.dietData);
  }

  /// Handle tap on a segment
  void _handleSegmentTap(BarSegmentData segment) {
    if (!widget.enableInteraction) return;

    // Provide haptic feedback for better user experience
    HapticFeedback.lightImpact();

    setState(() {
      _tappedSegment = segment;
      _highlightedSegment = segment;
    });

    // Start highlight animation
    _highlightAnimationController.forward().then((_) {
      _highlightAnimationController.reverse();
    });

    // Call callback if provided
    widget.onCategoryTap?.call(segment.category);

    // Clear tap state after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _tappedSegment = null;
          // Keep highlight if still hovering
          if (_highlightedSegment == segment) {
            // Check if mouse is still over the segment
            // This will be handled by the hover detection
          }
        });
      }
    });
  }

  /// Handle hover over a segment
  void _handleSegmentHover(BarSegmentData? segment) {
    if (!widget.enableInteraction) return;

    // Only update if different from current highlight (avoid unnecessary rebuilds)
    if (_highlightedSegment != segment) {
      setState(() {
        _highlightedSegment = segment;
      });

      // Start subtle hover animation if segment is hovered
      if (segment != null && _tappedSegment == null) {
        _highlightAnimationController.animateTo(0.5);
      } else if (segment == null) {
        _highlightAnimationController.reverse();
      }
    }
  }

  /// Check if chart has data to display
  bool get _hasData => _barData.hasData;

  /// Get effective height including padding
  double get _effectiveHeight {
    final padding = widget.padding ?? EdgeInsets.zero;
    return widget.height - padding.vertical;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main bar chart
          Expanded(child: _buildBarChart()),

          // Legend (if enabled)
          if (widget.showLegend && _hasData) ...[const SizedBox(height: 12), _buildLegend()],
        ],
      ),
    );
  }

  /// Build the main bar chart
  Widget _buildBarChart() {
    if (!_hasData) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, child) {
        return Container(
          height: _effectiveHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(widget.borderRadius), child: _buildSegments()),
        );
      },
    );
  }

  /// Build individual segments using CustomPainter
  Widget _buildSegments() {
    return GestureDetector(
      onTapDown: (details) => _handleTapDown(details),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapCancel(),
      child: MouseRegion(
        cursor: widget.enableInteraction ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onHover: (event) => _handleHover(event),
        onExit: (_) => _handleSegmentHover(null),
        child: AnimatedBuilder(
          animation: _highlightScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _highlightedSegment != null ? _highlightScaleAnimation.value : 1.0,
              child: CustomPaint(
                painter: BarChartPainter(
                  segments: _barData.segments,
                  highlightedSegment: _highlightedSegment,
                  tappedSegment: _tappedSegment,
                  animationProgress: _fillAnimation.value,
                  borderRadius: widget.borderRadius,
                  highlightIntensity: _highlightScaleAnimation.value - 1.0,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handle tap down to detect which segment was tapped
  void _handleTapDown(TapDownDetails details) {
    if (!widget.enableInteraction) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final relativePosition = localPosition.dx / renderBox.size.width * 100;

    // Find segment at tap position
    for (final segment in _barData.segments) {
      if (segment.containsPosition(relativePosition)) {
        _handleSegmentTap(segment);
        break;
      }
    }
  }

  /// Handle hover to detect which segment is being hovered
  void _handleHover(PointerHoverEvent event) {
    if (!widget.enableInteraction) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = event.localPosition;
    final relativePosition = localPosition.dx / renderBox.size.width * 100;

    // Find segment at hover position
    BarSegmentData? hoveredSegment;
    for (final segment in _barData.segments) {
      if (segment.containsPosition(relativePosition)) {
        hoveredSegment = segment;
        break;
      }
    }

    _handleSegmentHover(hoveredSegment);
  }

  /// Handle tap up event
  void _handleTapUp() {
    if (!widget.enableInteraction) return;

    // Reset tap state
    setState(() {
      _tappedSegment = null;
    });
  }

  /// Handle tap cancel event
  void _handleTapCancel() {
    if (!widget.enableInteraction) return;

    // Reset tap state and animation
    setState(() {
      _tappedSegment = null;
    });
    _highlightAnimationController.reverse();
  }

  /// Build legend
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Exercise legend
        if (_barData.hasExerciseData) ...[
          _buildLegendItem(
            icon: Icons.fitness_center,
            label: '운동',
            color: SPColors.reportGreen, // Use enhanced exercise color
            count: _barData.exerciseTotalCount,
            percentage: _barData.exercisePercentage,
          ),
          const SizedBox(width: 16),
        ],

        // Diet legend
        if (_barData.hasDietData)
          _buildLegendItem(
            icon: Icons.restaurant,
            label: '식단',
            color: SPColors.dietGreen, // Use enhanced diet color
            count: _barData.dietTotalCount,
            percentage: _barData.dietPercentage,
          ),
      ],
    );
  }

  /// Build individual legend item
  Widget _buildLegendItem({
    required IconData icon,
    required String label,
    required Color color,
    required int count,
    required double percentage,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label $count개 (${percentage.toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Build empty state when no data is available
  Widget _buildEmptyState() {
    return Container(
      height: _effectiveHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3), width: 1),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 24, color: Theme.of(context).disabledColor),
            const SizedBox(height: 8),
            Text(
              '표시할 데이터가 없습니다',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).disabledColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for rendering the unified bar chart
class BarChartPainter extends CustomPainter {
  final List<BarSegmentData> segments;
  final BarSegmentData? highlightedSegment;
  final BarSegmentData? tappedSegment;
  final double animationProgress;
  final double borderRadius;
  final double highlightIntensity;

  const BarChartPainter({
    required this.segments,
    this.highlightedSegment,
    this.tappedSegment,
    required this.animationProgress,
    this.borderRadius = 8.0,
    this.highlightIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 0.5;

    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = 0.5;

    // Calculate total animated width
    double totalAnimatedWidth = 0;
    for (final segment in segments) {
      totalAnimatedWidth += segment.effectiveWidth * animationProgress;
    }

    if (totalAnimatedWidth == 0) return;

    // Draw segments
    double currentX = 0;
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isHighlighted = highlightedSegment == segment;
      final isTapped = tappedSegment == segment;
      final animatedWidth = segment.effectiveWidth * animationProgress;
      final segmentWidth = (animatedWidth / totalAnimatedWidth) * size.width;

      if (segmentWidth <= 0) continue;

      // Set segment color with enhanced visual feedback
      final backgroundColor = Colors.white; // Assuming white background for contrast calculation
      final baseColor = segment.getAccessibleColor(backgroundColor);

      Color segmentColor;
      if (isTapped) {
        // Tapped state: use darker color with enhanced intensity
        segmentColor = segment.darkerColor;
      } else if (isHighlighted) {
        // Highlighted state: blend between base and darker color based on highlight intensity
        segmentColor = Color.lerp(baseColor, segment.darkerColor, 0.3 + (highlightIntensity * 0.4)) ?? baseColor;
      } else {
        // Normal state: use base accessible color
        segmentColor = baseColor;
      }

      paint.color = segmentColor;

      // Create segment rectangle
      final segmentRect = Rect.fromLTWH(currentX, 0, segmentWidth, size.height);

      // Draw segment with rounded corners for first and last segments
      if (i == 0 && i == segments.length - 1) {
        // Single segment - round all corners
        final rrect = RRect.fromRectAndRadius(segmentRect, Radius.circular(borderRadius));
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, borderPaint);
      } else if (i == 0) {
        // First segment - round left corners
        final rrect = RRect.fromRectAndCorners(
          segmentRect,
          topLeft: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
        );
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, borderPaint);
      } else if (i == segments.length - 1) {
        // Last segment - round right corners
        final rrect = RRect.fromRectAndCorners(
          segmentRect,
          topRight: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        );
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, borderPaint);
      } else {
        // Middle segments - no rounded corners
        canvas.drawRect(segmentRect, paint);
        canvas.drawRect(segmentRect, borderPaint);
      }

      // Draw segment dividers (vertical lines between segments)
      if (i < segments.length - 1) {
        final dividerPaint =
            Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.white
              ..strokeWidth = isHighlighted || isTapped ? 2.0 : 1.0; // Thicker divider for highlighted segments

        canvas.drawLine(Offset(currentX + segmentWidth, 0), Offset(currentX + segmentWidth, size.height), dividerPaint);
      }

      // Draw highlight border for enhanced visual feedback
      if (isHighlighted || isTapped) {
        final highlightBorderPaint =
            Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.white.withValues(alpha: 0.8)
              ..strokeWidth = isTapped ? 3.0 : 2.0;

        // Create highlight rectangle
        final highlightRect = Rect.fromLTWH(currentX, 0, segmentWidth, size.height);

        if (i == 0 && i == segments.length - 1) {
          // Single segment - round all corners
          final rrect = RRect.fromRectAndRadius(highlightRect, Radius.circular(borderRadius));
          canvas.drawRRect(rrect, highlightBorderPaint);
        } else if (i == 0) {
          // First segment - round left corners
          final rrect = RRect.fromRectAndCorners(
            highlightRect,
            topLeft: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
          );
          canvas.drawRRect(rrect, highlightBorderPaint);
        } else if (i == segments.length - 1) {
          // Last segment - round right corners
          final rrect = RRect.fromRectAndCorners(
            highlightRect,
            topRight: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          );
          canvas.drawRRect(rrect, highlightBorderPaint);
        } else {
          // Middle segments - no rounded corners
          canvas.drawRect(highlightRect, highlightBorderPaint);
        }
      }

      // Draw segment content (emoji and percentage) if segment is wide enough
      if (segmentWidth >= 20) {
        _drawSegmentContent(canvas, segment, segmentRect, isHighlighted || isTapped);
      }

      currentX += segmentWidth;
    }
  }

  /// Draw content inside a segment (emoji and percentage)
  void _drawSegmentContent(Canvas canvas, BarSegmentData segment, Rect segmentRect, bool isHighlighted) {
    final centerX = segmentRect.center.dx;
    final centerY = segmentRect.center.dy;

    // Determine text color for accessibility (ensure 4.5:1 contrast ratio)
    final segmentColor = segment.color;
    final textColor = _getAccessibleTextColor(segmentColor);

    // Draw emoji if segment is wide enough
    if (segmentRect.width >= 25) {
      final emojiStyle = TextStyle(fontSize: segmentRect.width >= 40 ? 16 : 12, color: textColor);

      final emojiPainter = TextPainter(
        text: TextSpan(text: segment.emoji, style: emojiStyle),
        textDirection: TextDirection.ltr,
      );

      emojiPainter.layout();

      // Position emoji in upper part of segment
      final emojiOffset = Offset(
        centerX - emojiPainter.width / 2,
        centerY - emojiPainter.height / 2 - (segmentRect.height * 0.15),
      );

      emojiPainter.paint(canvas, emojiOffset);
    }

    // Draw percentage if segment is wide enough
    if (segmentRect.width >= 35) {
      final percentageStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor);

      final percentagePainter = TextPainter(
        text: TextSpan(text: segment.formattedPercentage, style: percentageStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      percentagePainter.layout();

      // Position percentage in lower part of segment
      final percentageOffset = Offset(
        centerX - percentagePainter.width / 2,
        centerY - percentagePainter.height / 2 + (segmentRect.height * 0.15),
      );

      percentagePainter.paint(canvas, percentageOffset);
    }
  }

  /// Get accessible text color that meets 4.5:1 contrast ratio
  Color _getAccessibleTextColor(Color backgroundColor) {
    // Test white text contrast
    final whiteContrast = _calculateContrastRatio(Colors.white, backgroundColor);

    // Test black text contrast
    final blackContrast = _calculateContrastRatio(Colors.black, backgroundColor);

    // Return the color with better contrast, preferring white for dark backgrounds
    if (whiteContrast >= 4.5) {
      return Colors.white;
    } else if (blackContrast >= 4.5) {
      return Colors.black;
    } else {
      // If neither meets the standard, use the one with better contrast
      return whiteContrast > blackContrast ? Colors.white : Colors.black;
    }
  }

  /// Calculate contrast ratio between two colors
  double _calculateContrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.highlightedSegment != highlightedSegment ||
        oldDelegate.tappedSegment != tappedSegment ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.highlightIntensity != highlightIntensity;
  }
}
