import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/models/unified_bar_chart_utils.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/widgets/category_tooltip.dart';

/// Overlay widget for displaying tooltips above other content
class TooltipOverlay extends StatelessWidget {
  /// Child widget that the tooltip will appear over
  final Widget child;

  /// Tooltip widget to display
  final Widget? tooltip;

  /// Whether the tooltip is currently visible
  final bool showTooltip;

  const TooltipOverlay({super.key, required this.child, this.tooltip, this.showTooltip = false});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, if (showTooltip && tooltip != null) tooltip!]);
  }
}

/// Helper class for managing tooltip state and animations
class TooltipManager {
  /// Animation controller for tooltip animations
  AnimationController? _animationController;

  /// Current tooltip data
  BarSegmentData? _currentSegment;

  /// Current tooltip position
  Offset? _currentPosition;

  /// Whether tooltip is currently visible
  bool _isVisible = false;

  /// Callback for when tooltip visibility changes
  final VoidCallback? onVisibilityChanged;

  TooltipManager({this.onVisibilityChanged});

  /// Initialize animation controller
  void initialize(TickerProvider vsync) {
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: vsync);
  }

  /// Show tooltip for a segment at a specific position
  void showTooltip(BarSegmentData segment, Offset position) {
    _currentSegment = segment;
    _currentPosition = position;
    _isVisible = true;
    _animationController?.forward();
    onVisibilityChanged?.call();
  }

  /// Hide the current tooltip
  void hideTooltip() {
    _isVisible = false;
    _animationController?.reverse();
    onVisibilityChanged?.call();
  }

  /// Update tooltip position without changing visibility
  void updatePosition(Offset position) {
    _currentPosition = position;
    onVisibilityChanged?.call();
  }

  /// Get current tooltip widget
  Widget? buildTooltip(Size parentSize) {
    if (!_isVisible || _currentSegment == null || _currentPosition == null) {
      return null;
    }

    return CategoryTooltip(
      segmentData: _currentSegment!,
      position: _currentPosition!,
      parentSize: parentSize,
      isVisible: _isVisible,
      animationController: _animationController,
    );
  }

  /// Dispose of resources
  void dispose() {
    _animationController?.dispose();
  }

  /// Getters for current state
  bool get isVisible => _isVisible;
  BarSegmentData? get currentSegment => _currentSegment;
  Offset? get currentPosition => _currentPosition;
  AnimationController? get animationController => _animationController;
}

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

  /// Whether to show tooltips on hover/tap
  final bool showTooltips;

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

  /// Semantic label for screen readers
  final String? semanticLabel;

  /// Whether to enable keyboard navigation
  final bool enableKeyboardNavigation;

  /// Focus node for keyboard navigation
  final FocusNode? focusNode;

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
    this.showTooltips = true,
    this.semanticLabel,
    this.enableKeyboardNavigation = true,
    this.focusNode,
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

  /// Tooltip manager for handling tooltip display
  late TooltipManager _tooltipManager;

  /// Currently highlighted category type from legend interaction
  CategoryType? _highlightedCategoryType;

  /// Focus node for keyboard navigation
  late FocusNode _focusNode;

  /// Currently focused segment index for keyboard navigation
  int _focusedSegmentIndex = 0;

  /// Whether keyboard navigation is active
  bool _keyboardNavigationActive = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimationConfig();
    _initializeAnimations();
    _initializeTooltipManager();
    _initializeFocusNode();
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
    _tooltipManager.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Initialize animation configuration
  void _initializeAnimationConfig() {
    _animationConfig = widget.animationConfig ?? const AnimationConfig();
  }

  /// Initialize tooltip manager
  void _initializeTooltipManager() {
    _tooltipManager = TooltipManager(
      onVisibilityChanged: () {
        if (mounted) {
          setState(() {
            // Trigger rebuild when tooltip visibility changes
          });
        }
      },
    );
    _tooltipManager.initialize(this);
  }

  /// Initialize focus node for keyboard navigation
  void _initializeFocusNode() {
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  /// Handle focus changes for keyboard navigation
  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _keyboardNavigationActive = _focusNode.hasFocus;
        if (!_keyboardNavigationActive) {
          // Clear keyboard highlight when focus is lost
          if (_highlightedSegment != null && _keyboardNavigationActive) {
            _highlightedSegment = null;
          }
        }
      });
    }
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
    // Use UnifiedBarChartUtils for proper segment calculation with minimum width handling
    final segments = UnifiedBarChartUtils.calculateSegments(
      exerciseCategories: widget.exerciseData,
      dietCategories: widget.dietData,
      minSegmentWidth: widget.minSegmentWidth,
      sortByCount: widget.sortByCount,
    );

    _barData = UnifiedBarData.withSegments(
      exerciseCategories: widget.exerciseData,
      dietCategories: widget.dietData,
      segments: segments,
    );
  }

  /// Handle tap on a segment
  void _handleSegmentTap(BarSegmentData segment, Offset tapPosition) {
    if (!widget.enableInteraction) return;

    // Provide haptic feedback for better user experience
    HapticFeedback.lightImpact();

    setState(() {
      _tappedSegment = segment;
      _highlightedSegment = segment;
    });

    // Show tooltip if enabled
    if (widget.showTooltips) {
      _tooltipManager.showTooltip(segment, tapPosition);
    }

    // Start highlight animation
    _highlightAnimationController.forward().then((_) {
      _highlightAnimationController.reverse();
    });

    // Call callback if provided
    widget.onCategoryTap?.call(segment.category);

    // Clear tap state after animation, but keep tooltip visible
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
  void _handleSegmentHover(BarSegmentData? segment, Offset? hoverPosition) {
    if (!widget.enableInteraction) return;

    // Only update if different from current highlight (avoid unnecessary rebuilds)
    if (_highlightedSegment != segment) {
      setState(() {
        _highlightedSegment = segment;
      });

      // Show/hide tooltip based on hover state
      if (widget.showTooltips) {
        if (segment != null && hoverPosition != null) {
          _tooltipManager.showTooltip(segment, hoverPosition);
        } else {
          _tooltipManager.hideTooltip();
        }
      }

      // Start subtle hover animation if segment is hovered
      if (segment != null && _tappedSegment == null) {
        _highlightAnimationController.animateTo(0.5);
      } else if (segment == null) {
        _highlightAnimationController.reverse();
      }
    } else if (segment != null && hoverPosition != null && widget.showTooltips) {
      // Update tooltip position if hovering over the same segment
      _tooltipManager.updatePosition(hoverPosition);
    }
  }

  /// Check if chart has data to display
  bool get _hasData => _barData.hasData;

  /// Get effective height including padding
  double get _effectiveHeight {
    final padding = widget.padding ?? EdgeInsets.zero;
    return widget.height - padding.vertical;
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel() {
    if (!_hasData) {
      return '표시할 데이터가 없는 막대 그래프';
    }

    final totalCategories = _barData.segments.length;
    final exerciseCount = _barData.exerciseTotalCount;
    final dietCount = _barData.dietTotalCount;
    final totalCount = _barData.totalCount;

    String label = '카테고리 분포 막대 그래프. ';
    label += '총 $totalCount개 항목 중 ';

    if (exerciseCount > 0) {
      label += '운동 $exerciseCount개 (${_barData.exercisePercentage.toStringAsFixed(1)}%)';
    }

    if (dietCount > 0) {
      if (exerciseCount > 0) label += ', ';
      label += '식단 $dietCount개 (${_barData.dietPercentage.toStringAsFixed(1)}%)';
    }

    label += '. $totalCategories개 카테고리로 구성됨.';

    return label;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? _buildSemanticLabel(),
      hint: '카테고리별 분포를 보여주는 막대 그래프입니다. ${widget.enableKeyboardNavigation ? '화살표 키로 탐색하고 엔터나 스페이스로 선택할 수 있습니다.' : ''}',
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (widget.enableKeyboardNavigation) {
            _handleKeyboardNavigation(event);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TooltipOverlay(
          showTooltip: widget.showTooltips && _tooltipManager.isVisible,
          tooltip:
              widget.showTooltips
                  ? _tooltipManager.buildTooltip(Size(MediaQuery.of(context).size.width, widget.height))
                  : null,
          child: Container(
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
          ),
        ),
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
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: GestureDetector(
        onTapDown: (details) => _handleTapDown(details),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: () => _handleTapCancel(),
        child: MouseRegion(
          cursor: widget.enableInteraction ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onHover: (event) => _handleHover(event),
          onExit: (_) => _handleSegmentHover(null, null),
          child: AnimatedBuilder(
            animation: _highlightScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _highlightedSegment != null ? _highlightScaleAnimation.value : 1.0,
                child: Stack(
                  children: [
                    // Main chart painting
                    CustomPaint(
                      painter: BarChartPainter(
                        segments: _barData.segments,
                        highlightedSegment: _highlightedSegment,
                        tappedSegment: _tappedSegment,
                        highlightedCategoryType: _highlightedCategoryType,
                        animationProgress: _fillAnimation.value,
                        borderRadius: widget.borderRadius,
                        highlightIntensity: _highlightScaleAnimation.value - 1.0,
                      ),
                      size: Size.infinite,
                    ),
                    // Invisible semantic segments for screen readers
                    ..._buildSemanticSegments(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build invisible semantic segments for screen reader accessibility
  List<Widget> _buildSemanticSegments() {
    if (!_hasData) return [];

    return _barData.segments.asMap().entries.map((entry) {
      final index = entry.key;
      final segment = entry.value;

      final segmentWidth = segment.effectiveWidth;
      final left = segment.startPosition;

      return Positioned(
        left: (left / 100) * MediaQuery.of(context).size.width,
        top: 0,
        width: (segmentWidth / 100) * MediaQuery.of(context).size.width,
        height: _effectiveHeight,
        child: Semantics(
          button: widget.enableInteraction,
          label: '${segment.category.categoryName} ${segment.emoji}',
          value: '${segment.category.count}개, ${segment.formattedPercentage}',
          hint: widget.enableInteraction ? '탭하여 상세 정보 보기' : null,
          selected: _highlightedSegment == segment,
          focusable: widget.enableKeyboardNavigation,
          focused: _keyboardNavigationActive && _focusedSegmentIndex == index,
          onTap:
              widget.enableInteraction
                  ? () {
                    final centerPosition = Offset(
                      (left + segmentWidth / 2) / 100 * MediaQuery.of(context).size.width,
                      _effectiveHeight / 2,
                    );
                    _handleSegmentTap(segment, centerPosition);
                  }
                  : null,
          child: const SizedBox.expand(),
        ),
      );
    }).toList();
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
        _handleSegmentTap(segment, localPosition);
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

    _handleSegmentHover(hoveredSegment, hoveredSegment != null ? localPosition : null);
  }

  /// Handle tap up event
  void _handleTapUp() {
    if (!widget.enableInteraction) return;

    // Reset tap state
    setState(() {
      _tappedSegment = null;
    });

    // Hide tooltip after a delay to allow user to see it (only if not in test environment)
    if (widget.showTooltips) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _highlightedSegment == null) {
          _tooltipManager.hideTooltip();
        }
      });
    }
  }

  /// Handle tap cancel event
  void _handleTapCancel() {
    if (!widget.enableInteraction) return;

    // Reset tap state and animation
    setState(() {
      _tappedSegment = null;
    });
    _highlightAnimationController.reverse();

    // Hide tooltip immediately on cancel
    if (widget.showTooltips) {
      _tooltipManager.hideTooltip();
    }
  }

  /// Handle legend item tap
  void _handleLegendTap(CategoryType categoryType) {
    if (!widget.enableInteraction) return;

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      // Toggle highlight: if same type is tapped, clear highlight; otherwise set new highlight
      if (_highlightedCategoryType == categoryType) {
        _highlightedCategoryType = null;
      } else {
        _highlightedCategoryType = categoryType;
      }
    });

    // Hide any existing tooltip when legend is interacted with
    if (widget.showTooltips) {
      _tooltipManager.hideTooltip();
    }
  }

  /// Handle legend item tap down
  void _handleLegendTapDown(CategoryType categoryType) {
    if (!widget.enableInteraction) return;

    // Provide subtle visual feedback on tap down
    setState(() {
      _highlightedCategoryType = categoryType;
    });
  }

  /// Handle legend item tap up
  void _handleLegendTapUp() {
    if (!widget.enableInteraction) return;

    // Keep the highlight state as set by _handleLegendTap
    // This method is mainly for consistency with other tap handlers
  }

  /// Handle legend item tap cancel
  void _handleLegendTapCancel() {
    if (!widget.enableInteraction) return;

    // Reset to previous state on cancel
    setState(() {
      _highlightedCategoryType = null;
    });
  }

  /// Handle legend item hover
  void _handleLegendHover(CategoryType categoryType) {
    if (!widget.enableInteraction) return;

    // Only show hover effect if no type is currently selected
    if (_highlightedCategoryType == null) {
      setState(() {
        _highlightedCategoryType = categoryType;
      });
    }
  }

  /// Handle legend item hover exit
  void _handleLegendHoverExit() {
    if (!widget.enableInteraction) return;

    // Only clear hover effect if it was a hover (not a tap selection)
    // We can distinguish by checking if the highlight was set recently via tap
    // For simplicity, we'll clear hover effects after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          // Only clear if no persistent selection (this is a simple approach)
          // In a more complex implementation, we'd track hover vs tap state separately
        });
      }
    });
  }

  /// Handle keyboard navigation
  void _handleKeyboardNavigation(KeyEvent event) {
    if (!widget.enableKeyboardNavigation || !widget.enableInteraction || _barData.segments.isEmpty) {
      return;
    }

    if (event is KeyDownEvent) {
      bool handled = false;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          _moveFocusToPreviousSegment();
          handled = true;
          break;
        case LogicalKeyboardKey.arrowRight:
          _moveFocusToNextSegment();
          handled = true;
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          _activateCurrentSegment();
          handled = true;
          break;
        case LogicalKeyboardKey.escape:
          _clearKeyboardSelection();
          handled = true;
          break;
      }

      if (handled) {
        // Provide haptic feedback for keyboard navigation
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Move focus to previous segment
  void _moveFocusToPreviousSegment() {
    if (_barData.segments.isEmpty) return;

    setState(() {
      _focusedSegmentIndex = (_focusedSegmentIndex - 1).clamp(0, _barData.segments.length - 1);
      _highlightedSegment = _barData.segments[_focusedSegmentIndex];
      _keyboardNavigationActive = true;
    });

    // Show tooltip for focused segment
    if (widget.showTooltips) {
      final segment = _barData.segments[_focusedSegmentIndex];
      final centerPosition = Offset(
        (segment.startPosition + segment.effectiveWidth / 2) * context.size!.width / 100,
        widget.height / 2,
      );
      _tooltipManager.showTooltip(segment, centerPosition);
    }

    // Announce segment change to screen readers
    _announceSegmentChange(_barData.segments[_focusedSegmentIndex]);
  }

  /// Move focus to next segment
  void _moveFocusToNextSegment() {
    if (_barData.segments.isEmpty) return;

    setState(() {
      _focusedSegmentIndex = (_focusedSegmentIndex + 1).clamp(0, _barData.segments.length - 1);
      _highlightedSegment = _barData.segments[_focusedSegmentIndex];
      _keyboardNavigationActive = true;
    });

    // Show tooltip for focused segment
    if (widget.showTooltips) {
      final segment = _barData.segments[_focusedSegmentIndex];
      final centerPosition = Offset(
        (segment.startPosition + segment.effectiveWidth / 2) * context.size!.width / 100,
        widget.height / 2,
      );
      _tooltipManager.showTooltip(segment, centerPosition);
    }

    // Announce segment change to screen readers
    _announceSegmentChange(_barData.segments[_focusedSegmentIndex]);
  }

  /// Activate currently focused segment
  void _activateCurrentSegment() {
    if (_barData.segments.isEmpty || _focusedSegmentIndex >= _barData.segments.length) return;

    final segment = _barData.segments[_focusedSegmentIndex];
    final centerPosition = Offset(
      (segment.startPosition + segment.effectiveWidth / 2) * context.size!.width / 100,
      widget.height / 2,
    );

    _handleSegmentTap(segment, centerPosition);
  }

  /// Clear keyboard selection
  void _clearKeyboardSelection() {
    setState(() {
      _highlightedSegment = null;
      _keyboardNavigationActive = false;
      _focusedSegmentIndex = 0;
    });

    if (widget.showTooltips) {
      _tooltipManager.hideTooltip();
    }
  }

  /// Announce segment change to screen readers
  void _announceSegmentChange(BarSegmentData segment) {
    final announcement = '${segment.category.categoryName}, ${segment.formattedPercentage}, ${segment.category.count}개';
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Build legend with interactive type highlighting
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
            categoryType: CategoryType.exercise,
            isHighlighted: _highlightedCategoryType == CategoryType.exercise,
            isOtherHighlighted: _highlightedCategoryType != null && _highlightedCategoryType != CategoryType.exercise,
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
            categoryType: CategoryType.diet,
            isHighlighted: _highlightedCategoryType == CategoryType.diet,
            isOtherHighlighted: _highlightedCategoryType != null && _highlightedCategoryType != CategoryType.diet,
          ),
      ],
    );
  }

  /// Build individual legend item with touch interaction
  Widget _buildLegendItem({
    required IconData icon,
    required String label,
    required Color color,
    required int count,
    required double percentage,
    required CategoryType categoryType,
    required bool isHighlighted,
    required bool isOtherHighlighted,
  }) {
    final isInteractive = widget.enableInteraction;
    final opacity = isOtherHighlighted ? 0.3 : 1.0;
    final scale = isHighlighted ? 1.05 : 1.0;
    final iconColor = isHighlighted ? color : (isOtherHighlighted ? color.withValues(alpha: 0.3) : color);
    final textColor =
        isOtherHighlighted
            ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)
            : Theme.of(context).textTheme.bodySmall?.color;

    Widget legendContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Increased touch area
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isHighlighted ? color.withValues(alpha: 0.1) : Colors.transparent,
        border: isHighlighted ? Border.all(color: color.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 200),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, size: isHighlighted ? 18 : 16, color: iconColor),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ) ??
                    const TextStyle(),
                child: Text('$label $count개 (${percentage.toStringAsFixed(1)}%)'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isInteractive) {
      return Semantics(label: '$label 범례', value: '$count개, ${percentage.toStringAsFixed(1)}%', child: legendContent);
    }

    return Semantics(
      button: true,
      label: '$label 범례',
      value: '$count개, ${percentage.toStringAsFixed(1)}%',
      hint: '탭하여 ${isHighlighted ? '선택 해제' : '선택'}',
      selected: isHighlighted,
      child: GestureDetector(
        onTap: () => _handleLegendTap(categoryType),
        onTapDown: (_) => _handleLegendTapDown(categoryType),
        onTapUp: (_) => _handleLegendTapUp(),
        onTapCancel: () => _handleLegendTapCancel(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _handleLegendHover(categoryType),
          onExit: (_) => _handleLegendHoverExit(),
          child: legendContent,
        ),
      ),
    );
  }

  /// Build empty state when no data is available
  Widget _buildEmptyState() {
    return Semantics(
      label: '빈 막대 그래프',
      hint: '표시할 카테고리 데이터가 없습니다',
      child: Container(
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
      ),
    );
  }
}

