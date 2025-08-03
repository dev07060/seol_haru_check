import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Particle effect widget for achievement celebrations
class ParticleEffects extends StatefulWidget {
  final bool isActive;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;
  final Duration duration;
  final double size;
  final VoidCallback? onComplete;

  const ParticleEffects({
    super.key,
    required this.isActive,
    this.primaryColor = Colors.orange,
    this.secondaryColor = Colors.yellow,
    this.particleCount = 20,
    this.duration = const Duration(milliseconds: 2000),
    this.size = 200.0,
    this.onComplete,
  });

  @override
  State<ParticleEffects> createState() => _ParticleEffectsState();
}

class _ParticleEffectsState extends State<ParticleEffects> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _initializeParticles();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ParticleEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        startX: widget.size / 2,
        startY: widget.size / 2,
        velocityX: (random.nextDouble() - 0.5) * 200,
        velocityY: (random.nextDouble() - 0.5) * 200 - 50,
        color: index % 2 == 0 ? widget.primaryColor : widget.secondaryColor,
        size: random.nextDouble() * 6 + 2,
        life: random.nextDouble() * 0.5 + 0.5,
      );
    });
  }

  void _startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  void _stopAnimation() {
    _controller.stop();
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(painter: ParticlePainter(particles: _particles, progress: _controller.value));
        },
      ),
    );
  }
}

/// Individual particle data
class Particle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double size;
  final double life;

  const Particle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.life,
  });

  /// Get current position based on progress
  Offset getPosition(double progress) {
    final t = progress / life;
    if (t > 1.0) return Offset(startX, startY);

    final x = startX + velocityX * t;
    final y = startY + velocityY * t + 0.5 * 100 * t * t; // gravity effect

    return Offset(x, y);
  }

  /// Get current opacity based on progress
  double getOpacity(double progress) {
    final t = progress / life;
    if (t > 1.0) return 0.0;

    return (1.0 - t).clamp(0.0, 1.0);
  }

  /// Get current size based on progress
  double getCurrentSize(double progress) {
    final t = progress / life;
    if (t > 1.0) return 0.0;

    return size * (1.0 - t * 0.5);
  }
}

/// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final position = particle.getPosition(progress);
      final opacity = particle.getOpacity(progress);
      final currentSize = particle.getCurrentSize(progress);

      if (opacity <= 0 || currentSize <= 0) continue;

      final paint =
          Paint()
            ..color = particle.color.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(position, currentSize, paint);

      // Add glow effect
      final glowPaint =
          Paint()
            ..color = particle.color.withValues(alpha: opacity * 0.3)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(position, currentSize * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Confetti particle effect for special achievements
class ConfettiEffect extends StatefulWidget {
  final bool isActive;
  final Duration duration;
  final double size;
  final VoidCallback? onComplete;

  const ConfettiEffect({
    super.key,
    required this.isActive,
    this.duration = const Duration(milliseconds: 3000),
    this.size = 300.0,
    this.onComplete,
  });

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect> with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _initializeConfetti();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeConfetti() {
    final random = math.Random();
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink];

    _confetti = List.generate(30, (index) {
      return ConfettiParticle(
        startX: random.nextDouble() * widget.size,
        startY: -20,
        velocityX: (random.nextDouble() - 0.5) * 100,
        velocityY: random.nextDouble() * 50 + 50,
        color: colors[random.nextInt(colors.length)],
        width: random.nextDouble() * 8 + 4,
        height: random.nextDouble() * 12 + 6,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
      );
    });
  }

  void _startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ConfettiPainter(
              confetti: _confetti,
              progress: _controller.value,
              canvasSize: Size(widget.size, widget.size),
            ),
          );
        },
      ),
    );
  }
}

/// Confetti particle data
class ConfettiParticle {
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double width;
  final double height;
  final double rotation;
  final double rotationSpeed;

  const ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.width,
    required this.height,
    required this.rotation,
    required this.rotationSpeed,
  });

  /// Get current position based on progress
  Offset getPosition(double progress) {
    final x = startX + velocityX * progress;
    final y = startY + velocityY * progress + 0.5 * 200 * progress * progress;
    return Offset(x, y);
  }

  /// Get current rotation based on progress
  double getCurrentRotation(double progress) {
    return rotation + rotationSpeed * progress;
  }

  /// Get current opacity based on progress
  double getOpacity(double progress) {
    return (1.0 - progress).clamp(0.0, 1.0);
  }
}

/// Custom painter for confetti effects
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> confetti;
  final double progress;
  final Size canvasSize;

  ConfettiPainter({required this.confetti, required this.progress, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in confetti) {
      final position = particle.getPosition(progress);
      final rotation = particle.getCurrentRotation(progress);
      final opacity = particle.getOpacity(progress);

      if (opacity <= 0) continue;
      if (position.dy > canvasSize.height + 20) continue;

      final paint =
          Paint()
            ..color = particle.color.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);

      final rect = Rect.fromCenter(center: Offset.zero, width: particle.width, height: particle.height);

      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
