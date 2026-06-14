import 'liturgical_day.dart';

/// Pure, offline computation of the General Roman Calendar (Ordinary Form).
///
/// Computes season, liturgical colour, Sunday cycle (A/B/C), weekday cycle
/// (I/II), and the names of the movable + principal fixed solemnities — all
/// from the date alone, no data file. The full sanctoral calendar (daily
/// memorials) and the lectionary readings are separate datasets (see
/// LectionaryRepository); this engine covers the temporal cycle.
class LiturgicalCalendar {
  const LiturgicalCalendar();

  LiturgicalDay resolve(DateTime input) {
    final date = _d(input);
    final y = date.year;
    final easter = _easter(y);
    final ashWed = _add(easter, -46);
    final palmSun = _add(easter, -7);
    final holyThu = _add(easter, -3);
    final goodFri = _add(easter, -2);
    final pentecost = _add(easter, 49);
    final ascension = _add(easter, 39);
    final trinity = _add(easter, 56);
    final corpusChristi = _add(easter, 60); // Thursday
    final sacredHeart = _add(easter, 68); // Friday
    final christmas = DateTime(y, 12, 25);
    final epiphany = DateTime(y, 1, 6);
    final baptism = _firstSundayAfter(epiphany);
    final firstAdvent = _firstSundayOfAdvent(y);

    // ── Season ──
    final LiturgicalSeason season;
    if (!date.isBefore(firstAdvent) && date.isBefore(christmas)) {
      season = LiturgicalSeason.advent;
    } else if (!date.isBefore(christmas) || !date.isAfter(baptism)) {
      season = LiturgicalSeason.christmas;
    } else if (!date.isBefore(holyThu) && date.isBefore(easter)) {
      season = LiturgicalSeason.triduum;
    } else if (!date.isBefore(ashWed) && date.isBefore(holyThu)) {
      season = LiturgicalSeason.lent;
    } else if (!date.isBefore(easter) && !date.isAfter(pentecost)) {
      season = LiturgicalSeason.easter;
    } else {
      season = LiturgicalSeason.ordinary;
    }

    // ── Cycles ──
    final startYear = !date.isBefore(firstAdvent) ? y : y - 1;
    // Year A when the Advent-start year + 1 ≡ 1 (mod 3): Advent 2022 → 2022-23 = A.
    final sundayCycle = switch ((startYear + 1) % 3) {
      1 => 'A',
      2 => 'B',
      _ => 'C',
    };
    final weekdayCycle = startYear.isEven ? 'I' : 'II';

    // ── Movable & fixed solemnities (name + colour overrides) ──
    String? name;
    LiturgicalColor? color;
    var rank = LiturgicalRank.weekday;

    void mark(String n, LiturgicalColor c,
        [LiturgicalRank r = LiturgicalRank.solemnity]) {
      name = n;
      color = c;
      rank = r;
    }

    if (date == easter) {
      mark('Domingo de Páscoa', LiturgicalColor.white);
    } else if (date == palmSun) {
      mark('Domingo de Ramos', LiturgicalColor.red);
    } else if (date == holyThu) {
      mark('Quinta-feira Santa', LiturgicalColor.white);
    } else if (date == goodFri) {
      mark('Sexta-feira Santa', LiturgicalColor.red);
    } else if (date == _add(easter, -1)) {
      mark('Sábado Santo', LiturgicalColor.white);
    } else if (date == pentecost) {
      mark('Pentecostes', LiturgicalColor.red);
    } else if (date == ascension) {
      mark('Ascensão do Senhor', LiturgicalColor.white);
    } else if (date == trinity) {
      mark('Santíssima Trindade', LiturgicalColor.white);
    } else if (date == corpusChristi) {
      mark('Corpus Christi', LiturgicalColor.white);
    } else if (date == sacredHeart) {
      mark('Sagrado Coração de Jesus', LiturgicalColor.white);
    } else if (date == _add(_firstSundayOfAdvent(y), -7) &&
        season == LiturgicalSeason.ordinary) {
      // Christ the King — the Sunday before the next 1st Sunday of Advent.
      mark('Cristo Rei', LiturgicalColor.white);
    }

    // Principal fixed solemnities (only if no movable one claimed the day).
    name ??= _fixedSolemnity(date, (n, c) => mark(n, c));

    // ── Base colour by season (when no solemnity set it) ──
    color ??= _seasonColour(season, date, easter, ashWed, firstAdvent);

    // ── Celebration name fallback ──
    final celebration =
        name ?? _temporalName(season, date, easter, ashWed, firstAdvent, baptism);

    return LiturgicalDay(
      date: date,
      season: season,
      color: color!,
      celebration: celebration,
      rank: rank,
      sundayCycle: sundayCycle,
      weekdayCycle: weekdayCycle,
    );
  }

