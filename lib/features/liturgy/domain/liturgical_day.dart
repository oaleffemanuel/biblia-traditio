import '../../../core/theme/tokens.dart';
import 'package:flutter/material.dart';

enum LiturgicalSeason { advent, christmas, ordinary, lent, triduum, easter }

enum LiturgicalColor { green, red, white, purple, rose }

extension LiturgicalColorX on LiturgicalColor {
  Color get color => switch (this) {
        LiturgicalColor.green => LiturgicalPalette.green,
        LiturgicalColor.red => LiturgicalPalette.red,
        LiturgicalColor.white => LiturgicalPalette.white,
        LiturgicalColor.purple => LiturgicalPalette.purple,
        LiturgicalColor.rose => LiturgicalPalette.rose,
      };
  /// Dot fill that stays visible on both themes. Liturgical white (#EDE9E3) is
  /// nearly invisible on the light ivory canvas, so on light themes the white
  /// (solemnity) dot renders as a warm gold; every other colour reads fine on
  /// both backgrounds, and the dark theme is unchanged.
  Color dotColor({required bool light}) =>
      (this == LiturgicalColor.white && light)
          ? const Color(0xFFC9A227)
          : color;

  /// Stable slug for localisation (the human label lives in the ARB).
  String get key => name;
}

extension LiturgicalSeasonX on LiturgicalSeason {
  String get key => name;
}

/// Rank of the celebration, highest first. Mirrors the Table of Liturgical Days
/// closely enough for a calendar: what the day *is*, not its precedence number
/// (that lives in [LiturgicalCalendar]).
enum LiturgicalRank {
  solemnity,
  feast,
  memorial,
  optionalMemorial,
  commemoration,
  weekday,
}

extension LiturgicalRankX on LiturgicalRank {
  String get key => name;

  /// Whether the rank names a celebration rather than an ordinary weekday.
  bool get isCelebration =>
      this != LiturgicalRank.weekday && this != LiturgicalRank.optionalMemorial;
}

/// Penitential and precept observances attached to a day. Universal law only —
/// an episcopal conference may add to or commute these, which is why the app
/// labels them as the general norm rather than as local obligation.
@immutable
class LiturgicalObservance {
  /// Ash Wednesday and Good Friday: fast **and** abstinence.
  final bool isFastDay;

  /// Fridays of Lent (and, in universal law, Fridays through the year unless
  /// the conference substitutes another penance).
  final bool isAbstinenceDay;

  /// Holy day of obligation in universal law (canon 1246 §1). Conferences may
  /// transfer or suppress some of these.
  final bool isHolyDayOfObligation;

  /// Within the Octave of Easter or of the Nativity.
  final bool isInOctave;

  const LiturgicalObservance({
    this.isFastDay = false,
    this.isAbstinenceDay = false,
    this.isHolyDayOfObligation = false,
    this.isInOctave = false,
  });

  bool get isEmpty =>
      !isFastDay && !isAbstinenceDay && !isHolyDayOfObligation && !isInOctave;
}

/// An optional memorial that yields to the day's celebration but may still be
/// observed. Surfaced so the directory can say "hoje também se pode celebrar…".
@immutable
class OptionalMemorial {
  final String name;
  final LiturgicalColor color;
  const OptionalMemorial(this.name, this.color);
}

@immutable
class LiturgicalDay {
  final DateTime date;
  final LiturgicalSeason season;
  final LiturgicalColor color;
  final String celebration; // best-effort title
  final LiturgicalRank rank;
  final String sundayCycle; // 'A' | 'B' | 'C'
  final String weekdayCycle; // 'I' | 'II'

  /// Week of the season (1-based): Advent 1–4, Lent 1–6, Easter 1–8, Ordinary
  /// Time 1–34. Null in the Christmas season and the Triduum, which are counted
  /// by day rather than by week.
  final int? week;

  /// Optional memorials available on this day, in calendar order.
  final List<OptionalMemorial> optionalMemorials;

  final LiturgicalObservance observance;

  const LiturgicalDay({
    required this.date,
    required this.season,
    required this.color,
    required this.celebration,
    required this.rank,
    required this.sundayCycle,
    required this.weekdayCycle,
    this.week,
    this.optionalMemorials = const [],
    this.observance = const LiturgicalObservance(),
  });

  /// The lectionary cycle that actually governs this day's readings: Sundays
  /// and solemnities follow A/B/C, weekdays follow I/II.
  String get activeCycle =>
      date.weekday == DateTime.sunday || rank == LiturgicalRank.solemnity
          ? sundayCycle
          : weekdayCycle;
}
