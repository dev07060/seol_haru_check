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
  content = content.replaceAll('const stats = WeeklyStats(', 'final stats = TestDataHelper.createDefaultWeeklyStats(');

  file.writeAsStringSync(content);
  log('Fixed const WeeklyStats constructors in data_aggregation_test.dart');
}
