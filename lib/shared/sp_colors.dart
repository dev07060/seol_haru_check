import 'package:flutter/material.dart';

class SPColors {
  SPColors._(); // private constructor to prevent instantiation

  // Brand Colors (Original Pastel)
  static const Color podGreen = Color(0xFFCFEF4F);
  static const Color podBlue = Color(0xFF91DEF8);
  static const Color podOrange = Color(0xFFFFDBA1);
  static const Color podPurple = Color(0xFFF0CFFF);
  static const Color podPink = Color(0xFFFFCFD6);
  static const Color podMint = Color(0xFFBBF6E2);
  static const Color podLightGreen = Color(0xEED0EE4E);

  // Enhanced Colors for Reports (Deeper, More Vibrant)
  static const Color reportGreen = Color(0xFF4CAF50); // 활력적인 녹색 (근력운동)
  static const Color reportBlue = Color(0xFF2196F3); // 시원한 파란색 (유산소)
  static const Color reportOrange = Color(0xFFFF9800); // 에너지 넘치는 주황색 (스트레칭)
  static const Color reportPurple = Color(0xFF9C27B0); // 집중력을 높이는 보라색 (요가)
  static const Color reportRed = Color(0xFFE91E63); // 열정적인 빨간색 (고강도 운동)
  static const Color reportTeal = Color(0xFF009688); // 차분한 청록색 (수영)
  static const Color reportIndigo = Color(0xFF3F51B5); // 깊은 남색 (자전거)
  static const Color reportAmber = Color(0xFFFFC107); // 따뜻한 황색 (요가/필라테스)

  // Diet Colors (Appetizing and Natural)
  static const Color dietGreen = Color(0xFF689F38); // 자연스러운 녹색 (한식/채소)
  static const Color dietLightGreen = Color(0xFF8BC34A); // 신선한 연녹색 (샐러드)
  static const Color dietBrown = Color(0xFF8D6E63); // 고소한 갈색 (단백질)
  static const Color dietRed = Color(0xFFD32F2F); // 신선한 빨간색 (과일)
  static const Color dietPurple = Color(0xFF7B1FA2); // 깊은 보라색 (견과류)
  static const Color dietBlue = Color(0xFF1976D2); // 시원한 파란색 (유제품)

  // Gradient Colors for Enhanced Visual Appeal
  static const Color gradientStart = Color(0xFF667eea);
  static const Color gradientEnd = Color(0xFF764ba2);

  // Exercise Motivation Colors
  static const Color motivationRed = Color(0xFFD50000); // 강렬한 빨간색
  static const Color motivationOrange = Color(0xFFFF6D00); // 역동적인 주황색
  static const Color motivationGreen = Color(0xFF00C853); // 성취감을 주는 녹색
  static const Color motivationBlue = Color(0xFF2962FF); // 신뢰감을 주는 파란색

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

