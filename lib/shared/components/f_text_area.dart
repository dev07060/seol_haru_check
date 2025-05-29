import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

class FTextAreaConstants {
  static const double borderRadius = 4.0;
  static const double asteriskSpacing = 2.0;
  static const double asteriskBottomPadding = 4.0;
}

class FTextArea extends StatefulWidget {
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onEdditingComplete;
  final Function()? onTap;
  final AutovalidateMode? autoValidateMode;
  final String? hintText;
  final String? label;
  final TextInputType keyboardType;
  final bool isRequired;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final bool autoFocus;
  final String? errorText;
  final String? helperText;
  final bool _isContained;
  final int? maxLines;
  final int? minLines;

  const FTextArea._({
    super.key,
    this.focusNode,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onEdditingComplete,
    this.onTap,
    this.autoValidateMode = AutovalidateMode.onUnfocus,
    this.hintText,
    this.label,
    this.keyboardType = TextInputType.multiline,
    this.isRequired = false,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.textAlign,
    this.autoFocus = false,
    this.errorText,
    this.helperText,
    bool isContained = false,
    this.maxLines,
    this.minLines,
  }) : _isContained = isContained;

  // Normal factory constructor
  factory FTextArea({
    Key? key,
    FocusNode? focusNode,
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    Function()? onEdditingComplete,
    Function()? onTap,
    TextInputType keyboardType = TextInputType.multiline,
    AutovalidateMode? autoValidateMode,
    String? hintText,
    String? label,
    bool isRequired = false,
    bool enabled = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextAlign? textAlign,
    bool autoFocus = false,
    String? errorText,
    String? helperText,
    int? maxLines,
    int? minLines,
  }) {
    return FTextArea._(
      key: key,
      focusNode: focusNode,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEdditingComplete: onEdditingComplete,
      onTap: onTap,
      autoValidateMode: autoValidateMode,
      hintText: hintText,
      label: label,
      isRequired: isRequired,
      enabled: enabled,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      autoFocus: autoFocus,
      errorText: errorText,
      helperText: helperText,
      maxLines: maxLines,
      minLines: minLines,
      isContained: false,
    );
  }

  // Contained factory constructor
  factory FTextArea.contained({
    Key? key,
    FocusNode? focusNode,
    TextEditingController? controller,
    FormFieldValidator<String>? validator,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    Function()? onEdditingComplete,
    Function()? onTap,
    AutovalidateMode? autoValidateMode,
    String? hintText,
    String? label,
    bool isRequired = false,
    bool enabled = true,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    Widget? counter,
    TextAlign? textAlign,
    bool autoFocus = false,
    String? errorText,
    String? helperText,
    int? maxLines,
    int? minLines,
  }) {
    return FTextArea._(
      key: key,
      focusNode: focusNode,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEdditingComplete: onEdditingComplete,
      onTap: onTap,
      autoValidateMode: autoValidateMode,
      hintText: hintText,
      label: label,
      isRequired: isRequired,
      enabled: enabled,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      autoFocus: autoFocus,
      errorText: errorText,
      helperText: helperText,
      maxLines: maxLines,
      minLines: minLines,
      isContained: true,
    );
  }

  @override
  State<FTextArea> createState() => _FTextAreaState();
}