  // ── Colour helpers ──
  LiturgicalColor _seasonColour(LiturgicalSeason s, DateTime date,
      DateTime easter, DateTime ashWed, DateTime firstAdvent) {
    switch (s) {
      case LiturgicalSeason.advent:
        // Gaudete — 3rd Sunday of Advent.
        if (date == _add(firstAdvent, 14)) return LiturgicalColor.rose;
        return LiturgicalColor.purple;
      case LiturgicalSeason.lent:
        // Laetare — 4th Sunday of Lent.
        final firstLentSun = _firstSundayAfter(ashWed);
        if (date == _add(firstLentSun, 21)) return LiturgicalColor.rose;
        return LiturgicalColor.purple;
      case LiturgicalSeason.triduum:
        return LiturgicalColor.white;
      case LiturgicalSeason.easter:
      case LiturgicalSeason.christmas:
        return LiturgicalColor.white;
      case LiturgicalSeason.ordinary:
        return LiturgicalColor.green;
    }
  }

  // ── Name helpers ──
  String _temporalName(LiturgicalSeason s, DateTime date, DateTime easter,
      DateTime ashWed, DateTime firstAdvent, DateTime baptism) {
    final isSunday = date.weekday == DateTime.sunday;
    switch (s) {
      case LiturgicalSeason.advent:
        final w = (_diffDays(firstAdvent, date) ~/ 7) + 1;
        return isSunday ? '$wº Domingo do Advento' : 'Féria do Advento';
      case LiturgicalSeason.lent:
        final firstLentSun = _firstSundayAfter(ashWed);
        if (date.isBefore(firstLentSun)) return 'Após as Cinzas';
        final w = (_diffDays(firstLentSun, date) ~/ 7) + 1;
        return isSunday ? '$wº Domingo da Quaresma' : 'Féria da Quaresma';
      case LiturgicalSeason.easter:
        final w = (_diffDays(easter, date) ~/ 7) + 1;
        return isSunday ? '$wº Domingo da Páscoa' : 'Féria do Tempo Pascal';
      case LiturgicalSeason.christmas:
        return 'Tempo do Natal';
      case LiturgicalSeason.triduum:
        return 'Tríduo Pascal';
      case LiturgicalSeason.ordinary:
        return isSunday ? 'Domingo do Tempo Comum' : 'Féria do Tempo Comum';
    }
  }

  /// Principal fixed-date solemnities of the General Roman Calendar.
  String? _fixedSolemnity(DateTime d, void Function(String, LiturgicalColor) set) {
    final key = (d.month, d.day);
    final table = <(int, int), (String, LiturgicalColor)>{
      (1, 1): ('Santa Maria, Mãe de Deus', LiturgicalColor.white),
      (1, 6): ('Epifania do Senhor', LiturgicalColor.white),
      (3, 19): ('São José', LiturgicalColor.white),
      (3, 25): ('Anunciação do Senhor', LiturgicalColor.white),
      (6, 24): ('Natividade de São João Batista', LiturgicalColor.white),
      (6, 29): ('São Pedro e São Paulo', LiturgicalColor.red),
      (8, 15): ('Assunção de Nossa Senhora', LiturgicalColor.white),
      (11, 1): ('Todos os Santos', LiturgicalColor.white),
      (11, 2): ('Fiéis Defuntos', LiturgicalColor.purple),
      (12, 8): ('Imaculada Conceição', LiturgicalColor.white),
      (12, 25): ('Natal do Senhor', LiturgicalColor.white),
    };
    final hit = table[key];
    if (hit == null) return null;
    set(hit.$1, hit.$2);
    return hit.$1;
  }

  // ── Date math ──
  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  static DateTime _add(DateTime x, int days) => _d(x).add(Duration(days: days));
  static int _diffDays(DateTime a, DateTime b) =>
      _d(b).difference(_d(a)).inDays;

  /// Western (Gregorian) Easter — Anonymous Gregorian algorithm.
  static DateTime _easter(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final dd = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - dd - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// First Sunday of Advent: the Sunday on/after Nov 27 (range Nov27–Dec3).
  static DateTime _firstSundayOfAdvent(int year) {
    final nov27 = DateTime(year, 11, 27);
    return _firstSundayOnOrAfter(nov27);
  }

  static DateTime _firstSundayOnOrAfter(DateTime d) {
    final add = (7 - d.weekday % 7) % 7; // Sun(7)->0
    return _add(d, add);
  }

  static DateTime _firstSundayAfter(DateTime d) {
    final add = 7 - (d.weekday % 7); // strictly after; Sun(7)->7
    return _add(d, add == 0 ? 7 : add);
  }
}
