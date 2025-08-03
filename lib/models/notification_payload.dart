// lib/models/notification_payload.dart

/// 주간 리포트 알림 페이로드 구조
class WeeklyReportNotificationPayload {
  final String type;
  final String reportId;
  final String userUuid;
  final String weekStartDate;
  final String weekEndDate;
  final String title;
  final String body;

  const WeeklyReportNotificationPayload({
    required this.type,
    required this.reportId,
    required this.userUuid,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.title,
    required this.body,
  });

  /// Map에서 WeeklyReportNotificationPayload 생성
  factory WeeklyReportNotificationPayload.fromMap(Map<String, dynamic> map) {
    return WeeklyReportNotificationPayload(
      type: map['type'] ?? '',
      reportId: map['reportId'] ?? '',
      userUuid: map['userUuid'] ?? '',
      weekStartDate: map['weekStartDate'] ?? '',
      weekEndDate: map['weekEndDate'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
    );
  }

  /// WeeklyReportNotificationPayload를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'reportId': reportId,
      'userUuid': userUuid,
      'weekStartDate': weekStartDate,
      'weekEndDate': weekEndDate,
      'title': title,
      'body': body,
    };
  }

  /// FCM 메시지 데이터 형식으로 변환
  Map<String, String> toFCMData() {
    return {
      'type': type,
      'reportId': reportId,
      'userUuid': userUuid,
      'weekStartDate': weekStartDate,
      'weekEndDate': weekEndDate,
    };
  }

  /// FCM 알림 형식으로 변환
  Map<String, String> toFCMNotification() {
    return {'title': title, 'body': body};
  }

  @override
  String toString() {
    return 'WeeklyReportNotificationPayload(type: $type, reportId: $reportId, userUuid: $userUuid, weekStartDate: $weekStartDate, weekEndDate: $weekEndDate, title: $title, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyReportNotificationPayload &&
        other.type == type &&
        other.reportId == reportId &&
        other.userUuid == userUuid &&
        other.weekStartDate == weekStartDate &&
        other.weekEndDate == weekEndDate &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        reportId.hashCode ^
        userUuid.hashCode ^
        weekStartDate.hashCode ^
        weekEndDate.hashCode ^
        title.hashCode ^
        body.hashCode;
  }
}

/// 일반적인 알림 페이로드 구조
class NotificationPayload {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final bool tapped;

  NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    DateTime? receivedAt,
    this.tapped = false,
  }) : receivedAt = receivedAt ?? DateTime.now();

  /// Map에서 NotificationPayload 생성
  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      receivedAt: map['receivedAt'] != null ? DateTime.tryParse(map['receivedAt']) ?? DateTime.now() : DateTime.now(),
      tapped: map['tapped'] ?? false,
    );
  }

  /// NotificationPayload를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
      'tapped': tapped,
    };
  }

  /// FCM 메시지 데이터 형식으로 변환
  Map<String, String> toFCMData() {
    final fcmData = <String, String>{'type': type};

    // data의 모든 값을 String으로 변환
    data.forEach((key, value) {
      fcmData[key] = value.toString();
    });

    return fcmData;
  }

  /// FCM 알림 형식으로 변환
  Map<String, String> toFCMNotification() {
    return {'title': title, 'body': body};
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, title: $title, body: $body, data: $data, receivedAt: $receivedAt, tapped: $tapped)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPayload &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        other.data.toString() == data.toString() &&
        other.receivedAt == receivedAt &&
        other.tapped == tapped;
  }

  @override
  int get hashCode {
    return type.hashCode ^ title.hashCode ^ body.hashCode ^ data.hashCode ^ receivedAt.hashCode ^ tapped.hashCode;
  }
}

/// 알림 타입 상수
class NotificationTypes {
  static const String weeklyReport = 'weekly_report';
  static const String certification = 'certification';
  static const String system = 'system';

  // 주간 리포트 관련 알림 메시지
  static const String weeklyReportTitle = '주간 분석 리포트가 준비되었습니다! 📊';
  static const String weeklyReportBody = '지난 주 운동과 식단 활동을 AI가 분석했어요. 확인해보세요!';
  static const String weeklyReportBodyWithPeriod = '님의 주간 리포트가 준비되었습니다';

  // 부족한 데이터 알림 메시지
  static const String insufficientDataTitle = '더 꾸준한 인증이 필요해요! 💪';
  static const String insufficientDataBody = '이번 주는 인증이 부족했어요. 다음 주에는 더 열심히 해보세요!';

  // 데이터 없음 알림 메시지
  static const String noDataTitle = '건강한 습관을 시작해보세요! 🌟';
  static const String noDataBody = '운동과 식단 인증으로 건강한 라이프스타일을 만들어가요!';
}
