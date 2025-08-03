import 'dart:developer';
import 'dart:io';

void main() {
  final file = File('test/services/data_aggregation_test.dart');
  if (!file.existsSync()) {
    log('File not found');
    return;
  }

  String content = file.readAsStringSync();

  // const WeeklyStats( 패턴을 모두 TestDataHelper.createDefaultWeeklyStats(로 변경
  content = content.replaceAllMapped(
    RegExp(
      r'const WeeklyStats\(\s*totalCertifications:\s*(\d+),\s*exerciseDays:\s*(\d+),\s*dietDays:\s*(\d+),\s*exerciseTypes:\s*({[^}]*}),\s*consistencyScore:\s*([\d.]+),?\s*\)',
      multiLine: true,
      dotAll: true,
    ),
    (match) {
      final totalCert = match.group(1);
      final exerciseDays = match.group(2);
      final dietDays = match.group(3);
      final exerciseTypes = match.group(4);
      final consistency = match.group(5);

      return '''TestDataHelper.createDefaultWeeklyStats(
          totalCertifications: $totalCert,
          exerciseDays: $exerciseDays,
          dietDays: $dietDays,
          exerciseTypes: $exerciseTypes,
          consistencyScore: $consistency,
        )''';
    },
  );

  // import 추가
  if (!content.contains("import '../helpers/test_data_helper.dart';")) {
    content = content.replaceFirst(
      "import 'package:flutter_test/flutter_test.dart';",
      "import 'package:flutter_test/flutter_test.dart';\nimport '../helpers/test_data_helper.dart';",
    );
  }

  file.writeAsStringSync(content);
  log('Fixed data_aggregation_test.dart');
}
