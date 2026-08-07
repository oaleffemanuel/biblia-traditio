import 'general_roman_calendar.dart';
import 'liturgical_day.dart';

/// Per-sanctoral-list caches. The Liturgy screen resolves up to 46 days in a
/// single build (the date strip, the celebration card, the month grid), so the
/// two things that would otherwise be recomputed for every one of them — the
/// MM-DD index over ~200 entries, and the year's transfer map — are memoised.
/// Both are pure functions of the sanctoral list and the year.
final _sanctoralIndexCache =
    Expando<Map<int, List<SanctoralEntry>>>('sanctoralIndex');
final _transferCache =
    Expando<Map<int, Map<String, SanctoralEntry>>>('sanctoralTransfers');

/// A candidate celebration for a date, with its place in the Table of
/// Liturgical Days. Lower [precedence] wins.
class _Candidate {
  final String name;
  final LiturgicalRank rank;
  final LiturgicalColor color;
  final int precedence;
  const _Candidate(this.name, this.rank, this.color, this.precedence);
}

/// Precedence classes from the Table of Liturgical Days (Universal Norms on the
/// Liturgical Year, nos. 59). Only the numbers the app can actually distinguish
/// are used; regional propers slot into the gaps (4, 8, 11) when a regional
/// calendar is supplied.
class _P {
  static const triduum = 1;
  static const principal = 2; // Christmas, Epiphany, Ascension, Pentecost,
  // Sundays of Advent/Lent/Easter, Ash Wednesday,
  // Holy Week weekdays, Easter Octave days
  static const solemnity = 3;
  static const lordFeast = 5;
  static const sundayOrdinary = 6; // and Sundays of Christmas
  static const saintFeast = 7;
  static const privilegedWeekday = 9; // Advent 17–24, Christmas Octave, Lent
  static const memorial = 10;
  static const weekday = 13;
  // The Table places optional memorials at 12, above weekdays — but that is
  // about what *may* be celebrated, not what the day *is*. Left to itself the
  // day is the feria, so the app ranks an optional memorial below it and
  // offers it separately.
  static const optionalMemorial = 14;
}

/// Pure, offline computation of the **General Roman Calendar** (Ordinary Form).
///
/// From the date alone it derives the season and its week, the liturgical
/// colour, the Sunday (A/B/C) and weekday (I/II) cycles, the celebration and
/// its rank — resolving collisions through the Table of Liturgical Days — the
/// optional memorials still available, and the day's penitential/precept
/// observances. No data file, no network.
///
/// The sanctoral cycle is injected ([sanctoral]) so a regional calendar can be
/// layered later without touching the engine; the default is
/// [kGeneralRomanCalendar].
class LiturgicalCalendar {
  final List<SanctoralEntry> sanctoral;
  const LiturgicalCalendar({this.sanctoral = kGeneralRomanCalendar});

