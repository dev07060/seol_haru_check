import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/animations/morphing_chart_transition.dart';
import 'package:seol_haru_check/widgets/report/animations/particle_effects.dart';

/// Widget for celebrating newly unlocked achievements with animations
class AchievementCelebration extends StatefulWidget {
  final CategoryAchievement achievement;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final bool enableParticles;
  final bool enableConfetti;

  const AchievementCelebration({
    super.key,
    required this.achievement,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
    this.enableParticles = true,
    this.enableConfetti = false,
  });

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _particleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _scaleController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _particleController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _particleController, curve: Curves.easeOut));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _particleController.forward();

    // Auto dismiss after display duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() async {
    await _slideController.reverse();
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          FadeTransition(opacity: _fadeAnimation, child: Container(color: Colors.black.withValues(alpha: 0.3))),

          // Enhanced particle effects
          if (widget.enableParticles)
            Positioned.fill(
              child: ParticleEffects(
                isActive: _particleController.isAnimating,
                primaryColor: widget.achievement.color,
                secondaryColor: widget.achievement.rarity.color,
                particleCount: 25,
                duration: const Duration(milliseconds: 2000),
                size: MediaQuery.of(context).size.width,
              ),
            ),

          // Confetti effects for legendary achievements
          if (widget.enableConfetti && widget.achievement.rarity == AchievementRarity.legendary)
            Positioned.fill(
              child: ConfettiEffect(
                isActive: _particleController.isAnimating,
                duration: const Duration(milliseconds: 3000),
                size: MediaQuery.of(context).size.width,
              ),
            ),

          // Achievement card with pulse animation
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: PulseAnimation(
                  duration: const Duration(milliseconds: 1200),
                  minScale: 1.0,
                  maxScale: 1.02,
                  isActive: true,
                  child: _buildAchievementCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: widget.achievement.color.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 0)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement unlocked text
          Text(
            '🎉 성취 달성! 🎉',
            style: FTextStyles.title2_20.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Achievement icon with enhanced glow effect
          PulseAnimation(
            duration: const Duration(milliseconds: 800),
            minScale: 1.0,
            maxScale: 1.1,
            isActive: true,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.achievement.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: widget.achievement.color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                  BoxShadow(color: widget.achievement.color.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: Icon(widget.achievement.icon, size: 40, color: widget.achievement.color),
            ),
          ),

          const SizedBox(height: 20),

          // Achievement title
          Text(
            widget.achievement.title,
            style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Achievement description
          Text(
            widget.achievement.description,
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Rarity and points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.achievement.rarity.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.achievement.rarity.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  widget.achievement.rarity.displayName,
                  style: FTextStyles.body2_14.copyWith(
                    color: widget.achievement.rarity.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SPColors.podGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: SPColors.podGreen),
                    const SizedBox(width: 4),
                    Text(
                      '+${widget.achievement.points}',
                      style: FTextStyles.body2_14.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dismiss button
          TextButton(
            onPressed: _dismissWithAnimation,
            style: TextButton.styleFrom(
              backgroundColor: SPColors.podGreen.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              '확인',
              style: FTextStyles.body1_16.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
