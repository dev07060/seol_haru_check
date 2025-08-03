import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget that displays AI-generated recommendations
class RecommendationsSection extends StatelessWidget {
  final List<String> recommendations;

  const RecommendationsSection({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: SPColors.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.gray200),
        boxShadow: [
          BoxShadow(color: SPColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SPColors.podPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lightbulb_outline, size: 20, color: SPColors.podPurple),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.recommendations,
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recommendations list
            ...recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;

              return _buildRecommendationItem(context, index + 1, recommendation);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, int number, String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SPColors.podPurple.withValues(alpha: 0.05), SPColors.podPink.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.podPurple.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: SPColors.podPurple, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                '$number',
                style: FTextStyles.body2_14.copyWith(color: SPColors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Recommendation text
          Expanded(
            child: Text(
              recommendation,
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
