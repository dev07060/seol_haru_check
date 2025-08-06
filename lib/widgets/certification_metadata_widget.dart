import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/models/certification_model.dart';
import 'package:seol_haru_check/models/metadata_models.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget to display AI-extracted metadata for certifications
/// Gracefully handles certifications with and without metadata
class CertificationMetadataWidget extends StatelessWidget {
  final Certification certification;
  final bool isCompact;

  const CertificationMetadataWidget({super.key, required this.certification, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final fColors = FColors.of(context);

    // Return empty widget if no metadata is available
    if (!certification.metadataProcessed ||
        (certification.exerciseMetadata == null && certification.dietMetadata == null)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: fColors.backgroundNormalA,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fColors.lineAlternative, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: isCompact ? 14 : 16, color: fColors.blue60),
              const Gap(4),
              Text(
                'AI 분석 정보',
                style: (isCompact ? FTextStyles.caption_12 : FTextStyles.bodyS).copyWith(
                  color: fColors.blue60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(8),
          if (certification.exerciseMetadata != null) _buildExerciseMetadata(context, certification.exerciseMetadata!),
          if (certification.dietMetadata != null) _buildDietMetadata(context, certification.dietMetadata!),
        ],
      ),
    );
  }

  Widget _buildExerciseMetadata(BuildContext context, ExerciseMetadata metadata) {
    final fColors = FColors.of(context);
    final textStyle = (isCompact ? FTextStyles.caption_12 : FTextStyles.bodyS).copyWith(color: fColors.labelNormal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (metadata.exerciseType != null) _buildMetadataRow(context, '운동 종류', metadata.exerciseType!, textStyle),
        if (metadata.duration != null) _buildMetadataRow(context, '운동 시간', '${metadata.duration}분', textStyle),
        if (metadata.timePeriod != null) _buildMetadataRow(context, '운동 시간대', metadata.timePeriod!, textStyle),
        if (metadata.intensity != null) _buildMetadataRow(context, '운동 강도', metadata.intensity!, textStyle),
      ],
    );
  }

  Widget _buildDietMetadata(BuildContext context, DietMetadata metadata) {
    final fColors = FColors.of(context);
    final textStyle = (isCompact ? FTextStyles.caption_12 : FTextStyles.bodyS).copyWith(color: fColors.labelNormal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (metadata.mainIngredients.isNotEmpty)
          _buildMetadataRow(
            context,
            '주요 재료',
            metadata.mainIngredients.take(3).join(', ') +
                (metadata.mainIngredients.length > 3 ? ' 외 ${metadata.mainIngredients.length - 3}개' : ''),
            textStyle,
          ),
        if (metadata.foodCategory != null) _buildMetadataRow(context, '음식 분류', metadata.foodCategory!, textStyle),
        if (metadata.mealTime != null) _buildMetadataRow(context, '식사 시간', metadata.mealTime!, textStyle),
        if (metadata.estimatedCalories != null)
          _buildMetadataRow(context, '예상 칼로리', '약 ${metadata.estimatedCalories}kcal', textStyle),
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context, String label, String value, TextStyle textStyle) {
    final fColors = FColors.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isCompact ? 60 : 80,
            child: Text(
              '$label:',
              style: textStyle.copyWith(color: fColors.labelAssistive, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: textStyle, maxLines: isCompact ? 1 : 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
