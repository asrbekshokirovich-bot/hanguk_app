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
}
