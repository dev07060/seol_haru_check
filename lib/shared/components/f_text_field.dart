import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// FTextField
/// [prefixIcon], [suffixIcon]에 Row 사용시 [MainAxisSize.min] 사용
class FTextField extends StatefulWidget {
  const FTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.focusNode,
    this.textInputType,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.textStyle,
    this.hintStyle,
    this.fillColor,
    this.borderColor,
    this.focusBorderColor,
    this.borderRadius,
    this.inputFormatters,
    this.counterText,
    this.textAlign = TextAlign.start,
    this.contentPadding,
    this.isEnabled = true,
    this.autoValidateMode,
    this.onEditingComplete,
    this.validator,
    this.helperText,
    this.isContained = false,
    this.isRequired = false,
    this.label,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool obscureText;
  final FocusNode? focusNode;
  final TextInputType? textInputType;
  final int? maxLength;
  final int maxLines;
  final int minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final BorderRadius? borderRadius;
  final List<TextInputFormatter>? inputFormatters;
  final String? counterText;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;
  final bool isEnabled;
  final AutovalidateMode? autoValidateMode;
  final Function()? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final bool isContained;
  final bool isRequired;
  final String? label;

  factory FTextField.contained({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    bool obscureText = false,
    FocusNode? focusNode,
    TextInputType? textInputType,
    int? maxLength,
    int maxLines = 1,
    int minLines = 1,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool autofocus = false,
    TextStyle? textStyle,
    TextStyle? hintStyle,
    Color? fillColor,
    BorderRadius? borderRadius,
    List<TextInputFormatter>? inputFormatters,
    String? counterText,
    TextAlign textAlign = TextAlign.start,
    EdgeInsetsGeometry? contentPadding,
    bool isEnabled = true,
    AutovalidateMode? autoValidateMode,
    Function()? onEditingComplete,
    FormFieldValidator<String>? validator,
    String? helperText,
    bool isRequired = false,
    String? label,
  }) {
    return FTextField(
      key: key,
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      focusNode: focusNode,
      textInputType: textInputType,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      autofocus: autofocus,
      textStyle: textStyle,
      hintStyle: hintStyle,
      fillColor: fillColor,
      borderRadius: borderRadius,
      inputFormatters: inputFormatters,
      counterText: counterText,
      textAlign: textAlign,
      contentPadding: contentPadding,
      isEnabled: isEnabled,
      autoValidateMode: autoValidateMode,
      onEditingComplete: onEditingComplete,
      validator: validator,
      helperText: helperText,
      isContained: true,
      isRequired: isRequired,
      label: label,
    );
  }

  @override
  State<FTextField> createState() => _FTextFieldState();
}

class _FTextFieldState extends State<FTextField> {
  TextStyle get _textStyle =>
      widget.textStyle ??
      FTextStyles.body2_14.r.copyWith(
        color: widget.isEnabled ? FColors.of(context).labelNormal : FColors.of(context).labelDisable,
      );

  BorderRadius get _borderRadius => widget.borderRadius ?? BorderRadius.circular(4);

  Color get _fillColor =>
      widget.fillColor ?? (widget.isContained ? FColors.of(context).solidAssistive : Colors.transparent);

  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[_buildLabel(), const Gap(8)],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.isEnabled,
          cursorColor: FColors.of(context).lineStrong,
          cursorErrorColor: FColors.of(context).statusNegative,
          keyboardType: widget.textInputType,
          textAlignVertical: TextAlignVertical.center,
          textAlign: widget.textAlign,
          style: _textStyle,
          inputFormatters: widget.inputFormatters,
          decoration: _inputDecoration,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          autofocus: widget.autofocus,
          obscureText: widget.obscureText,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          autovalidateMode: widget.autoValidateMode ?? AutovalidateMode.onUnfocus,
          validator: _validator,
        ),
        if (widget.helperText != null && _errorText == null) ...[
          const Gap(8),
          Text(widget.helperText!, style: FTextStyles.body4_12.r.copyWith(color: FColors.of(context).labelAlternative)),
        ],
      ],
    );
  }

  /// inputDecoration
  InputDecoration get _inputDecoration {
    return InputDecoration(
      hintText: widget.hintText,
      hintStyle:
          widget.hintStyle ??
          _textStyle.copyWith(
            color: widget.isEnabled ? FColors.of(context).labelAssistive : FColors.of(context).labelDisable,
          ),
      border: _outlinedInputBorder(FColors.of(context).lineNormal),
      enabledBorder: _outlinedInputBorder(FColors.of(context).lineAlternative),
      disabledBorder: _outlinedInputBorder(FColors.of(context).lineAlternative),
      focusedBorder: _outlinedInputBorder(FColors.of(context).lineNormal),
      errorBorder: _outlinedInputBorder(FColors.of(context).statusNegative),
      focusedErrorBorder: _outlinedInputBorder(FColors.of(context).statusNegative),
      contentPadding: widget.contentPadding ?? const EdgeInsets.all(12),
      error: _buildError(),
      prefixIcon:
          widget.prefixIcon == null
              ? null
              : Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: widget.prefixIcon),
      suffixIcon:
          widget.suffixIcon == null
              ? null
              : Padding(padding: const EdgeInsets.only(left: 8, right: 12), child: widget.suffixIcon),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: widget.isEnabled ? _fillColor : FColors.of(context).solidDisable,
      isCollapsed: true,
      counterText: widget.counterText,
    );
  }

  /// 에러 위젯
  Widget? _buildError() {
    if (_errorText == null) return null;

    return Transform.translate(
      offset: const Offset(-12, 0),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_errorText!, style: FTextStyles.body4_12.r.copyWith(color: FColors.of(context).statusNegative)),
      ),
    );
  }

  /// 검증 함수
  /// _errorText 활용해 custom error 사용하기 때문에 null 리턴
  String? _validator(value) {
    _errorText = widget.validator?.call(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    return null;
  }

  /// 라벨 위젯
  Widget _buildLabel() {
    if (widget.label == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label!, style: FTextStyles.body3_13.copyWith(color: FColors.of(context).labelNormal)),
        if (widget.isRequired) ...[
          const Gap(2),
          Text(
            '*',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            style: FTextStyles.body4_12.b.copyWith(color: FColors.of(context).statusNegative),
          ),
        ],
      ],
    );
  }

  /// 테두리
  OutlineInputBorder _outlinedInputBorder(Color color) {
    switch (widget.isContained) {
      case true:
        return OutlineInputBorder(borderSide: BorderSide.none, borderRadius: _borderRadius);
      case false:
        return OutlineInputBorder(borderSide: BorderSide(color: color), borderRadius: _borderRadius);
    }
  }
}
