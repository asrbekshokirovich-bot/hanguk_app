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
