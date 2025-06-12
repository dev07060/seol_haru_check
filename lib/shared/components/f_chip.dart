import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/shared/themes/f_font_weight.dart';

/// outline, solid chip 위젯입니다.
/// [suffixIconPath]를 통해 아이콘을 추가할 수 있습니다.
class FChip extends StatelessWidget {
  const FChip({
    super.key,
    required this.label,
    this.suffixIcon,
    required this.isOutlined,
    this.isSelected = false,
    this.isDisabled = false,
    required this.onTap,
  });

  final String label;
  final Widget? suffixIcon;
  final bool isOutlined;
  final bool isSelected;
  final bool isDisabled;
  final GestureTapCallback onTap;

  factory FChip.solid({
    required String label,
    bool isSelected = false,
    bool isDisabled = false,
    Widget? suffixIcon,
    required GestureTapCallback onTap,
  }) {
    return FChip(
      label: label,
      isOutlined: false,
      isSelected: isSelected,
      isDisabled: isDisabled,
      onTap: onTap,
      suffixIcon: suffixIcon,
    );
  }

  factory FChip.outline({
    required String label,
    bool isSelected = false,
    bool isDisabled = false,
    Widget? suffixIcon,
    required GestureTapCallback onTap,
  }) {
    return FChip(
      label: label,
      isOutlined: true,
      isSelected: isSelected,
      isDisabled: isDisabled,
      onTap: onTap,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    late final Color? bgColor;
    late final Border? border;
    late final Color fontColor;
    late final FontWeight fontWeight;

    if (isOutlined) {
      fontColor =
          isDisabled
              ? FColors.of(context).labelDisable
              : isSelected
              ? FColors.of(context).labelStrong
              : FColors.of(context).labelNormal;
      bgColor = isDisabled ? FColors.of(context).solidDisable : null;
      border = Border.all(
        color:
            isDisabled
                ? FColors.of(context).lineAlternative
                : isSelected
                ? FColors.of(context).lineStrong
                : FColors.of(context).lineAlternative,
      );
    } else {
      fontColor =
          isDisabled
              ? FColors.of(context).labelDisable
              : isSelected
              ? FColors.of(context).inverseStrong
              : FColors.of(context).labelNormal;
      bgColor =
          isDisabled
              ? FColors.of(context).solidDisable
              : isSelected
              ? FColors.of(context).solidStrong
              : FColors.of(context).backgroundNormalN;
      border = null;
    }

    if (isDisabled) {
      fontWeight = FFontWeight.regular;
    } else if (isSelected) {
      fontWeight = FFontWeight.medium;
    } else {
      fontWeight = FFontWeight.regular;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: border, color: bgColor),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: FTextStyles.bodyL.copyWith(color: fontColor, fontWeight: fontWeight)),
            if (suffixIcon != null) ...[const Gap(4), suffixIcon!],
          ],
        ),
      ),
    );
  }
}
