import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/achievement_models.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/achievements/achievement_celebration.dart';
import 'package:seol_haru_check/widgets/report/animations/category_animation_manager.dart';
import 'package:seol_haru_check/widgets/report/animations/morphing_chart_transition.dart';
import 'package:seol_haru_check/widgets/report/animations/particle_effects.dart';

/// Showcase widget demonstrating all animation features
class AnimationShowcase extends StatefulWidget {
  const AnimationShowcase({super.key});

  @override
  State<AnimationShowcase> createState() => _AnimationShowcaseState();
}

class _AnimationShowcaseState extends State<AnimationShowcase> {
  bool _showParticles = false;
  bool _showConfetti = false;
  bool _showAchievement = false;
  bool _enableStagger = true;
  bool _enableMorphing = true;
  bool _enableColorTransitions = true;

  final List<CategoryVisualizationData> _sampleData = [
    CategoryVisualizationData(
      categoryName: '근력 운동',
      emoji: '💪',
      count: 5,
      percentage: 0.4,
      color: SPColors.podGreen,
      type: CategoryType.exercise,
    ),
    CategoryVisualizationData(
      categoryName: '유산소 운동',
      emoji: '🏃',
      count: 3,
      percentage: 0.3,
      color: SPColors.podBlue,
      type: CategoryType.exercise,
    ),
    CategoryVisualizationData(
      categoryName: '스트레칭',
      emoji: '🧘',
      count: 2,
      percentage: 0.2,
      color: SPColors.podOrange,
      type: CategoryType.exercise,
    ),
  ];

  final CategoryAchievement _sampleAchievement = CategoryAchievement(
    id: 'sample_achievement',
    title: '균형잡힌 한 주',
    description: '다양한 운동 카테고리를 골고루 실천했습니다!',
    type: AchievementType.categoryBalance,
    rarity: AchievementRarity.rare,
    icon: Icons.balance,
    color: SPColors.podPurple,
    achievedAt: DateTime.now(),
    points: 50,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Showcase'),
        backgroundColor: SPColors.podGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControlPanel(),
            const SizedBox(height: 24),
            _buildParticleEffectsDemo(),
            const SizedBox(height: 24),
            _buildStaggeredAnimationDemo(),
            const SizedBox(height: 24),
            _buildColorTransitionDemo(),
            const SizedBox(height: 24),
            _buildMorphingDemo(),
            const SizedBox(height: 24),
            _buildAchievementDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Animation Controls', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildControlButton(
                  'Particles',
                  _showParticles,
                  () => setState(() => _showParticles = !_showParticles),
                ),
                _buildControlButton('Confetti', _showConfetti, () => setState(() => _showConfetti = !_showConfetti)),
                _buildControlButton(
                  'Achievement',
                  _showAchievement,
                  () => setState(() => _showAchievement = !_showAchievement),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Animation Settings', style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildToggleSwitch('Stagger', _enableStagger, (value) => setState(() => _enableStagger = value)),
                _buildToggleSwitch('Morphing', _enableMorphing, (value) => setState(() => _enableMorphing = value)),
                _buildToggleSwitch(
                  'Color Transitions',
                  _enableColorTransitions,
                  (value) => setState(() => _enableColorTransitions = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, bool isActive, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? SPColors.podGreen : SPColors.gray300,
        foregroundColor: isActive ? Colors.white : SPColors.gray600,
      ),
      child: Text(label),
    );
  }

  Widget _buildToggleSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: FTextStyles.body2_14),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged, activeColor: SPColors.podGreen),
      ],
    );
  }

  Widget _buildParticleEffectsDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Particle Effects', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
              child: Stack(
                children: [
                  Center(
                    child: Text('Particle Effects Area', style: FTextStyles.body1_16.copyWith(color: SPColors.gray600)),
                  ),
                  if (_showParticles)
                    Positioned.fill(
                      child: ParticleEffects(
                        isActive: _showParticles,
                        primaryColor: SPColors.podGreen,
                        secondaryColor: SPColors.podOrange,
                        particleCount: 15,
                        duration: const Duration(milliseconds: 2000),
                        onComplete: () => setState(() => _showParticles = false),
                      ),
                    ),
                  if (_showConfetti)
                    Positioned.fill(
                      child: ConfettiEffect(
                        isActive: _showConfetti,
                        duration: const Duration(milliseconds: 3000),
                        onComplete: () => setState(() => _showConfetti = false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredAnimationDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staggered Animation', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StaggeredCategoryAnimation(
              animationConfig: AnimationConfig(
                enableStagger: _enableStagger,
                duration: const Duration(milliseconds: 1200),
                staggerDelay: const Duration(milliseconds: 150),
              ),
              isActive: true,
              children: _sampleData.map((data) => _buildCategoryCard(data)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTransitionDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color Transitions', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ColorTransitionWidget(
                    fromColor: SPColors.podGreen,
                    toColor: SPColors.podBlue,
                    duration: const Duration(milliseconds: 1000),
                    isActive: _enableColorTransitions,
                    builder:
                        (color) => Container(
                          height: 60,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                          child: const Center(
                            child: Text('Color A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ColorTransitionWidget(
                    fromColor: SPColors.podOrange,
                    toColor: SPColors.podPurple,
                    duration: const Duration(milliseconds: 1000),
                    isActive: _enableColorTransitions,
                    builder:
                        (color) => Container(
                          height: 60,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                          child: const Center(
                            child: Text('Color B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphingDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Morphing Transitions', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: MorphingChartTransition(
                currentChart: _buildMorphingContent('Current View', SPColors.podGreen),
                previousChart: _enableMorphing ? _buildMorphingContent('Previous View', SPColors.podBlue) : null,
                animationConfig: AnimationConfig(
                  enableMorphing: _enableMorphing,
                  morphDuration: const Duration(milliseconds: 800),
                ),
                isTransitioning: _enableMorphing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphingContent(String text, Color color) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildAchievementDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievement Celebration', style: FTextStyles.title3_18.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => setState(() => _showAchievement = true),
                style: ElevatedButton.styleFrom(backgroundColor: SPColors.podPurple, foregroundColor: Colors.white),
                child: const Text('Show Achievement'),
              ),
            ),
            if (_showAchievement)
              Positioned.fill(
                child: AchievementCelebration(
                  achievement: _sampleAchievement,
                  enableParticles: true,
                  enableConfetti: _sampleAchievement.rarity == AchievementRarity.legendary,
                  onDismiss: () => setState(() => _showAchievement = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryVisualizationData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(data.categoryName, style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.bold))),
          AnimatedCategoryCount(
            currentCount: data.count,
            textStyle: FTextStyles.body1_16.copyWith(color: data.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
