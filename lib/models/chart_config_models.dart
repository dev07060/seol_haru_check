import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Chart theme configuration that integrates with SPColors system
class ChartTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color gridColor;
  final Color borderColor;
  final TextStyle labelStyle;
  final TextStyle titleStyle;
  final TextStyle tooltipStyle;
  final List<Color> categoryColors;

  const ChartTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.gridColor,
    required this.borderColor,
    required this.labelStyle,
    required this.titleStyle,
    required this.tooltipStyle,
    required this.categoryColors,
  });

  /// Create chart theme from context using SPColors
  factory ChartTheme.fromContext(BuildContext context) {
    return ChartTheme(
      primaryColor: SPColors.podGreen,
      secondaryColor: SPColors.podBlue,
      backgroundColor: SPColors.backgroundColor(context),
      textColor: SPColors.textColor(context),
      gridColor: SPColors.gray200,
      borderColor: SPColors.gray300,
      labelStyle: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
      titleStyle: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context)),
      tooltipStyle: FTextStyles.body3_13.copyWith(color: SPColors.white),
      categoryColors: [
        SPColors.podGreen,
        SPColors.podBlue,
        SPColors.podOrange,
        SPColors.podPurple,
        SPColors.podPink,
        SPColors.podMint,
        SPColors.podLightGreen,
      ],
    );
  }

  /// Create light theme variant
  factory ChartTheme.light() {
    return ChartTheme(
      primaryColor: SPColors.podGreen,
      secondaryColor: SPColors.podBlue,
      backgroundColor: SPColors.white,
      textColor: SPColors.black,
      gridColor: SPColors.gray200,
      borderColor: SPColors.gray300,
      labelStyle: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
      titleStyle: FTextStyles.title3_18.copyWith(color: SPColors.black),
      tooltipStyle: FTextStyles.body3_13.copyWith(color: SPColors.white),
      categoryColors: [
        SPColors.podGreen,
        SPColors.podBlue,
        SPColors.podOrange,
        SPColors.podPurple,
        SPColors.podPink,
        SPColors.podMint,
        SPColors.podLightGreen,
      ],
    );
  }

  /// Create dark theme variant
  factory ChartTheme.dark() {
    return ChartTheme(
      primaryColor: SPColors.podGreen,
      secondaryColor: SPColors.podBlue,
      backgroundColor: SPColors.black,
      textColor: SPColors.white,
      gridColor: SPColors.gray700,
      borderColor: SPColors.gray600,
      labelStyle: FTextStyles.body2_14.copyWith(color: SPColors.gray400),
      titleStyle: FTextStyles.title3_18.copyWith(color: SPColors.white),
      tooltipStyle: FTextStyles.body3_13.copyWith(color: SPColors.black),
      categoryColors: [
        SPColors.podGreen,
        SPColors.podBlue,
        SPColors.podOrange,
        SPColors.podPurple,
        SPColors.podPink,
        SPColors.podMint,
        SPColors.podLightGreen,
      ],
    );
  }

  /// Get color for category by index
  Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// Copy with modifications
  ChartTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? gridColor,
    Color? borderColor,
    TextStyle? labelStyle,
    TextStyle? titleStyle,
    TextStyle? tooltipStyle,
    List<Color>? categoryColors,
  }) {
    return ChartTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      gridColor: gridColor ?? this.gridColor,
      borderColor: borderColor ?? this.borderColor,
      labelStyle: labelStyle ?? this.labelStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      categoryColors: categoryColors ?? this.categoryColors,
    );
  }
}