class _FTextAreaState extends State<FTextArea> {
  String? _errorText;
  bool _isFocused = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _errorText = widget.errorText;
    widget.focusNode?.addListener(_handleFocusChange);
    _isFocused = widget.focusNode?.hasFocus ?? false;
    _currentLength = widget.controller?.text.length ?? 0;
    widget.controller?.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(FTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      widget.focusNode?.addListener(_handleFocusChange);
      _isFocused = widget.focusNode?.hasFocus ?? false;
    }
    // controller가 변경된 경우 리스너 재설정
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChanged);
      widget.controller?.addListener(_handleTextChanged);
      _currentLength = widget.controller?.text.length ?? 0;
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    widget.controller?.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {
        _currentLength = widget.controller?.text.length ?? 0;
      });
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode?.hasFocus ?? false;
      });
    }
  }

  // 상태에 따른 색상을 반환하는 함수
  Color _getTextColor(BuildContext context) {
    final colors = FColors.of(context);

    // Error가 있는 경우
    if (_errorText != null && _errorText!.isNotEmpty) {
      return colors.statusNegative;
    }
    // Focus된 상태
    if (_isFocused) {
      return colors.labelNormal;
    }
    // 기본 상태 (Unfocused)
    return colors.labelAssistive;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const Gap(8),
        SizedBox(
          height: 164,
          child: TextFormField(
            cursorHeight: 16,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            focusNode: widget.focusNode,
            maxLength: widget.maxLength,
            textAlignVertical: TextAlignVertical.top,
            textAlign: widget.textAlign ?? TextAlign.start,
            validator: (value) {
              if (widget.validator != null) {
                final error = widget.validator!(value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _errorText != error) {
                    setState(() {
                      _errorText = error;
                    });
                  }
                });
                return error; // error를 실제로 반환
              }
              return null;
            },
            enabled: widget.enabled,
            autofocus: widget.autoFocus,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEdditingComplete,
            autovalidateMode: widget.autoValidateMode,
            controller: widget.controller,
            cursorColor: FColors.of(context).lineStrong,
            keyboardType: widget.keyboardType,
            style: FTextStyles.bodyL.r.copyWith(
              color: widget.enabled ? FColors.of(context).labelNormal : FColors.of(context).labelAssistive,
            ),
            maxLines: widget.maxLines, // maxLines 설정
            minLines: widget.minLines, // minLines 설정
            expands: true,
            decoration: _buildInputDecoration(),
          ),
        ),
        const Gap(8),
        _buildStatusText(),
      ],
    );
  }

  Widget _buildLabel() {
    if (widget.label == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label!, style: FTextStyles.bodyM.copyWith(color: FColors.of(context).labelNormal)),
            if (widget.isRequired) ...[
              const Gap(FTextAreaConstants.asteriskSpacing),
              Column(
                children: [
                  Text(
                    '*',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: FTextStyles.bodyS.b.copyWith(color: FColors.of(context).statusNegative),
                  ),
                  const Gap(FTextAreaConstants.asteriskBottomPadding),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    final colors = FColors.of(context);

    if (widget.maxLength != null || _errorText != null && _errorText!.isNotEmpty || widget.helperText != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Error Text나 Helper Text 표시
          if (_errorText != null && _errorText!.isNotEmpty)
            Text(
              _errorText!,
              style: FTextStyles.bodyS.copyWith(color: colors.statusNegative),
              textAlign: TextAlign.start,
            )
          else if (widget.helperText != null)
            Text(
              widget.helperText!,
              style: FTextStyles.bodyS.copyWith(color: colors.labelAlternative),
              textAlign: TextAlign.start,
            )
          else
            const SizedBox(), // errorText나 helperText가 없을 때 빈 공간
          // MaxLength 표시 (항상 오른쪽)
          if (widget.maxLength != null)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _currentLength.toString(),
                    style: FTextStyles.bodyS.r.copyWith(color: _getTextColor(context)),
                  ),
                  TextSpan(
                    text: ' /${widget.maxLength}',
                    style: FTextStyles.bodyS.r.copyWith(color: FColors.of(context).labelAssistive),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  InputDecoration _buildInputDecoration() {
    final colors = FColors.of(context);
    if (widget._isContained) {
      return InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        isDense: true,
        counter: const SizedBox.shrink(),
        errorMaxLines: 1,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: colors.labelAssistive),
        errorStyle: const TextStyle(color: Colors.transparent, fontSize: 0, height: 0.0),
        filled: true,
        fillColor: widget.enabled ? colors.solidAssistive : colors.solidDisable,
        enabled: widget.enabled,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
        ),
      );
    }

    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      isDense: true,
      counter: const SizedBox.shrink(),
      errorMaxLines: 1,
      hintText: widget.hintText,
      hintStyle: TextStyle(color: colors.labelAssistive),
      errorStyle: const TextStyle(color: Colors.transparent, fontSize: 0, height: 0.0),
      filled: !widget.enabled,
      fillColor: widget.enabled ? null : colors.solidDisable,
      enabled: widget.enabled,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colors.lineNormal, width: 1),
        borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.lineAlternative, width: 1),
        borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.lineNormal, width: 1),
        borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.statusNegative, width: 1),
        borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.lineAlternative, width: 1),
        borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.statusNegative, width: 1),
        borderRadius: BorderRadius.circular(FTextAreaConstants.borderRadius),
      ),
    );
  }
}
