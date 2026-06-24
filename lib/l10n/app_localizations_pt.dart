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
  String get actionDelete => 'Excluir';

  @override
  String get actionRemove => 'Remover';

  @override
  String get actionDownload => 'Baixar';

  @override
  String get removePackageTitle => 'Remover pacote?';

  @override
  String get removePackageMessage =>
      'Você precisará baixá-lo novamente para reinstalar.';

  @override
  String get deleteNoteTitle => 'Excluir nota?';

  @override
  String get deleteNoteMessage => 'Esta ação não pode ser desfeita.';

  @override
  String get contactLaunchFailed => 'Não foi possível abrir o WhatsApp.';

  @override
  String get copied => 'Copiado';

  @override
  String get installSuccess => 'Instalado com sucesso';

  @override
  String get removeSuccess => 'Pacote removido';

  @override
  String get highlight => 'Destacar';

  @override
  String get deuterocanonicalShort => 'DC';

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
  String get planSubtitle => 'Um ano pela Sagrada Escritura';

  @override
  String get planToday => 'Hoje';

  @override
  String planDay(int day) {
    return 'Dia $day';
  }

  @override
  String planDayProgress(int day, int total) {
    return 'Dia $day de $total';
  }

  @override
  String planProgress(int done, int total) {
    return '$done de $total dias lidos';
  }

  @override
  String get planMarkRead => 'Marcar como lido';

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
  String get readingFirst => 'Primeira Leitura';

  @override
  String get readingPsalm => 'Salmo';

  @override
  String get readingSecond => 'Segunda Leitura';

  @override
  String get readingGospel => 'Evangelho';

  @override
  String get onbNameTitle => 'Como devemos chamá-lo?';

  @override
  String get onbNameSubtitle => 'Usaremos o seu nome para saudá-lo.';

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
  String get onbSkip => 'Pular';

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
  String get filterFathers => 'Patrística';

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
  String get parallelReading => 'Leitura paralela';

  @override
  String get singleTranslation => 'Tradução única';

  @override
  String get parallelOptionsTitle => 'Leitura paralela';

  @override
  String get secondaryTranslation => 'Tradução secundária';

  @override
  String get noSecondaryTranslation =>
      'Nenhuma tradução secundária instalada ainda.';

  @override
  String get openOfflineResources => 'Abrir Recursos offline';

  @override
  String get verseNotInTranslation =>
      'Versículo não disponível nesta tradução.';

  @override
  String get parallelLayoutLabel => 'Disposição';

  @override
  String get layoutAuto => 'Automático';

  @override
  String get layoutStacked => 'Empilhado';

  @override
  String get layoutSideBySide => 'Lado a lado';

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
  String get settingsAbout => 'Sobre';

  @override
  String get licensesTitle => 'Licenças e atribuições';

  @override
  String get licensesIntro =>
      'Biblia Traditio respeita as fontes que utiliza. Veja abaixo a origem e a licença de cada conteúdo.';

  @override
  String get licVulgataTitle => 'Vulgata Clementina (Latim)';

  @override
  String get licVulgataBody => 'Texto bíblico em latim, em domínio público.';

  @override
  String get licPatristicsTitle => 'Comentário dos Padres da Igreja';

  @override
  String get licPatristicsBody =>
      'Fontes patrísticas em domínio público, traduzidas e adaptadas automaticamente. Podem conter imprecisões — leia com discernimento.';

  @override
  String get licPortugueseTitle => 'Bíblia em Português (beta)';

  @override
  String get licPortugueseBody =>
      'Versão de uso interno para esta fase de testes. A origem da tradução ainda será confirmada antes de qualquer publicação pública.';

  @override
  String get licMatosTitle => 'Padre Matos Soares (Português)';

  @override
  String get licMatosBody =>
      'Tradução católica do Pe. Matos Soares (falecido em 1950) — candidata a domínio público no Brasil desde 2021 (vida + 70 anos). A proveniência está em verificação durante o beta.';

  @override
  String get ossLicenses => 'Licenças de código aberto';

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
      'As leituras deste dia ainda não estão disponíveis.';

  @override
  String get liturgyOpenInBible => 'Abrir na Bíblia';

  @override
  String get readingTextUnavailable => 'Texto da leitura não disponível.';

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

  @override
  String get liturgyResponseWordOfLord => 'Palavra do Senhor.';

  @override
  String get liturgyResponseThanksToGod => 'Graças a Deus.';

  @override
  String get liturgyResponseGloryToYou => 'Glória a vós, Senhor.';

  @override
  String get liturgyResponseWordOfSalvation => 'Palavra da Salvação.';

  @override
  String liturgyGospelAccording(String evangelist) {
    return 'Proclamação do Evangelho de Jesus Cristo segundo $evangelist';
  }

  @override
  String get licGreekTitle => 'Novo Testamento Grego (SBLGNT)';

  @override
  String get licGreekBody =>
      'O Novo Testamento Grego SBL (SBLGNT), © Society of Biblical Literature e Logos Bible Software. Usado sob a licença Creative Commons Atribuição 4.0.';
}
