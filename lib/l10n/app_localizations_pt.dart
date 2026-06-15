// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppL10nPt extends AppL10n {
  AppL10nPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Biblia Traditio';

  @override
  String get tagline => 'A Escritura à luz da Tradição.';

  @override
  String get navHome => 'Início';

  @override
  String get navLiturgy => 'Liturgia';

  @override
  String get navBible => 'Bíblia';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionClose => 'Fechar';

  @override
  String get greetingMorning => 'Bom dia,';

  @override
  String get greetingAfternoon => 'Boa tarde,';

  @override
  String get greetingEvening => 'Boa noite,';

  @override
  String get greetingFallback => 'Paz e bem';

  @override
  String get quickContinue => 'Continuar';

  @override
  String get quickToday => 'Hoje';

  @override
  String get quickFavorites => 'Favoritos';

  @override
  String get homeJourney => 'Continue a sua jornada';

  @override
  String get readingPlan => 'Plano de leitura';

  @override
  String get comingSoon => 'Em breve';

  @override
  String get notes => 'Notas';

  @override
  String get notesEmptySubtitle => 'As suas reflexões pessoais';

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
  String get liturgyToday => 'Liturgia de hoje';

  @override
  String get ordinaryTime => 'Tempo Comum';

  @override
  String liturgicalYear(String cycle) {
    return 'Ano $cycle';
  }

  @override
  String get readingFirst => '1ª leitura';

  @override
  String get readingPsalm => 'Salmo';

  @override
  String get readingSecond => '2ª leitura';

  @override
  String get readingGospel => 'Evangelho';

  @override
  String get onbNameTitle => 'Como devemos chamá-lo?';

  @override
  String get onbNameSubtitle => 'Usaremos o seu nome para o saudar.';

  @override
  String get namePlaceholder => 'O seu nome';

  @override
  String get onbLanguageTitle => 'Idioma';

  @override
  String get onbLanguageSubtitle => 'Em que língua prefere a interface?';

  @override
  String get onbTranslationTitle => 'Tradução';

  @override
  String get onbTranslationSubtitle =>
      'Escolha a sua tradução principal das Escrituras.';

  @override
  String get onbNotificationsTitle => 'Lembretes diários';

  @override
  String get onbNotificationsSubtitle =>
      'Receba um convite suave para a leitura e a liturgia do dia.';

  @override
  String get onbPlanTitle => 'Plano de leitura';

  @override
  String get onbPlanSubtitle =>
      'Deseja seguir um plano para ler as Escrituras?';

  @override
  String get onbContinue => 'Continuar';

  @override
  String get onbEnter => 'Entrar';

  @override
  String get onbSkip => 'Saltar';

  @override
  String get enable => 'Ativar';

  @override
  String get notNow => 'Agora não';

  @override
  String get bibleTitle => 'Bíblia';

  @override
  String get search => 'Pesquisar';

  @override
  String get oldTestament => 'Antigo testamento';

  @override
  String get newTestament => 'Novo testamento';

  @override
  String get oldTestamentShort => 'AT';

  @override
  String get newTestamentShort => 'NT';

  @override
  String get noBooksFound => 'Nenhum livro encontrado.';

  @override
  String get contentNotInstalled =>
      'Conteúdo ainda não instalado.\nInstale um pacote de tradução em Ajustes.';

  @override
  String chapterTitle(int number) {
    return 'Capítulo $number';
  }

  @override
  String chapterPickerTitle(String book) {
    return '$book — capítulo';
  }

  @override
  String get goToVerse => 'Ir para versículo';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Próximo';

  @override
  String get scriptureNotInstalled =>
      'O texto bíblico ainda não está instalado.';

  @override
  String get share => 'Partilhar';

  @override
  String get copyVerse => 'Copiar versículo';

  @override
  String get favorite => 'Favoritar';

  @override
  String get unfavorite => 'Remover dos favoritos';

  @override
  String get bookmark => 'Marcar';

  @override
  String get unbookmark => 'Remover marcador';

  @override
  String get note => 'Nota';

  @override
  String notesWithCount(int count) {
    return 'Notas ($count)';
  }

  @override
  String get churchFathers => 'Padres da Igreja';

  @override
  String get myNotes => 'Minhas Notas';

  @override
  String get noCommentaryForVerse =>
      'Ainda não há comentário para este versículo.';

  @override
  String get patristicsNotInstalled =>
      'Instale o Comentário dos Padres em Ajustes para ler este versículo com a Igreja.';

  @override
  String get noNotesForVerse => 'Ainda não há notas para este versículo.';

  @override
  String get writeReflection => 'Escrever uma reflexão';

  @override
  String commentaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentários',
      one: '1 comentário',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'Todos';

  @override
  String get filterFathers => 'Padres';

  @override
  String get filterMedieval => 'Medieval';

  @override
  String get filterAugustine => 'Santo Agostinho';

  @override
  String get filterAquinas => 'S. Tomás de Aquino';

  @override
  String get colorMode => 'Modo de cor';

  @override
  String get fontSizeSoon => 'Tamanho da fonte (em breve)';

  @override
  String century(String value) {
    return 'séc. $value';
  }

  @override
  String get machineTranslation => 'tradução automática';

  @override
  String get shareCopy => 'Copiar';

  @override
  String get shareText => 'Texto';

  @override
  String get shareImage => 'Imagem';

  @override
  String noteEditorTitle(String reference) {
    return 'Nota — $reference';
  }

  @override
  String get noteHint => 'Escreva a sua reflexão…';

  @override
  String get searchHint => 'Pesquisar Escritura, Padres, notas…';

  @override
  String get searchScopeAll => 'Tudo';

  @override
  String get searchScopeScripture => 'Escritura';

  @override
  String get searchScopeFathers => 'Padres';

  @override
  String get searchScopeNotes => 'Notas';

  @override
  String get searchTypeMore => 'Escreva ao menos 2 letras para pesquisar.';

  @override
  String searchNoResults(String query) {
    return 'Nenhum resultado para “$query”.';
  }

  @override
  String get sectionScripture => 'Escritura';

  @override
  String get notesScreenTitle => 'Notas';

  @override
  String get searchNotesHint => 'Pesquisar notas';

  @override
  String get noNotesYet => 'Nenhuma nota ainda.';

  @override
  String get favoritesTitle => 'Favoritos';

  @override
  String get noFavoritesYet => 'Nenhum favorito ainda.';

  @override
  String get highlightsTitle => 'Destaques';

  @override
  String get noHighlightsYet => 'Nenhum destaque ainda.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsName => 'Nome';

  @override
  String get settingsReading => 'Leitura';

  @override
  String get settingsTranslation => 'Tradução';

  @override
  String get settingsAppLanguage => 'Idioma do app';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get settingsReminders => 'Lembretes diários';

  @override
  String get settingsOfflineResources => 'Recursos offline';

  @override
  String get settingsContact => 'Contato / Feedback';

  @override
  String get whatsappTitle => 'Fale conosco no WhatsApp';

  @override
  String get whatsappSubtitle => 'Envie sugestões e relate problemas';

  @override
  String get noTranslationInstalled => 'Nenhuma instalada';

  @override
  String get packageRequired => 'Necessário';

  @override
  String packageInstalled(String size) {
    return 'Instalado · $size';
  }

  @override
  String packageDownload(String download, String installed) {
    return 'Download $download · $installed instalado';
  }

  @override
  String installFailed(String error) {
    return 'Falha ao instalar: $error';
  }

  @override
  String get liturgyTitle => 'Liturgia';

  @override
  String get celebrationOfDay => 'Celebração do dia';

  @override
  String get lectionaryNotice =>
      'O calendário litúrgico está disponível offline. As leituras da Missa requerem o pacote do Lecionário (em breve).';

  @override
  String get preparingBible => 'Preparando a Bíblia…';

  @override
  String get startupError => 'Erro ao iniciar.';

  @override
  String get seasonAdvent => 'Advento';

  @override
  String get seasonChristmas => 'Tempo do Natal';

  @override
  String get seasonOrdinary => 'Tempo Comum';

  @override
  String get seasonLent => 'Quaresma';

  @override
  String get seasonTriduum => 'Tríduo Pascal';

  @override
  String get seasonEaster => 'Tempo Pascal';

  @override
  String get rankSolemnity => 'Solenidade';

  @override
  String get rankFeast => 'Festa';

  @override
  String get rankMemorial => 'Memória';
}
