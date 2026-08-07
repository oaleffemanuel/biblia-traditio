import 'liturgical_day.dart';

/// One card in the directory: a label, the answer, and at most a line or two
/// explaining it. Deliberately small — the directory answers questions, it
/// doesn't lecture.
class DirectoryCard {
  final String label;
  final String value;
  final String? note;
  const DirectoryCard(this.label, this.value, [this.note]);
}

/// The day, explained — season, celebration, colour, week, year, cycle,
/// preface, observances and what else the day remembers.
class DirectoryEntry {
  final List<DirectoryCard> cards;
  const DirectoryEntry(this.cards);
}

/// Explains the current celebration, offline.
///
/// Content is a concise summary of what the Church's own books say — the
/// *Normas Universais sobre o Ano Litúrgico e o Calendário*, the *Instrução
/// Geral do Missal Romano* and the Code of Canon Law for the precept and
/// penitential days. Where the Missal offers a choice (which preface, which
/// optional memorial) the directory names the family rather than pretending to
/// know what a given church will use.
class LiturgicalDirectory {
  const LiturgicalDirectory();

  /// Labels are supplied by the caller so the sheet stays localisable.
  DirectoryEntry explain(LiturgicalDay day, DirectoryLabels l) {
    return DirectoryEntry([
      DirectoryCard(l.season, _seasonName(day.season, l), _seasonNote(day.season)),
      DirectoryCard(l.celebration, day.celebration, _rankNote(day.rank, l)),
      DirectoryCard(l.color, _colorName(day.color, l), _colorNote(day.color)),
      // "19ª semana do Tempo Comum" — the number alone doesn't say of what.
      if (day.week != null)
        DirectoryCard(l.week, '${l.weekOf(day.week!)} do ${_seasonName(day.season, l)}'),
      DirectoryCard(l.year, l.yearOf(day.sundayCycle),
          _cycleNote(day, l)),
      DirectoryCard(l.cycle, l.cycleOf(day.weekdayCycle),
          'Rege as leituras das férias; os domingos seguem o ano A/B/C.'),
      DirectoryCard(l.preface, _preface(day)),
      if (_observances(day).isNotEmpty)
        DirectoryCard(l.observances, _observances(day).join('\n')),
      if (day.optionalMemorials.isNotEmpty)
        DirectoryCard(l.ephemerides,
            day.optionalMemorials.map((m) => m.name).join('\n'),
            'Memórias facultativas: podem ser celebradas ou omitidas.'),
    ]);
  }

  // ── Season ────────────────────────────────────────────────────────────────
  String _seasonName(LiturgicalSeason s, DirectoryLabels l) => l.seasonName(s);

  String _seasonNote(LiturgicalSeason s) => switch (s) {
        LiturgicalSeason.advent =>
          'Quatro semanas de espera: preparam o Natal e despertam a expectativa da vinda gloriosa. Não é uma segunda Quaresma.',
        LiturgicalSeason.christmas =>
          'Do Natal ao Batismo do Senhor. Celebra a manifestação de Deus feito homem; os oito primeiros dias formam a Oitava.',
        LiturgicalSeason.lent =>
          'Quarenta dias de oração, jejum e esmola que preparam a Páscoa e renovam o batismo.',
        LiturgicalSeason.triduum =>
          'O centro do ano litúrgico: uma só celebração distribuída da Ceia do Senhor às Vésperas do Domingo de Páscoa.',
        LiturgicalSeason.easter =>
          'Cinquenta dias celebrados “como um só dia de festa”, da Páscoa ao Pentecostes.',
        LiturgicalSeason.ordinary =>
          'As trinta e quatro semanas em que a Igreja percorre o mistério de Cristo na sua totalidade.',
      };

  // ── Rank ──────────────────────────────────────────────────────────────────
  String _rankNote(LiturgicalRank r, DirectoryLabels l) => switch (r) {
        LiturgicalRank.solemnity =>
          '${l.rankName(r)} — o grau mais alto: com Glória e Credo, e transferida se um tempo forte a impedir.',
        LiturgicalRank.feast =>
          '${l.rankName(r)} — celebra-se com Glória, dentro do dia. As festas do Senhor precedem o domingo do Tempo Comum.',
        LiturgicalRank.memorial =>
          '${l.rankName(r)} — insere-se no dia sem o substituir; nos tempos fortes cede lugar à féria.',
        LiturgicalRank.optionalMemorial =>
          '${l.rankName(r)} — pode ser celebrada ou omitida.',
        LiturgicalRank.commemoration =>
          '${l.rankName(r)} — entra na oração do dia sem mudar o resto da liturgia.',
        LiturgicalRank.weekday =>
          '${l.rankName(r)} — dia sem celebração própria, em que a liturgia percorre a Escritura continuamente.',
      };

  // ── Colour ────────────────────────────────────────────────────────────────
  String _colorName(LiturgicalColor c, DirectoryLabels l) => l.colorName(c);

