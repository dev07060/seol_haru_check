import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/shared/custom/f_bounceable.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

enum FOutlinedButtonSize { large, medium, small }

enum FOutlinedButtonVariant { primary, secondary, assistive }

class FOutlinedButton extends StatefulWidget {
  const FOutlinedButton._({
    super.key,
    required this.text,
    required this.onPressed,
    required this.variant,
    this.width,
    this.suffixPath,
    this.prefixPath,
    this.disabled = false,
    this.size = FOutlinedButtonSize.medium,
    this.color,
    this.borderRadius,
  });

  // Primary Button Factory Constructor
  factory FOutlinedButton.primary({
    Key? key,
    required String text,
    required FutureOr<void> Function() onPressed,
    double? width,
    String? suffixPath,
    String? prefixPath,
    bool disabled = false,
    FOutlinedButtonSize size = FOutlinedButtonSize.medium,
    double? borderRadius,
  }) {
    return FOutlinedButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: FOutlinedButtonVariant.primary,
      width: width,
      suffixPath: suffixPath,
      prefixPath: prefixPath,
      disabled: disabled,
      size: size,
      borderRadius: borderRadius,
    );
  }

  // Secondary Button Factory Constructor
  factory FOutlinedButton.secondary({
    Key? key,
    required String text,
    required FutureOr<void> Function() onPressed,
    double? width,
    String? suffixPath,
    String? prefixPath,
    bool disabled = false,
    FOutlinedButtonSize size = FOutlinedButtonSize.medium,
    double? borderRadius,
  }) {
    return FOutlinedButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: FOutlinedButtonVariant.secondary,
      width: width,
      suffixPath: suffixPath,
      prefixPath: prefixPath,
      disabled: disabled,
      size: size,
      borderRadius: borderRadius,
    );
  }

  // Assistive Button Factory Constructor
  factory FOutlinedButton.assistive({
    Key? key,
    required String text,
    required FutureOr<void> Function() onPressed,
    double? width,
    String? suffixPath,
    String? prefixPath,
    bool disabled = false,
    FOutlinedButtonSize size = FOutlinedButtonSize.medium,
    Color? color,
    double? borderRadius,
  }) {
    return FOutlinedButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: FOutlinedButtonVariant.assistive,
      width: width,
      suffixPath: suffixPath,
      prefixPath: prefixPath,
      disabled: disabled,
      size: size,
      color: color,
      borderRadius: borderRadius,
    );
  }

  final String text;
  final double? width;
  final String? suffixPath;
  final String? prefixPath;
  final bool disabled;
  final FutureOr<void> Function() onPressed;
  final FOutlinedButtonSize size;
  final FOutlinedButtonVariant variant;
  final Color? color;
  final double? borderRadius;

  @override
  State<FOutlinedButton> createState() => _FOutlinedButtonState();
}

class _FOutlinedButtonState extends State<FOutlinedButton> {
  bool isPressed = false;

  /// 내부 플래그
  bool _isActionInProgress = false;

  Future<void> _handleAction(FutureOr<void> Function() action) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      await action();
    } finally {
      _isActionInProgress = false;
    }
  }

  double _fixedHeight() {
    switch (widget.size) {
      case FOutlinedButtonSize.large:
        return 52;
      case FOutlinedButtonSize.medium:
        return 48;
      case FOutlinedButtonSize.small:
        return 32;
    }
  }

  double _horizontalPadding() {
    switch (widget.size) {
      case FOutlinedButtonSize.large:
        return 20;
      case FOutlinedButtonSize.medium:
        return 18;
      case FOutlinedButtonSize.small:
        return 14;
    }
  }

  Color _borderColor() {
    if (widget.disabled) {
      return FColors.of(context).lineAlternative;
    }

    switch (widget.variant) {
      case FOutlinedButtonVariant.primary:
        return FColors.of(context).lineStrong;
      case FOutlinedButtonVariant.secondary:
        return FColors.of(context).lineAlternative;
      case FOutlinedButtonVariant.assistive:
        return widget.color ?? FColors.of(context).fiet;
    }
  }

  Color _contentColor() {
    if (widget.disabled) {
      return FColors.of(context).labelDisable;
    }

    switch (widget.variant) {
      case FOutlinedButtonVariant.primary:
        return FColors.of(context).labelStrong;
      case FOutlinedButtonVariant.secondary:
        return FColors.of(context).labelStrong;
      case FOutlinedButtonVariant.assistive:
        return widget.color ?? FColors.of(context).fiet;
    }
  }

  TextStyle _textStyle() {
    switch (widget.size) {
      case FOutlinedButtonSize.large:
        return FTextStyles.bodyXL.copyWith(color: _contentColor());
      case FOutlinedButtonSize.medium:
        return FTextStyles.bodyL.copyWith(color: _contentColor());
      case FOutlinedButtonSize.small:
        return FTextStyles.bodyM.copyWith(color: _contentColor());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FBounceable(
      onTap: widget.disabled ? () {} : () => _handleAction(widget.onPressed),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding()),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 4.0),
          border: Border.all(color: widget.disabled ? FColors.of(context).lineAlternative : _borderColor()),
        ),
        constraints: BoxConstraints(minHeight: _fixedHeight(), maxHeight: _fixedHeight()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.prefixPath != null) ...[
              SPSvg.asset(widget.prefixPath!, width: 16, color: _contentColor()),
              const Gap(4),
            ],
            Text(widget.text, style: _textStyle()),
            if (widget.suffixPath != null) ...[
              const Gap(4),
              SPSvg.asset(widget.suffixPath!, width: 16, color: _contentColor()),
            ],
          ],
        ),
      ),
    );
  }
}
