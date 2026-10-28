// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppL10nIt extends AppL10n {
  AppL10nIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Biblia Traditio';

  @override
  String get tagline => 'La Scrittura alla luce della Tradizione.';

  @override
  String get navHome => 'Inizio';

  @override
  String get navLiturgy => 'Liturgia';

  @override
  String get navBible => 'Bibbia';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionConfirm => 'Conferma';

  @override
  String get actionClose => 'Chiudi';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionRemove => 'Rimuovi';

  @override
  String get actionDownload => 'Scarica';

  @override
  String get removePackageTitle => 'Rimuovere il pacchetto?';

  @override
  String get removePackageMessage =>
      'Dovrai scaricarlo di nuovo per reinstallarlo.';

  @override
  String get deleteNoteTitle => 'Eliminare la nota?';

  @override
  String get deleteNoteMessage => 'L\'operazione non può essere annullata.';

  @override
  String get contactLaunchFailed => 'Impossibile aprire WhatsApp.';

  @override
  String get copied => 'Copiato';

  @override
  String get installSuccess => 'Installato con successo';

  @override
  String get removeSuccess => 'Pacchetto rimosso';

  @override
  String get highlight => 'Evidenzia';

  @override
  String get deuterocanonicalShort => 'DC';

  @override
  String get greetingMorning => 'Buongiorno,';

  @override
  String get greetingAfternoon => 'Buon pomeriggio,';

  @override
  String get greetingEvening => 'Buonasera,';

  @override
  String get greetingFallback => 'La pace sia con te';

  @override
  String get quickContinue => 'Continuare';

  @override
  String get quickToday => 'Oggi';

  @override
  String get quickFavorites => 'Preferiti';

  @override
  String get homeJourney => 'Continua il tuo viaggio';

  @override
  String get readingPlan => 'Piano di lettura';

  @override
  String get comingSoon => 'Prossimamente';

  @override
  String get planSubtitle => 'Un anno attraverso la Sacra Scrittura';

  @override
  String get planToday => 'Oggi';

  @override
  String planDay(int day) {
    return 'Giorno $day';
  }

  @override
  String planDayProgress(int day, int total) {
    return 'Giorno $day di $total';
  }

  @override
  String planProgress(int done, int total) {
    return '$done di $total giorni letti';
  }

  @override
  String get planMarkRead => 'Segna come letto';

  @override
  String get notes => 'Note';

  @override
  String get notesEmptySubtitle => 'Le tue riflessioni personali';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get liturgyToday => 'La liturgia di oggi';

  @override
  String get ordinaryTime => 'Tempo Ordinario';

  @override
  String liturgicalYear(String cycle) {
    return 'Anno $cycle';
  }

  @override
  String get readingFirst => 'Prima lettura';

  @override
  String get readingPsalm => 'Salmo';

  @override
  String get readingSecond => 'Seconda lettura';

  @override
  String get readingGospel => 'Vangelo';

  @override
  String get onbNameTitle => 'Come dovremmo chiamarti?';

  @override
  String get onbNameSubtitle => 'Useremo il tuo nome per salutarti.';

  @override
  String get namePlaceholder => 'Il tuo nome';

  @override
  String get onbLanguageTitle => 'Lingua';

  @override
  String get onbLanguageSubtitle =>
      'Quale lingua preferisci per l\'interfaccia?';

  @override
  String get onbTranslationTitle => 'Traduzione';

  @override
  String get onbTranslationSubtitle =>
      'Scegli la tua traduzione principale delle Scritture.';

  @override
  String get onbNotificationsTitle => 'Promemoria giornalieri';

  @override
  String get onbNotificationsSubtitle =>
      'Ricevi un gentile invito alla lettura e alla liturgia del giorno.';

  @override
  String get onbPlanTitle => 'Piano di lettura';

  @override
  String get onbPlanSubtitle =>
      'Ti piacerebbe seguire un programma per leggere le Scritture?';

  @override
  String get onbContinue => 'Continuare';

  @override
  String get onbEnter => 'Entra';

  @override
  String get onbSkip => 'Salta';

  @override
  String get enable => 'Abilitare';

  @override
  String get notNow => 'Non adesso';

  @override
  String get bibleTitle => 'Bibbia';

  @override
  String get search => 'Ricerca';

  @override
  String get oldTestament => 'Antico Testamento';

  @override
  String get newTestament => 'Nuovo Testamento';

  @override
  String get oldTestamentShort => 'OT';

  @override
  String get newTestamentShort => 'NT';

  @override
  String get noBooksFound => 'Nessun libro trovato.';

  @override
  String get contentNotInstalled => 'Contenuto non ancora installato.\n';

  @override
  String chapterTitle(int number) {
    return 'Capitolo $number';
  }

  @override
  String chapterPickerTitle(String book) {
    return '$book — capitolo';
  }

  @override
  String get goToVerse => 'Vai al verso';

  @override
  String get previous => 'Precedente';

  @override
  String get next => 'Prossimo';

  @override
  String get scriptureNotInstalled =>
      'Il testo biblico non è ancora installato.';

  @override
  String get share => 'Condividere';

  @override
  String get copyVerse => 'Copia versetto';

  @override
  String get favorite => 'Preferito';

  @override
  String get unfavorite => 'Rimuovi dai preferiti';

  @override
  String get bookmark => 'Segnalibro';

  @override
  String get unbookmark => 'Rimuovi segnalibro';

  @override
  String get note => 'Nota';

  @override
  String notesWithCount(int count) {
    return 'Note ($count)';
  }

  @override
  String get churchFathers => 'Padri della Chiesa';

  @override
  String get myNotes => 'I miei appunti';

  @override
  String get noCommentaryForVerse =>
      'Nessun commento ancora disponibile per questo versetto.';

  @override
  String get patristicsNotInstalled =>
      'Installa il commento dei Padri della Chiesa in Impostazioni per leggere questo versetto con la Chiesa.';

  @override
  String get noNotesForVerse => 'Nessuna nota per questo verso ancora.';

  @override
  String get writeReflection => 'Scrivi una riflessione';

  @override
  String commentaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commenti',
      one: '1 commento',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'Tutto';

  @override
  String get filterFathers => 'Patristica';

  @override
  String get filterMedieval => 'Medievale';

  @override
  String get filterAugustine => 'Sant\'Agostino';

  @override
  String get filterAquinas => 'San Tommaso d\'Aquino';

  @override
  String get colorMode => 'Modalità colore';

  @override
  String get fontSizeSoon => 'Dimensione carattere (presto)';

  @override
  String century(String value) {
    return 'sec. $value';
  }

  @override
  String get machineTranslation => 'traduzione automatica';

  @override
  String get shareCopy => 'Copia';

  @override
  String get shareText => 'Testo';

  @override
  String get shareImage => 'Immagine';

  @override
  String noteEditorTitle(String reference) {
    return 'Nota: $reference';
  }

  @override
  String get noteHint => 'Scrivi la tua riflessione...';

  @override
  String get parallelReading => 'Lettura parallela';

  @override
  String get singleTranslation => 'Traduzione unica';

  @override
  String get parallelOptionsTitle => 'Lettura parallela';

  @override
  String get secondaryTranslation => 'Traduzione secondaria';

  @override
  String get noSecondaryTranslation =>
      'Nessuna traduzione secondaria ancora installata.';

  @override
  String get openOfflineResources => 'Apri Risorse offline';

  @override
  String get verseNotInTranslation =>
      'Versetto non disponibile in questa traduzione.';

  @override
  String get parallelLayoutLabel => 'Disposizione';

  @override
  String get layoutAuto => 'Automatico';

  @override
  String get layoutStacked => 'Impilato';

  @override
  String get layoutSideBySide => 'Fianco a fianco';

  @override
  String get searchHint => 'Cerca Scrittura, Patristica, note...';

  @override
  String get searchScopeAll => 'Tutto';

  @override
  String get searchScopeScripture => 'Scrittura';

  @override
  String get searchScopeFathers => 'Patristica';

  @override
  String get searchScopeNotes => 'Note';

  @override
  String get searchTypeMore => 'Digita almeno 2 lettere per cercare.';

  @override
  String searchNoResults(String query) {
    return 'Nessun risultato per “$query”.';
  }

  @override
  String get sectionScripture => 'Scrittura';

  @override
  String get notesScreenTitle => 'Note';

  @override
  String get searchNotesHint => 'Cerca note';

  @override
  String get noNotesYet => 'Nessuna nota ancora.';

  @override
  String get favoritesTitle => 'Preferiti';

  @override
  String get noFavoritesYet => 'Nessun preferito ancora';

  @override
  String get highlightsTitle => 'Punti salienti';

  @override
  String get noHighlightsYet => 'Nessun momento saliente per ora.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsName => 'Nome';

  @override
  String get settingsReading => 'Lettura';

  @override
  String get settingsTranslation => 'Traduzione';

  @override
  String get settingsAppLanguage => 'Lingua dell\'app';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Leggero';

  @override
  String get themeDark => 'Buio';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get settingsReminders => 'Promemoria giornalieri';

  @override
  String get settingsOfflineResources => 'Risorse non in linea';

  @override
  String get settingsAbout => 'Di';

  @override
  String get licensesTitle => 'Licenze e attribuzioni';

  @override
  String get licensesIntro =>
      'Biblia Traditio rispetta le fonti che utilizza. ';

  @override
  String get licVulgataTitle => 'Vulgata Clementina (latino)';

  @override
  String get licVulgataBody => 'Testo biblico latino di pubblico dominio.';

  @override
  String get licPatristicsTitle => 'Commento dei Padri della Chiesa';

  @override
  String get licPatristicsBody =>
      'Fonti patristiche di pubblico dominio, tradotte automaticamente e adattate. ';

  @override
  String get licPortugueseTitle => 'Bibbia portoghese (beta)';

  @override
  String get licPortugueseBody =>
      'Una versione interna per questa fase di test. ';

  @override
  String get licMatosTitle => 'Padre Matos Soares (portoghese)';

  @override
  String get licMatosBody => 'Traduzione cattolica di p. ';

  @override
  String get ossLicenses => 'Licenze open source';

  @override
  String get settingsContact => 'Contatto/risposta';

  @override
  String get whatsappTitle => 'Contattaci su WhatsApp';

  @override
  String get whatsappSubtitle => 'Invia suggerimenti e segnala problemi';

  @override
  String get noTranslationInstalled => 'Nessuno installato';

  @override
  String get packageRequired => 'Necessario';

  @override
  String packageInstalled(String size) {
    return 'Installato · $size';
  }

  @override
  String packageDownload(String download, String installed) {
    return 'Scarica $download · $installed installato';
  }

  @override
  String installFailed(String error) {
    return 'Installazione non riuscita: $error';
  }

  @override
  String get liturgyTitle => 'Liturgia';

  @override
  String get celebrationOfDay => 'Celebrazione del giorno';

  @override
  String get lectionaryNotice =>
      'Le letture per questo giorno non sono ancora disponibili.';

  @override
  String get liturgyOpenInBible => 'Aperto nella Bibbia';

  @override
  String get readingTextUnavailable => 'Lettura del testo non disponibile.';

  @override
  String get preparingBible => 'Preparare la Bibbia...';

  @override
  String get startupError => 'Impossibile avviare.';

  @override
  String get seasonAdvent => 'Avvento';

  @override
  String get seasonChristmas => 'Tempo di Natale';

  @override
  String get seasonOrdinary => 'Tempo Ordinario';

  @override
  String get seasonLent => 'Prestato';

  @override
  String get seasonTriduum => 'Triduo Pasquale';

  @override
  String get seasonEaster => 'Tempo di Pasqua';

  @override
  String get rankSolemnity => 'Solennità';

  @override
  String get rankFeast => 'Festa';

  @override
  String get rankMemorial => 'Memoriale';

  @override
  String get liturgyResponseWordOfLord => 'La parola del Signore.';

  @override
  String get liturgyResponseThanksToGod => 'Grazie a Dio.';

  @override
  String get liturgyResponseGloryToYou => 'Gloria a te, o Signore.';

  @override
  String get liturgyResponseWordOfSalvation => 'Il Vangelo del Signore.';

  @override
  String liturgyGospelAccording(String evangelist) {
    return 'Una lettura dal santo Vangelo secondo $evangelist';
  }

  @override
  String get licGreekTitle => 'Nuovo Testamento greco (SBLGNT)';

  @override
  String get licGreekBody =>
      'Il Nuovo Testamento greco SBL (SBLGNT), © Society of Biblical Literature e Logos Bible Software. ';

  @override
  String get pressBackAgainToExit => 'Premi nuovamente indietro per uscire.';

  @override
  String get searchScopeBooks => 'Libri';

  @override
  String get sectionBooks => 'Libri';

  @override
  String get sectionGoTo => 'Vai a';

  @override
  String get searchOpenBook => 'Libro aperto';

  @override
  String get commentaryTabPatristics => 'Patristica';

  @override
  String get commentaryExpandAll => 'Mostra tutto';

  @override
  String get commentaryCollapseAll => 'Comprimi tutto';

  @override
  String get commentaryCollapse => 'Crollo';

  @override
  String get shareCommentary => 'Condividi il commento';

  @override
  String get roleDoctor => 'Dottore della Chiesa';

  @override
  String get rolePope => 'Papa';

  @override
  String get roleBishop => 'Vescovo';

  @override
  String get roleMonk => 'Monaco';

  @override
  String get rolePriest => 'Sacerdote';

  @override
  String get roleDeacon => 'Diacono';

  @override
  String get roleExegete => 'Esegeta';

  @override
  String get roleTheologian => 'Teologo';

  @override
  String get roleHistorian => 'Storico';

  @override
  String get rolePoet => 'Poeta';

  @override
  String get rolePatristics => 'Patristica';

  @override
  String get roleMedieval => 'Medievale';

  @override
  String get roleEarlyChristian => 'Paleocristiano';

  @override
  String get roleSaint => 'Santo';

  @override
  String get roleSaintFem => 'Santo';

  @override
  String get roleLiturgy => 'Liturgia';

  @override
  String get roleDocPatristic => 'Documento patristico';

  @override
  String get roleDocMedieval => 'Documento medievale';

  @override
  String get roleDocHistorical => 'Documento storico';

  @override
  String get roleDocGeneral => 'Documento generale';

  @override
  String authorMeta(String role, String century) {
    return '$role — $century cent.';
  }

  @override
  String get settingsCommentary => 'Commento';

  @override
  String get commentaryPreferences => 'Preferenze di commento';

  @override
  String get commentaryPreferencesSubtitle =>
      'Scegli quali commentatori visualizzare quando apri un versetto.';

  @override
  String get commentaryClassification => 'Classificazione';

  @override
  String get commentaryCenturies => 'Secoli';

  @override
  String get filterScholastic => 'Scolastico';

  @override
  String get filterSaints => 'Santi';

  @override
  String get commentaryOnlySaints => 'Solo santi';

  @override
  String get commentaryOnlySaintsSubtitle =>
      'Modalità semplificata: mostra solo i santi.';

  @override
  String get commentaryResetDefaults =>
      'Ripristina le impostazioni predefinite';

  @override
  String get commentaryPrefsAll => 'Tutti commentatori';

  @override
  String commentaryPrefsFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtri attivi',
      one: '1 filtro attivo',
    );
    return '$_temp0';
  }

  @override
  String commentaryHiddenByPrefs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commenti nascosti dalle tue preferenze',
      one: '1 commento nascosto dalle tue preferenze',
    );
    return '$_temp0';
  }

  @override
  String get commentaryShowHidden => 'Mostralo comunque';

  @override
  String get shareSelectVerses => 'Seleziona versi';

  @override
  String shareSelectionTooLong(int max) {
    return 'Selezione troppo lunga per un\'immagine (max. caratteri $max). ';
  }

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versetti selezionati',
      one: '1 versetto selezionato',
    );
    return '$_temp0';
  }

  @override
  String get selectionHint =>
      'Tocca i versi per scegliere un passaggio continuo.';

  @override
  String get selectionClear => 'Chiaro';

  @override
  String get shareSelection => 'Selezione delle azioni';

  @override
  String get planSectionBook => 'Lettura';

  @override
  String get planSectionWisdom => 'Saggezza';

  @override
  String get planCompleted => 'Leggere';

  @override
  String get onbStyleTitle => 'Quale stile di traduzione preferisci?';

  @override
  String get onbStyleSubtitle => 'Lo usiamo per suggerire una traduzione. ';

  @override
  String get styleAcademic => 'Più accademico';

  @override
  String get styleSimple => 'Più semplice';

  @override
  String get styleBalanced => 'Equilibrato';

  @override
  String get styleLiturgical => 'Liturgico';

  @override
  String get onbParallelTitle => 'Desideri un testo parallelo?';

  @override
  String get onbParallelSubtitle =>
      'Vengono visualizzati solo i testi effettivamente installati.';

  @override
  String get parallelLatin => 'latino';

  @override
  String get parallelGreek => 'greco';

  @override
  String get parallelHebrew => 'Ebraico/originale';

  @override
  String get parallelNone => 'NO';

  @override
  String get langLatin => 'latino';

  @override
  String get langGreek => 'greco';

  @override
  String get langHebrew => 'ebraico';

  @override
  String get langPortuguese => 'portoghese';

  @override
  String get langEnglish => 'Inglese';

  @override
  String get langItalian => 'Italiano';

  @override
  String get langSpanish => 'spagnolo';

  @override
  String get langFrench => 'francese';

  @override
  String translationWithLanguage(String language, String title) {
    return '$language — $title';
  }

  @override
  String get saintOfTheDay => 'Santo del giorno';

  @override
  String get saintReadMore => 'Per saperne di più';

  @override
  String saintSource(String source) {
    return 'Fonte: $source';
  }

  @override
  String saintDied(String year) {
    return '†$year';
  }

  @override
  String get liturgicalDirectory => 'Direttorio liturgico';

  @override
  String get directoryOpen => 'Comprendi questa celebrazione';

  @override
  String get directorySeason => 'Tempo liturgico';

  @override
  String get directoryCelebration => 'La celebrazione';

  @override
  String get directoryColor => 'Colore liturgico';

  @override
  String get directoryRank => 'Grado di celebrazione';

  @override
  String get directoryPractical => 'Note pratiche';

  @override
  String get directorySource =>
      'Sulla base delle Norme universali sull\'anno liturgico e sul calendario, dell\'Ordinamento generale del Messale Romano e del Codice di Diritto Canonico.';

  @override
  String liturgyWeekOf(int week) {
    return 'settimana $week';
  }

  @override
  String get liturgyReadings => 'Letture del giorno';

  @override
  String get rankOptionalMemorial => 'Memoria facoltativa';

  @override
  String get rankCommemoration => 'Commemorazione';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorRed => 'Rosso';

  @override
  String get colorWhite => 'Bianco';

  @override
  String get colorPurple => 'Viola';

  @override
  String get colorRose => 'Rosa';

  @override
  String get actionUndo => 'Disfare';

  @override
  String get favoriteRemoved => 'Rimosso dai preferiti';

  @override
  String get highlightRemoved => 'Evidenziazione rimossa';

  @override
  String liturgyReadingOf(String book) {
    return 'Una lettura $book';
  }

  @override
  String liturgyGospelCross(String evangelist) {
    return '✠ Una lettura dal santo Vangelo secondo $evangelist';
  }

  @override
  String get psalmRefrain => 'Risposta';

  @override
  String get psalmVerses => 'Versi';

  @override
  String get psalmRefrainUnavailable =>
      'La risposta adeguata per questa giornata è data nel Lezionario.';

  @override
  String get directoryCardSeason => 'Tempo liturgico';

  @override
  String get directoryCardCelebration => 'Celebrazione';

  @override
  String get directoryCardColor => 'Colore liturgico';

  @override
  String get directoryCardWeek => 'Settimana';

  @override
  String get directoryCardYear => 'Anno liturgico';

  @override
  String get directoryCardCycle => 'Ciclo';

  @override
  String get directoryCardPreface => 'Prefazione';

  @override
  String get directoryCardObservances => 'Osservanze';

  @override
  String get directoryCardEphemerides => 'Anche oggi';

  @override
  String liturgicalCycle(String cycle) {
    return 'Ciclo $cycle';
  }

  @override
  String commentaryExcerpt(int number) {
    return 'Commento $number';
  }

  @override
  String commentaryExcerptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estratti',
      one: '1 estratto',
    );
    return '$_temp0';
  }

  @override
  String get homePsalmToday => 'Il salmo di oggi';

  @override
  String get homePsalmRefrain => 'Ritornello del salmo';

  @override
  String get homeReadPsalm => 'Leggi il salmo';

  @override
  String get homeGospelToday => 'Il Vangelo di oggi';

  @override
  String get homeReadGospel => 'Leggi il Vangelo';

  @override
  String get homeSeeLiturgy => 'Vedi la liturgia';

  @override
  String get sectionPentateuch => 'Pentateuco';

  @override
  String get sectionHistorical => 'Libri storici';

  @override
  String get sectionWisdom => 'Libri di saggezza';

  @override
  String get sectionProphets => 'Profeti';

  @override
  String get sectionGospels => 'Vangeli';

  @override
  String get sectionActs => 'Atti degli Apostoli';

  @override
  String get sectionPauline => 'Lettere di San Paolo';

  @override
  String get sectionCatholicLetters => 'Lettere cattoliche';

  @override
  String get sectionApocalypse => 'Apocalisse';

  @override
  String get themesTitle => 'Biblioteca tematica';

  @override
  String get themesSubtitle => 'Scrittura per temi, letta con i Padri';

  @override
  String get themeLibraryLoadError =>
      'Impossibile caricare la libreria tematica. ';

  @override
  String themePassages(int n) {
    return '$n passaggi';
  }

  @override
  String get themePassagesLabel => 'Passaggi';

  @override
  String themeCommentaryCount(int n) {
    return '$n commenti dei Padri';
  }

  @override
  String get themeNoText => 'Testo non disponibile nella traduzione attuale.';

  @override
  String get shareChooseExcerpt => 'Scegli l\'estratto per l\'immagine';

  @override
  String get shareExcerptHint =>
      'Tocca le frasi che dovrebbero apparire sulla carta. ';

  @override
  String shareExcerptCount(int n, int max) {
    return '$n di caratteri $max';
  }

  @override
  String get shareContinue => 'Continuare';

  @override
  String get shareExcerptTooLong =>
      'Troppo lungo per una carta: deseleziona una frase.';

  @override
  String get shareExcerptNone => 'Seleziona almeno una frase.';
}
