import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';

/// Skeleton loading widget for better UX during data loading
class SkeletonLoading extends StatefulWidget {
  const SkeletonLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? SPColors.gray200;
    final highlightColor = widget.highlightColor ?? SPColors.gray100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading for text lines
class SkeletonText extends StatelessWidget {
  const SkeletonText({super.key, this.width, this.height = 16.0, this.lines = 1, this.spacing = 8.0});

  final double? width;
  final double height;
  final int lines;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        final lineWidth = width ?? (isLastLine ? 120.0 : double.infinity);

        return Padding(
          padding: EdgeInsets.only(bottom: isLastLine ? 0 : spacing),
          child: SkeletonLoading(width: lineWidth, height: height, borderRadius: 4.0),
        );
      }),
    );
  }
}

/// Skeleton loading for cards
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.width, this.height = 120.0, this.padding = const EdgeInsets.all(16.0)});

  final double? width;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: SPColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: SPColors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoading(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(child: SkeletonText(height: 18)),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonText(lines: 2, height: 14),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoading(width: 60, height: 12, borderRadius: 6),
              SkeletonLoading(width: 40, height: 12, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading for weekly report sections
class WeeklyReportSkeleton extends StatelessWidget {
  const WeeklyReportSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header skeleton
        SkeletonText(width: 200, height: 24),
        const SizedBox(height: 8),
        SkeletonText(width: 150, height: 16),
        const SizedBox(height: 24),

        // Stats cards skeleton
        Row(
          children: [
            Expanded(child: SkeletonCard(height: 80)),
            const SizedBox(width: 12),
            Expanded(child: SkeletonCard(height: 80)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonCard(height: 80)),
            const SizedBox(width: 12),
            Expanded(child: SkeletonCard(height: 80)),
          ],
        ),
        const SizedBox(height: 24),

        // Analysis sections skeleton
        SkeletonCard(height: 150),
        const SizedBox(height: 16),
        SkeletonCard(height: 150),
        const SizedBox(height: 16),
        SkeletonCard(height: 120),
      ],
    );
  }
}
