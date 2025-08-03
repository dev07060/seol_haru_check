import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/widgets/report/animations/particle_effects.dart';

/// Comprehensive animation manager for category chart transitions
class CategoryAnimationManager extends StatefulWidget {
  final Widget child;
  final List<CategoryVisualizationData> currentData;
  final List<CategoryVisualizationData>? previousData;
  final AnimationConfig animationConfig;
  final bool enableTransitions;
  final VoidCallback? onAnimationComplete;

  const CategoryAnimationManager({
    super.key,
    required this.child,
    required this.currentData,
    this.previousData,
    required this.animationConfig,
    this.enableTransitions = true,
    this.onAnimationComplete,
  });

  @override
  State<CategoryAnimationManager> createState() => _CategoryAnimationManagerState();
}

class _CategoryAnimationManagerState extends State<CategoryAnimationManager> with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late AnimationController _colorController;
  late AnimationController _particleController;

  bool _isTransitioning = false;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(CategoryAnimationManager oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentData != oldWidget.currentData && widget.enableTransitions) {
      _startTransition();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _colorController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _transitionController = AnimationController(duration: widget.animationConfig.morphDuration, vsync: this);

    _colorController = AnimationController(duration: widget.animationConfig.colorTransitionDuration, vsync: this);

    _particleController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _transitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isTransitioning = false;
        });
        widget.onAnimationComplete?.call();
      }
    });
  }

  void _startTransition() {
    if (!widget.animationConfig.enableMorphing) return;

    setState(() {
      _isTransitioning = true;
    });

    // Start transition animations
    _transitionController.reset();
    _transitionController.forward();

    if (widget.animationConfig.enableColorTransitions) {
      _colorController.reset();
      _colorController.forward();
    }

    // Show particles if enabled and data significantly changed
    if (widget.animationConfig.enableParticles && _hasSignificantChange()) {
      setState(() {
        _showParticles = true;
      });
      _particleController.reset();
      _particleController.forward();
    }
  }

  bool _hasSignificantChange() {
    if (widget.previousData == null) return true;

    // Check if categories were added or removed
    if (widget.currentData.length != widget.previousData!.length) return true;

    // Check if any category count changed significantly (>20%)
    for (int i = 0; i < widget.currentData.length && i < widget.previousData!.length; i++) {
      final current = widget.currentData[i].count;
      final previous = widget.previousData![i].count;

      if (previous > 0) {
        final changePercent = (current - previous).abs() / previous;
        if (changePercent > 0.2) return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with transition
        AnimatedBuilder(
          animation: _transitionController,
          builder: (context, child) {
            return widget.child;
          },
        ),

        // Particle effects overlay
        if (_showParticles)
          Positioned.fill(
            child: ParticleEffects(
              isActive: _showParticles,
              primaryColor: _getPrimaryColor(),
              secondaryColor: _getSecondaryColor(),
              particleCount: 12,
              duration: const Duration(milliseconds: 1500),
              onComplete: () {
                setState(() {
                  _showParticles = false;
                });
              },
            ),
          ),
      ],
    );
  }

  Color _getPrimaryColor() {
    if (widget.currentData.isEmpty) return Colors.blue;
    return widget.currentData.first.color;
  }

  Color _getSecondaryColor() {
    if (widget.currentData.length < 2) return Colors.orange;
    return widget.currentData[1].color;
  }
}

/// Enhanced category item with smooth animations
class AnimatedCategoryItem extends StatefulWidget {
  final CategoryVisualizationData categoryData;
  final CategoryVisualizationData? previousCategoryData;
  final AnimationConfig animationConfig;
  final int index;
  final Widget Function(CategoryVisualizationData data, Color animatedColor) builder;
  final VoidCallback? onTap;

  const AnimatedCategoryItem({
    super.key,
    required this.categoryData,
    this.previousCategoryData,
    required this.animationConfig,
    required this.index,
    required this.builder,
    this.onTap,
  });

  @override
  State<AnimatedCategoryItem> createState() => _AnimatedCategoryItemState();
}

class _AnimatedCategoryItemState extends State<AnimatedCategoryItem> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _colorController;
  late AnimationController _scaleController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void didUpdateWidget(AnimatedCategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.categoryData != oldWidget.categoryData) {
      _updateColorAnimation();
      if (widget.animationConfig.enableColorTransitions) {
        _colorController.reset();
        _colorController.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _controller = AnimationController(duration: widget.animationConfig.duration, vsync: this);

    _colorController = AnimationController(duration: widget.animationConfig.colorTransitionDuration, vsync: this);

    _scaleController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    // Staggered slide animation
    final staggerDelay =
        widget.animationConfig.enableStagger
            ? widget.index * widget.animationConfig.staggerDelay.inMilliseconds / 1000.0
            : 0.0;

    final begin = staggerDelay / (_controller.duration?.inMilliseconds ?? 1000) * 1000;
    final end = (begin + 0.8).clamp(0.0, 1.0);

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: widget.animationConfig.curve)));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: Curves.easeIn)));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    final fromColor = widget.previousCategoryData?.color ?? widget.categoryData.color;
    final toColor = widget.categoryData.color;

    _colorAnimation = ColorTween(
      begin: fromColor,
      end: toColor,
    ).animate(CurvedAnimation(parent: _colorController, curve: Curves.easeInOut));
  }

  void _startAnimations() {
    _controller.forward();
    _colorController.forward();
    _scaleController.forward();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _colorAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 20),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: widget.builder(widget.categoryData, _colorAnimation.value ?? widget.categoryData.color),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Smooth number transition widget for category counts
class AnimatedCategoryCount extends StatefulWidget {
  final int currentCount;
  final int? previousCount;
  final Duration duration;
  final TextStyle textStyle;

  const AnimatedCategoryCount({
    super.key,
    required this.currentCount,
    this.previousCount,
    this.duration = const Duration(milliseconds: 800),
    required this.textStyle,
  });

  @override
  State<AnimatedCategoryCount> createState() => _AnimatedCategoryCountState();
}

class _AnimatedCategoryCountState extends State<AnimatedCategoryCount> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  @override
  void didUpdateWidget(AnimatedCategoryCount oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentCount != oldWidget.currentCount) {
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _updateAnimation();
    _controller.forward();
  }

  void _updateAnimation() {
    final fromCount = widget.previousCount ?? widget.currentCount;
    final toCount = widget.currentCount;

    _countAnimation = Tween<double>(
      begin: fromCount.toDouble(),
      end: toCount.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (fromCount != toCount) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        return Text(_countAnimation.value.round().toString(), style: widget.textStyle);
      },
    );
  }
}
