import 'package:flutter/material.dart';

// context extension
// how to use
// context.isBrightness
// ex) context.isBrightness? return const Placeholder() : return const Placeholder();
extension BuildContextExtensions on BuildContext {
  bool get isBrightness {
    Brightness brightnessValue = Theme.of(this).brightness;

    return brightnessValue == Brightness.light;
  }
}
