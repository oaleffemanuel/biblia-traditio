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
  String get label => switch (this) {
        LiturgicalColor.green => 'Verde',
        LiturgicalColor.red => 'Vermelho',
        LiturgicalColor.white => 'Branco',
        LiturgicalColor.purple => 'Roxo',
        LiturgicalColor.rose => 'Rosa',
      };
}

extension LiturgicalSeasonX on LiturgicalSeason {
  String get labelPt => switch (this) {
        LiturgicalSeason.advent => 'Advento',
        LiturgicalSeason.christmas => 'Tempo do Natal',
        LiturgicalSeason.ordinary => 'Tempo Comum',
        LiturgicalSeason.lent => 'Quaresma',
        LiturgicalSeason.triduum => 'Tríduo Pascal',
        LiturgicalSeason.easter => 'Tempo Pascal',
      };
}

/// Rank of the celebration (highest first).
enum LiturgicalRank { solemnity, feast, memorial, weekday }

class LiturgicalDay {
  final DateTime date;
  final LiturgicalSeason season;
  final LiturgicalColor color;
  final String celebration; // best-effort title
  final LiturgicalRank rank;
  final String sundayCycle; // 'A' | 'B' | 'C'
  final String weekdayCycle; // 'I' | 'II'

  const LiturgicalDay({
    required this.date,
    required this.season,
    required this.color,
    required this.celebration,
    required this.rank,
    required this.sundayCycle,
    required this.weekdayCycle,
  });
}
