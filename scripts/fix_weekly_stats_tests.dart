import 'dart:developer';
import 'dart:io';

void main() {
  // 수정할 테스트 파일들
  final testFiles = [
    'test/models/weekly_report_model_test.dart',
    'test/providers/weekly_report_provider_test.dart',
    'test/services/data_aggregation_test.dart',
    'test/widgets/report_summary_card_test.dart',
    'test/widgets/weekly_report_page_test.dart',
  ];

  for (final filePath in testFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      log('File not found: $filePath');
      continue;
    }

    String content = file.readAsStringSync();

    // WeeklyStats 생성자 패턴을 찾아서 수정
    final patterns = [
      // 기본 패턴들
      RegExp(
        r'const WeeklyStats\(\s*totalCertifications:\s*(\d+),\s*exerciseDays:\s*(\d+),\s*dietDays:\s*(\d+),\s*exerciseTypes:\s*({[^}]*}),\s*consistencyScore:\s*([\d.]+),?\s*\)',
      ),
      RegExp(
        r'WeeklyStats\(\s*totalCertifications:\s*(\d+),\s*exerciseDays:\s*(\d+),\s*dietDays:\s*(\d+),\s*exerciseTypes:\s*({[^}]*}),\s*consistencyScore:\s*([\d.]+),?\s*\)',
      ),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
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
      });
    }

    // import 추가
    if (!content.contains("import '../helpers/test_data_helper.dart';") &&
        !content.contains("import 'helpers/test_data_helper.dart';")) {
      content = content.replaceFirst(
        RegExp(r"import 'package:seol_haru_check/models/weekly_report_model.dart';"),
        "import 'package:seol_haru_check/models/weekly_report_model.dart';\nimport '../helpers/test_data_helper.dart';",
      );
    }

    file.writeAsStringSync(content);
    log('Fixed: $filePath');
  }
}
