import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Tooltip content widget that displays category information
class CategoryTooltipContent extends StatelessWidget {
  /// The segment data to display in the tooltip
  final BarSegmentData segmentData;

  /// Animation controller for fade in/out effects
  final AnimationController? animationController;

  /// Custom background color for the tooltip
  final Color? backgroundColor;

  /// Custom text color for the tooltip
  final Color? textColor;

  /// Maximum width for the tooltip
  final double maxWidth;

  /// Padding inside the tooltip
  final EdgeInsets padding;

  /// Border radius for the tooltip
  final double borderRadius;

  /// Shadow elevation for the tooltip
  final double elevation;

  const CategoryTooltipContent({
    super.key,
    required this.segmentData,
    this.animationController,
    this.backgroundColor,
    this.textColor,
    this.maxWidth = 200.0,
    this.padding = const EdgeInsets.all(12.0),
    this.borderRadius = 8.0,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tooltipBackgroundColor = backgroundColor ?? theme.colorScheme.surface;
    final tooltipTextColor = textColor ?? theme.colorScheme.onSurface;

    // Ensure sufficient contrast for accessibility
    final adjustedBackgroundColor = _ensureAccessibleBackground(tooltipBackgroundColor, theme);
    final adjustedTextColor = _ensureAccessibleTextColor(tooltipTextColor, adjustedBackgroundColor);

    Widget tooltipContent = Semantics(
      container: true,
      label: '카테고리 상세 정보',
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        decoration: BoxDecoration(
          color: adjustedBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3), width: 1),
        ),
        child: _buildTooltipContent(context, adjustedTextColor),
      ),
    );

    // Add animation if controller is provided
    if (animationController != null) {
      tooltipContent = AnimatedBuilder(
        animation: animationController!,
        builder: (context, child) {
          return Transform.scale(
            scale: animationController!.value,
            child: Opacity(opacity: animationController!.value, child: child),
          );
        },
        child: tooltipContent,
      );
    }

    return tooltipContent;
  }

  /// Ensure tooltip background has sufficient contrast
  Color _ensureAccessibleBackground(Color backgroundColor, ThemeData theme) {
    final backgroundLuminance = backgroundColor.computeLuminance();
    final surfaceLuminance = theme.colorScheme.surface.computeLuminance();

    // If contrast is too low, adjust the background
    final contrastRatio = _calculateContrastRatio(backgroundColor, theme.colorScheme.surface);
    if (contrastRatio < 3.0) {
      // Adjust background to ensure better contrast
      if (backgroundLuminance > 0.5) {
        return backgroundColor.withValues(alpha: 0.95);
      } else {
        return Color.lerp(backgroundColor, Colors.white, 0.1) ?? backgroundColor;
      }
    }

    return backgroundColor;
  }

  /// Ensure text color has sufficient contrast against background
  Color _ensureAccessibleTextColor(Color textColor, Color backgroundColor) {
    final contrastRatio = _calculateContrastRatio(textColor, backgroundColor);

    if (contrastRatio >= 4.5) {
      return textColor;
    }

    // If contrast is insufficient, use high contrast color
    final backgroundLuminance = backgroundColor.computeLuminance();
    return backgroundLuminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Calculate contrast ratio between two colors
  double _calculateContrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter = foregroundLuminance > backgroundLuminance ? foregroundLuminance : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance ? backgroundLuminance : foregroundLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Build the content inside the tooltip
  Widget _buildTooltipContent(BuildContext context, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with emoji and name
        Semantics(
          header: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(label: '카테고리 이모지', child: Text(segmentData.emoji, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  label: '카테고리 이름',
                  child: Text(
                    segmentData.category.categoryName,
                    style: FTextStyles.title4_17.copyWith(color: textColor, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Small segment indicator
              if (segmentData.isSmallSegment) ...[
                const SizedBox(width: 4),
                Semantics(
                  label: '작은 구간 표시',
                  hint: '이 카테고리는 작은 비율이지만 가독성을 위해 최소 크기로 표시됩니다',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '작은 구간',
                      style: FTextStyles.body3_13.copyWith(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Category type indicator
        Semantics(
          label: '카테고리 유형',
          value: segmentData.categoryType.displayName,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: segmentData.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              segmentData.categoryType.displayName,
              style: FTextStyles.body3_13.copyWith(color: segmentData.color, fontWeight: FontWeight.w500),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Statistics section
        Semantics(
          label: '통계 정보',
          child: Column(
            children: [
              _buildStatRow(context, '개수', '${segmentData.category.count}개', textColor),
              const SizedBox(height: 4),
              _buildStatRow(context, '비율', segmentData.formattedPercentage, textColor),
            ],
          ),
        ),

        // Small segment explanation
        if (segmentData.isSmallSegment) ...[
          const SizedBox(height: 8),
          Semantics(
            label: '작은 구간 설명',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '작은 비율이지만 가독성을 위해 최소 크기로 표시됩니다',
                      style: FTextStyles.body3_13.copyWith(color: Colors.blue.shade700, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Additional description if available
        if (segmentData.category.description != null) ...[
          const SizedBox(height: 8),
          Semantics(
            label: '추가 설명',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                segmentData.category.description!,
                style: FTextStyles.body3_13.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build a statistics row with label and value
  Widget _buildStatRow(BuildContext context, String label, String value, Color textColor) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            excludeSemantics: true,
            child: Text(label, style: FTextStyles.body2_14.copyWith(color: textColor.withValues(alpha: 0.7))),
          ),
          Semantics(
            excludeSemantics: true,
            child: Text(value, style: FTextStyles.body2_14.copyWith(color: textColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Tooltip widget that displays category information when a bar segment is tapped or hovered
class CategoryTooltip extends StatelessWidget {
  /// The segment data to display in the tooltip
  final BarSegmentData segmentData;

  /// Position where the tooltip should appear
  final Offset position;

  /// Size of the parent widget for positioning calculations
  final Size parentSize;

  /// Whether to show the tooltip
  final bool isVisible;

  /// Animation controller for fade in/out effects
  final AnimationController? animationController;

  /// Custom background color for the tooltip
  final Color? backgroundColor;

  /// Custom text color for the tooltip
  final Color? textColor;

  /// Maximum width for the tooltip
  final double maxWidth;

  /// Padding inside the tooltip
  final EdgeInsets padding;

  /// Border radius for the tooltip
  final double borderRadius;

  /// Shadow elevation for the tooltip
  final double elevation;

  const CategoryTooltip({
    super.key,
    required this.segmentData,
    required this.position,
    required this.parentSize,
    this.isVisible = true,
    this.animationController,
    this.backgroundColor,
    this.textColor,
    this.maxWidth = 200.0,
    this.padding = const EdgeInsets.all(12.0),
    this.borderRadius = 8.0,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      left: _calculateHorizontalPosition(),
      top: _calculateVerticalPosition(),
      child: Semantics(
        liveRegion: true,
        child: CategoryTooltipContent(
          segmentData: segmentData,
          animationController: animationController,
          backgroundColor: backgroundColor,
          textColor: textColor,
          maxWidth: maxWidth,
          padding: padding,
          borderRadius: borderRadius,
          elevation: elevation,
        ),
      ),
    );
  }

  /// Calculate horizontal position to keep tooltip within bounds
  double _calculateHorizontalPosition() {
    const tooltipWidth = 200.0; // Approximate tooltip width
    const margin = 16.0; // Margin from screen edges

    double left = position.dx - (tooltipWidth / 2);

    // Ensure tooltip doesn't go off the left edge
    if (left < margin) {
      left = margin;
    }

    // Ensure tooltip doesn't go off the right edge
    if (left + tooltipWidth > parentSize.width - margin) {
      left = parentSize.width - tooltipWidth - margin;
    }

    return left;
  }

  /// Calculate vertical position to keep tooltip within bounds
  double _calculateVerticalPosition() {
    const tooltipHeight = 120.0; // Approximate tooltip height
    const margin = 16.0; // Margin from screen edges
    const offsetFromTouch = 20.0; // Offset from touch point

    double top = position.dy - tooltipHeight - offsetFromTouch;

    // If tooltip would go above the screen, show it below the touch point
    if (top < margin) {
      top = position.dy + offsetFromTouch;
    }

    // Ensure tooltip doesn't go off the bottom edge
    if (top + tooltipHeight > parentSize.height - margin) {
      top = parentSize.height - tooltipHeight - margin;
    }

    return top;
  }
}
