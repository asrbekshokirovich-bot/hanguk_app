// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get trainingTabTitle => 'Tayyorgarlik markazi';

  @override
  String get trainingTabSubtitle =>
      'Universitet arizalaringizni sun\'iy intellekt yordamida mashq qiling.';

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
  String get navHome => 'Bosh';

  @override
  String get navMap => 'Xarita';

  @override
  String get navDocs => 'Hujjatlar';

  @override
  String get navTraining => 'Tayyorgarlik';

  @override
  String get applicationsTabTitle => 'Arizalarim';

  @override
  String get mapTabTitle => 'Universitetlar';

  @override
  String get documentsTabTitle => 'Hujjatlarim';

  @override
  String get accountTooltip => 'Hisob';

  @override
  String get ok => 'OK';

  @override
  String get loadingLabel => 'Yuklanmoqda...';

  @override
  String get accountBackTooltip => 'Orqaga';

  @override
  String get accountTitle => 'Hisob';

  @override
  String get accountSignedInAs => 'Tizimga kirgan hisob';

  @override
  String get accountUnknownAccount => '(noma\'lum hisob)';

  @override
  String get accountSessionLabel => 'Sessiya';

  @override
  String get accountSigningOut => 'Chiqilmoqda...';

  @override
  String get accountSignOut => 'Tizimdan chiqish';

  @override
  String get accountYourDataLabel => 'Sizning ma\'lumotlaringiz';

  @override
  String get accountYourDataBody =>
      'Hanguk saqlab turgan barcha hisob ma\'lumotlaringizning — profil, arizalar, o\'quv rejalari, qoralamalar, intervyu seanslari va izohlar — JSON nusxasini yuklab oling.';

  @override
  String get accountPreparingExport => 'Eksport tayyorlanmoqda...';

  @override
  String get accountDownloadMyData => 'Ma\'lumotlarimni yuklab olish';

  @override
  String get accountDangerZoneLabel => 'Xavfli zona';

  @override
  String get accountDangerZoneBody =>
      'Hisobni o\'chirish qaytarib bo\'lmaydigan amaldir. Profilingiz, arizalaringiz, o\'quv rejalaringiz, motivatsion xat qoralamalari, intervyu seanslari va yozuvlaringiz butunlay o\'chiriladi. Saqlangan hujjatlar 30 kun ichida, zaxira nusxalari esa 90 kun ichida muddati tugaydi.';

  @override
  String get accountDeleteAccount => 'Hisobni o\'chirish';

  @override
  String get accountPrivacyPolicy => 'Maxfiylik siyosati';

  @override
  String get accountTermsOfService => 'Foydalanish shartlari';

  @override
  String get accountDeleteErrorTitle => 'Hisob o\'chirilmadi';

  @override
  String accountDeleteErrorBody(Object error) {
    return 'Ma\'lumotlaringizni o\'chirishda xatolik yuz berdi:\n\n$error\n\nO\'chirishni yakunlay olishimiz uchun privacy@hanguk.uz manziliga email yuboring.';
  }

  @override
  String accountExportFailed(Object error) {
    return 'Eksport amalga oshmadi: $error';
  }

  @override
  String get accountDeleteDialogTitle => 'Hisobingizni o\'chirib tashlaysizmi?';

  @override
  String get accountDeleteDialogBody =>
      'Bu hisobingizni, arizalaringizni, o\'quv rejalaringizni, motivatsion xat qoralamalarini, intervyu seanslari va yozuvlarini butunlay o\'chirib tashlaydi.\n\nTasdiqlash uchun DELETE deb yozing.';

  @override
  String get accountDeleteDialogConfirm => 'Butunlay o\'chirish';

  @override
  String get accountDeleteProgress => 'Hisob o\'chirilmoqda...';

  @override
  String get loginStudentPortal => 'Talaba portali';

  @override
  String get loginAccessCodeHelp =>
      'Konsultantingiz yoki universitet vakili bergan 8 belgili kirish kodini (harflar va raqamlar) kiriting.';

  @override
  String get loginAccessCodeButton => 'Kirish kodi orqali kirish';

  @override
  String get loginSwitchToPhone => '← Telefon raqami orqali kirmoqchiman';

  @override
  String get loginComingSoonTitle => 'Tez orada';

  @override
  String get loginComingSoonBody =>
      'Tizimlarimiz yangilanayotgani sababli ommaviy ro\'yxatdan o\'tish va telefon orqali kirish vaqtincha to\'xtatildi.\n\nTalabalar: hozircha sehrli kirish kodingiz bilan tizimga kiring.';

  @override
  String get loginSwitchToMagicCode => 'Sehrli kod orqali kirishga o\'tish';

  @override
  String get loginErrorInvalidPhone =>
      'Iltimos, to\'g\'ri telefon raqamini kiriting (masalan, +12345678).';

  @override
  String get loginErrorPasswordTooShort =>
      'Parol kamida 6 ta belgidan iborat bo\'lishi kerak.';

  @override
  String get loginErrorInvalidCredentials =>
      'Telefon raqami yoki parol noto\'g\'ri.';

  @override
  String get loginErrorInvalidAccessCode =>
      'Iltimos, to\'g\'ri kirish kodini kiriting (kamida 6 belgi).';

  @override
  String get signUpErrorNameRequired => 'To\'liq ismni kiritish shart.';

  @override
  String get signUpErrorPhoneRequired =>
      'To\'g\'ri telefon raqami kerak (masalan, +12345678).';

  @override
  String get signUpErrorPasswordMismatch => 'Parollar mos kelmadi.';

  @override
  String get signUpSuccess => 'Hisob yaratildi! Iltimos, tizimga kiring.';

  @override
  String get notifSettingsTitle => 'Bildirishnoma sozlamalari';

  @override
  String get notifSettingsEmptyTitle => 'Hali kuzatilayotgan universitet yo\'q';

  @override
  String get notifSettingsEmptyBody =>
      'Universitet sahifasida "Bu muassasani kuzatish"ni bosib obuna bo\'ling. Kamida bitta kuzatuv qo\'shilgach, bildirishnoma sozlamalari shu yerda paydo bo\'ladi.';

  @override
  String get notifSettingsCalendar => 'Taqvim o\'zgarishlari';

  @override
  String get notifSettingsCalendarDesc => 'Muddat sanalari o\'zgarsa';

  @override
  String get notifSettingsCorrection => 'Tuzatish e\'lonlari';

  @override
  String get notifSettingsCorrectionDesc =>
      '정정공고 e\'lon qilindi — eng yuqori ustuvorlik';

  @override
  String get notifSettingsRequirement => 'Talab o\'zgarishlari';

  @override
  String get notifSettingsRequirementDesc =>
      'TOPIK / GPA / til imtihoni qoidalari o\'zgarsa';

  @override
  String get notifSettingsScholarship => 'Stipendiya yangiliklari';

  @override
  String get notifSettingsScholarshipDesc =>
      'Standart bo\'yicha o\'chirilgan — ko\'p bildirishnoma keladi';

  @override
  String notifSettingsLoadError(Object error) {
    return 'Xato: $error';
  }

  @override
  String notifSettingsPushLanguage(String lang) {
    return 'Push bildirishnoma tili: $lang';
  }

  @override
  String notifSettingsUpdateError(Object error) {
    return 'Sozlamani yangilab bo\'lmadi: $error';
  }
}