/// CustomPainter for rendering the unified bar chart
class BarChartPainter extends CustomPainter {
  final List<BarSegmentData> segments;
  final BarSegmentData? highlightedSegment;
  final BarSegmentData? tappedSegment;
  final CategoryType? highlightedCategoryType;
  final double animationProgress;
  final double borderRadius;
  final double highlightIntensity;

  const BarChartPainter({
    required this.segments,
    this.highlightedSegment,
    this.tappedSegment,
    this.highlightedCategoryType,
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
      final isCategoryHighlighted = highlightedCategoryType != null && segment.categoryType == highlightedCategoryType;
      final isOtherCategoryHighlighted =
          highlightedCategoryType != null && segment.categoryType != highlightedCategoryType;
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
      } else if (isCategoryHighlighted) {
        // Category highlighted from legend: enhance the color slightly
        segmentColor = Color.lerp(baseColor, segment.darkerColor, 0.2) ?? baseColor;
      } else if (isOtherCategoryHighlighted) {
        // Other category highlighted: dim this segment
        segmentColor = baseColor.withValues(alpha: 0.3);
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

      // Draw small segment indicator for enhanced visibility
      if (segment.isSmallSegment && segmentWidth >= 8) {
        _drawSmallSegmentEnhancement(canvas, segmentRect, segment.color);
      }

      // Draw segment content with improved threshold handling
      // Always attempt to draw content - the _drawSegmentContent method will handle size optimization
      if (segmentWidth >= 8) {
        _drawSegmentContent(canvas, segment, segmentRect, isHighlighted || isTapped);
      }

      currentX += segmentWidth;
    }
  }

