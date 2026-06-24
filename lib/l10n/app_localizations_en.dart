// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Biblia Traditio';

  @override
  String get tagline => 'Scripture in the light of Tradition.';

  @override
  String get navHome => 'Home';

  @override
  String get navLiturgy => 'Liturgy';

  @override
  String get navBible => 'Bible';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionClose => 'Close';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionDownload => 'Download';

  @override
  String get removePackageTitle => 'Remove package?';

  @override
  String get removePackageMessage =>
      'You\'ll need to download it again to reinstall.';

  @override
  String get deleteNoteTitle => 'Delete note?';

  @override
  String get deleteNoteMessage => 'This can\'t be undone.';

  @override
  String get contactLaunchFailed => 'Couldn\'t open WhatsApp.';

  @override
  String get copied => 'Copied';

  @override
  String get installSuccess => 'Installed successfully';

  @override
  String get removeSuccess => 'Package removed';

  @override
  String get highlight => 'Highlight';

  @override
  String get deuterocanonicalShort => 'DC';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get greetingFallback => 'Peace be with you';

  @override
  String get quickContinue => 'Continue';

  @override
  String get quickToday => 'Today';

  @override
  String get quickFavorites => 'Favorites';

  @override
  String get homeJourney => 'Continue your journey';

  @override
  String get readingPlan => 'Reading plan';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get planSubtitle => 'A year through Sacred Scripture';

  @override
  String get planToday => 'Today';

  @override
  String planDay(int day) {
    return 'Day $day';
  }

  @override
  String planDayProgress(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String planProgress(int done, int total) {
    return '$done of $total days read';
  }

  @override
  String get planMarkRead => 'Mark as read';

  @override
  String get notes => 'Notes';

  @override
  String get notesEmptySubtitle => 'Your personal reflections';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get liturgyToday => 'Today\'s liturgy';

  @override
  String get ordinaryTime => 'Ordinary Time';

  @override
  String liturgicalYear(String cycle) {
    return 'Year $cycle';
  }

  @override
  String get readingFirst => 'First Reading';

  @override
  String get readingPsalm => 'Psalm';

  @override
  String get readingSecond => 'Second Reading';

  @override
  String get readingGospel => 'Gospel';

  @override
  String get onbNameTitle => 'What should we call you?';

  @override
  String get onbNameSubtitle => 'We\'ll use your name to greet you.';

  @override
  String get namePlaceholder => 'Your name';

  @override
  String get onbLanguageTitle => 'Language';

  @override
  String get onbLanguageSubtitle =>
      'Which language do you prefer for the interface?';

  @override
  String get onbTranslationTitle => 'Translation';

  @override
  String get onbTranslationSubtitle =>
      'Choose your primary Scripture translation.';

  @override
  String get onbNotificationsTitle => 'Daily reminders';

  @override
  String get onbNotificationsSubtitle =>
      'Receive a gentle invitation to the day\'s reading and liturgy.';

  @override
  String get onbPlanTitle => 'Reading plan';

  @override
  String get onbPlanSubtitle =>
      'Would you like to follow a plan to read the Scriptures?';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbEnter => 'Enter';

  @override
  String get onbSkip => 'Skip';

  @override
  String get enable => 'Enable';

  @override
  String get notNow => 'Not now';

  @override
  String get bibleTitle => 'Bible';

  @override
  String get search => 'Search';

  @override
  String get oldTestament => 'Old Testament';

  @override
  String get newTestament => 'New Testament';

  @override
  String get oldTestamentShort => 'OT';

  @override
  String get newTestamentShort => 'NT';

  @override
  String get noBooksFound => 'No books found.';

  @override
  String get contentNotInstalled =>
      'Content not installed yet.\nInstall a translation pack in Settings.';

  @override
  String chapterTitle(int number) {
    return 'Chapter $number';
  }

  @override
  String chapterPickerTitle(String book) {
    return '$book — chapter';
  }

  @override
  String get goToVerse => 'Go to verse';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get scriptureNotInstalled => 'The Bible text is not installed yet.';

  @override
  String get share => 'Share';

  @override
  String get copyVerse => 'Copy verse';

  @override
  String get favorite => 'Favorite';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get unbookmark => 'Remove bookmark';

  @override
  String get note => 'Note';

  @override
  String notesWithCount(int count) {
    return 'Notes ($count)';
  }

  @override
  String get churchFathers => 'Church Fathers';

  @override
  String get myNotes => 'My Notes';

  @override
  String get noCommentaryForVerse =>
      'No commentary available for this verse yet.';

  @override
  String get patristicsNotInstalled =>
      'Install the Church Fathers commentary in Settings to read this verse with the Church.';

  @override
  String get noNotesForVerse => 'No notes for this verse yet.';

  @override
  String get writeReflection => 'Write a reflection';

  @override
  String commentaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaries',
      one: '1 commentary',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterFathers => 'Patristics';

  @override
  String get filterMedieval => 'Medieval';

  @override
  String get filterAugustine => 'St Augustine';

  @override
  String get filterAquinas => 'St Thomas Aquinas';

  @override
  String get colorMode => 'Color mode';

  @override
  String get fontSizeSoon => 'Font size (soon)';

  @override
  String century(String value) {
    return 'cent. $value';
  }

  @override
  String get machineTranslation => 'machine translation';

  @override
  String get shareCopy => 'Copy';

  @override
  String get shareText => 'Text';

  @override
  String get shareImage => 'Image';

  @override
  String noteEditorTitle(String reference) {
    return 'Note — $reference';
  }

  @override
  String get noteHint => 'Write your reflection…';

  @override
  String get parallelReading => 'Parallel reading';

  @override
  String get singleTranslation => 'Single translation';

  @override
  String get parallelOptionsTitle => 'Parallel reading';

  @override
  String get secondaryTranslation => 'Secondary translation';

  @override
  String get noSecondaryTranslation =>
      'No secondary translation installed yet.';

  @override
  String get openOfflineResources => 'Open Offline resources';

  @override
  String get verseNotInTranslation =>
      'Verse not available in this translation.';

  @override
  String get parallelLayoutLabel => 'Layout';

  @override
  String get layoutAuto => 'Automatic';

  @override
  String get layoutStacked => 'Stacked';

  @override
  String get layoutSideBySide => 'Side by side';

  @override
  String get searchHint => 'Search Scripture, Fathers, notes…';

  @override
  String get searchScopeAll => 'All';

  @override
  String get searchScopeScripture => 'Scripture';

  @override
  String get searchScopeFathers => 'Fathers';

  @override
  String get searchScopeNotes => 'Notes';

  @override
  String get searchTypeMore => 'Type at least 2 letters to search.';

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”.';
  }

  @override
  String get sectionScripture => 'Scripture';

  @override
  String get notesScreenTitle => 'Notes';

  @override
  String get searchNotesHint => 'Search notes';

  @override
  String get noNotesYet => 'No notes yet.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get noFavoritesYet => 'No favorites yet.';

  @override
  String get highlightsTitle => 'Highlights';

  @override
  String get noHighlightsYet => 'No highlights yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsReading => 'Reading';

  @override
  String get settingsTranslation => 'Translation';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsReminders => 'Daily reminders';

  @override
  String get settingsOfflineResources => 'Offline resources';

  @override
  String get settingsAbout => 'About';

  @override
  String get licensesTitle => 'Licenses & Attributions';

  @override
  String get licensesIntro =>
      'Biblia Traditio respects the sources it uses. Below is the origin and license of each.';

  @override
  String get licVulgataTitle => 'Clementine Vulgate (Latin)';

  @override
  String get licVulgataBody => 'Latin biblical text in the public domain.';

  @override
  String get licPatristicsTitle => 'Church Fathers\' Commentary';

  @override
  String get licPatristicsBody =>
      'Patristic sources in the public domain, machine-translated and adapted. May contain inaccuracies — read with discernment.';

  @override
  String get licPortugueseTitle => 'Portuguese Bible (beta)';

  @override
  String get licPortugueseBody =>
      'An internal version for this testing phase. The translation\'s provenance will be confirmed before any public release.';

  @override
  String get licMatosTitle => 'Padre Matos Soares (Portuguese)';

  @override
  String get licMatosBody =>
      'Catholic translation by Fr. Matos Soares (d. 1950) — a public-domain candidate in Brazil since 2021 (life + 70 years). Provenance is being verified during the beta.';

  @override
  String get ossLicenses => 'Open-source licenses';

  @override
  String get settingsContact => 'Contact / Feedback';

  @override
  String get whatsappTitle => 'Contact us on WhatsApp';

  @override
  String get whatsappSubtitle => 'Send suggestions and report issues';

  @override
  String get noTranslationInstalled => 'None installed';

  @override
  String get packageRequired => 'Required';

  @override
  String packageInstalled(String size) {
    return 'Installed · $size';
  }

  @override
  String packageDownload(String download, String installed) {
    return 'Download $download · $installed installed';
  }

  @override
  String installFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get liturgyTitle => 'Liturgy';

  @override
  String get celebrationOfDay => 'Celebration of the day';

  @override
  String get lectionaryNotice => 'Readings for this day are not available yet.';

  @override
  String get liturgyOpenInBible => 'Open in Bible';

  @override
  String get readingTextUnavailable => 'Reading text not available.';

  @override
  String get preparingBible => 'Preparing the Bible…';

  @override
  String get startupError => 'Failed to start.';

  @override
  String get seasonAdvent => 'Advent';

  @override
  String get seasonChristmas => 'Christmas Time';

  @override
  String get seasonOrdinary => 'Ordinary Time';

  @override
  String get seasonLent => 'Lent';

  @override
  String get seasonTriduum => 'Paschal Triduum';

  @override
  String get seasonEaster => 'Eastertide';

  @override
  String get rankSolemnity => 'Solemnity';

  @override
  String get rankFeast => 'Feast';

  @override
  String get rankMemorial => 'Memorial';

  @override
  String get liturgyResponseWordOfLord => 'The word of the Lord.';

  @override
  String get liturgyResponseThanksToGod => 'Thanks be to God.';

  @override
  String get liturgyResponseGloryToYou => 'Glory to you, O Lord.';

  @override
  String get liturgyResponseWordOfSalvation => 'The Gospel of the Lord.';

  @override
  String liturgyGospelAccording(String evangelist) {
    return 'A reading from the holy Gospel according to $evangelist';
  }

  @override
  String get licGreekTitle => 'Greek New Testament (SBLGNT)';

  @override
  String get licGreekBody =>
      'The SBL Greek New Testament (SBLGNT), © Society of Biblical Literature and Logos Bible Software. Used under the Creative Commons Attribution 4.0 license.';
}