/// Animation configuration for chart transitions
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final bool enableStagger;
  final Duration staggerDelay;
  final bool enableBounce;
  final double bounceIntensity;
  final bool enableMorphing;
  final Duration morphDuration;
  final bool enableParticles;
  final bool enableColorTransitions;
  final Duration colorTransitionDuration;

  const AnimationConfig({
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeInOut,
    this.enableStagger = true,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.enableBounce = false,
    this.bounceIntensity = 0.1,
    this.enableMorphing = true,
    this.morphDuration = const Duration(milliseconds: 800),
    this.enableParticles = true,
    this.enableColorTransitions = true,
    this.colorTransitionDuration = const Duration(milliseconds: 600),
  });

  /// Fast animation preset
  factory AnimationConfig.fast() {
    return const AnimationConfig(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
      enableStagger: false,
      staggerDelay: Duration(milliseconds: 50),
      enableMorphing: true,
      morphDuration: Duration(milliseconds: 400),
      enableParticles: false,
      enableColorTransitions: true,
      colorTransitionDuration: Duration(milliseconds: 300),
    );
  }

  /// Slow animation preset
  factory AnimationConfig.slow() {
    return const AnimationConfig(
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      enableStagger: true,
      staggerDelay: Duration(milliseconds: 150),
      enableMorphing: true,
      morphDuration: Duration(milliseconds: 1000),
      enableParticles: true,
      enableColorTransitions: true,
      colorTransitionDuration: Duration(milliseconds: 800),
    );
  }

  /// Bouncy animation preset
  factory AnimationConfig.bouncy() {
    return const AnimationConfig(
      duration: Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      enableStagger: true,
      staggerDelay: Duration(milliseconds: 100),
      enableBounce: true,
      bounceIntensity: 0.2,
      enableMorphing: true,
      morphDuration: Duration(milliseconds: 900),
      enableParticles: true,
      enableColorTransitions: true,
      colorTransitionDuration: Duration(milliseconds: 700),
    );
  }

  /// No animation preset
  factory AnimationConfig.none() {
    return const AnimationConfig(
      duration: Duration.zero,
      curve: Curves.linear,
      enableStagger: false,
      staggerDelay: Duration.zero,
      enableMorphing: false,
      morphDuration: Duration.zero,
      enableParticles: false,
      enableColorTransitions: false,
      colorTransitionDuration: Duration.zero,
    );
  }

  /// Category transition preset - optimized for smooth category changes
  factory AnimationConfig.categoryTransition() {
    return const AnimationConfig(
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      enableStagger: true,
      staggerDelay: Duration(milliseconds: 80),
      enableBounce: false,
      bounceIntensity: 0.0,
      enableMorphing: true,
      morphDuration: Duration(milliseconds: 600),
      enableParticles: false,
      enableColorTransitions: true,
      colorTransitionDuration: Duration(milliseconds: 500),
    );
  }

  /// Achievement celebration preset - with particles and bounce
  factory AnimationConfig.celebration() {
    return const AnimationConfig(
      duration: Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      enableStagger: true,
      staggerDelay: Duration(milliseconds: 120),
      enableBounce: true,
      bounceIntensity: 0.3,
      enableMorphing: true,
      morphDuration: Duration(milliseconds: 1000),
      enableParticles: true,
      enableColorTransitions: true,
      colorTransitionDuration: Duration(milliseconds: 800),
    );
  }

  /// Copy with modifications
  AnimationConfig copyWith({
    Duration? duration,
    Curve? curve,
    bool? enableStagger,
    Duration? staggerDelay,
    bool? enableBounce,
    double? bounceIntensity,
    bool? enableMorphing,
    Duration? morphDuration,
    bool? enableParticles,
    bool? enableColorTransitions,
    Duration? colorTransitionDuration,
  }) {
    return AnimationConfig(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      enableStagger: enableStagger ?? this.enableStagger,
      staggerDelay: staggerDelay ?? this.staggerDelay,
      enableBounce: enableBounce ?? this.enableBounce,
      bounceIntensity: bounceIntensity ?? this.bounceIntensity,
      enableMorphing: enableMorphing ?? this.enableMorphing,
      morphDuration: morphDuration ?? this.morphDuration,
      enableParticles: enableParticles ?? this.enableParticles,
      enableColorTransitions: enableColorTransitions ?? this.enableColorTransitions,
      colorTransitionDuration: colorTransitionDuration ?? this.colorTransitionDuration,
    );
  }
}

/// Chart error types for better error handling
enum ChartErrorType { dataProcessing, rendering, animation, interaction, export }

/// Chart error model
class ChartError {
  final ChartErrorType type;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const ChartError({required this.type, required this.message, this.originalError, this.stackTrace});

  @override
  String toString() {
    return 'ChartError(type: $type, message: $message)';
  }
}
