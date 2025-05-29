import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/shared/custom/f_bounceable.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/shared/themes/f_font_weight.dart';

enum FSolidButtonSize { large, medium, small }

enum FSolidButtonVariant { primary, secondary, assistive }

/// 다음 프로젝트에서는 borderRadius를 입력받지 않는 것으로 수정.
/// 현재 프로젝트에서 사용하는 부분이 있어 그대로 유지
class FSolidButton extends StatefulWidget {
  const FSolidButton._({
    super.key,
    required this.text,
    required this.onPressed,
    required this.variant,
    this.width,
    this.suffixPath,
    this.prefixPath,
    this.disabled = false,
    this.size = FSolidButtonSize.medium,
    this.borderRadius,
  });

  // Primary Button Factory Constructor
  factory FSolidButton.primary({
    Key? key,
    required String text,
    required FutureOr<void> Function()? onPressed,
    double? width,
    String? suffixPath,
    String? prefixPath,
    bool disabled = false,
    FSolidButtonSize size = FSolidButtonSize.medium,
    double? borderRadius,
  }) {
    return FSolidButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: FSolidButtonVariant.primary,
      width: width,
      suffixPath: suffixPath,
      prefixPath: prefixPath,
      disabled: disabled,
      size: size,
      borderRadius: borderRadius,
    );
  }

  // Secondary Button Factory Constructor
  factory FSolidButton.secondary({
    Key? key,
    required String text,
    required FutureOr<void> Function()? onPressed,
    double? width,
    String? suffixPath,
    String? prefixPath,
    bool disabled = false,
    FSolidButtonSize size = FSolidButtonSize.medium,
    double? borderRadius,
  }) {
    return FSolidButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: FSolidButtonVariant.secondary,
      width: width,
      suffixPath: suffixPath,
      prefixPath: prefixPath,
      disabled: disabled,
      size: size,
      borderRadius: borderRadius,
    );
  }

  // Assistive Button Factory Constructor
  factory FSolidButton.assistive({
    Key? key,
    required String text,
    required FutureOr<void> Function()? onPressed,
    double? width,
    String? suffixPath,
    String? prefixPath,
    bool disabled = false,
    FSolidButtonSize size = FSolidButtonSize.medium,
    double? borderRadius,
  }) {
    return FSolidButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: FSolidButtonVariant.assistive,
      width: width,
      suffixPath: suffixPath,
      prefixPath: prefixPath,
      disabled: disabled,
      size: size,
      borderRadius: borderRadius,
    );
  }

  final String text;
  final double? width;
  final String? suffixPath;
  final String? prefixPath;
  final bool disabled;
  final FutureOr<void> Function()? onPressed;
  final FSolidButtonSize size;
  final double? borderRadius;
  final FSolidButtonVariant variant;

  @override
  State<FSolidButton> createState() => _FSolidButtonState();
}

class _FSolidButtonState extends State<FSolidButton> {
  /// 내부 플래그
  bool _isActionInProgress = false;

  Future<void> _handleAction(FutureOr<void> Function()? action) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      await action?.call();
    } finally {
      _isActionInProgress = false;
    }
  }

  Color _bgColor() {
    if (widget.disabled) {
      return FColors.of(context).solidDisable;
    }

    switch (widget.variant) {
      case FSolidButtonVariant.primary:
        return FColors.of(context).solidStrong;
      case FSolidButtonVariant.secondary:
        return FColors.of(context).solidAlternative;
      case FSolidButtonVariant.assistive:
        return FColors.of(context).solidAssistive;
    }
  }

  Color _textColor() {
    if (widget.disabled) {
      return FColors.of(context).labelDisable;
    }

    switch (widget.variant) {
      case FSolidButtonVariant.primary:
        return FColors.of(context).inverseStrong;
      case FSolidButtonVariant.secondary:
        return FColors.of(context).labelNormal;
      case FSolidButtonVariant.assistive:
        return FColors.of(context).labelNormal;
    }
  }

  double _fixedHeight() {
    switch (widget.size) {
      case FSolidButtonSize.large:
        return 52;
      case FSolidButtonSize.medium:
        return 48;
      case FSolidButtonSize.small:
        return 32;
    }
  }

  double _horizontalPadding() {
    switch (widget.size) {
      case FSolidButtonSize.large:
        return 20;
      case FSolidButtonSize.medium:
        return 18;
      case FSolidButtonSize.small:
        return 14;
    }
  }

  TextStyle _textStyle() {
    final FontWeight fontWeight = widget.variant == FSolidButtonVariant.primary ? FFontWeight.bold : FFontWeight.medium;

    switch (widget.size) {
      case FSolidButtonSize.large:
        return FTextStyles.bodyXL.copyWith(color: _textColor(), fontWeight: fontWeight);
      case FSolidButtonSize.medium:
        return FTextStyles.bodyL.copyWith(color: _textColor(), fontWeight: fontWeight);
      case FSolidButtonSize.small:
        return FTextStyles.bodyM.copyWith(color: _textColor(), fontWeight: fontWeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FBounceable(
      onTap: widget.disabled ? () {} : () => _handleAction(widget.onPressed),
      child: Container(
        decoration: BoxDecoration(color: _bgColor(), borderRadius: BorderRadius.circular(widget.borderRadius ?? 4)),
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding()),
        constraints: BoxConstraints(
          minHeight: _fixedHeight(),
          maxHeight: _fixedHeight(),
          minWidth: widget.width ?? double.infinity,
          maxWidth: widget.width ?? double.infinity,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.prefixPath != null) ...[
              SPSvg.asset(widget.prefixPath!, width: 16, color: _textColor()),
              const Gap(4),
            ],
            Text(widget.text, style: _textStyle()),
            if (widget.suffixPath != null) ...[
              const Gap(4),
              SPSvg.asset(widget.suffixPath!, width: 16, color: _textColor()),
            ],
          ],
        ),
      ),
    );
  }
}
