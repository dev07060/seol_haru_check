import 'package:flutter/material.dart';
import 'package:seol_haru_check/services/consistency_calculator.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Dialog that explains how consistency score is calculated
class ConsistencyExplanationDialog extends StatelessWidget {
  final double consistencyScore;

  const ConsistencyExplanationDialog({super.key, required this.consistencyScore});

  @override
  Widget build(BuildContext context) {
    final grade = ConsistencyCalculator.getConsistencyGrade(consistencyScore);
    final feedback = ConsistencyCalculator.getConsistencyFeedback(consistencyScore);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SPColors.reportGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.analytics, color: SPColors.reportGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '일관성 점수 설명',
                        style: FTextStyles.title3_18.copyWith(
                          color: SPColors.textColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '현재 점수: ${(consistencyScore * 100).toInt()}% ($grade)',
                        style: FTextStyles.body2_14.copyWith(color: SPColors.reportGreen, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: SPColors.gray600),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Feedback
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
              child: Text(feedback, style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context))),
            ),

            const SizedBox(height: 20),

            // Calculation explanation
            Text(
              '일관성 점수 계산 방법',
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            _buildCalculationItem(
              context,
              '활동 분포 (30%)',
              '매일 꾸준히 활동할수록 높은 점수',
              Icons.calendar_today,
              SPColors.reportBlue,
            ),

            _buildCalculationItem(
              context,
              '운동/식단 균형 (25%)',
              '운동과 식단을 균형있게 관리할수록 높은 점수',
              Icons.balance,
              SPColors.reportOrange,
            ),

            _buildCalculationItem(
              context,
              '목표 달성률 (25%)',
              '주간 목표(운동 4일, 식단 6일) 달성률',
              Icons.flag,
              SPColors.reportPurple,
            ),

            _buildCalculationItem(
              context,
              '활동 다양성 (20%)',
              '다양한 운동과 식단을 시도할수록 높은 점수',
              Icons.diversity_3,
              SPColors.reportTeal,
            ),

            const SizedBox(height: 20),

            // Grade explanation
            Text(
              '등급 기준',
              style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            _buildGradeItem(context, 'S급', '90% 이상', SPColors.reportGreen),
            _buildGradeItem(context, 'A급', '80-90%', SPColors.reportBlue),
            _buildGradeItem(context, 'B급', '70-80%', SPColors.reportOrange),
            _buildGradeItem(context, 'C급', '60-70%', SPColors.reportPurple),
            _buildGradeItem(context, 'D급', '50-60%', SPColors.reportAmber),
            _buildGradeItem(context, 'F급', '50% 미만', SPColors.danger100),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SPColors.reportGreen,
                  foregroundColor: SPColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  '확인',
                  style: FTextStyles.body1_16.copyWith(color: SPColors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationItem(BuildContext context, String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
                ),
                Text(description, style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeItem(BuildContext context, String grade, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(grade, style: FTextStyles.body3_13.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Text(range, style: FTextStyles.body2_14.copyWith(color: SPColors.textColor(context))),
        ],
      ),
    );
  }
}