  /// Draw content inside a segment (emoji and percentage) with improved readability for small segments
  void _drawSegmentContent(Canvas canvas, BarSegmentData segment, Rect segmentRect, bool isHighlighted) {
    // Determine text color for accessibility (ensure 4.5:1 contrast ratio)
    final segmentColor = segment.color;
    final textColor = _getAccessibleTextColor(segmentColor);

    // Enhanced content rendering based on segment size
    final segmentWidth = segmentRect.width;

    // Define size thresholds for different content layouts
    const double verySmallThreshold = 15.0;
    const double smallThreshold = 25.0;
    const double mediumThreshold = 40.0;
    const double largeThreshold = 60.0;

    if (segmentWidth < verySmallThreshold) {
      // Very small segments: only show a subtle indicator dot
      _drawSmallSegmentIndicator(canvas, segmentRect, textColor);
    } else if (segmentWidth < smallThreshold) {
      // Small segments: show only emoji, optimized size
      _drawOptimizedEmoji(canvas, segment, segmentRect, textColor, isSmall: true);
    } else if (segmentWidth < mediumThreshold) {
      // Medium segments: show emoji and abbreviated percentage
      _drawOptimizedEmoji(canvas, segment, segmentRect, textColor);
      _drawOptimizedPercentage(canvas, segment, segmentRect, textColor, abbreviated: true);
    } else if (segmentWidth < largeThreshold) {
      // Large segments: show full content with standard layout
      _drawOptimizedEmoji(canvas, segment, segmentRect, textColor);
      _drawOptimizedPercentage(canvas, segment, segmentRect, textColor);
    } else {
      // Very large segments: show enhanced content with category name if space allows
      _drawOptimizedEmoji(canvas, segment, segmentRect, textColor);
      _drawOptimizedPercentage(canvas, segment, segmentRect, textColor);
      _drawCategoryName(canvas, segment, segmentRect, textColor);
    }
  }

