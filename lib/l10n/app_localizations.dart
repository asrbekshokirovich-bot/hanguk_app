import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uz'),
    Locale('ko'),
    Locale('ru'),
    Locale('vi'),
  ];

  /// Title of the Training bottom-nav tab.
  ///
  /// In en, this message translates to:
  /// **'Training Center'**
  String get trainingTabTitle;

  /// One-line description of the Training tab.
  ///
  /// In en, this message translates to:
  /// **'Prepare for your university applications with AI-guided training modules.'**
  String get trainingTabSubtitle;

  /// No description provided for @studyPlanCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Plan Builder'**
  String get studyPlanCardTitle;

  /// No description provided for @studyPlanCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Craft a compelling roadmap for your academic journey.'**
  String get studyPlanCardDesc;

  /// No description provided for @personalStatementCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Statement'**
  String get personalStatementCardTitle;

  /// No description provided for @personalStatementCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Write effective and engaging personal essays.'**
  String get personalStatementCardDesc;

  /// No description provided for @interviewCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview Preparation'**
  String get interviewCardTitle;

  /// No description provided for @interviewCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice mock questions and improve your confidence.'**
  String get interviewCardDesc;

  /// No description provided for @applyCta.
  ///
  /// In en, this message translates to:
  /// **'Apply to a university'**
  String get applyCta;

  /// No description provided for @noApplicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get noApplicationsTitle;

  /// No description provided for @noApplicationsBody.
  ///
  /// In en, this message translates to:
  /// **'Add a target university first — drafting starts from a target school.'**
  String get noApplicationsBody;

  /// No description provided for @startInterview.
  ///
  /// In en, this message translates to:
  /// **'Start Interview'**
  String get startInterview;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @endInterview.
  ///
  /// In en, this message translates to:
  /// **'End Interview'**
  String get endInterview;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get practiceAgain;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @greetWait.
  ///
  /// In en, this message translates to:
  /// **'Connecting — your interviewer will greet you shortly...'**
  String get greetWait;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn to speak'**
  String get yourTurn;

  /// No description provided for @aiSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Interviewer is speaking...'**
  String get aiSpeaking;

  /// No description provided for @wrappingUp.
  ///
  /// In en, this message translates to:
  /// **'Wrapping up the interview...'**
  String get wrappingUp;

  /// No description provided for @micRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required for the interview.'**
  String get micRequired;

  /// Shown while the Kakao Roadview WebView is fetching a panorama.
  ///
  /// In en, this message translates to:
  /// **'Loading campus walkaround'**
  String get walkaroundLoadingTitle;

  /// No description provided for @walkaroundLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetching street view near campus.'**
  String get walkaroundLoadingSubtitle;

  /// Shown when no Kakao panorama is found within 200m of the campus pin.
  ///
  /// In en, this message translates to:
  /// **'No street view here'**
  String get walkaroundNoPanoTitle;

  /// No description provided for @walkaroundNoPanoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This campus doesn\'t have a walkable street view nearby.'**
  String get walkaroundNoPanoSubtitle;

  /// Shown when the Kakao JS SDK loads but is blocked at runtime.
  ///
  /// In en, this message translates to:
  /// **'Street view unavailable'**
  String get walkaroundBlockedTitle;

  /// No description provided for @walkaroundBlockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The map provider blocked this request. Try again on a different network.'**
  String get walkaroundBlockedSubtitle;

  /// Shown when the Kakao JS SDK fails to load (network error).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the map provider'**
  String get walkaroundNetworkTitle;

  /// No description provided for @walkaroundNetworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get walkaroundNetworkSubtitle;

  /// Shown when initializing the Kakao Roadview throws unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Street view couldn\'t start'**
  String get walkaroundInitErrorTitle;

  /// No description provided for @walkaroundInitErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong starting the walkaround. Please try again.'**
  String get walkaroundInitErrorSubtitle;

  /// Button label for the curated panorama tour (Pannellum), when available.
  ///
  /// In en, this message translates to:
  /// **'Virtual Tour'**
  String get virtualTourTitle;

  /// Button label for the Kakao Roadview walkaround.
  ///
  /// In en, this message translates to:
  /// **'Virtual Walkaround'**
  String get virtualWalkaroundTitle;

  /// Bottom-nav label for the Applications/Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom-nav label for the Map tab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Bottom-nav label for the Documents tab.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get navDocs;

  /// Bottom-nav label for the Training tab. Kept short for the nav bar —
  /// the full screen title is trainingTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get navTraining;

  /// AppBar title for the Applications tab.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get applicationsTabTitle;

  /// Top-bar title for the Map tab.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get mapTabTitle;

  /// AppBar title for the Documents tab.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get documentsTabTitle;

  /// Tooltip for the account icon button in the Applications AppBar —
  /// opens the AccountScreen with sign-out, data export, and delete
  /// account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTooltip;

  /// Generic confirm/dismiss button used in alert dialogs.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Neutral 'Loading...' label used by spinner placeholder views.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// Tooltip on the back arrow at the top of the AccountScreen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get accountBackTooltip;

  /// Header shown next to the back arrow at the top of the AccountScreen.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// Label above the email/phone of the currently logged-in user.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get accountSignedInAs;

  /// Fallback shown when neither email nor phone is available for the
  /// current Supabase user.
  ///
  /// In en, this message translates to:
  /// **'(unknown account)'**
  String get accountUnknownAccount;

  /// Section header for the sign-out card on the AccountScreen.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get accountSessionLabel;

  /// Label on the sign-out button while the sign-out call is in flight.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get accountSigningOut;

  /// Idle label on the sign-out button.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Section header for the data-export card (PIPA + GDPR right to data
  /// portability).
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get accountYourDataLabel;

  /// Body copy under the 'Your data' header.
  ///
  /// In en, this message translates to:
  /// **'Download a JSON copy of everything Hanguk holds about your account — profile, applications, study plans, drafts, interview sessions and feedback.'**
  String get accountYourDataBody;

  /// Label on the data-export button while the call is in flight.
  ///
  /// In en, this message translates to:
  /// **'Preparing export…'**
  String get accountPreparingExport;

  /// Idle label on the data-export button.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get accountDownloadMyData;

  /// Section header for the delete-account card on the AccountScreen. Red.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get accountDangerZoneLabel;

  /// Body copy under the 'Danger zone' header.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent. We will erase your profile, applications, study plans, personal-statement drafts, interview sessions, and transcripts. Documents in storage are removed within 30 days; backups age out within 90 days.'**
  String get accountDangerZoneBody;

  /// Label on the red 'Delete account' button.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteAccount;

  /// Legal footer link on the AccountScreen.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get accountPrivacyPolicy;

  /// Legal footer link on the AccountScreen.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get accountTermsOfService;

  /// Title of the AlertDialog shown when fn_delete_my_account RPC throws.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account'**
  String get accountDeleteErrorTitle;

  /// Body of the AlertDialog shown when fn_delete_my_account RPC throws.
  ///
  /// In en, this message translates to:
  /// **'We hit an error while deleting your data:\n\n{error}\n\nPlease email privacy@hanguk.uz so we can finish the deletion for you.'**
  String accountDeleteErrorBody(Object error);

  /// SnackBar message shown when the export-my-data Edge Function fails.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String accountExportFailed(Object error);

  /// Title of the 'type DELETE to confirm' dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get accountDeleteDialogTitle;

  /// Body of the 'type DELETE to confirm' dialog. The literal 'DELETE'
  /// is intentionally untranslated — the TextField compares against it.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account, applications, study plans, personal-statement drafts, interview sessions, and transcripts.\n\nType DELETE to confirm.'**
  String get accountDeleteDialogBody;

  /// Label on the red confirm button at the bottom of the delete dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get accountDeleteDialogConfirm;

  /// Status text shown in the non-dismissible deletion progress dialog.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get accountDeleteProgress;

  /// Subtitle under the 'Hanguk' wordmark on the LoginScreen card.
  ///
  /// In en, this message translates to:
  /// **'Student Portal'**
  String get loginStudentPortal;

  /// Help text above the magic-code TextField.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-character access code (letters and numbers) provided by your consultant or university representative.'**
  String get loginAccessCodeHelp;

  /// Primary button label in magic-code mode.
  ///
  /// In en, this message translates to:
  /// **'Login manually with Access Code'**
  String get loginAccessCodeButton;

  /// Fallback TextButton that returns to the phone-login UI.
  ///
  /// In en, this message translates to:
  /// **'← I actually want to Log in via Phone Number'**
  String get loginSwitchToPhone;

  /// Title of the 'maintenance' card on the LoginScreen.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get loginComingSoonTitle;

  /// Body of the 'maintenance' card on the LoginScreen.
  ///
  /// In en, this message translates to:
  /// **'Public sign up and phone login are currently under maintenance as we upgrade our systems.\n\nStudents: Please use your Magic Access Code to log in for now.'**
  String get loginComingSoonBody;

  /// TextButton inside the 'Coming Soon' card.
  ///
  /// In en, this message translates to:
  /// **'Switch to Magic Code Login'**
  String get loginSwitchToMagicCode;

  /// Validation error when the phone number on Sign In is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number (e.g. +12345678).'**
  String get loginErrorInvalidPhone;

  /// Validation error when the password is shorter than 6 chars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginErrorPasswordTooShort;

  /// Error shown after Supabase signInWithPhone rejects the credentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number or password.'**
  String get loginErrorInvalidCredentials;

  /// Validation error when the magic code is too short.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid access code (min 6 characters).'**
  String get loginErrorInvalidAccessCode;

  /// Sign-Up validation error: name is empty.
  ///
  /// In en, this message translates to:
  /// **'Full Name is required.'**
  String get signUpErrorNameRequired;

  /// Sign-Up validation error: phone is empty/too short.
  ///
  /// In en, this message translates to:
  /// **'A valid phone number is required (e.g. +12345678).'**
  String get signUpErrorPhoneRequired;

  /// Sign-Up validation error: confirm password mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get signUpErrorPasswordMismatch;

  /// Sign-Up success banner.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Please log in.'**
  String get signUpSuccess;

  /// AppBar title for the /notifications/settings screen.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notifSettingsTitle;

  /// Empty-state title on the notification settings screen.
  ///
  /// In en, this message translates to:
  /// **'No tracked universities yet'**
  String get notifSettingsEmptyTitle;

  /// Empty-state body on the notification settings screen.
  ///
  /// In en, this message translates to:
  /// **'Tap "Track this institution" on a university page to follow it. Notification preferences appear here once you have at least one tracked institution.'**
  String get notifSettingsEmptyBody;

  /// SwitchListTile title — toggles notify_on_calendar_change.
  ///
  /// In en, this message translates to:
  /// **'Calendar changes'**
  String get notifSettingsCalendar;

  /// SwitchListTile subtitle for the calendar-changes toggle.
  ///
  /// In en, this message translates to:
  /// **'Deadline dates move'**
  String get notifSettingsCalendarDesc;

  /// SwitchListTile title — toggles notify_on_correction.
  ///
  /// In en, this message translates to:
  /// **'Correction notices'**
  String get notifSettingsCorrection;

  /// SwitchListTile subtitle for the correction-notice toggle.
  ///
  /// In en, this message translates to:
  /// **'정정공고 published — highest priority'**
  String get notifSettingsCorrectionDesc;

  /// SwitchListTile title — toggles notify_on_requirement_change.
  ///
  /// In en, this message translates to:
  /// **'Requirement changes'**
  String get notifSettingsRequirement;

  /// SwitchListTile subtitle for the requirement-changes toggle.
  ///
  /// In en, this message translates to:
  /// **'TOPIK / GPA / language test rules change'**
  String get notifSettingsRequirementDesc;

  /// SwitchListTile title — toggles notify_on_scholarship_change.
  ///
  /// In en, this message translates to:
  /// **'Scholarship updates'**
  String get notifSettingsScholarship;

  /// SwitchListTile subtitle for the scholarship-updates toggle.
  ///
  /// In en, this message translates to:
  /// **'Off by default — high volume'**
  String get notifSettingsScholarshipDesc;

  /// Centered error message when the notification settings provider
  /// is in the error state.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String notifSettingsLoadError(Object error);

  /// Label above each per-institution card showing the preferred
  /// notification language.
  ///
  /// In en, this message translates to:
  /// **'Push payload language: {lang}'**
  String notifSettingsPushLanguage(String lang);

  /// SnackBar message when updateNotificationPrefs() throws.
  ///
  /// In en, this message translates to:
  /// **'Could not update preference: {error}'**
  String notifSettingsUpdateError(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'ru', 'uz', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