  LiturgicalDay resolve(DateTime input) {
    final date = _d(input);
    final y = date.year;

    // The liturgical year that owns this date starts at one of two Advents.
    final adventThisYear = _firstSundayOfAdvent(y);
    final startYear = !date.isBefore(adventThisYear) ? y : y - 1;
    final firstAdvent = _firstSundayOfAdvent(startYear);

    // Easter and everything hinged on it, for the civil year of [date].
    final easter = _easter(y);
    final ashWed = _add(easter, -46);
    final palmSun = _add(easter, -7);
    final holyThu = _add(easter, -3);
    final goodFri = _add(easter, -2);
    final holySat = _add(easter, -1);
    final easterOctaveEnd = _add(easter, 7); // Divine Mercy Sunday
    final ascension = _add(easter, 39);
    final pentecost = _add(easter, 49);
    final trinity = _add(easter, 56);
    final corpusChristi = _add(easter, 60);
    final sacredHeart = _add(easter, 68);
    final immaculateHeart = _add(easter, 69);

    // Christmas season spans a year boundary, so both ends are computed from
    // the liturgical year's own start.
    final christmas = DateTime(startYear, 12, 25);
    final baptism = _baptismOfTheLord(startYear + 1);
    final holyFamily = _holyFamily(startYear);
    final christKing = _add(_firstSundayOfAdvent(startYear + 1), -7);

    final season = _season(
      date: date,
      firstAdvent: firstAdvent,
      christmas: christmas,
      baptism: baptism,
      ashWed: ashWed,
      holyThu: holyThu,
      easter: easter,
      pentecost: pentecost,
    );

    // Year A when the Advent-start year + 1 ≡ 1 (mod 3): Advent 2022 → A.
    final sundayCycle = switch ((startYear + 1) % 3) {
      1 => 'A',
      2 => 'B',
      _ => 'C',
    };
    // Year I in odd civil years, II in even ones — counted on the civil year in
    // which most of the liturgical year falls.
    final weekdayCycle = startYear.isEven ? 'I' : 'II';

    final isSunday = date.weekday == DateTime.sunday;
    final candidates = <_Candidate>[];

    // ── Temporal cycle ──────────────────────────────────────────────────────
    void temporal(String n, LiturgicalRank r, LiturgicalColor c, int p) =>
        candidates.add(_Candidate(n, r, c, p));

    if (date == holyThu) {
      temporal('Quinta-feira Santa', LiturgicalRank.solemnity,
          LiturgicalColor.white, _P.triduum);
    } else if (date == goodFri) {
      temporal('Sexta-feira Santa da Paixão do Senhor',
          LiturgicalRank.solemnity, LiturgicalColor.red, _P.triduum);
    } else if (date == holySat) {
      temporal('Sábado Santo', LiturgicalRank.solemnity, LiturgicalColor.white,
          _P.triduum);
    } else if (date == easter) {
      temporal('Domingo de Páscoa da Ressurreição do Senhor',
          LiturgicalRank.solemnity, LiturgicalColor.white, _P.triduum);
    } else if (date.isAfter(easter) && date.isBefore(easterOctaveEnd)) {
      temporal('${_weekdayNamePt(date)} da Oitava da Páscoa',
          LiturgicalRank.solemnity, LiturgicalColor.white, _P.principal);
    } else if (date == easterOctaveEnd) {
      temporal('2º Domingo da Páscoa (da Divina Misericórdia)',
          LiturgicalRank.solemnity, LiturgicalColor.white, _P.principal);
    } else if (date == palmSun) {
      temporal('Domingo de Ramos na Paixão do Senhor',
          LiturgicalRank.solemnity, LiturgicalColor.red, _P.principal);
    } else if (date.isAfter(palmSun) && date.isBefore(holyThu)) {
      temporal('${_weekdayNamePt(date)} da Semana Santa',
          LiturgicalRank.weekday, LiturgicalColor.purple, _P.principal);
    } else if (date == ashWed) {
      temporal('Quarta-feira de Cinzas', LiturgicalRank.weekday,
          LiturgicalColor.purple, _P.principal);
    } else if (date == pentecost) {
      temporal('Domingo de Pentecostes', LiturgicalRank.solemnity,
          LiturgicalColor.red, _P.principal);
    } else if (date == ascension) {
      temporal('Ascensão do Senhor', LiturgicalRank.solemnity,
          LiturgicalColor.white, _P.principal);
    } else if (date == trinity) {
      temporal('Santíssima Trindade', LiturgicalRank.solemnity,
          LiturgicalColor.white, _P.solemnity);
    } else if (date == corpusChristi) {
      temporal('Santíssimo Corpo e Sangue de Cristo', LiturgicalRank.solemnity,
          LiturgicalColor.white, _P.solemnity);
    } else if (date == sacredHeart) {
      temporal('Sagrado Coração de Jesus', LiturgicalRank.solemnity,
          LiturgicalColor.white, _P.solemnity);
    } else if (date == christKing) {
      temporal('Nosso Senhor Jesus Cristo, Rei do Universo',
          LiturgicalRank.solemnity, LiturgicalColor.white, _P.solemnity);
    } else if (date == holyFamily) {
      temporal('Sagrada Família de Jesus, Maria e José', LiturgicalRank.feast,
          LiturgicalColor.white, _P.lordFeast);
    } else if (date == baptism) {
      temporal('Batismo do Senhor', LiturgicalRank.feast,
          LiturgicalColor.white, _P.lordFeast);
    } else if (date == immaculateHeart) {
      temporal('Imaculado Coração de Maria', LiturgicalRank.memorial,
          LiturgicalColor.white, _P.memorial);
    } else {
      temporal(
        _ferialName(season, date, easter, ashWed, firstAdvent, isSunday),
        isSunday ? LiturgicalRank.weekday : LiturgicalRank.weekday,
        _seasonColour(season, date, ashWed, firstAdvent),
        _ferialPrecedence(season, date, isSunday, firstAdvent, christmas),
      );
    }

    // ── Sanctoral cycle (fixed dates + anything transferred onto this day) ──
    for (final e in _sanctoralFor(date, easter, firstAdvent)) {
      candidates.add(_Candidate(
        e.name,
        e.rank,
        e.color,
        switch (e.rank) {
          LiturgicalRank.solemnity => _P.solemnity,
          LiturgicalRank.feast => e.ofTheLord ? _P.lordFeast : _P.saintFeast,
          LiturgicalRank.memorial => _P.memorial,
          LiturgicalRank.commemoration => _P.solemnity, // All Souls
          _ => _P.optionalMemorial,
        },
      ));
    }

    // ── Resolve ─────────────────────────────────────────────────────────────
    candidates.sort((a, b) => a.precedence.compareTo(b.precedence));
    final winner = candidates.first;

    // Everything that lost but may still be observed. A memorial impeded by a
    // privileged weekday (Lent, Advent 17–24, Christmas Octave) becomes
    // optional rather than disappearing.
    final optional = <OptionalMemorial>[
      for (final c in candidates.skip(1))
        if (c.rank == LiturgicalRank.optionalMemorial ||
            c.rank == LiturgicalRank.memorial)
          OptionalMemorial(c.name, c.color),
    ];

    final week = _week(season, date, easter, ashWed, firstAdvent, baptism,
        pentecost, christKing);

    return LiturgicalDay(
      date: date,
      season: season,
      color: winner.color,
      celebration: winner.name,
      rank: winner.rank,
      sundayCycle: sundayCycle,
      weekdayCycle: weekdayCycle,
      week: week,
      optionalMemorials: optional,
      observance: _observance(
        date: date,
        winner: winner,
        ashWed: ashWed,
        goodFri: goodFri,
        easter: easter,
        easterOctaveEnd: easterOctaveEnd,
        christmas: christmas,
        holyThu: holyThu,
      ),
    );
  }

