// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Biblia Traditio';

  @override
  String get tagline => 'Escritura a la luz de la Tradición.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navLiturgy => 'Liturgia';

  @override
  String get navBible => 'Biblia';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get actionRemove => 'Eliminar';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get removePackageTitle => '¿Quitar paquete?';

  @override
  String get removePackageMessage =>
      'Deberá descargarlo nuevamente para reinstalarlo.';

  @override
  String get deleteNoteTitle => '¿Eliminar nota?';

  @override
  String get deleteNoteMessage => 'Esto no se puede deshacer.';

  @override
  String get contactLaunchFailed => 'No se pudo abrir WhatsApp.';

  @override
  String get copied => 'copiado';

  @override
  String get installSuccess => 'Instalado exitosamente';

  @override
  String get removeSuccess => 'Paquete eliminado';

  @override
  String get highlight => 'Resaltar';

  @override
  String get deuterocanonicalShort => 'corriente continua';

  @override
  String get greetingMorning => 'Buen día,';

  @override
  String get greetingAfternoon => 'Buenas tardes,';

  @override
  String get greetingEvening => 'Buenas noches,';

  @override
  String get greetingFallback => 'La paz sea contigo';

  @override
  String get quickContinue => 'Continuar';

  @override
  String get quickToday => 'Hoy';

  @override
  String get quickFavorites => 'Favoritos';

  @override
  String get homeJourney => 'continúa tu viaje';

  @override
  String get readingPlan => 'plan de lectura';

  @override
  String get comingSoon => 'Muy pronto';

  @override
  String get planSubtitle => 'Un año a través de la Sagrada Escritura';

  @override
  String get planToday => 'Hoy';

  @override
  String planDay(int day) {
    return 'Día $day';
  }

  @override
  String planDayProgress(int day, int total) {
    return 'Día $day de $total';
  }

  @override
  String planProgress(int done, int total) {
    return '$done de $total días leídos';
  }

  @override
  String get planMarkRead => 'Marcar como leído';

  @override
  String get notes => 'Notas';

  @override
  String get notesEmptySubtitle => 'Tus reflexiones personales';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get liturgyToday => 'la liturgia de hoy';

  @override
  String get ordinaryTime => 'Tiempo Ordinario';

  @override
  String liturgicalYear(String cycle) {
    return 'Año $cycle';
  }

  @override
  String get readingFirst => 'Primera lectura';

  @override
  String get readingPsalm => 'Salmo';

  @override
  String get readingSecond => 'Segunda lectura';

  @override
  String get readingGospel => 'Evangelio';

  @override
  String get onbNameTitle => '¿Cómo deberíamos llamarte?';

  @override
  String get onbNameSubtitle => 'Usaremos tu nombre para saludarte.';

  @override
  String get namePlaceholder => 'Su nombre';

  @override
  String get onbLanguageTitle => 'Idioma';

  @override
  String get onbLanguageSubtitle => '¿Qué idioma prefieres para la interfaz?';

  @override
  String get onbTranslationTitle => 'Traducción';

  @override
  String get onbTranslationSubtitle =>
      'Elija su traducción principal de las Escrituras.';

  @override
  String get onbNotificationsTitle => 'Recordatorios diarios';

  @override
  String get onbNotificationsSubtitle =>
      'Reciba una amable invitación a la lectura y la liturgia del día.';

  @override
  String get onbPlanTitle => 'plan de lectura';

  @override
  String get onbPlanSubtitle =>
      '¿Te gustaría seguir un plan para leer las Escrituras?';

  @override
  String get onbContinue => 'Continuar';

  @override
  String get onbEnter => 'Ingresar';

  @override
  String get onbSkip => 'Omitir';

  @override
  String get enable => 'Permitir';

  @override
  String get notNow => 'Ahora no';

  @override
  String get bibleTitle => 'Biblia';

  @override
  String get search => 'Buscar';

  @override
  String get oldTestament => 'Antiguo Testamento';

  @override
  String get newTestament => 'Nuevo Testamento';

  @override
  String get oldTestamentShort => 'Antiguo Testamento';

  @override
  String get newTestamentShort => 'Nuevo Testamento';

  @override
  String get noBooksFound => 'No se encontraron libros.';

  @override
  String get contentNotInstalled => 'Contenido aún no instalado.\n';

  @override
  String chapterTitle(int number) {
    return 'Capítulo $number';
  }

  @override
  String chapterPickerTitle(String book) {
    return '$book — capítulo';
  }

  @override
  String get goToVerse => 'ir al verso';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Próximo';

  @override
  String get scriptureNotInstalled => 'El texto bíblico aún no está instalado.';

  @override
  String get share => 'Compartir';

  @override
  String get copyVerse => 'Copiar verso';

  @override
  String get favorite => 'Favorito';

  @override
  String get unfavorite => 'Quitar de favoritos';

  @override
  String get bookmark => 'Marcador';

  @override
  String get unbookmark => 'Quitar marcador';

  @override
  String get note => 'Nota';

  @override
  String notesWithCount(int count) {
    return 'Notas ($count)';
  }

  @override
  String get churchFathers => 'Padres de la Iglesia';

  @override
  String get myNotes => 'Mis notas';

  @override
  String get noCommentaryForVerse =>
      'Aún no hay comentarios disponibles para este versículo.';

  @override
  String get patristicsNotInstalled =>
      'Instale el comentario de los Padres de la Iglesia en Configuración para leer este versículo con la Iglesia.';

  @override
  String get noNotesForVerse => 'Aún no hay notas para este versículo.';

  @override
  String get writeReflection => 'escribe una reflexion';

  @override
  String commentaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios',
      one: '1 comentario',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'Todo';

  @override
  String get filterFathers => 'Patrística';

  @override
  String get filterMedieval => 'Medieval';

  @override
  String get filterAugustine => 'San Agustín';

  @override
  String get filterAquinas => 'Santo Tomás de Aquino';

  @override
  String get colorMode => 'Modo de color';

  @override
  String get fontSizeSoon => 'Tamaño de fuente (pronto)';

  @override
  String century(String value) {
    return 'sig. $value';
  }

  @override
  String get machineTranslation => 'traducción automática';

  @override
  String get shareCopy => 'Copiar';

  @override
  String get shareText => 'Texto';

  @override
  String get shareImage => 'Imagen';

  @override
  String noteEditorTitle(String reference) {
    return 'Nota: $reference';
  }

  @override
  String get noteHint => 'Escribe tu reflexión...';

  @override
  String get parallelReading => 'Lectura paralela';

  @override
  String get singleTranslation => 'traducción única';

  @override
  String get parallelOptionsTitle => 'Lectura paralela';

  @override
  String get secondaryTranslation => 'traducción secundaria';

  @override
  String get noSecondaryTranslation =>
      'Aún no se ha instalado ninguna traducción secundaria.';

  @override
  String get openOfflineResources => 'Abrir recursos sin conexión';

  @override
  String get verseNotInTranslation => 'Verso no disponible en esta traducción.';

  @override
  String get parallelLayoutLabel => 'Disposición';

  @override
  String get layoutAuto => 'Automático';

  @override
  String get layoutStacked => 'apilados';

  @override
  String get layoutSideBySide => 'Juntos';

  @override
  String get searchHint => 'Buscar Escritura, Patrística, notas…';

  @override
  String get searchScopeAll => 'Todo';

  @override
  String get searchScopeScripture => 'Sagrada Escritura';

  @override
  String get searchScopeFathers => 'Patrística';

  @override
  String get searchScopeNotes => 'Notas';

  @override
  String get searchTypeMore => 'Escriba al menos 2 letras para buscar.';

  @override
  String searchNoResults(String query) {
    return 'No hay resultados para “$query”.';
  }

  @override
  String get sectionScripture => 'Sagrada Escritura';

  @override
  String get notesScreenTitle => 'Notas';

  @override
  String get searchNotesHint => 'Notas de búsqueda';

  @override
  String get noNotesYet => 'Aún no hay notas.';

  @override
  String get favoritesTitle => 'Favoritos';

  @override
  String get noFavoritesYet => 'Aún no hay favoritos.';

  @override
  String get highlightsTitle => 'Reflejos';

  @override
  String get noHighlightsYet => 'Aún no hay aspectos destacados.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsName => 'Nombre';

  @override
  String get settingsReading => 'Lectura';

  @override
  String get settingsTranslation => 'Traducción';

  @override
  String get settingsAppLanguage => 'Idioma de la aplicación';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Luz';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get settingsReminders => 'Recordatorios diarios';

  @override
  String get settingsOfflineResources => 'Recursos sin conexión';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get licensesTitle => 'Licencias y Atribuciones';

  @override
  String get licensesIntro =>
      'Biblia Traditio respeta las fuentes que utiliza. ';

  @override
  String get licVulgataTitle => 'Vulgata Clementina (latina)';

  @override
  String get licVulgataBody => 'Texto bíblico latino de dominio público.';

  @override
  String get licPatristicsTitle => 'Comentario de los Padres de la Iglesia';

  @override
  String get licPatristicsBody =>
      'Fuentes patrísticas de dominio público, traducidas y adaptadas automáticamente. ';

  @override
  String get licPortugueseTitle => 'Biblia portuguesa (beta)';

  @override
  String get licPortugueseBody =>
      'Una versión interna para esta fase de prueba. ';

  @override
  String get licMatosTitle => 'Padre Matos Soares (portugués)';

  @override
  String get licMatosBody => 'Traducción católica del P. ';

  @override
  String get ossLicenses => 'Licencias de código abierto';

  @override
  String get settingsContact => 'Contacto / Comentarios';

  @override
  String get whatsappTitle => 'Contáctanos por WhatsApp';

  @override
  String get whatsappSubtitle => 'Enviar sugerencias e informar problemas';

  @override
  String get noTranslationInstalled => 'Ninguno instalado';

  @override
  String get packageRequired => 'Requerido';

  @override
  String packageInstalled(String size) {
    return 'Instalado · $size';
  }

  @override
  String packageDownload(String download, String installed) {
    return 'Descargar $download · $installed instalado';
  }

  @override
  String installFailed(String error) {
    return 'Error de instalación: $error';
  }

  @override
  String get liturgyTitle => 'Liturgia';

  @override
  String get celebrationOfDay => 'Celebración del día';

  @override
  String get lectionaryNotice =>
      'Las lecturas para este día aún no están disponibles.';

  @override
  String get liturgyOpenInBible => 'Abrir en la Biblia';

  @override
  String get readingTextUnavailable => 'Texto de lectura no disponible.';

  @override
  String get preparingBible => 'Preparando la Biblia...';

  @override
  String get startupError => 'No se pudo iniciar.';

  @override
  String get seasonAdvent => 'Adviento';

  @override
  String get seasonChristmas => 'Navidad';

  @override
  String get seasonOrdinary => 'Tiempo Ordinario';

  @override
  String get seasonLent => 'Cuaresma';

  @override
  String get seasonTriduum => 'Triduo Pascual';

  @override
  String get seasonEaster => 'marea de pascua';

  @override
  String get rankSolemnity => 'Solemnidad';

  @override
  String get rankFeast => 'Banquete';

  @override
  String get rankMemorial => 'Memorial';

  @override
  String get liturgyResponseWordOfLord => 'La palabra del Señor.';

  @override
  String get liturgyResponseThanksToGod => 'Gracias a Dios.';

  @override
  String get liturgyResponseGloryToYou => 'Gloria a ti, oh Señor.';

  @override
  String get liturgyResponseWordOfSalvation => 'El Evangelio del Señor.';

  @override
  String liturgyGospelAccording(String evangelist) {
    return 'Una lectura del santo Evangelio según $evangelist';
  }

  @override
  String get licGreekTitle => 'Nuevo Testamento griego (SBLGNT)';

  @override
  String get licGreekBody =>
      'El Nuevo Testamento griego SBL (SBLGNT), © Sociedad de Literatura Bíblica y Software Bíblico Logos. ';

  @override
  String get pressBackAgainToExit =>
      'Presione hacia atrás nuevamente para salir.';

  @override
  String get searchScopeBooks => 'Libros';

  @override
  String get sectionBooks => 'Libros';

  @override
  String get sectionGoTo => 'Ir a';

  @override
  String get searchOpenBook => 'Libro abierto';

  @override
  String get commentaryTabPatristics => 'Patrística';

  @override
  String get commentaryExpandAll => 'Mostrar todo';

  @override
  String get commentaryCollapseAll => 'Contraer todo';

  @override
  String get commentaryCollapse => 'Colapsar';

  @override
  String get shareCommentary => 'Compartir comentario';

  @override
  String get roleDoctor => 'Doctor de la Iglesia';

  @override
  String get rolePope => 'Papa';

  @override
  String get roleBishop => 'Obispo';

  @override
  String get roleMonk => 'Monje';

  @override
  String get rolePriest => 'Sacerdote';

  @override
  String get roleDeacon => 'Diácono';

  @override
  String get roleExegete => 'exégeta';

  @override
  String get roleTheologian => 'Teólogo';

  @override
  String get roleHistorian => 'Historiador';

  @override
  String get rolePoet => 'Poeta';

  @override
  String get rolePatristics => 'Patrística';

  @override
  String get roleMedieval => 'Medieval';

  @override
  String get roleEarlyChristian => 'Cristiano primitivo';

  @override
  String get roleSaint => 'Smo.';

  @override
  String get roleSaintFem => 'Smo.';

  @override
  String get roleLiturgy => 'Liturgia';

  @override
  String get roleDocPatristic => 'Documento Patrístico';

  @override
  String get roleDocMedieval => 'Documento medieval';

  @override
  String get roleDocHistorical => 'Documento histórico';

  @override
  String get roleDocGeneral => 'Documento General';

  @override
  String authorMeta(String role, String century) {
    return '$role — $century centavo.';
  }

  @override
  String get settingsCommentary => 'Comentario';

  @override
  String get commentaryPreferences => 'Preferencias de comentarios';

  @override
  String get commentaryPreferencesSubtitle =>
      'Elige qué comentaristas aparecen al abrir un verso.';

  @override
  String get commentaryClassification => 'Clasificación';

  @override
  String get commentaryCenturies => 'Siglos';

  @override
  String get filterScholastic => 'Escolar';

  @override
  String get filterSaints => 'santos';

  @override
  String get commentaryOnlySaints => 'Solo santos';

  @override
  String get commentaryOnlySaintsSubtitle =>
      'Modo simplificado: muestra sólo santos.';

  @override
  String get commentaryResetDefaults =>
      'Restablecer los valores predeterminados';

  @override
  String get commentaryPrefsAll => 'Todos los comentaristas';

  @override
  String commentaryPrefsFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros activos',
      one: '1 filtro activo',
    );
    return '$_temp0';
  }

  @override
  String commentaryHiddenByPrefs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios ocultos por tus preferencias',
      one: '1 comentario oculto por tus preferencias',
    );
    return '$_temp0';
  }

  @override
  String get commentaryShowHidden => 'Mostrar de todos modos';

  @override
  String get shareSelectVerses => 'Seleccionar versos';

  @override
  String shareSelectionTooLong(int max) {
    return 'Selección demasiado larga para una imagen (máximo de caracteres $max). ';
  }

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versículos seleccionados',
      one: '1 versículo seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get selectionHint => 'Toque versos para elegir un pasaje continuo.';

  @override
  String get selectionClear => 'Claro';

  @override
  String get shareSelection => 'Selección de acciones';

  @override
  String get planSectionBook => 'Lectura';

  @override
  String get planSectionWisdom => 'Sabiduría';

  @override
  String get planCompleted => 'Leer';

  @override
  String get onbStyleTitle => '¿Qué estilo de traducción prefieres?';

  @override
  String get onbStyleSubtitle => 'Usamos esto para sugerir una traducción. ';

  @override
  String get styleAcademic => 'Más académico';

  @override
  String get styleSimple => 'Más simple';

  @override
  String get styleBalanced => 'Equilibrado';

  @override
  String get styleLiturgical => 'Litúrgico';

  @override
  String get onbParallelTitle => '¿Quieres un texto paralelo?';

  @override
  String get onbParallelSubtitle =>
      'Sólo se muestran los textos realmente instalados.';

  @override
  String get parallelLatin => 'latín';

  @override
  String get parallelGreek => 'Griego';

  @override
  String get parallelHebrew => 'Hebreo / original';

  @override
  String get parallelNone => 'No';

  @override
  String get langLatin => 'latín';

  @override
  String get langGreek => 'Griego';

  @override
  String get langHebrew => 'hebreo';

  @override
  String get langPortuguese => 'portugués';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langItalian => 'italiano';

  @override
  String get langSpanish => 'Español';

  @override
  String get langFrench => 'Francés';

  @override
  String translationWithLanguage(String language, String title) {
    return '$language — $title';
  }

  @override
  String get saintOfTheDay => 'santo del dia';

  @override
  String get saintReadMore => 'Leer más';

  @override
  String saintSource(String source) {
    return 'Fuente: $source';
  }

  @override
  String saintDied(String year) {
    return '†$year';
  }

  @override
  String get liturgicalDirectory => 'Directorio litúrgico';

  @override
  String get directoryOpen => 'Entiende esta celebración';

  @override
  String get directorySeason => 'Tiempo litúrgico';

  @override
  String get directoryCelebration => 'la celebración';

  @override
  String get directoryColor => 'Color litúrgico';

  @override
  String get directoryRank => 'Grado de celebración';

  @override
  String get directoryPractical => 'Notas practicas';

  @override
  String get directorySource =>
      'Basado en las Normas Universales sobre el Año Litúrgico y el Calendario, la Instrucción General del Misal Romano y el Código de Derecho Canónico.';

  @override
  String liturgyWeekOf(int week) {
    return 'semana $week';
  }

  @override
  String get liturgyReadings => 'lecturas del dia';

  @override
  String get rankOptionalMemorial => 'Memorial opcional';

  @override
  String get rankCommemoration => 'Conmemoración';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorWhite => 'Blanco';

  @override
  String get colorPurple => 'Púrpura';

  @override
  String get colorRose => 'Rosa';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get favoriteRemoved => 'Eliminado de favoritos';

  @override
  String get highlightRemoved => 'Resaltado eliminado';

  @override
  String liturgyReadingOf(String book) {
    return 'Una lectura $book';
  }

  @override
  String liturgyGospelCross(String evangelist) {
    return '✠ Una lectura del santo Evangelio según $evangelist';
  }

  @override
  String get psalmRefrain => 'Respuesta';

  @override
  String get psalmVerses => 'Versos';

  @override
  String get psalmRefrainUnavailable =>
      'La respuesta adecuada para este día se da en el Leccionario.';

  @override
  String get directoryCardSeason => 'Temporada Litúrgica';

  @override
  String get directoryCardCelebration => 'Celebración';

  @override
  String get directoryCardColor => 'Color litúrgico';

  @override
  String get directoryCardWeek => 'Semana';

  @override
  String get directoryCardYear => 'Año Litúrgico';

  @override
  String get directoryCardCycle => 'Ciclo';

  @override
  String get directoryCardPreface => 'Prefacio';

  @override
  String get directoryCardObservances => 'Observancias';

  @override
  String get directoryCardEphemerides => 'También hoy';

  @override
  String liturgicalCycle(String cycle) {
    return 'Ciclo $cycle';
  }

  @override
  String commentaryExcerpt(int number) {
    return 'Comentar $number';
  }

  @override
  String commentaryExcerptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fragmentos',
      one: '1 fragmento',
    );
    return '$_temp0';
  }

  @override
  String get homePsalmToday => 'salmo de hoy';

  @override
  String get homePsalmRefrain => 'estribillo del salmo';

  @override
  String get homeReadPsalm => 'leer el salmo';

  @override
  String get homeGospelToday => 'El evangelio de hoy';

  @override
  String get homeReadGospel => 'leer el evangelio';

  @override
  String get homeSeeLiturgy => 'ver la liturgia';

  @override
  String get sectionPentateuch => 'Pentateuco';

  @override
  String get sectionHistorical => 'libros historicos';

  @override
  String get sectionWisdom => 'libros de sabiduría';

  @override
  String get sectionProphets => 'Profetas';

  @override
  String get sectionGospels => 'evangelios';

  @override
  String get sectionActs => 'Hechos de los Apóstoles';

  @override
  String get sectionPauline => 'Cartas de San Pablo';

  @override
  String get sectionCatholicLetters => 'cartas catolicas';

  @override
  String get sectionApocalypse => 'Apocalipsis';

  @override
  String get themesTitle => 'biblioteca temática';

  @override
  String get themesSubtitle => 'Escritura por tema, leída con los Padres';

  @override
  String get themeLibraryLoadError =>
      'No se pudo cargar la biblioteca temática. ';

  @override
  String themePassages(int n) {
    return 'Pasajes $n';
  }

  @override
  String get themePassagesLabel => 'Pasajes';

  @override
  String themeCommentaryCount(int n) {
    return '$n comentarios de los Padres';
  }

  @override
  String get themeNoText => 'Texto no disponible en la traducción actual.';

  @override
  String get shareChooseExcerpt => 'Elige el extracto de la imagen.';

  @override
  String get shareExcerptHint =>
      'Toca las frases que deberían aparecer en la tarjeta. ';

  @override
  String shareExcerptCount(int n, int max) {
    return '$n de caracteres $max';
  }

  @override
  String get shareContinue => 'Continuar';

  @override
  String get shareExcerptTooLong =>
      'Demasiado largo para una tarjeta: anule la selección de una oración.';

  @override
  String get shareExcerptNone => 'Seleccione al menos una oración.';
}