  /// Draw a small indicator dot for very small segments
  void _drawSmallSegmentIndicator(Canvas canvas, Rect segmentRect, Color color) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

    final radius = math.min(segmentRect.width * 0.3, segmentRect.height * 0.2);
    final center = segmentRect.center;

    canvas.drawCircle(center, radius, paint);
  }

  /// Draw optimized emoji with size adaptation
  void _drawOptimizedEmoji(
    Canvas canvas,
    BarSegmentData segment,
    Rect segmentRect,
    Color textColor, {
    bool isSmall = false,
  }) {
    final centerX = segmentRect.center.dx;
    final centerY = segmentRect.center.dy;
    final segmentWidth = segmentRect.width;
    final segmentHeight = segmentRect.height;

    // Calculate optimal emoji size based on segment dimensions
    double emojiSize;
    if (isSmall) {
      emojiSize = math.min(segmentWidth * 0.6, segmentHeight * 0.7).clamp(8.0, 14.0);
    } else if (segmentWidth < 40) {
      emojiSize = math.min(segmentWidth * 0.4, segmentHeight * 0.5).clamp(10.0, 16.0);
    } else {
      emojiSize = math.min(segmentWidth * 0.3, segmentHeight * 0.4).clamp(12.0, 20.0);
    }

    final emojiStyle = TextStyle(fontSize: emojiSize, color: textColor, fontWeight: FontWeight.w500);

    final emojiPainter = TextPainter(
      text: TextSpan(text: segment.emoji, style: emojiStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    emojiPainter.layout();

    // Check if emoji fits within segment bounds
    if (emojiPainter.width <= segmentWidth - 2 && emojiPainter.height <= segmentHeight - 2) {
      // Position emoji - adjust based on whether percentage will be shown
      final hasPercentage = segmentWidth >= 25;
      final verticalOffset = hasPercentage ? -segmentHeight * 0.15 : 0.0;

      final emojiOffset = Offset(centerX - emojiPainter.width / 2, centerY - emojiPainter.height / 2 + verticalOffset);

      emojiPainter.paint(canvas, emojiOffset);
    }
  }

  /// Draw optimized percentage with overflow handling
  void _drawOptimizedPercentage(
    Canvas canvas,
    BarSegmentData segment,
    Rect segmentRect,
    Color textColor, {
    bool abbreviated = false,
  }) {
    final centerX = segmentRect.center.dx;
    final centerY = segmentRect.center.dy;
    final segmentWidth = segmentRect.width;
    final segmentHeight = segmentRect.height;

    // Calculate optimal font size based on segment width
    double fontSize;
    if (segmentWidth < 30) {
      fontSize = 8.0;
    } else if (segmentWidth < 45) {
      fontSize = 9.0;
    } else {
      fontSize = 10.0;
    }

    // Format percentage text based on available space
    String percentageText;
    if (abbreviated && segmentWidth < 35) {
      // For very small segments, show just the number
      final percentValue = segment.percentage.round();
      percentageText = '$percentValue%';
    } else {
      percentageText = segment.formattedPercentage;
    }

    final percentageStyle = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: textColor);

    final percentagePainter = TextPainter(
      text: TextSpan(text: percentageText, style: percentageStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    );

    // Layout with width constraint to prevent overflow
    percentagePainter.layout(maxWidth: segmentWidth - 4);

    // Only draw if text fits within segment bounds
    if (percentagePainter.width <= segmentWidth - 2) {
      final percentageOffset = Offset(
        centerX - percentagePainter.width / 2,
        centerY - percentagePainter.height / 2 + (segmentHeight * 0.15),
      );

      percentagePainter.paint(canvas, percentageOffset);
    }
  }

  /// Draw category name for large segments
  void _drawCategoryName(Canvas canvas, BarSegmentData segment, Rect segmentRect, Color textColor) {
    final centerX = segmentRect.center.dx;
    final centerY = segmentRect.center.dy;
    final segmentWidth = segmentRect.width;
    final segmentHeight = segmentRect.height;

    // Only show category name if segment is large enough
    if (segmentWidth < 80) return;

    final categoryName = segment.category.categoryName;
    final fontSize = math.min(segmentWidth * 0.08, 9.0).clamp(7.0, 9.0);

    final nameStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: textColor.withValues(alpha: 0.9),
    );

    final namePainter = TextPainter(
      text: TextSpan(text: categoryName, style: nameStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    );

    // Layout with width constraint
    namePainter.layout(maxWidth: segmentWidth - 8);

    // Only draw if text fits and doesn't overlap with other content
    if (namePainter.width <= segmentWidth - 4 && segmentHeight > 45) {
      final nameOffset = Offset(centerX - namePainter.width / 2, centerY + (segmentHeight * 0.35));

      namePainter.paint(canvas, nameOffset);
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

  /// Draw subtle enhancement for small segments to improve visibility
  void _drawSmallSegmentEnhancement(Canvas canvas, Rect segmentRect, Color segmentColor) {
    // Add a subtle gradient overlay to make small segments more noticeable
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        segmentColor.withValues(alpha: 0.1),
        segmentColor.withValues(alpha: 0.3),
        segmentColor.withValues(alpha: 0.1),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final gradientPaint =
        Paint()
          ..shader = gradient.createShader(segmentRect)
          ..style = PaintingStyle.fill;

    canvas.drawRect(segmentRect, gradientPaint);

    // Add a subtle top border to enhance definition
    final topBorderPaint =
        Paint()
          ..color = segmentColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(segmentRect.left, segmentRect.top),
      Offset(segmentRect.right, segmentRect.top),
      topBorderPaint,
    );
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.highlightedSegment != highlightedSegment ||
        oldDelegate.tappedSegment != tappedSegment ||
        oldDelegate.highlightedCategoryType != highlightedCategoryType ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.highlightIntensity != highlightIntensity;
  }
}
