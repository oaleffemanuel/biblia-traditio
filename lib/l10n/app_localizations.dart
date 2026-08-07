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

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @removePackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove package?'**
  String get removePackageTitle;

  /// No description provided for @removePackageMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to download it again to reinstall.'**
  String get removePackageMessage;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteMessage.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteNoteMessage;

  /// No description provided for @contactLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open WhatsApp.'**
  String get contactLaunchFailed;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @installSuccess.
  ///
  /// In en, this message translates to:
  /// **'Installed successfully'**
  String get installSuccess;

  /// No description provided for @removeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Package removed'**
  String get removeSuccess;

  /// No description provided for @highlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlight;

  /// No description provided for @deuterocanonicalShort.
  ///
  /// In en, this message translates to:
  /// **'DC'**
  String get deuterocanonicalShort;

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

  /// No description provided for @planSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A year through Sacred Scripture'**
  String get planSubtitle;

  /// No description provided for @planToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get planToday;

  /// No description provided for @planDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String planDay(int day);

  /// No description provided for @planDayProgress.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String planDayProgress(int day, int total);

  /// No description provided for @planProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} days read'**
  String planProgress(int done, int total);

  /// No description provided for @planMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get planMarkRead;

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
  /// **'First Reading'**
  String get readingFirst;

  /// No description provided for @readingPsalm.
  ///
  /// In en, this message translates to:
  /// **'Psalm'**
  String get readingPsalm;

  /// No description provided for @readingSecond.
  ///
  /// In en, this message translates to:
  /// **'Second Reading'**
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

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @noCommentaryForVerse.
  ///
  /// In en, this message translates to:
  /// **'No commentary available for this verse yet.'**
  String get noCommentaryForVerse;

  /// No description provided for @patristicsNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Install the Church Fathers commentary in Settings to read this verse with the Church.'**
  String get patristicsNotInstalled;

  /// No description provided for @noNotesForVerse.
  ///
  /// In en, this message translates to:
  /// **'No notes for this verse yet.'**
  String get noNotesForVerse;

  /// No description provided for @writeReflection.
  ///
  /// In en, this message translates to:
  /// **'Write a reflection'**
  String get writeReflection;

  /// No description provided for @commentaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 commentary} other{{count} commentaries}}'**
  String commentaryCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterFathers.
  ///
  /// In en, this message translates to:
  /// **'Patristics'**
  String get filterFathers;

  /// No description provided for @filterMedieval.
  ///
  /// In en, this message translates to:
  /// **'Medieval'**
  String get filterMedieval;

  /// No description provided for @filterAugustine.
  ///
  /// In en, this message translates to:
  /// **'St Augustine'**
  String get filterAugustine;

  /// No description provided for @filterAquinas.
  ///
  /// In en, this message translates to:
  /// **'St Thomas Aquinas'**
  String get filterAquinas;

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

  /// No description provided for @parallelReading.
  ///
  /// In en, this message translates to:
  /// **'Parallel reading'**
  String get parallelReading;

  /// No description provided for @singleTranslation.
  ///
  /// In en, this message translates to:
  /// **'Single translation'**
  String get singleTranslation;

  /// No description provided for @parallelOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parallel reading'**
  String get parallelOptionsTitle;

  /// No description provided for @secondaryTranslation.
  ///
  /// In en, this message translates to:
  /// **'Secondary translation'**
  String get secondaryTranslation;

  /// No description provided for @noSecondaryTranslation.
  ///
  /// In en, this message translates to:
  /// **'No secondary translation installed yet.'**
  String get noSecondaryTranslation;

  /// No description provided for @openOfflineResources.
  ///
  /// In en, this message translates to:
  /// **'Open Offline resources'**
  String get openOfflineResources;

  /// No description provided for @verseNotInTranslation.
  ///
  /// In en, this message translates to:
  /// **'Verse not available in this translation.'**
  String get verseNotInTranslation;

  /// No description provided for @parallelLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get parallelLayoutLabel;

  /// No description provided for @layoutAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get layoutAuto;

  /// No description provided for @layoutStacked.
  ///
  /// In en, this message translates to:
  /// **'Stacked'**
  String get layoutStacked;

  /// No description provided for @layoutSideBySide.
  ///
  /// In en, this message translates to:
  /// **'Side by side'**
  String get layoutSideBySide;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Scripture, Patristics, notes…'**
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
  /// **'Patristics'**
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

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @licensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Licenses & Attributions'**
  String get licensesTitle;

  /// No description provided for @licensesIntro.
  ///
  /// In en, this message translates to:
  /// **'Biblia Traditio respects the sources it uses. Below is the origin and license of each.'**
  String get licensesIntro;

  /// No description provided for @licVulgataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clementine Vulgate (Latin)'**
  String get licVulgataTitle;

  /// No description provided for @licVulgataBody.
  ///
  /// In en, this message translates to:
  /// **'Latin biblical text in the public domain.'**
  String get licVulgataBody;

  /// No description provided for @licPatristicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Church Fathers\' Commentary'**
  String get licPatristicsTitle;

  /// No description provided for @licPatristicsBody.
  ///
  /// In en, this message translates to:
  /// **'Patristic sources in the public domain, machine-translated and adapted. May contain inaccuracies — read with discernment.'**
  String get licPatristicsBody;

  /// No description provided for @licPortugueseTitle.
  ///
  /// In en, this message translates to:
  /// **'Portuguese Bible (beta)'**
  String get licPortugueseTitle;

  /// No description provided for @licPortugueseBody.
  ///
  /// In en, this message translates to:
  /// **'An internal version for this testing phase. The translation\'s provenance will be confirmed before any public release.'**
  String get licPortugueseBody;

  /// No description provided for @licMatosTitle.
  ///
  /// In en, this message translates to:
  /// **'Padre Matos Soares (Portuguese)'**
  String get licMatosTitle;

  /// No description provided for @licMatosBody.
  ///
  /// In en, this message translates to:
  /// **'Catholic translation by Fr. Matos Soares (d. 1950) — a public-domain candidate in Brazil since 2021 (life + 70 years). Provenance is being verified during the beta.'**
  String get licMatosBody;

  /// No description provided for @ossLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get ossLicenses;

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
  /// **'Readings for this day are not available yet.'**
  String get lectionaryNotice;

  /// No description provided for @liturgyOpenInBible.
  ///
  /// In en, this message translates to:
  /// **'Open in Bible'**
  String get liturgyOpenInBible;

  /// No description provided for @readingTextUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reading text not available.'**
  String get readingTextUnavailable;

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

  /// No description provided for @liturgyResponseWordOfLord.
  ///
  /// In en, this message translates to:
  /// **'The word of the Lord.'**
  String get liturgyResponseWordOfLord;

  /// No description provided for @liturgyResponseThanksToGod.
  ///
  /// In en, this message translates to:
  /// **'Thanks be to God.'**
  String get liturgyResponseThanksToGod;

  /// No description provided for @liturgyResponseGloryToYou.
  ///
  /// In en, this message translates to:
  /// **'Glory to you, O Lord.'**
  String get liturgyResponseGloryToYou;

  /// No description provided for @liturgyResponseWordOfSalvation.
  ///
  /// In en, this message translates to:
  /// **'The Gospel of the Lord.'**
  String get liturgyResponseWordOfSalvation;

  /// No description provided for @liturgyGospelAccording.
  ///
  /// In en, this message translates to:
  /// **'A reading from the holy Gospel according to {evangelist}'**
  String liturgyGospelAccording(String evangelist);

  /// No description provided for @licGreekTitle.
  ///
  /// In en, this message translates to:
  /// **'Greek New Testament (SBLGNT)'**
  String get licGreekTitle;

  /// No description provided for @licGreekBody.
  ///
  /// In en, this message translates to:
  /// **'The SBL Greek New Testament (SBLGNT), © Society of Biblical Literature and Logos Bible Software. Used under the Creative Commons Attribution 4.0 license.'**
  String get licGreekBody;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit.'**
  String get pressBackAgainToExit;

  /// No description provided for @searchScopeBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get searchScopeBooks;

  /// No description provided for @sectionBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get sectionBooks;

  /// No description provided for @sectionGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get sectionGoTo;

  /// No description provided for @searchOpenBook.
  ///
  /// In en, this message translates to:
  /// **'Open book'**
  String get searchOpenBook;

  /// No description provided for @commentaryTabPatristics.
  ///
  /// In en, this message translates to:
  /// **'Patristics'**
  String get commentaryTabPatristics;

  /// No description provided for @commentaryExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get commentaryExpandAll;

  /// No description provided for @commentaryCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get commentaryCollapseAll;

  /// No description provided for @commentaryCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get commentaryCollapse;

  /// No description provided for @shareCommentary.
  ///
  /// In en, this message translates to:
  /// **'Share commentary'**
  String get shareCommentary;

  /// No description provided for @roleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor of the Church'**
  String get roleDoctor;

  /// No description provided for @rolePope.
  ///
  /// In en, this message translates to:
  /// **'Pope'**
  String get rolePope;

  /// No description provided for @roleBishop.
  ///
  /// In en, this message translates to:
  /// **'Bishop'**
  String get roleBishop;

  /// No description provided for @roleMonk.
  ///
  /// In en, this message translates to:
  /// **'Monk'**
  String get roleMonk;

  /// No description provided for @rolePriest.
  ///
  /// In en, this message translates to:
  /// **'Priest'**
  String get rolePriest;

  /// No description provided for @roleDeacon.
  ///
  /// In en, this message translates to:
  /// **'Deacon'**
  String get roleDeacon;

  /// No description provided for @roleExegete.
  ///
  /// In en, this message translates to:
  /// **'Exegete'**
  String get roleExegete;

  /// No description provided for @roleTheologian.
  ///
  /// In en, this message translates to:
  /// **'Theologian'**
  String get roleTheologian;

  /// No description provided for @roleHistorian.
  ///
  /// In en, this message translates to:
  /// **'Historian'**
  String get roleHistorian;

  /// No description provided for @rolePoet.
  ///
  /// In en, this message translates to:
  /// **'Poet'**
  String get rolePoet;

  /// No description provided for @rolePatristics.
  ///
  /// In en, this message translates to:
  /// **'Patristics'**
  String get rolePatristics;

  /// No description provided for @roleMedieval.
  ///
  /// In en, this message translates to:
  /// **'Medieval'**
  String get roleMedieval;

  /// No description provided for @roleEarlyChristian.
  ///
  /// In en, this message translates to:
  /// **'Early Christian'**
  String get roleEarlyChristian;

  /// No description provided for @roleSaint.
  ///
  /// In en, this message translates to:
  /// **'Saint'**
  String get roleSaint;

  /// No description provided for @roleSaintFem.
  ///
  /// In en, this message translates to:
  /// **'Saint'**
  String get roleSaintFem;

  /// No description provided for @roleLiturgy.
  ///
  /// In en, this message translates to:
  /// **'Liturgy'**
  String get roleLiturgy;

  /// No description provided for @roleDocPatristic.
  ///
  /// In en, this message translates to:
  /// **'Patristic Document'**
  String get roleDocPatristic;

  /// No description provided for @roleDocMedieval.
  ///
  /// In en, this message translates to:
  /// **'Medieval Document'**
  String get roleDocMedieval;

  /// No description provided for @roleDocHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical Document'**
  String get roleDocHistorical;

  /// No description provided for @roleDocGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Document'**
  String get roleDocGeneral;

  /// No description provided for @authorMeta.
  ///
  /// In en, this message translates to:
  /// **'{role} — {century} cent.'**
  String authorMeta(String role, String century);

  /// No description provided for @settingsCommentary.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get settingsCommentary;

  /// No description provided for @commentaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Commentary preferences'**
  String get commentaryPreferences;

  /// No description provided for @commentaryPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which commentators appear when you open a verse.'**
  String get commentaryPreferencesSubtitle;

  /// No description provided for @commentaryClassification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get commentaryClassification;

  /// No description provided for @commentaryCenturies.
  ///
  /// In en, this message translates to:
  /// **'Centuries'**
  String get commentaryCenturies;

  /// No description provided for @filterScholastic.
  ///
  /// In en, this message translates to:
  /// **'Scholastic'**
  String get filterScholastic;

  /// No description provided for @filterSaints.
  ///
  /// In en, this message translates to:
  /// **'Saints'**
  String get filterSaints;

  /// No description provided for @commentaryOnlySaints.
  ///
  /// In en, this message translates to:
  /// **'Saints only'**
  String get commentaryOnlySaints;

  /// No description provided for @commentaryOnlySaintsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simplified mode: show only saints.'**
  String get commentaryOnlySaintsSubtitle;

  /// No description provided for @commentaryResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get commentaryResetDefaults;

  /// No description provided for @commentaryPrefsAll.
  ///
  /// In en, this message translates to:
  /// **'All commentators'**
  String get commentaryPrefsAll;

  /// No description provided for @commentaryPrefsFilters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter active} other{{count} filters active}}'**
  String commentaryPrefsFilters(int count);

  /// No description provided for @commentaryHiddenByPrefs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 commentary hidden by your preferences} other{{count} commentaries hidden by your preferences}}'**
  String commentaryHiddenByPrefs(int count);

  /// No description provided for @commentaryShowHidden.
  ///
  /// In en, this message translates to:
  /// **'Show anyway'**
  String get commentaryShowHidden;

  /// No description provided for @shareSelectVerses.
  ///
  /// In en, this message translates to:
  /// **'Select verses'**
  String get shareSelectVerses;

  /// No description provided for @shareSelectionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Selection too long for an image (max {max} characters). Choose fewer verses.'**
  String shareSelectionTooLong(int max);

  /// No description provided for @selectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verse selected} other{{count} verses selected}}'**
  String selectionCount(int count);

  /// No description provided for @selectionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap verses to choose a continuous passage.'**
  String get selectionHint;

  /// No description provided for @selectionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get selectionClear;

  /// No description provided for @shareSelection.
  ///
  /// In en, this message translates to:
  /// **'Share selection'**
  String get shareSelection;

  /// No description provided for @planSectionBook.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get planSectionBook;

  /// No description provided for @planSectionWisdom.
  ///
  /// In en, this message translates to:
  /// **'Wisdom'**
  String get planSectionWisdom;

  /// No description provided for @planCompleted.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get planCompleted;

  /// No description provided for @onbStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Which translation style do you prefer?'**
  String get onbStyleTitle;

  /// No description provided for @onbStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use this to suggest a translation. All of them stay available.'**
  String get onbStyleSubtitle;

  /// No description provided for @styleAcademic.
  ///
  /// In en, this message translates to:
  /// **'More academic'**
  String get styleAcademic;

  /// No description provided for @styleSimple.
  ///
  /// In en, this message translates to:
  /// **'Simpler'**
  String get styleSimple;

  /// No description provided for @styleBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get styleBalanced;

  /// No description provided for @styleLiturgical.
  ///
  /// In en, this message translates to:
  /// **'Liturgical'**
  String get styleLiturgical;

  /// No description provided for @onbParallelTitle.
  ///
  /// In en, this message translates to:
  /// **'Would you like a parallel text?'**
  String get onbParallelTitle;

  /// No description provided for @onbParallelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only texts actually installed are shown.'**
  String get onbParallelSubtitle;

  /// No description provided for @parallelLatin.
  ///
  /// In en, this message translates to:
  /// **'Latin'**
  String get parallelLatin;

  /// No description provided for @parallelGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get parallelGreek;

  /// No description provided for @parallelHebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew / original'**
  String get parallelHebrew;

  /// No description provided for @parallelNone.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get parallelNone;

  /// No description provided for @langLatin.
  ///
  /// In en, this message translates to:
  /// **'Latin'**
  String get langLatin;

  /// No description provided for @langGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get langGreek;

  /// No description provided for @langHebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get langHebrew;

  /// No description provided for @langPortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get langPortuguese;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @translationWithLanguage.
  ///
  /// In en, this message translates to:
  /// **'{language} — {title}'**
  String translationWithLanguage(String language, String title);

  /// No description provided for @saintOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Saint of the Day'**
  String get saintOfTheDay;

  /// No description provided for @saintReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get saintReadMore;

  /// No description provided for @saintSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String saintSource(String source);

  /// No description provided for @saintDied.
  ///
  /// In en, this message translates to:
  /// **'†{year}'**
  String saintDied(String year);

  /// No description provided for @liturgicalDirectory.
  ///
  /// In en, this message translates to:
  /// **'Liturgical Directory'**
  String get liturgicalDirectory;

  /// No description provided for @directoryOpen.
  ///
  /// In en, this message translates to:
  /// **'Understand this celebration'**
  String get directoryOpen;

  /// No description provided for @directorySeason.
  ///
  /// In en, this message translates to:
  /// **'Liturgical season'**
  String get directorySeason;

  /// No description provided for @directoryCelebration.
  ///
  /// In en, this message translates to:
  /// **'The celebration'**
  String get directoryCelebration;

  /// No description provided for @directoryColor.
  ///
  /// In en, this message translates to:
  /// **'Liturgical colour'**
  String get directoryColor;

  /// No description provided for @directoryRank.
  ///
  /// In en, this message translates to:
  /// **'Grade of celebration'**
  String get directoryRank;

  /// No description provided for @directoryPractical.
  ///
  /// In en, this message translates to:
  /// **'Practical notes'**
  String get directoryPractical;

  /// No description provided for @directorySource.
  ///
  /// In en, this message translates to:
  /// **'Based on the Universal Norms on the Liturgical Year and the Calendar, the General Instruction of the Roman Missal and the Code of Canon Law.'**
  String get directorySource;

  /// No description provided for @liturgyWeekOf.
  ///
  /// In en, this message translates to:
  /// **'week {week}'**
  String liturgyWeekOf(int week);

  /// No description provided for @liturgyReadings.
  ///
  /// In en, this message translates to:
  /// **'Readings of the day'**
  String get liturgyReadings;

  /// No description provided for @rankOptionalMemorial.
  ///
  /// In en, this message translates to:
  /// **'Optional memorial'**
  String get rankOptionalMemorial;

  /// No description provided for @rankCommemoration.
  ///
  /// In en, this message translates to:
  /// **'Commemoration'**
  String get rankCommemoration;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colorRose;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoriteRemoved;

  /// No description provided for @highlightRemoved.
  ///
  /// In en, this message translates to:
  /// **'Highlight removed'**
  String get highlightRemoved;

  /// No description provided for @liturgyReadingOf.
  ///
  /// In en, this message translates to:
  /// **'A reading {book}'**
  String liturgyReadingOf(String book);

  /// No description provided for @liturgyGospelCross.
  ///
  /// In en, this message translates to:
  /// **'✠ A reading from the holy Gospel according to {evangelist}'**
  String liturgyGospelCross(String evangelist);

  /// No description provided for @psalmRefrain.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get psalmRefrain;

  /// No description provided for @psalmVerses.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get psalmVerses;

  /// No description provided for @psalmRefrainUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The proper response for this day is given in the Lectionary.'**
  String get psalmRefrainUnavailable;

  /// No description provided for @directoryCardSeason.
  ///
  /// In en, this message translates to:
  /// **'Liturgical Season'**
  String get directoryCardSeason;

  /// No description provided for @directoryCardCelebration.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get directoryCardCelebration;

  /// No description provided for @directoryCardColor.
  ///
  /// In en, this message translates to:
  /// **'Liturgical Colour'**
  String get directoryCardColor;

  /// No description provided for @directoryCardWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get directoryCardWeek;

  /// No description provided for @directoryCardYear.
  ///
  /// In en, this message translates to:
  /// **'Liturgical Year'**
  String get directoryCardYear;

  /// No description provided for @directoryCardCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get directoryCardCycle;

  /// No description provided for @directoryCardPreface.
  ///
  /// In en, this message translates to:
  /// **'Preface'**
  String get directoryCardPreface;

  /// No description provided for @directoryCardObservances.
  ///
  /// In en, this message translates to:
  /// **'Observances'**
  String get directoryCardObservances;

  /// No description provided for @directoryCardEphemerides.
  ///
  /// In en, this message translates to:
  /// **'Also today'**
  String get directoryCardEphemerides;

  /// No description provided for @liturgicalCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle {cycle}'**
  String liturgicalCycle(String cycle);

  /// No description provided for @commentaryExcerpt.
  ///
  /// In en, this message translates to:
  /// **'Comment {number}'**
  String commentaryExcerpt(int number);

  /// No description provided for @commentaryExcerptCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 excerpt} other{{count} excerpts}}'**
  String commentaryExcerptCount(int count);
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
