class AppStrings {
  // 이 클래스는 인스턴스화되지 않도록 private 생성자를 만듭니다.
  AppStrings._();

  // CertificationTrackerPage 관련 문자열
  static const String appTitle = 'Haru_Check';
  static const String refresh = '새로고침';
  static const String guideText = '참여자의 칸을 클릭하여 운동 완료 상태를 변경할 수 있습니다';
  static const String participants = '참여자';
  static const String participantsList = '참여자 리스트';
  static const String noParticipants = '참여자가 아직 없습니다';
  static const String noCertificationOnThisDay = '이 날짜에는 인증 기록이 없습니다.';
  static const String noCertificationOnToDay = '오늘은 아직 인증 기록이 없습니다.';
  static const String moveToToday = '오늘 날짜로 이동';
  static const String addCertificationToday = '오늘 첫 인증 추가하기';
  static const String noCertificationOnThisDayOther = '님은 이 날짜에 인증 기록이 없습니다.';
  static const String noCertificationOnToDayOther = '님은 오늘 아직 인증 기록이 없습니다.';
  static const String myActivityFeed = '내 활동 피드';
  static const String clickNicknameToViewFeed = '다른 참여자의 닉네임을 클릭하여 피드를 확인할 수 있어요';

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

  // 로그인/로그아웃 관련 문자열
  static const String login = '로그인';
  static const String logout = '로그아웃';
  static const String confirmLogout = '정말 로그아웃 하시겠습니까?';
  static const String logoutSuccess = '로그아웃 되었습니다.';
  static const String logoutFailed = '로그아웃 실패. 잠시후 다시 시도해주세요';
  static const String loginFailed = '로그인 실패';
  static const String signUp = '회원가입(ID 생성시에만)';
  static const String signUpSuccess = '회원가입에 성공했습니다. 자동으로 로그인됩니다.';
  static const String signUpFailed = '회원가입에 실패했습니다. 다시 시도해주세요.';
  static const String nicknameAlreadyInUse = '이미 사용 중인 닉네임입니다.';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';
  static const String nicknameHint = '닉네임을 입력해 주세요.';
  static const String nicknameAndPasswordRequired = '닉네임과 4자리 비밀번호를 모두 올바르게 입력해주세요.';

  // 앱 관련 문자열
  static const String appTitleKorean = '운동 체크';
  static const String errorOccurred = '오류가 발생했습니다';
  static const String confirm = '확인';
  static const String uploadLimit2 = '업로드 제한';
  static const String authError = '인증 오류: 사용자 정보가 일치하지 않습니다.';
  static const String cannotGetUserEmail = '사용자 이메일을 가져올 수 없습니다.';
  static const String typeLabel = '유형';
  static const String password = '비밀번호';
  static const String cannotLoadImage = '이미지를 불러올 수 없어요';

  // Firestore 컬렉션 및 필드 이름
  static const String usersCollection = 'users';
  static const String certificationsCollection = 'certifications';
  static const String nicknameField = 'nickname';
  static const String uuidField = 'uuid';
  static const String createdAtField = 'createdAt';
  static const String typeField = 'type';
  static const String contentField = 'content';
  static const String photoUrlField = 'photoUrl';
  static const String passwordField = 'password';

  // 주간 리포트 관련 문자열
  static const String weeklyReport = '주간 리포트';
  static const String weeklyAnalysis = '주간 분석';
  static const String thisWeekReport = '이번 주 리포트';
  static const String noReportYet = '아직 리포트가 없습니다';
  static const String reportGenerating = '리포트 생성 중...';
  static const String pullToRefresh = '당겨서 새로고침';
  static const String exerciseAnalysis = '운동 분석';
  static const String dietAnalysis = '식단 분석';
  static const String recommendations = '추천사항';
  static const String weeklyStats = '주간 통계';
  static const String totalCertifications = '총 인증 수';
  static const String exerciseDays = '운동 일수';
  static const String dietDays = '식단 일수';
  static const String consistencyScore = '일관성 점수';
  static const String strengthAreas = '잘하고 있는 부분';
  static const String improvementAreas = '개선이 필요한 부분';
  static const String overallAssessment = '종합 평가';
  static const String insufficientData = '분석을 위한 데이터가 부족합니다';
  static const String needMoreCertifications = '더 많은 인증이 필요합니다 (최소 3일)';
  static const String keepItUp = '계속 화이팅하세요!';
  static const String networkError = '네트워크 오류가 발생했습니다';
  static const String retry = '다시 시도';
  static const String loadingMore = '더 불러오는 중...';
  static const String noMoreReports = '더 이상 리포트가 없습니다';
  static const String selectWeek = '주차 선택';
  static const String previousWeeks = '이전 주차';
  static const String selectDate = '날짜 선택';
  static const String noReportForWeek = '해당 주차에 리포트가 없습니다';
  static const String goToWeek = '해당 주차로 이동';
  static const String currentWeek = '현재 주';
  static const String weekOf = '주차';

