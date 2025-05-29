import 'dart:ui' as ui show FontFeature, FontVariation, Shadow, TextLeadingDistribution;

import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/themes/f_font_weight.dart';

class FTextStyle extends TextStyle {
  final double _fontSize;
  final FontWeight _fontWeight;
  final double lineHeight;

  FTextStyle({
    required FontWeight super.fontWeight,
    required double super.fontSize,
    required this.lineHeight,
    super.color,
    double? height,
    super.decoration,
    super.decorationStyle,
    super.decorationColor,
    List<ui.FontFeature> fontFeatures = const [],
  }) : _fontSize = fontSize,
       _fontWeight = fontWeight,
       super(height: height ?? lineHeight / fontSize, fontFamily: 'Pretendard', fontFeatures: [...fontFeatures]);

  /// [color], [fontWeight] 외의 요소를 사용하려면, 해당 기능을 추가해야 한다.
  @override
  FTextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? surface,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) => FTextStyle(
    fontSize: fontSize ?? _fontSize,
    fontWeight: fontWeight ?? _fontWeight,
    lineHeight: lineHeight,
    color: color,
    height: height,
    fontFeatures: fontFeatures ?? [],
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
  );

  //* figma상의 명칭에 맞춰서 단축어로 작성하였습니다.
  FTextStyle get eb => copyWith(fontWeight: FFontWeight.extraBold);
  FTextStyle get b => copyWith(fontWeight: FFontWeight.bold);
  FTextStyle get sb => copyWith(fontWeight: FFontWeight.semiBold);
  FTextStyle get m => copyWith(fontWeight: FFontWeight.medium);
  FTextStyle get r => copyWith(fontWeight: FFontWeight.regular);
}