  // Exercise Category Color Mapping with Enhanced System
  static Color getExerciseColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case '근력 운동':
      case '근력운동':
      case '웨이트':
      case '헬스':
        return reportGreen;
      case '유산소 운동':
      case '유산소운동':
      case '유산소':
      case '러닝':
      case '조깅':
        return reportBlue;
      case '스트레칭':
      case '스트레치':
        return reportOrange;
      case '요가':
        return reportPurple;
      case '수영':
        return reportTeal;
      case '자전거':
      case '사이클':
      case '사이클링':
        return reportIndigo;
      case '필라테스':
        return reportAmber;
      case '고강도':
      case 'hiit':
      case '크로스핏':
        return reportRed;
      case '등산':
      case '하이킹':
        return Color(0xFF795548); // Brown for hiking
      case '테니스':
      case '배드민턴':
        return Color(0xFF607D8B); // Blue Grey for racket sports
      default:
        return reportGreen; // 기본값
    }
  }

  // Diet Category Color Mapping with Enhanced System
  static Color getDietColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case '한식':
      case '한국음식':
      case '집밥':
        return dietGreen;
      case '샐러드':
      case '채소':
      case '야채':
        return dietLightGreen;
      case '단백질':
      case '고기':
      case '생선':
      case '닭가슴살':
        return dietBrown;
      case '과일':
      case '과일류':
      case '과일 간식':
        return dietRed;
      case '견과류':
      case '견과':
      case '아몬드':
      case '호두':
        return dietPurple;
      case '유제품':
      case '우유':
      case '치즈':
      case '요거트':
        return dietBlue;
      case '간식':
      case '디저트':
        return Color(0xFFFF7043); // Deep Orange for snacks
      case '음료':
      case '차':
      case '커피':
        return Color(0xFF8D6E63); // Brown for beverages
      default:
        return dietGreen; // 기본값
    }
  }

  // Get color with opacity for subtle effects
  static Color withCustomOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Get darker shade of a color for better contrast
  static Color getDarkerShade(Color color, [double factor = 0.2]) {
    final alpha = (color.a * 255.0).round() & 0xff;
    final currentRed = (color.r * 255.0).round() & 0xff;
    final currentGreen = (color.g * 255.0).round() & 0xff;
    final currentBlue = (color.b * 255.0).round() & 0xff;

    final red = (currentRed * (1 - factor)).round();
    final green = (currentGreen * (1 - factor)).round();
    final blue = (currentBlue * (1 - factor)).round();

    return Color.fromARGB(alpha, red, green, blue);
  }

  // Get lighter shade of a color
  static Color getLighterShade(Color color, [double factor = 0.2]) {
    final alpha = (color.a * 255.0).round() & 0xff;
    final currentRed = (color.r * 255.0).round() & 0xff;
    final currentGreen = (color.g * 255.0).round() & 0xff;
    final currentBlue = (color.b * 255.0).round() & 0xff;

    final red = (currentRed + ((255 - currentRed) * factor)).round();
    final green = (currentGreen + ((255 - currentGreen) * factor)).round();
    final blue = (currentBlue + ((255 - currentBlue) * factor)).round();

    return Color.fromARGB(alpha, red, green, blue);
  }

  // Chart colors for unified bar chart
  static List<Color> get chartColors => [
    reportGreen,
    reportBlue,
    reportOrange,
    reportPurple,
    reportRed,
    reportTeal,
    reportIndigo,
    reportAmber,
    dietGreen,
    dietLightGreen,
    dietBrown,
    dietRed,
    dietPurple,
    dietBlue,
  ];

  // Motivation gradient colors
  static LinearGradient get motivationGradient =>
      LinearGradient(colors: [motivationRed, motivationOrange], begin: Alignment.topLeft, end: Alignment.bottomRight);

  // Success gradient for achievements
  static LinearGradient get successGradient =>
      LinearGradient(colors: [motivationGreen, reportGreen], begin: Alignment.topLeft, end: Alignment.bottomRight);

  // Exercise Category Emoji Mapping
  static String getExerciseEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case '근력 운동':
      case '근력운동':
      case '웨이트':
      case '헬스':
        return '💪';
      case '유산소 운동':
      case '유산소운동':
      case '유산소':
      case '러닝':
      case '조깅':
        return '🏃';
      case '스트레칭':
      case '스트레치':
        return '🤸';
      case '요가':
        return '🧘';
      case '수영':
        return '🏊';
      case '자전거':
      case '사이클':
      case '사이클링':
        return '🚴';
      case '필라테스':
        return '🤸‍♀️';
      case '고강도':
      case 'hiit':
      case '크로스핏':
        return '🔥';
      case '등산':
      case '하이킹':
        return '🥾';
      case '테니스':
        return '🎾';
      case '배드민턴':
        return '🏸';
      case '축구':
        return '⚽';
      case '농구':
        return '🏀';
      case '야구':
        return '⚾';
      case '골프':
        return '⛳';
      case '복싱':
        return '🥊';
      case '태권도':
      case '무술':
        return '🥋';
      case '댄스':
      case '춤':
        return '💃';
      default:
        return '🏃'; // 기본값
    }
  }

  // Diet Category Emoji Mapping
  static String getDietEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case '한식':
      case '한국음식':
      case '집밥':
        return '🍚';
      case '샐러드':
      case '채소':
      case '야채':
        return '🥗';
      case '단백질':
      case '고기':
      case '닭가슴살':
        return '🍗';
      case '생선':
        return '🐟';
      case '과일':
      case '과일류':
      case '과일 간식':
        return '🍎';
      case '견과류':
      case '견과':
      case '아몬드':
      case '호두':
        return '🥜';
      case '유제품':
      case '우유':
        return '🥛';
      case '치즈':
        return '🧀';
      case '요거트':
        return '🥛';
      case '간식':
      case '디저트':
        return '🍰';
      case '음료':
        return '🥤';
      case '차':
        return '🍵';
      case '커피':
        return '☕';
      case '빵':
      case '베이커리':
        return '🍞';
      case '파스타':
        return '🍝';
      case '피자':
        return '🍕';
      case '국물':
      case '스프':
        return '🍲';
      case '밥':
        return '🍚';
      case '면':
      case '라면':
        return '🍜';
      default:
        return '🍽️'; // 기본값
    }
  }

  // Get category color and emoji together for unified bar chart
  static CategoryColorEmoji getCategoryColorEmoji(String categoryName, bool isExercise) {
    if (isExercise) {
      return CategoryColorEmoji(color: getExerciseColor(categoryName), emoji: getExerciseEmoji(categoryName));
    } else {
      return CategoryColorEmoji(color: getDietColor(categoryName), emoji: getDietEmoji(categoryName));
    }
  }
}

/// Helper class to hold color and emoji together
class CategoryColorEmoji {
  final Color color;
  final String emoji;

  const CategoryColorEmoji({required this.color, required this.emoji});
}