  String _colorNote(LiturgicalColor c) => switch (c) {
        LiturgicalColor.green => 'Esperança e crescimento — o Tempo Comum.',
        LiturgicalColor.white =>
          'Luz e alegria — Natal, Páscoa, festas do Senhor, de Nossa Senhora, dos anjos e dos santos não mártires.',
        LiturgicalColor.red =>
          'Fogo e sangue — Pentecostes, Ramos, Sexta-feira Santa, Apóstolos e mártires.',
        LiturgicalColor.purple => 'Preparação e conversão — Advento e Quaresma; também nas exéquias.',
        LiturgicalColor.rose =>
          'Permitido só dois dias no ano: Gaudete, no Advento, e Laetare, na Quaresma.',
      };

  String _cycleNote(LiturgicalDay day, DirectoryLabels l) =>
      'Rege as leituras dos domingos e das solenidades.';

  // ── Preface ───────────────────────────────────────────────────────────────
  /// Which family of prefaces the Missal appoints. The exact preface is a
  /// choice made in the celebration, so the directory names the family.
  String _preface(LiturgicalDay day) {
    final n = day.celebration;
    bool has(String s) => n.contains(s);
    if (has('Natal do Senhor') || has('Oitava do Natal')) {
      return 'Prefácio do Natal (I–III)';
    }
    if (has('Epifania')) return 'Prefácio da Epifania';
    if (has('Ascensão')) return 'Prefácio da Ascensão (I ou II)';
    if (has('Pentecostes')) return 'Prefácio do Pentecostes';
    if (has('Trindade')) return 'Prefácio da Santíssima Trindade';
    if (has('Corpo e Sangue')) return 'Prefácio da Santíssima Eucaristia (I ou II)';
    if (has('Sagrado Coração')) return 'Prefácio do Sagrado Coração';
    if (has('Rei do Universo')) return 'Prefácio de Cristo Rei';
    if (has('Ramos') || has('Semana Santa')) return 'Prefácio da Paixão do Senhor (I ou II)';
    if (has('Sexta-feira Santa')) return 'Sem prefácio — não há Missa neste dia';
    if (has('Cinzas')) return 'Prefácio da Quaresma (I–IV)';

    if (day.rank == LiturgicalRank.solemnity ||
        day.rank == LiturgicalRank.feast) {
      return 'Prefácio próprio da celebração';
    }
    return switch (day.season) {
      LiturgicalSeason.advent => 'Prefácio do Advento (I ou II)',
      LiturgicalSeason.christmas => 'Prefácio do Natal (I–III)',
      LiturgicalSeason.lent => 'Prefácio da Quaresma (I–IV)',
      LiturgicalSeason.triduum => 'Prefácio próprio do Tríduo',
      LiturgicalSeason.easter => 'Prefácio Pascal (I–V)',
      LiturgicalSeason.ordinary =>
        day.date.weekday == DateTime.sunday
            ? 'Prefácio dos Domingos do Tempo Comum (I–VIII)'
            : 'Prefácio Comum (I–VI)',
    };
  }

  // ── Observances ───────────────────────────────────────────────────────────
  List<String> _observances(LiturgicalDay day) {
    final o = day.observance;
    return [
      if (o.isHolyDayOfObligation && day.date.weekday == DateTime.sunday)
        'Dia de preceito.',
      if (o.isHolyDayOfObligation && day.date.weekday != DateTime.sunday)
        'Dia de preceito no direito universal — a conferência episcopal pode transferi-lo ou dispensá-lo.',
      if (o.isFastDay)
        'Jejum e abstinência. Jejum dos 18 aos 59 anos; abstinência a partir dos 14.',
      if (o.isAbstinenceDay && !o.isFastDay)
        'Abstinência de carne (sexta-feira), a partir dos 14 anos.',
      if (o.isInOctave) 'Dia dentro de uma oitava.',
    ];
  }
}

/// Localised labels the directory needs. Supplied by the presentation layer so
/// the domain stays free of Flutter and of any single language.
class DirectoryLabels {
  final String season;
  final String celebration;
  final String color;
  final String week;
  final String year;
  final String cycle;
  final String preface;
  final String observances;
  final String ephemerides;
  final String Function(LiturgicalSeason) seasonName;
  final String Function(LiturgicalColor) colorName;
  final String Function(LiturgicalRank) rankName;
  final String Function(int) weekOf;
  final String Function(String) yearOf;
  final String Function(String) cycleOf;

  const DirectoryLabels({
    required this.season,
    required this.celebration,
    required this.color,
    required this.week,
    required this.year,
    required this.cycle,
    required this.preface,
    required this.observances,
    required this.ephemerides,
    required this.seasonName,
    required this.colorName,
    required this.rankName,
    required this.weekOf,
    required this.yearOf,
    required this.cycleOf,
  });
}