  // 알림 관련 문자열
  static const String notifications = '알림';
  static const String notificationSettings = '알림 설정';
  static const String notificationHistory = '알림 기록';
  static const String enableNotifications = '알림 허용';
  static const String disableNotifications = '알림 차단';
  static const String notificationPermissionRequired = '알림 권한이 필요합니다';
  static const String notificationPermissionDenied = '알림 권한이 거부되었습니다';
  static const String notificationPermissionGranted = '알림 권한이 허용되었습니다';
  static const String openSettings = '설정 열기';
  static const String noNotifications = '알림이 없습니다';
  static const String clearNotificationHistory = '알림 기록 지우기';
  static const String confirmClearHistory = '알림 기록을 모두 지우시겠습니까?';
  static const String notificationHistoryCleared = '알림 기록이 지워졌습니다';
  static const String newReportAvailable = '새로운 리포트가 있습니다';
  static const String tapToView = '탭하여 확인';
  static const String unreadNotifications = '읽지 않은 알림';
  static const String allNotifications = '모든 알림';
  static const String markAllAsRead = '모두 읽음으로 표시';
  static const String notificationTapped = '확인함';
  static const String notificationReceived = '수신됨';

  // 일반 메시지
  static const String loginRequired = '로그인이 필요합니다.';
  static const String defaultUserName = '사용자';
  static const String errorLoadingData = '데이터를 불러오는 중 오류가 발생했습니다.';

  // 오류 처리 관련 문자열
  static const String connectionError = '인터넷 연결을 확인해주세요.';
  static const String serverError = '서버에 일시적인 문제가 발생했습니다.';
  static const String timeoutError = '요청 시간이 초과되었습니다.';
  static const String permissionError = '접근 권한이 없습니다.';
  static const String quotaExceededError = '사용량이 초과되었습니다.';
  static const String dataCorruptedError = '데이터가 손상되었습니다.';
  static const String offlineMode = '오프라인 모드';
  static const String offlineModeDescription = '인터넷 연결이 없어 저장된 데이터를 표시합니다.';
  static const String connectToInternet = '인터넷에 연결하여 최신 데이터를 확인하세요.';
  static const String retryConnection = '연결 재시도';
  static const String cacheExpired = '저장된 데이터가 만료되었습니다.';
  static const String syncingData = '데이터 동기화 중...';
  static const String syncCompleted = '동기화 완료';
  static const String syncFailed = '동기화 실패';
  static const String errorReporting = '오류 신고';
  static const String errorReported = '오류가 신고되었습니다.';
  static const String reportError = '오류 신고하기';
  static const String errorDetails = '오류 세부사항';
  static const String contactSupport = '고객지원 문의';
  static const String tryAgainLater = '잠시 후 다시 시도해주세요.';
  static const String unexpectedError = '예상치 못한 오류가 발생했습니다.';
  static const String dataValidationError = '입력 데이터가 올바르지 않습니다.';
  static const String serviceUnavailable = '서비스를 일시적으로 사용할 수 없습니다.';
  static const String maintenanceMode = '서비스 점검 중입니다.';
  static const String versionOutdated = '앱 버전이 오래되었습니다. 업데이트해주세요.';
  static const String updateRequired = '업데이트 필요';
  static const String updateApp = '앱 업데이트';
  static const String skipUpdate = '나중에';
  static const String criticalError = '심각한 오류가 발생했습니다.';
  static const String restartApp = '앱 재시작';
  static const String clearCache = '캐시 지우기';
  static const String cacheCleared = '캐시가 지워졌습니다.';
  static const String errorCode = '오류 코드';
  static const String timestamp = '발생 시간';
  static const String userAction = '사용자 작업';
  static const String systemInfo = '시스템 정보';
  static const String sendErrorReport = '오류 리포트 전송';
  static const String errorReportSent = '오류 리포트가 전송되었습니다.';
  static const String errorReportFailed = '오류 리포트 전송에 실패했습니다.';

  // Category insights related strings
  static const String categoryDiversity = '카테고리 다양성';
  static const String categoryBalance = '카테고리 균형';
  static const String topCategories = '주요 활동 카테고리';
  static const String weeklyGoals = '주간 목표 달성률';
  static const String exerciseGoal = '운동 목표';
  static const String dietGoal = '식단 목표';
  static const String diversityGoal = '다양성 목표';
  static const String perfectBalance = '완벽한 균형';
  static const String goodBalance = '좋은 균형';
  static const String averageBalance = '보통 균형';
  static const String poorBalance = '불균형';

  // 로딩 상태 관련 문자열
  static const String analyzing = '분석 중...';
  static const String processingData = '데이터 처리 중...';
  static const String generatingReport = '리포트 생성 중...';
  static const String almostDone = '거의 완료되었습니다...';
  static const String finalizing = '마무리 중...';
  static const String preparingResults = '결과 준비 중...';
  static const String loadingProgress = '진행률';
  static const String estimatedTime = '예상 시간';
  static const String timeRemaining = '남은 시간';
  static const String processingSteps = '처리 단계';
  static const String currentStep = '현재 단계';
  static const String stepOf = '단계';
  static const String pleaseWait = '잠시만 기다려주세요';
  static const String operationInProgress = '작업이 진행 중입니다';
  static const String doNotClose = '창을 닫지 마세요';
  static const String backgroundProcessing = '백그라운드에서 처리 중';
  static const String willNotifyWhenComplete = '완료되면 알려드리겠습니다';
  static const String longRunningOperation = '시간이 오래 걸릴 수 있습니다';
  static const String refreshingData = '데이터 새로고침 중';
  static const String updatingContent = '콘텐츠 업데이트 중';
  static const String savingChanges = '변경사항 저장 중';
  static const String loadingContent = '콘텐츠 로딩 중';
  static const String preparingInterface = '인터페이스 준비 중';
}
