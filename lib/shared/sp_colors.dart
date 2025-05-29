import 'package:flutter/material.dart';

class SPColors {
  SPColors._(); // private constructor to prevent instantiation

  // Brand Colors
  static const Color podGreen = Color(0xFFCFEF4F);
  static const Color podBlue = Color(0xFF91DEF8);
  static const Color podOrange = Color(0xFFFFDBA1);
  static const Color podPurple = Color(0xFFF0CFFF);
  static const Color podPink = Color(0xFFFFCFD6);
  static const Color podMint = Color(0xFFBBF6E2);
  static const Color podLightGreen = Color(0xEED0EE4E);

  // Grayscale Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray100 = Color(0xFFF9FAFB);
  static const Color gray200 = Color(0xFFF0F2F4);
  static const Color gray300 = Color(0xFFE2E4E9);
  static const Color gray400 = Color(0xFFD3D6DE);
  static const Color gray500 = Color(0xFFC5CAD3);
  static const Color gray600 = Color(0xFFA8AFBD);
  static const Color gray700 = Color(0xFF8B95A7);
  static const Color gray800 = Color(0xFF6E7A91);
  static const Color gray900 = Color(0xFF586274);
  static const Color gray1000 = Color(0xFF424957);
  static const Color black = Color(0xFF000000);

  // Shadow && Social Login Button Colors
  static const Color shadow = Color(0xEE16181D);

  // Additional Colors
  static const Color danger100 = Color(0xFFFC5555);
  static const Color success100 = Color(0xFF29CC6A);

  // Method to get color based on brightness
  static Color getColor(BuildContext context, Color lightColor, Color darkColor) {
    return Theme.of(context).brightness == Brightness.light ? lightColor : darkColor;
  }

  // Example of how to use getColor method for dynamic theming
  static Color backgroundColor(BuildContext context) {
    return getColor(context, white, black);
  }

  static Color textColor(BuildContext context) {
    return getColor(context, black, white);
  }
}
