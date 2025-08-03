import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';

/// Widget that provides smooth morphing transitions between different chart views
class MorphingChartTransition extends StatefulWidget {
  final Widget currentChart;
  final Widget? previousChart;
  final AnimationConfig animationConfig;
  final bool isTransitioning;
  final VoidCallback? onTransitionComplete;

  const MorphingChartTransition({
    super.key,
    required this.currentChart,
    this.previousChart,
    required this.animationConfig,
    this.isTransitioning = false,
    this.onTransitionComplete,
  });

  @override
  State<MorphingChartTransition> createState() => _MorphingChartTransitionState();
}

class _MorphingChartTransitionState extends State<MorphingChartTransition> with TickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(MorphingChartTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransitioning && !oldWidget.isTransitioning) {
      _startTransition();
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _morphController = AnimationController(duration: widget.animationConfig.morphDuration, vsync: this);

    _morphAnimation = CurvedAnimation(parent: _morphController, curve: widget.animationConfig.curve);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _morphController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _morphController, curve: const Interval(0.2, 0.8, curve: Curves.easeInOut)));

    _morphController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTransitionComplete?.call();
      }
    });
  }

  void _startTransition() {
    if (widget.animationConfig.enableMorphing) {
      _morphController.reset();
      _morphController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animationConfig.enableMorphing || widget.previousChart == null) {
      return widget.currentChart;
    }

    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        return Stack(
          children: [
            // Previous chart fading out
            if (widget.previousChart != null)
              Opacity(
                opacity: 1.0 - _morphAnimation.value,
                child: Transform.scale(scale: 1.0 - (_morphAnimation.value * 0.1), child: widget.previousChart!),
              ),

            // Current chart fading in
            Opacity(
              opacity: _morphAnimation.value,
              child: Transform.scale(scale: 0.9 + (_morphAnimation.value * 0.1), child: widget.currentChart),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for smooth color transitions in charts
class ColorTransitionWidget extends StatefulWidget {
  final Color fromColor;
  final Color toColor;
  final Duration duration;
  final Curve curve;
  final Widget Function(Color color) builder;
  final bool isActive;

  const ColorTransitionWidget({
    super.key,
    required this.fromColor,
    required this.toColor,
    required this.duration,
    this.curve = Curves.easeInOut,
    required this.builder,
    this.isActive = true,
  });

  @override
  State<ColorTransitionWidget> createState() => _ColorTransitionWidgetState();
}

class _ColorTransitionWidgetState extends State<ColorTransitionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ColorTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromColor != oldWidget.fromColor || widget.toColor != oldWidget.toColor) {
      _updateColorAnimation();
      if (widget.isActive) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    _colorAnimation = ColorTween(
      begin: widget.fromColor,
      end: widget.toColor,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return widget.builder(_colorAnimation.value ?? widget.toColor);
      },
    );
  }
}

/// Staggered animation container for category items
class StaggeredCategoryAnimation extends StatefulWidget {
  final List<Widget> children;
  final AnimationConfig animationConfig;
  final bool isActive;
  final Axis direction;

  const StaggeredCategoryAnimation({
    super.key,
    required this.children,
    required this.animationConfig,
    this.isActive = true,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredCategoryAnimation> createState() => _StaggeredCategoryAnimationState();
}

class _StaggeredCategoryAnimationState extends State<StaggeredCategoryAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _itemAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StaggeredCategoryAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _initializeAnimations();
    }
    if (widget.isActive && !oldWidget.isActive) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _controller = AnimationController(duration: widget.animationConfig.duration, vsync: this);

    _itemAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < widget.children.length; i++) {
      final staggerDelay =
          widget.animationConfig.enableStagger ? i * widget.animationConfig.staggerDelay.inMilliseconds / 1000.0 : 0.0;

      final begin = staggerDelay / (_controller.duration?.inMilliseconds ?? 1000) * 1000;
      final end = (begin + 0.8).clamp(0.0, 1.0);

      // Opacity animation
      _itemAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: widget.animationConfig.curve)),
        ),
      );

      // Slide animation
      final slideOffset = widget.direction == Axis.vertical ? const Offset(0.0, 0.3) : const Offset(0.3, 0.0);

      _slideAnimations.add(
        Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: widget.animationConfig.curve)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return widget.direction == Axis.vertical
            ? Column(children: _buildAnimatedChildren())
            : Row(children: _buildAnimatedChildren());
      },
    );
  }

  List<Widget> _buildAnimatedChildren() {
    return widget.children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;

      if (index >= _itemAnimations.length) return child;

      return SlideTransition(
        position: _slideAnimations[index],
        child: FadeTransition(
          opacity: _itemAnimations[index],
          child: widget.animationConfig.enableBounce ? _buildBounceWrapper(child, index) : child,
        ),
      );
    }).toList();
  }

  Widget _buildBounceWrapper(Widget child, int index) {
    final bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0 + widget.animationConfig.bounceIntensity,
    ).animate(CurvedAnimation(parent: _controller, curve: Interval(0.6, 1.0, curve: Curves.elasticOut)));

    return ScaleTransition(scale: bounceAnimation, child: child);
  }
}

/// Pulse animation for highlighting elements
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool isActive;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 1.0,
    this.maxScale = 1.1,
    this.isActive = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: widget.child);
      },
    );
  }
}
