// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get trainingTabTitle => '트레이닝 센터';

  @override
  String get trainingTabSubtitle => 'AI 가이드 트레이닝 모듈로 대학 지원을 준비하세요.';

  @override
  String get studyPlanCardTitle => 'Study Plan Builder';

  @override
  String get studyPlanCardDesc =>
      'Craft a compelling roadmap for your academic journey.';

  @override
  String get personalStatementCardTitle => 'Personal Statement';

  @override
  String get personalStatementCardDesc =>
      'Write effective and engaging personal essays.';

  @override
  String get interviewCardTitle => 'Interview Preparation';

  @override
  String get interviewCardDesc =>
      'Practice mock questions and improve your confidence.';

  @override
  String get applyCta => 'Apply to a university';

  @override
  String get noApplicationsTitle => 'No applications yet';

  @override
  String get noApplicationsBody =>
      'Add a target university first — drafting starts from a target school.';

  @override
  String get startInterview => 'Start Interview';

  @override
  String get cancel => 'Cancel';

  @override
  String get endInterview => 'End Interview';

  @override
  String get endSession => 'End Session';

  @override
  String get practiceAgain => 'Practice Again';

  @override
  String get connecting => 'Connecting...';

  @override
  String get greetWait =>
      'Connecting — your interviewer will greet you shortly...';

  @override
  String get yourTurn => 'Your turn to speak';

  @override
  String get aiSpeaking => 'Interviewer is speaking...';

  @override
  String get wrappingUp => 'Wrapping up the interview...';

  @override
  String get micRequired => 'Microphone access is required for the interview.';

  @override
  String get walkaroundLoadingTitle => '캠퍼스 워크어라운드 로딩 중';

  @override
  String get walkaroundLoadingSubtitle => '캠퍼스 주변 거리뷰를 가져오는 중입니다.';

  @override
  String get walkaroundNoPanoTitle => '이 위치의 거리뷰가 없습니다';

  @override
  String get walkaroundNoPanoSubtitle => '이 캠퍼스 근처에는 걸어볼 수 있는 거리뷰가 없습니다.';

  @override
  String get walkaroundBlockedTitle => '거리뷰를 사용할 수 없습니다';

  @override
  String get walkaroundBlockedSubtitle =>
      '지도 제공자가 요청을 차단했습니다. 다른 네트워크에서 다시 시도해 주세요.';

  @override
  String get walkaroundNetworkTitle => '지도 서비스에 연결할 수 없습니다';

  @override
  String get walkaroundNetworkSubtitle => '연결 상태를 확인하고 다시 시도해 주세요.';

  @override
  String get walkaroundInitErrorTitle => '거리뷰를 시작할 수 없습니다';

  @override
  String get walkaroundInitErrorSubtitle =>
      '워크어라운드 시작 중 오류가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get virtualTourTitle => '가상 투어';

  @override
  String get virtualWalkaroundTitle => '가상 워크어라운드';

  @override
  String get navHome => '홈';

  @override
  String get navMap => '지도';

  @override
  String get navDocs => '서류';

  @override
  String get navTraining => '트레이닝';

  @override
  String get applicationsTabTitle => '내 지원서';

  @override
  String get mapTabTitle => '대학교';

  @override
  String get documentsTabTitle => '내 서류';

  @override
  String get accountTooltip => '계정';

  @override
  String get ok => '확인';

  @override
  String get loadingLabel => '로딩 중...';

  @override
  String get accountBackTooltip => '뒤로';

  @override
  String get accountTitle => '계정';

  @override
  String get accountSignedInAs => '로그인 계정';

  @override
  String get accountUnknownAccount => '(알 수 없는 계정)';

  @override
  String get accountSessionLabel => '세션';

  @override
  String get accountSigningOut => '로그아웃 중...';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get accountYourDataLabel => '내 데이터';

  @override
  String get accountYourDataBody =>
      'Hanguk이 보관 중인 계정 데이터(프로필, 지원서, 학습 계획, 초안, 모의 면접 세션 및 피드백)의 JSON 사본을 다운로드합니다.';

  @override
  String get accountPreparingExport => '내보내기 준비 중...';

  @override
  String get accountDownloadMyData => '내 데이터 다운로드';

  @override
  String get accountDangerZoneLabel => '위험 구역';

  @override
  String get accountDangerZoneBody =>
      '계정 삭제는 영구적입니다. 프로필, 지원서, 학습 계획, 자기소개서 초안, 모의 면접 세션 및 기록이 모두 삭제됩니다. 저장된 문서는 30일 이내, 백업본은 90일 이내에 만료됩니다.';

  @override
  String get accountDeleteAccount => '계정 삭제';

  @override
  String get accountPrivacyPolicy => '개인정보처리방침';

  @override
  String get accountTermsOfService => '이용약관';

  @override
  String get accountDeleteErrorTitle => '계정을 삭제할 수 없습니다';

  @override
  String accountDeleteErrorBody(Object error) {
    return '데이터 삭제 중 오류가 발생했습니다:\n\n$error\n\n삭제를 완료할 수 있도록 privacy@hanguk.uz로 이메일을 보내주세요.';
  }

  @override
  String accountExportFailed(Object error) {
    return '내보내기 실패: $error';
  }

  @override
  String get accountDeleteDialogTitle => '계정을 삭제하시겠습니까?';

  @override
  String get accountDeleteDialogBody =>
      '계정, 지원서, 학습 계획, 자기소개서 초안, 모의 면접 세션 및 기록이 영구적으로 삭제됩니다.\n\n계속하려면 DELETE를 입력하세요.';

  @override
  String get accountDeleteDialogConfirm => '영구 삭제';

  @override
  String get accountDeleteProgress => '계정 삭제 중...';

  @override
  String get loginStudentPortal => '학생 포털';

  @override
  String get loginAccessCodeHelp =>
      '컨설턴트 또는 대학 담당자가 제공한 8자리 액세스 코드(영문과 숫자)를 입력하세요.';

  @override
  String get loginAccessCodeButton => '액세스 코드로 로그인';

  @override
  String get loginSwitchToPhone => '← 전화번호로 로그인할게요';

  @override
  String get loginComingSoonTitle => '출시 예정';

  @override
  String get loginComingSoonBody =>
      '시스템 업그레이드 작업 중이라 공개 회원가입과 전화 로그인이 일시 중단되었습니다.\n\n학생 여러분: 당분간 매직 액세스 코드로 로그인해 주세요.';

  @override
  String get loginSwitchToMagicCode => '매직 코드 로그인으로 전환';

  @override
  String get loginErrorInvalidPhone => '유효한 전화번호를 입력해 주세요 (예: +12345678).';

  @override
  String get loginErrorPasswordTooShort => '비밀번호는 6자 이상이어야 합니다.';

  @override
  String get loginErrorInvalidCredentials => '전화번호 또는 비밀번호가 올바르지 않습니다.';

  @override
  String get loginErrorInvalidAccessCode => '유효한 액세스 코드를 입력해 주세요 (최소 6자).';

  @override
  String get signUpErrorNameRequired => '이름을 입력해 주세요.';

  @override
  String get signUpErrorPhoneRequired => '유효한 전화번호가 필요합니다 (예: +12345678).';

  @override
  String get signUpErrorPasswordMismatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get signUpSuccess => '계정이 생성되었습니다. 로그인해 주세요.';

  @override
  String get notifSettingsTitle => '알림 설정';

  @override
  String get notifSettingsEmptyTitle => '추적 중인 대학이 없습니다';

  @override
  String get notifSettingsEmptyBody =>
      '대학 페이지에서 "이 학교 추적"을 탭하여 팔로우하세요. 추적 중인 학교가 하나 이상 생기면 알림 설정이 여기에 표시됩니다.';

  @override
  String get notifSettingsCalendar => '일정 변경';

  @override
  String get notifSettingsCalendarDesc => '마감일이 변경될 때';

  @override
  String get notifSettingsCorrection => '정정공고';

  @override
  String get notifSettingsCorrectionDesc => '정정공고 게시 — 최우선 알림';

  @override
  String get notifSettingsRequirement => '지원 요건 변경';

  @override
  String get notifSettingsRequirementDesc => 'TOPIK / 학점 / 어학 시험 규정 변경';

  @override
  String get notifSettingsScholarship => '장학금 업데이트';

  @override
  String get notifSettingsScholarshipDesc => '기본값 꺼짐 — 알림이 많을 수 있음';

  @override
  String notifSettingsLoadError(Object error) {
    return '오류: $error';
  }

  @override
  String notifSettingsPushLanguage(String lang) {
    return '푸시 알림 언어: $lang';
  }

  @override
  String notifSettingsUpdateError(Object error) {
    return '설정을 업데이트하지 못했습니다: $error';
  }
}
