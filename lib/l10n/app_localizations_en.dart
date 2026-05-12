// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get trainingTabTitle => 'Training Center';

  @override
  String get trainingTabSubtitle =>
      'Prepare for your university applications with AI-guided training modules.';

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
  String get walkaroundLoadingTitle => 'Loading campus walkaround';

  @override
  String get walkaroundLoadingSubtitle => 'Fetching street view near campus.';

  @override
  String get walkaroundNoPanoTitle => 'No street view here';

  @override
  String get walkaroundNoPanoSubtitle =>
      'This campus doesn\'t have a walkable street view nearby.';

  @override
  String get walkaroundBlockedTitle => 'Street view unavailable';

  @override
  String get walkaroundBlockedSubtitle =>
      'The map provider blocked this request. Try again on a different network.';

  @override
  String get walkaroundNetworkTitle => 'Couldn\'t reach the map provider';

  @override
  String get walkaroundNetworkSubtitle =>
      'Check your connection and try again.';

  @override
  String get walkaroundInitErrorTitle => 'Street view couldn\'t start';

  @override
  String get walkaroundInitErrorSubtitle =>
      'Something went wrong starting the walkaround. Please try again.';

  @override
  String get virtualTourTitle => 'Virtual Tour';

  @override
  String get virtualWalkaroundTitle => 'Virtual Walkaround';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navDocs => 'Docs';

  @override
  String get navTraining => 'Training';

  @override
  String get applicationsTabTitle => 'My Applications';

  @override
  String get mapTabTitle => 'Universities';

  @override
  String get documentsTabTitle => 'My Documents';

  @override
  String get accountTooltip => 'Account';

  @override
  String get ok => 'OK';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get accountBackTooltip => 'Back';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSignedInAs => 'Signed in as';

  @override
  String get accountUnknownAccount => '(unknown account)';

  @override
  String get accountSessionLabel => 'Session';

  @override
  String get accountSigningOut => 'Signing out…';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountYourDataLabel => 'Your data';

  @override
  String get accountYourDataBody =>
      'Download a JSON copy of everything Hanguk holds about your account — profile, applications, study plans, drafts, interview sessions and feedback.';

  @override
  String get accountPreparingExport => 'Preparing export…';

  @override
  String get accountDownloadMyData => 'Download my data';

  @override
  String get accountDangerZoneLabel => 'Danger zone';

  @override
  String get accountDangerZoneBody =>
      'Deleting your account is permanent. We will erase your profile, applications, study plans, personal-statement drafts, interview sessions, and transcripts. Documents in storage are removed within 30 days; backups age out within 90 days.';

  @override
  String get accountDeleteAccount => 'Delete account';

  @override
  String get accountPrivacyPolicy => 'Privacy Policy';

  @override
  String get accountTermsOfService => 'Terms of Service';

  @override
  String get accountDeleteErrorTitle => 'Could not delete account';

  @override
  String accountDeleteErrorBody(Object error) {
    return 'We hit an error while deleting your data:\n\n$error\n\nPlease email privacy@hanguk.uz so we can finish the deletion for you.';
  }

  @override
  String accountExportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get accountDeleteDialogTitle => 'Delete your account?';

  @override
  String get accountDeleteDialogBody =>
      'This will permanently delete your account, applications, study plans, personal-statement drafts, interview sessions, and transcripts.\n\nType DELETE to confirm.';

  @override
  String get accountDeleteDialogConfirm => 'Delete forever';

  @override
  String get accountDeleteProgress => 'Deleting your account…';

  @override
  String get loginStudentPortal => 'Student Portal';

  @override
  String get loginAccessCodeHelp =>
      'Enter the 8-character access code (letters and numbers) provided by your consultant or university representative.';

  @override
  String get loginAccessCodeButton => 'Login manually with Access Code';

  @override
  String get loginSwitchToPhone =>
      '← I actually want to Log in via Phone Number';

  @override
  String get loginComingSoonTitle => 'Coming Soon';

  @override
  String get loginComingSoonBody =>
      'Public sign up and phone login are currently under maintenance as we upgrade our systems.\n\nStudents: Please use your Magic Access Code to log in for now.';

  @override
  String get loginSwitchToMagicCode => 'Switch to Magic Code Login';

  @override
  String get loginErrorInvalidPhone =>
      'Please enter a valid phone number (e.g. +12345678).';

  @override
  String get loginErrorPasswordTooShort =>
      'Password must be at least 6 characters.';

  @override
  String get loginErrorInvalidCredentials => 'Invalid phone number or password.';

  @override
  String get loginErrorInvalidAccessCode =>
      'Please enter a valid access code (min 6 characters).';

  @override
  String get signUpErrorNameRequired => 'Full Name is required.';

  @override
  String get signUpErrorPhoneRequired =>
      'A valid phone number is required (e.g. +12345678).';

  @override
  String get signUpErrorPasswordMismatch => 'Passwords do not match.';

  @override
  String get signUpSuccess => 'Account created successfully! Please log in.';

  @override
  String get notifSettingsTitle => 'Notification settings';

  @override
  String get notifSettingsEmptyTitle => 'No tracked universities yet';

  @override
  String get notifSettingsEmptyBody =>
      'Tap "Track this institution" on a university page to follow it. Notification preferences appear here once you have at least one tracked institution.';

  @override
  String get notifSettingsCalendar => 'Calendar changes';

  @override
  String get notifSettingsCalendarDesc => 'Deadline dates move';

  @override
  String get notifSettingsCorrection => 'Correction notices';

  @override
  String get notifSettingsCorrectionDesc =>
      '정정공고 published — highest priority';

  @override
  String get notifSettingsRequirement => 'Requirement changes';

  @override
  String get notifSettingsRequirementDesc =>
      'TOPIK / GPA / language test rules change';

  @override
  String get notifSettingsScholarship => 'Scholarship updates';

  @override
  String get notifSettingsScholarshipDesc => 'Off by default — high volume';

  @override
  String notifSettingsLoadError(Object error) {
    return 'Error: $error';
  }

  @override
  String notifSettingsPushLanguage(String lang) {
    return 'Push payload language: $lang';
  }

  @override
  String notifSettingsUpdateError(Object error) {
    return 'Could not update preference: $error';
  }
}