  // ── Season ────────────────────────────────────────────────────────────────
  LiturgicalSeason _season({
    required DateTime date,
    required DateTime firstAdvent,
    required DateTime christmas,
    required DateTime baptism,
    required DateTime ashWed,
    required DateTime holyThu,
    required DateTime easter,
    required DateTime pentecost,
  }) {
    if (!date.isBefore(firstAdvent) && date.isBefore(christmas)) {
      return LiturgicalSeason.advent;
    }
    if (!date.isBefore(christmas) && !date.isAfter(baptism)) {
      return LiturgicalSeason.christmas;
    }
    if (!date.isBefore(holyThu) && date.isBefore(easter)) {
      return LiturgicalSeason.triduum;
    }
    if (!date.isBefore(ashWed) && date.isBefore(holyThu)) {
      return LiturgicalSeason.lent;
    }
    if (!date.isBefore(easter) && !date.isAfter(pentecost)) {
      return LiturgicalSeason.easter;
    }
    return LiturgicalSeason.ordinary;
  }

  // ── Colour ────────────────────────────────────────────────────────────────
  LiturgicalColor _seasonColour(LiturgicalSeason s, DateTime date,
      DateTime ashWed, DateTime firstAdvent) {
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
      case LiturgicalSeason.easter:
      case LiturgicalSeason.christmas:
        return LiturgicalColor.white;
      case LiturgicalSeason.ordinary:
        return LiturgicalColor.green;
    }
  }

  // ── Ferial naming & precedence ────────────────────────────────────────────
  String _ferialName(LiturgicalSeason s, DateTime date, DateTime easter,
      DateTime ashWed, DateTime firstAdvent, bool isSunday) {
    switch (s) {
      case LiturgicalSeason.advent:
        final w = (_diffDays(firstAdvent, date) ~/ 7) + 1;
        return isSunday
            ? '$wº Domingo do Advento'
            : '${_weekdayNamePt(date)} da $wª Semana do Advento';
      case LiturgicalSeason.lent:
        final firstLentSun = _firstSundayAfter(ashWed);
        if (date.isBefore(firstLentSun)) {
          return '${_weekdayNamePt(date)} depois das Cinzas';
        }
        final w = (_diffDays(firstLentSun, date) ~/ 7) + 1;
        return isSunday
            ? '$wº Domingo da Quaresma'
            : '${_weekdayNamePt(date)} da $wª Semana da Quaresma';
      case LiturgicalSeason.easter:
        final w = (_diffDays(easter, date) ~/ 7) + 1;
        return isSunday
            ? '$wº Domingo da Páscoa'
            : '${_weekdayNamePt(date)} da $wª Semana da Páscoa';
      case LiturgicalSeason.christmas:
        return _christmasFerialName(date);
      case LiturgicalSeason.triduum:
        return 'Tríduo Pascal';
      case LiturgicalSeason.ordinary:
        return isSunday ? 'Domingo do Tempo Comum' : 'Féria do Tempo Comum';
    }
  }

  String _christmasFerialName(DateTime date) {
    final christmas = DateTime(date.month == 1 ? date.year - 1 : date.year, 12, 25);
    final n = _diffDays(christmas, date) + 1; // 1 = Christmas Day
    if (n >= 2 && n <= 8) return '$nº dia da Oitava do Natal';
    if (date.month == 1 && date.day >= 2 && date.day <= 5) {
      return '${_weekdayNamePt(date)} antes da Epifania';
    }
    return '${_weekdayNamePt(date)} do Tempo do Natal';
  }

  int _ferialPrecedence(LiturgicalSeason s, DateTime date, bool isSunday,
      DateTime firstAdvent, DateTime christmas) {
    if (isSunday) {
      return switch (s) {
        LiturgicalSeason.advent ||
        LiturgicalSeason.lent ||
        LiturgicalSeason.easter =>
          _P.principal,
        _ => _P.sundayOrdinary,
      };
    }
    switch (s) {
      case LiturgicalSeason.advent:
        // The ferias from 17 December are privileged.
        return date.month == 12 && date.day >= 17
            ? _P.privilegedWeekday
            : _P.weekday;
      case LiturgicalSeason.christmas:
        final inOctave = !date.isBefore(christmas) &&
            _diffDays(christmas, date) <= 7;
        return inOctave ? _P.privilegedWeekday : _P.weekday;
      case LiturgicalSeason.lent:
        return _P.privilegedWeekday;
      default:
        return _P.weekday;
    }
  }

  // ── Week of the season ────────────────────────────────────────────────────
  int? _week(
      LiturgicalSeason s,
      DateTime date,
      DateTime easter,
      DateTime ashWed,
      DateTime firstAdvent,
      DateTime baptism,
      DateTime pentecost,
      DateTime christKing) {
    switch (s) {
      case LiturgicalSeason.advent:
        return (_diffDays(firstAdvent, date) ~/ 7) + 1;
      case LiturgicalSeason.lent:
        final firstLentSun = _firstSundayAfter(ashWed);
        if (date.isBefore(firstLentSun)) return null; // days after Ash Wednesday
        return (_diffDays(firstLentSun, date) ~/ 7) + 1;
      case LiturgicalSeason.easter:
        return (_diffDays(easter, date) ~/ 7) + 1;
      case LiturgicalSeason.ordinary:
        // Ordinary Time is counted in two blocks that together run 1–34: the
        // first from the Baptism of the Lord to Ash Wednesday, the second
        // backwards from Christ the King (the 34th week).
        final sunday = _sundayOnOrBefore(date);
        if (date.isBefore(ashWed)) {
          return (_diffDays(_sundayOnOrBefore(baptism), sunday) ~/ 7) + 1;
        }
        return 34 - (_diffDays(sunday, christKing) ~/ 7);
      case LiturgicalSeason.christmas:
      case LiturgicalSeason.triduum:
        return null; // counted by day, not by week
    }
  }

  // ── Sanctoral, including transfers ────────────────────────────────────────
  /// Fixed-date celebrations for [date], plus any solemnity whose own date was
  /// impeded (a Sunday of Lent, Holy Week, the Easter Octave) and which the
  /// General Norms move to the next free day.
  ///
  /// Caveat worth knowing: the Holy See occasionally *anticipates* a transfer
  /// instead of postponing it (St Joseph 2008 was moved to 15 March, before
  /// Holy Week). This engine applies the general rule — postponement — so such
  /// a year will differ from the decree by a few days.
  List<SanctoralEntry> _sanctoralFor(
      DateTime date, DateTime easter, DateTime firstAdvent) {
    final out = <SanctoralEntry>[];
    if (!_isImpeded(date, easter)) {
      out.addAll(_index()[date.month * 100 + date.day] ?? const []);
    }
    final moved = _transfers(date.year, easter)[_key(date)];
    if (moved != null) out.add(moved);
    return out;
  }

  /// The sanctoral list bucketed by MM*100+DD, built once per list.
  Map<int, List<SanctoralEntry>> _index() {
    final cached = _sanctoralIndexCache[sanctoral];
    if (cached != null) return cached;
    final built = <int, List<SanctoralEntry>>{};
    for (final e in sanctoral) {
      built.putIfAbsent(e.month * 100 + e.day, () => []).add(e);
    }
    _sanctoralIndexCache[sanctoral] = built;
    return built;
  }

  /// Solemnities displaced from their own date in [year], keyed by the day they
  /// land on. Computed in calendar order and skipping days already claimed, so
  /// two solemnities impeded by the same Holy Week (St Joseph and the
  /// Annunciation) don't collide on one day.
  Map<String, SanctoralEntry> _transfers(int year, DateTime easter) {
    final byYear = _transferCache[sanctoral] ??= {};
    final cached = byYear[year];
    if (cached != null) return cached;

    final impeded = <(DateTime, SanctoralEntry)>[];
    for (final e in sanctoral) {
      if (e.rank != LiturgicalRank.solemnity) continue;
      final origin = DateTime(year, e.month, e.day);
      if (_isImpeded(origin, easter)) impeded.add((origin, e));
    }
    impeded.sort((a, b) => a.$1.compareTo(b.$1));

    final taken = <String>{};
    final out = <String, SanctoralEntry>{};
    for (final (origin, entry) in impeded) {
      var d = _add(origin, 1);
      for (var i = 0; i < 30; i++) {
        if (!_isImpeded(d, easter) && !taken.contains(_key(d))) break;
        d = _add(d, 1);
      }
      taken.add(_key(d));
      out[_key(d)] = entry;
    }
    byYear[year] = out;
    return out;
  }

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Days that admit no sanctoral celebration at all: the Triduum, Holy Week,
  /// the Octave of Easter, and the Sundays of Advent, Lent and Easter.
  bool _isImpeded(DateTime d, DateTime easter) {
    final palmSun = _add(easter, -7);
    final octaveEnd = _add(easter, 7);
    if (!d.isBefore(palmSun) && !d.isAfter(octaveEnd)) return true;
    if (d.weekday != DateTime.sunday) return false;
    final ashWed = _add(easter, -46);
    final pentecost = _add(easter, 49);
    if (!d.isBefore(ashWed) && d.isBefore(easter)) return true; // Sundays of Lent
    if (!d.isBefore(easter) && !d.isAfter(pentecost)) return true; // of Easter
    final adventStart = _firstSundayOfAdvent(d.year);
    final christmas = DateTime(d.year, 12, 25);
    return !d.isBefore(adventStart) && d.isBefore(christmas);
  }

  // ── Observances ───────────────────────────────────────────────────────────
  LiturgicalObservance _observance({
    required DateTime date,
    required _Candidate winner,
    required DateTime ashWed,
    required DateTime goodFri,
    required DateTime easter,
    required DateTime easterOctaveEnd,
    required DateTime christmas,
    required DateTime holyThu,
  }) {
    final isFriday = date.weekday == DateTime.friday;
    final fast = date == ashWed || date == goodFri;
    final isSolemnity = winner.rank == LiturgicalRank.solemnity;
    // Canon 1251: abstinence on every Friday unless a solemnity falls on it.
    final abstinence = fast || (isFriday && !isSolemnity);

    final holyDay = date.weekday == DateTime.sunday ||
        sanctoral.any((e) =>
            e.holyDayOfObligation && e.month == date.month && e.day == date.day);

    final inEasterOctave =
        !date.isBefore(easter) && !date.isAfter(easterOctaveEnd);
    final inChristmasOctave =
        !date.isBefore(christmas) && _diffDays(christmas, date) <= 7;

    return LiturgicalObservance(
      isFastDay: fast,
      isAbstinenceDay: abstinence,
      isHolyDayOfObligation: holyDay,
      isInOctave: inEasterOctave || inChristmasOctave,
    );
  }

  // ── Movable feasts of the Christmas season ────────────────────────────────
  /// Sunday within the Octave of Christmas; when Christmas itself is a Sunday
  /// (so there is no such Sunday) the feast is kept on 30 December.
  static DateTime _holyFamily(int startYear) {
    final christmas = DateTime(startYear, 12, 25);
    if (christmas.weekday == DateTime.sunday) {
      return DateTime(startYear, 12, 30);
    }
    return _firstSundayAfter(christmas);
  }

  /// The Sunday after 6 January. When Epiphany is celebrated on 7 or 8 January
  /// (a regional transfer the general calendar does not make) the Baptism moves
  /// to the following Monday — handled by a regional calendar, not here.
  static DateTime _baptismOfTheLord(int year) =>
      _firstSundayAfter(DateTime(year, 1, 6));

  // ── Date math ─────────────────────────────────────────────────────────────
  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  /// Calendar-day arithmetic. Uses the date constructor rather than
  /// `Duration(days:)` so a daylight-saving transition can never shift a day
  /// off midnight (which would break every `==` comparison in this file).
  static DateTime _add(DateTime x, int days) =>
      DateTime(x.year, x.month, x.day + days);

  static int _diffDays(DateTime a, DateTime b) =>
      _d(b).difference(_d(a)).inDays;

  static DateTime _sundayOnOrBefore(DateTime d) =>
      _add(d, -(d.weekday % 7)); // Sunday(7) → 0

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

  /// First Sunday of Advent: the Sunday on/after Nov 27 (range Nov 27–Dec 3).
  static DateTime _firstSundayOfAdvent(int year) =>
      _firstSundayOnOrAfter(DateTime(year, 11, 27));

  static DateTime _firstSundayOnOrAfter(DateTime d) =>
      _add(d, (7 - d.weekday % 7) % 7);

  static DateTime _firstSundayAfter(DateTime d) {
    final add = 7 - (d.weekday % 7);
    return _add(d, add == 0 ? 7 : add);
  }

  /// Portuguese weekday, as the Roman calendar names ferias.
  static String _weekdayNamePt(DateTime d) => switch (d.weekday) {
        DateTime.monday => 'Segunda-feira',
        DateTime.tuesday => 'Terça-feira',
        DateTime.wednesday => 'Quarta-feira',
        DateTime.thursday => 'Quinta-feira',
        DateTime.friday => 'Sexta-feira',
        DateTime.saturday => 'Sábado',
        _ => 'Domingo',
      };
}
