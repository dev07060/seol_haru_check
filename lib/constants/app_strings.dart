class AppStrings {
  // 이 클래스는 인스턴스화되지 않도록 private 생성자를 만듭니다.
  AppStrings._();

  // CertificationTrackerPage 관련 문자열
  static const String appTitle = '운동 식단 인증';
  static const String refresh = '새로고침';
  static const String guideText = '참여자의 칸을 클릭하여 운동 완료 상태를 변경할 수 있습니다';
  static const String participants = '참여자';
  static const String noParticipants = '참여자가 아직 없습니다';

  // 참가하기 다이얼로그 관련 문자열
  static const String join = '참가하기';
  static const String nickname = '닉네임';
  static const String password4digits = '비밀번호 (4자리)';
  static const String cancel = '취소';
  static const String complete = '완료';
  static const String joinCompleteMessage = '참가가 완료되었습니다';

  // 인증 추가 다이얼로그 관련 문자열
  static const String addCertification = '인증 추가하기';
  static const String uploadLimit = '하루 최대 3개까지 업로드 가능';
  static const String exercise = '운동';
  static const String diet = '식단';
  static const String contentHint = '인증 내용을 입력하세요';
  static const String selectImage = '이미지 선택';
  static const String changeImage = '이미지 변경';
  static const String passwordHint = '비밀번호(4자리)';
  static const String submit = '제출';
  static const String fillAllFields = '모든 필드를 채워주세요.';
  static const String passwordIncorrect = '비밀번호가 일치하지 않습니다';

  // 인증 조회 다이얼로그 관련 문자열
  static const String certificationRecord = '님의 인증 기록';
  static const String addCertificationTooltip = '추가 인증';
  static const String closeTooltip = '닫기';
  static const String deleteCertification = '인증 삭제';
  static const String delete = '삭제';
}
