import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Biblia Traditio'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Scripture in the light of Tradition.'**
  String get tagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLiturgy.
  ///
  /// In en, this message translates to:
  /// **'Liturgy'**
  String get navLiturgy;

  /// No description provided for @navBible.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get navBible;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @greetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Peace be with you'**
  String get greetingFallback;

  /// No description provided for @quickContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get quickContinue;

  /// No description provided for @quickToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get quickToday;

  /// No description provided for @quickFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get quickFavorites;

  /// No description provided for @homeJourney.
  ///
  /// In en, this message translates to:
  /// **'Continue your journey'**
  String get homeJourney;

  /// No description provided for @readingPlan.
  ///
  /// In en, this message translates to:
  /// **'Reading plan'**
  String get readingPlan;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal reflections'**
  String get notesEmptySubtitle;

  /// No description provided for @noteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String noteCount(int count);

  /// No description provided for @liturgyToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s liturgy'**
  String get liturgyToday;

  /// No description provided for @ordinaryTime.
  ///
  /// In en, this message translates to:
  /// **'Ordinary Time'**
  String get ordinaryTime;

  /// No description provided for @liturgicalYear.
  ///
  /// In en, this message translates to:
  /// **'Year {cycle}'**
  String liturgicalYear(String cycle);

  /// No description provided for @readingFirst.
  ///
  /// In en, this message translates to:
  /// **'1st reading'**
  String get readingFirst;

  /// No description provided for @readingPsalm.
  ///
  /// In en, this message translates to:
  /// **'Psalm'**
  String get readingPsalm;

  /// No description provided for @readingSecond.
  ///
  /// In en, this message translates to:
  /// **'2nd reading'**
  String get readingSecond;

  /// No description provided for @readingGospel.
  ///
  /// In en, this message translates to:
  /// **'Gospel'**
  String get readingGospel;

  /// No description provided for @onbNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onbNameTitle;

  /// No description provided for @onbNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use your name to greet you.'**
  String get onbNameSubtitle;

  /// No description provided for @namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get namePlaceholder;

  /// No description provided for @onbLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onbLanguageTitle;

  /// No description provided for @onbLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which language do you prefer for the interface?'**
  String get onbLanguageSubtitle;

  /// No description provided for @onbTranslationTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get onbTranslationTitle;

  /// No description provided for @onbTranslationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your primary Scripture translation.'**
  String get onbTranslationSubtitle;

  /// No description provided for @onbNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get onbNotificationsTitle;

  /// No description provided for @onbNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive a gentle invitation to the day\'s reading and liturgy.'**
  String get onbNotificationsSubtitle;

  /// No description provided for @onbPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading plan'**
  String get onbPlanTitle;

  /// No description provided for @onbPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Would you like to follow a plan to read the Scriptures?'**
  String get onbPlanSubtitle;

  /// No description provided for @onbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbContinue;

  /// No description provided for @onbEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get onbEnter;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @bibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Bible'**
  String get bibleTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @oldTestament.
  ///
  /// In en, this message translates to:
  /// **'Old Testament'**
  String get oldTestament;

  /// No description provided for @newTestament.
  ///
  /// In en, this message translates to:
  /// **'New Testament'**
  String get newTestament;

  /// No description provided for @oldTestamentShort.
  ///
  /// In en, this message translates to:
  /// **'OT'**
  String get oldTestamentShort;

  /// No description provided for @newTestamentShort.
  ///
  /// In en, this message translates to:
  /// **'NT'**
  String get newTestamentShort;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found.'**
  String get noBooksFound;

  /// No description provided for @contentNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Content not installed yet.\nInstall a translation pack in Settings.'**
  String get contentNotInstalled;

  /// No description provided for @chapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterTitle(int number);

  /// No description provided for @chapterPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'{book} — chapter'**
  String chapterPickerTitle(String book);

  /// No description provided for @goToVerse.
  ///
  /// In en, this message translates to:
  /// **'Go to verse'**
  String get goToVerse;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @scriptureNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'The Bible text is not installed yet.'**
  String get scriptureNotInstalled;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyVerse.
  ///
  /// In en, this message translates to:
  /// **'Copy verse'**
  String get copyVerse;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @unbookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get unbookmark;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Notes ({count})'**
  String notesWithCount(int count);

  /// No description provided for @churchFathers.
  ///
  /// In en, this message translates to:
  /// **'Church Fathers'**
  String get churchFathers;

  /// No description provided for @colorMode.
  ///
  /// In en, this message translates to:
  /// **'Color mode'**
  String get colorMode;

  /// No description provided for @fontSizeSoon.
  ///
  /// In en, this message translates to:
  /// **'Font size (soon)'**
  String get fontSizeSoon;

  /// No description provided for @century.
  ///
  /// In en, this message translates to:
  /// **'cent. {value}'**
  String century(String value);

  /// No description provided for @machineTranslation.
  ///
  /// In en, this message translates to:
  /// **'machine translation'**
  String get machineTranslation;

  /// No description provided for @shareCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get shareCopy;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get shareText;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get shareImage;

  /// No description provided for @noteEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Note — {reference}'**
  String noteEditorTitle(String reference);

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reflection…'**
  String get noteHint;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Scripture, Fathers, notes…'**
  String get searchHint;

  /// No description provided for @searchScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchScopeAll;

  /// No description provided for @searchScopeScripture.
  ///
  /// In en, this message translates to:
  /// **'Scripture'**
  String get searchScopeScripture;

  /// No description provided for @searchScopeFathers.
  ///
  /// In en, this message translates to:
  /// **'Fathers'**
  String get searchScopeFathers;

  /// No description provided for @searchScopeNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get searchScopeNotes;

  /// No description provided for @searchTypeMore.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters to search.'**
  String get searchTypeMore;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”.'**
  String searchNoResults(String query);

  /// No description provided for @sectionScripture.
  ///
  /// In en, this message translates to:
  /// **'Scripture'**
  String get sectionScripture;

  /// No description provided for @notesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesScreenTitle;

  /// No description provided for @searchNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchNotesHint;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotesYet;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.'**
  String get noFavoritesYet;

  /// No description provided for @highlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlightsTitle;

  /// No description provided for @noHighlightsYet.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet.'**
  String get noHighlightsYet;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsName;

  /// No description provided for @settingsReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get settingsReading;

  /// No description provided for @settingsTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get settingsTranslation;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get settingsReminders;

  /// No description provided for @settingsOfflineResources.
  ///
  /// In en, this message translates to:
  /// **'Offline resources'**
  String get settingsOfflineResources;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact / Feedback'**
  String get settingsContact;

  /// No description provided for @whatsappTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us on WhatsApp'**
  String get whatsappTitle;

  /// No description provided for @whatsappSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send suggestions and report issues'**
  String get whatsappSubtitle;

  /// No description provided for @noTranslationInstalled.
  ///
  /// In en, this message translates to:
  /// **'None installed'**
  String get noTranslationInstalled;

  /// No description provided for @packageRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get packageRequired;

  /// No description provided for @packageInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed · {size}'**
  String packageInstalled(String size);

  /// No description provided for @packageDownload.
  ///
  /// In en, this message translates to:
  /// **'Download {download} · {installed} installed'**
  String packageDownload(String download, String installed);

  /// No description provided for @installFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed: {error}'**
  String installFailed(String error);

  /// No description provided for @liturgyTitle.
  ///
  /// In en, this message translates to:
  /// **'Liturgy'**
  String get liturgyTitle;

  /// No description provided for @celebrationOfDay.
  ///
  /// In en, this message translates to:
  /// **'Celebration of the day'**
  String get celebrationOfDay;

  /// No description provided for @lectionaryNotice.
  ///
  /// In en, this message translates to:
  /// **'The liturgical calendar is available offline. The Mass readings require the Lectionary pack (coming soon).'**
  String get lectionaryNotice;

  /// No description provided for @preparingBible.
  ///
  /// In en, this message translates to:
  /// **'Preparing the Bible…'**
  String get preparingBible;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Failed to start.'**
  String get startupError;

  /// No description provided for @seasonAdvent.
  ///
  /// In en, this message translates to:
  /// **'Advent'**
  String get seasonAdvent;

  /// No description provided for @seasonChristmas.
  ///
  /// In en, this message translates to:
  /// **'Christmas Time'**
  String get seasonChristmas;

  /// No description provided for @seasonOrdinary.
  ///
  /// In en, this message translates to:
  /// **'Ordinary Time'**
  String get seasonOrdinary;

  /// No description provided for @seasonLent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get seasonLent;

  /// No description provided for @seasonTriduum.
  ///
  /// In en, this message translates to:
  /// **'Paschal Triduum'**
  String get seasonTriduum;

  /// No description provided for @seasonEaster.
  ///
  /// In en, this message translates to:
  /// **'Eastertide'**
  String get seasonEaster;

  /// No description provided for @rankSolemnity.
  ///
  /// In en, this message translates to:
  /// **'Solemnity'**
  String get rankSolemnity;

  /// No description provided for @rankFeast.
  ///
  /// In en, this message translates to:
  /// **'Feast'**
  String get rankFeast;

  /// No description provided for @rankMemorial.
  ///
  /// In en, this message translates to:
  /// **'Memorial'**
  String get rankMemorial;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'pt':
      return AppL10nPt();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
