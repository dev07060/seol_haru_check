class AppStrings {
  // 이 클래스는 인스턴스화되지 않도록 private 생성자를 만듭니다.
  AppStrings._();

  // CertificationTrackerPage 관련 문자열
  static const String appTitle = 'Haru_Check';
  static const String refresh = '새로고침';
  static const String guideText = '참여자의 칸을 클릭하여 운동 완료 상태를 변경할 수 있습니다';
  static const String participants = '참여자';
  static const String noParticipants = '참여자가 아직 없습니다';
  static const String noCertificationOnThisDay = '이 날짜에는 인증 기록이 없습니다.';
  static const String noCertificationOnToDay = '오늘은 아직 인증 기록이 없습니다.';
  static const String moveToToday = '오늘 날짜로 이동';
  static const String addCertificationToday = '오늘 첫 인증 추가하기';
  static const String noCertificationOnThisDayOther = '님은 이 날짜에 인증 기록이 없습니다.';
  static const String noCertificationOnToDayOther = '님은 오늘 아직 인증 기록이 없습니다.';
  static const String myActivityFeed = '내 활동 피드';

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
  static const String passwordHint = '비밀번호(4희자리)';
  static const String submit = '제출';
  static const String fillAllFields = '모든 필드를 채워주세요.';
  static const String certificationAddedSuccessfully = '인증이 성공적으로 추가되었습니다.';
  static const String passwordIncorrect = '비밀번호가 일치하지 않습니다';

  // 인증 조회 다이얼로그 관련 문자열
  static const String certificationRecord = '님의 인증 기록';
  static const String addCertificationTooltip = '추가 인증';
  static const String closeTooltip = '닫기';
  static const String deleteCertification = '인증 삭제';
  static const String delete = '삭제';

  // MyFeedPage 관련 문자열
  static const String confirmDeleteCertificationTitle = '인증 삭제';
  static const String confirmDeleteCertificationDescription = '이 인증을 정말 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.';
  static const String certificationDeletedSuccessfully = '인증이 삭제되었습니다.';
  static const String certificationDeletionFailed = '인증 삭제 중 오류가 발생했습니다.';

  // 데이터 마이그레이션 관련 문자열
  static const String migrateOldDataButton = '이전 데이터 마이그레이션';
  static const String confirmDataMigrationTitle = '데이터 마이그레이션';
  static const String confirmDataMigrationDescription = '이전 인증 데이터를 현재 계정으로 가져옵니다. 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?';
  static const String dataMigrationSuccessful = '데이터 마이그레이션이 완료되었습니다.';
  static const String dataMigrationFailed = '데이터 마이그레이션 중 오류가 발생했습니다.';

  // 일반 메시지
  static const String loginRequired = '로그인이 필요합니다.';
  static const String defaultUserName = '사용자';
  static const String errorLoadingData = '데이터를 불러오는 중 오류가 발생했습니다.';
}
