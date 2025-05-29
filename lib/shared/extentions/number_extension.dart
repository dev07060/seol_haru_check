import 'package:intl/intl.dart';

extension StringExtensions on num {
  String toCleanString([int precision = 1]) {
    double truncatedValue;

    if (precision == 0) {
      // precision이 0인 경우, 값을 정수로 처리
      truncatedValue = toInt().toDouble();
    } else {
      // 지정된 precision에 따라 값을 버림 처리
      truncatedValue = (this * (10 * precision)).truncateToDouble() / (10 * precision);
    }

    // 소수점 이하가 0이면 정수로 반환
    if (truncatedValue % 1 == 0) {
      return truncatedValue.toInt().toString();
    } else {
      return truncatedValue.toStringAsFixed(precision);
    }
  }

  String withComma() => NumberFormat('#,##0').format(this);
}
