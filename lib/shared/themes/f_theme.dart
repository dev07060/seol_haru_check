import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seol_haru_check/shared/extentions/context_extension.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';

// 사용 예제 코드
// return MaterialApp.router(
//   debugShowCheckedModeBanner: false,
//   routerConfig: AppRouter().router,
//   themeMode: FTheme.lightMode,
//   theme: FTheme.light,
//   darkTheme: FTheme.dark,
// );

// FTheme.lightMode, FTheme.darkMode의 상태관리 필요
// light theme, dark theme 구분해서 각각 필요한 요소들 추가 가능
class FTheme {
  static String get defaultFontFamily => 'Pretendard';

  // 이모지와 한글을 위한 폰트 fallback 리스트
  static List<String> get fontFamilyFallback => [
    'Pretendard',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'Noto Sans',
    'sans-serif',
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
    'Noto Color Emoji',
  ];

  static TextTheme get lightTextTheme =>
      ThemeData.light().textTheme.apply(fontFamily: defaultFontFamily, fontFamilyFallback: fontFamilyFallback);

  static TextTheme get darkTextTheme =>
      ThemeData.dark().textTheme.apply(fontFamily: defaultFontFamily, fontFamilyFallback: fontFamilyFallback);

  static ThemeData light(context) => ThemeData.light().copyWith(
    textTheme: lightTextTheme,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark, // Light Mode에서 상태 표시줄 아이콘을 어둡게
    ),
    scaffoldBackgroundColor: FColors.of(context).lightNormalN,
  );

  static ThemeData dark(context) => ThemeData.dark().copyWith(
    textTheme: darkTextTheme,
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light, // Dark Mode에서 상태 표시줄 아이콘을 밝게
    ),
    scaffoldBackgroundColor: FColors.of(context).darkNormalN,
  );

  static bool isLightMode(BuildContext context) {
    return context.isBrightness;
  }
}
