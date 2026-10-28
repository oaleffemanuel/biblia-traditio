// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Biblia Traditio';

  @override
  String get tagline => 'L\'Écriture à la lumière de la Tradition.';

  @override
  String get navHome => 'Accueil';

  @override
  String get navLiturgy => 'Liturgie';

  @override
  String get navBible => 'Bible';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get actionDownload => 'Télécharger';

  @override
  String get removePackageTitle => 'Supprimer le paquet ?';

  @override
  String get removePackageMessage =>
      'Vous devrez le télécharger à nouveau pour le réinstaller.';

  @override
  String get deleteNoteTitle => 'Supprimer la note ?';

  @override
  String get deleteNoteMessage => 'Cela ne peut pas être annulé.';

  @override
  String get contactLaunchFailed => 'Impossible d\'ouvrir WhatsApp.';

  @override
  String get copied => 'Copié';

  @override
  String get installSuccess => 'Installé avec succès';

  @override
  String get removeSuccess => 'Paquet supprimé';

  @override
  String get highlight => 'Surligner';

  @override
  String get deuterocanonicalShort => 'CC';

  @override
  String get greetingMorning => 'Bonjour,';

  @override
  String get greetingAfternoon => 'Bon après-midi,';

  @override
  String get greetingEvening => 'Bonne soirée,';

  @override
  String get greetingFallback => 'La paix soit avec toi';

  @override
  String get quickContinue => 'Continuer';

  @override
  String get quickToday => 'Aujourd\'hui';

  @override
  String get quickFavorites => 'Favoris';

  @override
  String get homeJourney => 'Continuez votre voyage';

  @override
  String get readingPlan => 'Plan de lecture';

  @override
  String get comingSoon => 'À venir';

  @override
  String get planSubtitle => 'Une année à travers l\'Écriture Sainte';

  @override
  String get planToday => 'Aujourd\'hui';

  @override
  String planDay(int day) {
    return 'Jour $day';
  }

  @override
  String planDayProgress(int day, int total) {
    return 'Jour $day de $total';
  }

  @override
  String planProgress(int done, int total) {
    return '$done sur $total jours de lecture';
  }

  @override
  String get planMarkRead => 'Marquer comme lu';

  @override
  String get notes => 'Remarques';

  @override
  String get notesEmptySubtitle => 'Vos réflexions personnelles';

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
  String get liturgyToday => 'La liturgie d\'aujourd\'hui';

  @override
  String get ordinaryTime => 'Temps ordinaire';

  @override
  String liturgicalYear(String cycle) {
    return 'Année $cycle';
  }

  @override
  String get readingFirst => 'Première lecture';

  @override
  String get readingPsalm => 'Psaume';

  @override
  String get readingSecond => 'Deuxième lecture';

  @override
  String get readingGospel => 'Gospel';

  @override
  String get onbNameTitle => 'Comment devrions-nous vous appeler ?';

  @override
  String get onbNameSubtitle => 'Nous utiliserons votre nom pour vous saluer.';

  @override
  String get namePlaceholder => 'Votre nom';

  @override
  String get onbLanguageTitle => 'Langue';

  @override
  String get onbLanguageSubtitle =>
      'Quelle langue préférez-vous pour l’interface ?';

  @override
  String get onbTranslationTitle => 'Traduction';

  @override
  String get onbTranslationSubtitle =>
      'Choisissez votre traduction principale des Écritures.';

  @override
  String get onbNotificationsTitle => 'Rappels quotidiens';

  @override
  String get onbNotificationsSubtitle =>
      'Recevez une douce invitation à la lecture et à la liturgie du jour.';

  @override
  String get onbPlanTitle => 'Plan de lecture';

  @override
  String get onbPlanSubtitle =>
      'Souhaitez-vous suivre un plan pour lire les Écritures ?';

  @override
  String get onbContinue => 'Continuer';

  @override
  String get onbEnter => 'Entrer';

  @override
  String get onbSkip => 'Ignorer';

  @override
  String get enable => 'Activer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get bibleTitle => 'Bible';

  @override
  String get search => 'Recherche';

  @override
  String get oldTestament => 'Ancien Testament';

  @override
  String get newTestament => 'le Nouveau Testament';

  @override
  String get oldTestamentShort => 'OT';

  @override
  String get newTestamentShort => 'NT';

  @override
  String get noBooksFound => 'Aucun livre trouvé.';

  @override
  String get contentNotInstalled => 'Contenu pas encore installé.\n';

  @override
  String chapterTitle(int number) {
    return 'Chapitre $number';
  }

  @override
  String chapterPickerTitle(String book) {
    return '$book — chapitre';
  }

  @override
  String get goToVerse => 'Aller au verset';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get scriptureNotInstalled =>
      'Le texte biblique n\'est pas encore installé.';

  @override
  String get share => 'Partager';

  @override
  String get copyVerse => 'Copier le verset';

  @override
  String get favorite => 'Préféré';

  @override
  String get unfavorite => 'Supprimer des favoris';

  @override
  String get bookmark => 'Marque-page';

  @override
  String get unbookmark => 'Supprimer le favori';

  @override
  String get note => 'Note';

  @override
  String notesWithCount(int count) {
    return 'Remarques ($count)';
  }

  @override
  String get churchFathers => 'Pères de l\'Église';

  @override
  String get myNotes => 'Mes notes';

  @override
  String get noCommentaryForVerse =>
      'Aucun commentaire disponible pour ce verset pour l\'instant.';

  @override
  String get patristicsNotInstalled =>
      'Installez le commentaire des Pères de l\'Église dans Paramètres pour lire ce verset avec l\'Église.';

  @override
  String get noNotesForVerse => 'Aucune note pour ce verset pour l\'instant.';

  @override
  String get writeReflection => 'Écrivez une réflexion';

  @override
  String commentaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires',
      one: '1 commentaire',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'Tous';

  @override
  String get filterFathers => 'Patristique';

  @override
  String get filterMedieval => 'Médiéval';

  @override
  String get filterAugustine => 'Saint Augustin';

  @override
  String get filterAquinas => 'Saint Thomas d\'Aquin';

  @override
  String get colorMode => 'Mode couleur';

  @override
  String get fontSizeSoon => 'Taille de la police (bientôt)';

  @override
  String century(String value) {
    return 'siècle $value';
  }

  @override
  String get machineTranslation => 'traduction automatique';

  @override
  String get shareCopy => 'Copie';

  @override
  String get shareText => 'Texte';

  @override
  String get shareImage => 'Image';

  @override
  String noteEditorTitle(String reference) {
    return 'Remarque — $reference';
  }

  @override
  String get noteHint => 'Écrivez votre réflexion…';

  @override
  String get parallelReading => 'Lecture parallèle';

  @override
  String get singleTranslation => 'Traduction unique';

  @override
  String get parallelOptionsTitle => 'Lecture parallèle';

  @override
  String get secondaryTranslation => 'Traduction secondaire';

  @override
  String get noSecondaryTranslation =>
      'Aucune traduction secondaire installée pour le moment.';

  @override
  String get openOfflineResources => 'Ouvrir les ressources hors ligne';

  @override
  String get verseNotInTranslation =>
      'Verset non disponible dans cette traduction.';

  @override
  String get parallelLayoutLabel => 'Mise en page';

  @override
  String get layoutAuto => 'Automatique';

  @override
  String get layoutStacked => 'Empilé';

  @override
  String get layoutSideBySide => 'Côte à côte';

  @override
  String get searchHint =>
      'Rechercher dans les Écritures, la Patristique, les notes…';

  @override
  String get searchScopeAll => 'Tous';

  @override
  String get searchScopeScripture => 'Écriture';

  @override
  String get searchScopeFathers => 'Patristique';

  @override
  String get searchScopeNotes => 'Remarques';

  @override
  String get searchTypeMore =>
      'Tapez au moins 2 lettres pour effectuer la recherche.';

  @override
  String searchNoResults(String query) {
    return 'Aucun résultat pour « $query ».';
  }

  @override
  String get sectionScripture => 'Écriture';

  @override
  String get notesScreenTitle => 'Remarques';

  @override
  String get searchNotesHint => 'Notes de recherche';

  @override
  String get noNotesYet => 'Aucune note pour l\'instant.';

  @override
  String get favoritesTitle => 'Favoris';

  @override
  String get noFavoritesYet => 'Pas encore de favoris.';

  @override
  String get highlightsTitle => 'Points forts';

  @override
  String get noHighlightsYet => 'Pas encore de faits saillants.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsName => 'Nom';

  @override
  String get settingsReading => 'En lisant';

  @override
  String get settingsTranslation => 'Traduction';

  @override
  String get settingsAppLanguage => 'Langue de l\'application';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeLight => 'Lumière';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get settingsReminders => 'Rappels quotidiens';

  @override
  String get settingsOfflineResources => 'Ressources hors ligne';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get licensesTitle => 'Licences et attributions';

  @override
  String get licensesIntro =>
      'Biblia Traditio respecte les sources qu\'elle utilise. ';

  @override
  String get licVulgataTitle => 'Vulgate Clémentine (latin)';

  @override
  String get licVulgataBody => 'Texte biblique latin dans le domaine public.';

  @override
  String get licPatristicsTitle => 'Commentaire des Pères de l’Église';

  @override
  String get licPatristicsBody =>
      'Sources patristiques du domaine public, traduites automatiquement et adaptées. ';

  @override
  String get licPortugueseTitle => 'Bible portugaise (bêta)';

  @override
  String get licPortugueseBody =>
      'Une version interne pour cette phase de test. ';

  @override
  String get licMatosTitle => 'Padre Matos Soares (portugais)';

  @override
  String get licMatosBody => 'Traduction catholique du P. ';

  @override
  String get ossLicenses => 'Licences open source';

  @override
  String get settingsContact => 'Contact / Commentaires';

  @override
  String get whatsappTitle => 'Contactez-nous sur WhatsApp';

  @override
  String get whatsappSubtitle =>
      'Envoyer des suggestions et signaler des problèmes';

  @override
  String get noTranslationInstalled => 'Aucun installé';

  @override
  String get packageRequired => 'Requis';

  @override
  String packageInstalled(String size) {
    return 'Installé · $size';
  }

  @override
  String packageDownload(String download, String installed) {
    return 'Télécharger $download · $installed installé';
  }

  @override
  String installFailed(String error) {
    return 'Échec de l\'installation : $error';
  }

  @override
  String get liturgyTitle => 'Liturgie';

  @override
  String get celebrationOfDay => 'Célébration du jour';

  @override
  String get lectionaryNotice =>
      'Les lectures de cette journée ne sont pas encore disponibles.';

  @override
  String get liturgyOpenInBible => 'Ouvrir dans la Bible';

  @override
  String get readingTextUnavailable => 'Texte de lecture non disponible.';

  @override
  String get preparingBible => 'Préparer la Bible…';

  @override
  String get startupError => 'Échec du démarrage.';

  @override
  String get seasonAdvent => 'Avènement';

  @override
  String get seasonChristmas => 'Période de Noël';

  @override
  String get seasonOrdinary => 'Temps ordinaire';

  @override
  String get seasonLent => 'Carême';

  @override
  String get seasonTriduum => 'Triduum pascal';

  @override
  String get seasonEaster => 'Pâques';

  @override
  String get rankSolemnity => 'Solennité';

  @override
  String get rankFeast => 'Festin';

  @override
  String get rankMemorial => 'Mémorial';

  @override
  String get liturgyResponseWordOfLord => 'La parole du Seigneur.';

  @override
  String get liturgyResponseThanksToGod => 'Grâce à Dieu.';

  @override
  String get liturgyResponseGloryToYou => 'Gloire à toi, ô Seigneur.';

  @override
  String get liturgyResponseWordOfSalvation => 'L\'Évangile du Seigneur.';

  @override
  String liturgyGospelAccording(String evangelist) {
    return 'Une lecture du saint Évangile selon $evangelist';
  }

  @override
  String get licGreekTitle => 'Nouveau Testament grec (SBLGNT)';

  @override
  String get licGreekBody =>
      'Le Nouveau Testament grec SBL (SBLGNT), © Société de littérature biblique et Logos Bible Software. ';

  @override
  String get pressBackAgainToExit => 'Appuyez à nouveau pour quitter.';

  @override
  String get searchScopeBooks => 'Livres';

  @override
  String get sectionBooks => 'Livres';

  @override
  String get sectionGoTo => 'Aller à';

  @override
  String get searchOpenBook => 'Livre ouvert';

  @override
  String get commentaryTabPatristics => 'Patristique';

  @override
  String get commentaryExpandAll => 'Afficher tout';

  @override
  String get commentaryCollapseAll => 'Tout réduire';

  @override
  String get commentaryCollapse => 'Effondrement';

  @override
  String get shareCommentary => 'Partager les commentaires';

  @override
  String get roleDoctor => 'Docteur de l\'Église';

  @override
  String get rolePope => 'Pape';

  @override
  String get roleBishop => 'Évêque';

  @override
  String get roleMonk => 'Moine';

  @override
  String get rolePriest => 'Prêtre';

  @override
  String get roleDeacon => 'Diacre';

  @override
  String get roleExegete => 'Exégète';

  @override
  String get roleTheologian => 'Théologien';

  @override
  String get roleHistorian => 'Historien';

  @override
  String get rolePoet => 'Poète';

  @override
  String get rolePatristics => 'Patristique';

  @override
  String get roleMedieval => 'Médiéval';

  @override
  String get roleEarlyChristian => 'Premier chrétien';

  @override
  String get roleSaint => 'Saint';

  @override
  String get roleSaintFem => 'Saint';

  @override
  String get roleLiturgy => 'Liturgie';

  @override
  String get roleDocPatristic => 'Document patristique';

  @override
  String get roleDocMedieval => 'Document médiéval';

  @override
  String get roleDocHistorical => 'Document historique';

  @override
  String get roleDocGeneral => 'Document général';

  @override
  String authorMeta(String role, String century) {
    return '$role — $century cent.';
  }

  @override
  String get settingsCommentary => 'Commentaire';

  @override
  String get commentaryPreferences => 'Préférences de commentaires';

  @override
  String get commentaryPreferencesSubtitle =>
      'Choisissez quels commentateurs apparaissent lorsque vous ouvrez un verset.';

  @override
  String get commentaryClassification => 'Classification';

  @override
  String get commentaryCenturies => 'Des siècles';

  @override
  String get filterScholastic => 'Scolaire';

  @override
  String get filterSaints => 'Saints';

  @override
  String get commentaryOnlySaints => 'Saints seulement';

  @override
  String get commentaryOnlySaintsSubtitle =>
      'Mode simplifié : afficher uniquement les saints.';

  @override
  String get commentaryResetDefaults => 'Réinitialiser aux valeurs par défaut';

  @override
  String get commentaryPrefsAll => 'Tous les commentateurs';

  @override
  String commentaryPrefsFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtres actifs',
      one: '1 filtre actif',
    );
    return '$_temp0';
  }

  @override
  String commentaryHiddenByPrefs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commentaires masqués par vos préférences',
      one: '1 commentaire masqué par vos préférences',
    );
    return '$_temp0';
  }

  @override
  String get commentaryShowHidden => 'Montrer quand même';

  @override
  String get shareSelectVerses => 'Sélectionnez des versets';

  @override
  String shareSelectionTooLong(int max) {
    return 'Sélection trop longue pour une image (caractères $max max). ';
  }

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versets sélectionnés',
      one: '1 verset sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get selectionHint =>
      'Appuyez sur les versets pour choisir un passage continu.';

  @override
  String get selectionClear => 'Clair';

  @override
  String get shareSelection => 'Sélection d\'actions';

  @override
  String get planSectionBook => 'En lisant';

  @override
  String get planSectionWisdom => 'Sagesse';

  @override
  String get planCompleted => 'Lire';

  @override
  String get onbStyleTitle => 'Quel style de traduction préférez-vous ?';

  @override
  String get onbStyleSubtitle =>
      'Nous l\'utilisons pour suggérer une traduction. ';

  @override
  String get styleAcademic => 'Plus académique';

  @override
  String get styleSimple => 'Plus simple';

  @override
  String get styleBalanced => 'Équilibré';

  @override
  String get styleLiturgical => 'Liturgique';

  @override
  String get onbParallelTitle => 'Souhaitez-vous un texte parallèle ?';

  @override
  String get onbParallelSubtitle =>
      'Seuls les textes réellement installés sont affichés.';

  @override
  String get parallelLatin => 'latin';

  @override
  String get parallelGreek => 'grec';

  @override
  String get parallelHebrew => 'Hébreu / original';

  @override
  String get parallelNone => 'Non';

  @override
  String get langLatin => 'latin';

  @override
  String get langGreek => 'grec';

  @override
  String get langHebrew => 'hébreu';

  @override
  String get langPortuguese => 'portugais';

  @override
  String get langEnglish => 'Anglais';

  @override
  String get langItalian => 'italien';

  @override
  String get langSpanish => 'Espagnol';

  @override
  String get langFrench => 'Français';

  @override
  String translationWithLanguage(String language, String title) {
    return '$language — $title';
  }

  @override
  String get saintOfTheDay => 'Saint du jour';

  @override
  String get saintReadMore => 'En savoir plus';

  @override
  String saintSource(String source) {
    return 'Source : $source';
  }

  @override
  String saintDied(String year) {
    return '†$year';
  }

  @override
  String get liturgicalDirectory => 'Annuaire liturgique';

  @override
  String get directoryOpen => 'Comprendre cette célébration';

  @override
  String get directorySeason => 'Saison liturgique';

  @override
  String get directoryCelebration => 'La célébration';

  @override
  String get directoryColor => 'Couleur liturgique';

  @override
  String get directoryRank => 'Niveau de célébration';

  @override
  String get directoryPractical => 'Notes pratiques';

  @override
  String get directorySource =>
      'Basé sur les Normes universelles sur l\'année liturgique et le calendrier, l\'Instruction générale du missel romain et le Code de droit canonique.';

  @override
  String liturgyWeekOf(int week) {
    return 'semaine $week';
  }

  @override
  String get liturgyReadings => 'Lectures du jour';

  @override
  String get rankOptionalMemorial => 'Mémorial facultatif';

  @override
  String get rankCommemoration => 'Commémoration';

  @override
  String get colorGreen => 'Vert';

  @override
  String get colorRed => 'Rouge';

  @override
  String get colorWhite => 'Blanc';

  @override
  String get colorPurple => 'Violet';

  @override
  String get colorRose => 'Rose';

  @override
  String get actionUndo => 'Défaire';

  @override
  String get favoriteRemoved => 'Supprimé des favoris';

  @override
  String get highlightRemoved => 'Surbrillance supprimée';

  @override
  String liturgyReadingOf(String book) {
    return 'Une lecture $book';
  }

  @override
  String liturgyGospelCross(String evangelist) {
    return '✠ Une lecture du saint Évangile selon $evangelist';
  }

  @override
  String get psalmRefrain => 'Réponse';

  @override
  String get psalmVerses => 'Versets';

  @override
  String get psalmRefrainUnavailable =>
      'La réponse appropriée pour cette journée est donnée dans le Lectionnaire.';

  @override
  String get directoryCardSeason => 'Saison liturgique';

  @override
  String get directoryCardCelebration => 'Célébration';

  @override
  String get directoryCardColor => 'Couleur liturgique';

  @override
  String get directoryCardWeek => 'Semaine';

  @override
  String get directoryCardYear => 'Année liturgique';

  @override
  String get directoryCardCycle => 'Faire du vélo';

  @override
  String get directoryCardPreface => 'Préface';

  @override
  String get directoryCardObservances => 'Célébrations';

  @override
  String get directoryCardEphemerides => 'Aujourd\'hui aussi';

  @override
  String liturgicalCycle(String cycle) {
    return 'Cycle $cycle';
  }

  @override
  String commentaryExcerpt(int number) {
    return 'Commentaire $number';
  }

  @override
  String commentaryExcerptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count extraits',
      one: '1 extrait',
    );
    return '$_temp0';
  }

  @override
  String get homePsalmToday => 'Le psaume d\'aujourd\'hui';

  @override
  String get homePsalmRefrain => 'Psaume s\'abstenir';

  @override
  String get homeReadPsalm => 'Lire le psaume';

  @override
  String get homeGospelToday => 'L\'Évangile d\'aujourd\'hui';

  @override
  String get homeReadGospel => 'Lire l\'Evangile';

  @override
  String get homeSeeLiturgy => 'Voir la liturgie';

  @override
  String get sectionPentateuch => 'Pentateuque';

  @override
  String get sectionHistorical => 'Livres historiques';

  @override
  String get sectionWisdom => 'Livres de sagesse';

  @override
  String get sectionProphets => 'Prophètes';

  @override
  String get sectionGospels => 'Évangiles';

  @override
  String get sectionActs => 'Actes des Apôtres';

  @override
  String get sectionPauline => 'Lettres de saint Paul';

  @override
  String get sectionCatholicLetters => 'Lettres catholiques';

  @override
  String get sectionApocalypse => 'Apocalypse';

  @override
  String get themesTitle => 'Bibliothèque thématique';

  @override
  String get themesSubtitle => 'Écriture par thème, lue avec les Pères';

  @override
  String get themeLibraryLoadError =>
      'La bibliothèque thématique n\'a pas pu être chargée. ';

  @override
  String themePassages(int n) {
    return 'Passages $n';
  }

  @override
  String get themePassagesLabel => 'Passages';

  @override
  String themeCommentaryCount(int n) {
    return '$n commentaires des Pères';
  }

  @override
  String get themeNoText => 'Texte non disponible dans la traduction actuelle.';

  @override
  String get shareChooseExcerpt => 'Choisissez l\'extrait pour l\'image';

  @override
  String get shareExcerptHint =>
      'Appuyez sur les phrases qui doivent apparaître sur la carte. ';

  @override
  String shareExcerptCount(int n, int max) {
    return 'Caractères $n sur $max';
  }

  @override
  String get shareContinue => 'Continuer';

  @override
  String get shareExcerptTooLong =>
      'Trop long pour une seule carte : désélectionnez une phrase.';

  @override
  String get shareExcerptNone => 'Sélectionnez au moins une phrase.';
}
