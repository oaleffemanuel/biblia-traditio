import 'dart:convert';
import 'dart:io';

import 'package:biblia_traditio/features/liturgy/domain/liturgical_calendar.dart';
import 'package:biblia_traditio/features/liturgy/domain/liturgical_day.dart';
import 'package:biblia_traditio/features/liturgy/domain/liturgical_directory.dart';
import 'package:biblia_traditio/features/liturgy/domain/saints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cal = LiturgicalCalendar();
  const directory = LiturgicalDirectory();

  group('saints dataset', () {
    late Map<String, dynamic> raw;
    late List<SaintEntry> entries;

    setUpAll(() {
      raw = jsonDecode(File('assets/saints/saints.json').readAsStringSync())
          as Map<String, dynamic>;
      entries = [
        for (final e in raw['entries'] as List)
          SaintEntry.fromJson(e as Map<String, dynamic>),
      ];
    });

    test('every entry is keyed MM-DD and parses to a real calendar day', () {
      for (final e in entries) {
        expect(RegExp(r'^\d{2}-\d{2}$').hasMatch(e.day), isTrue,
            reason: '${e.name}: "${e.day}"');
        final month = int.parse(e.day.split('-')[0]);
        final day = int.parse(e.day.split('-')[1]);
        expect(month, inInclusiveRange(1, 12));
        expect(day, inInclusiveRange(1, 31));
        expect(DateTime(2026, month, day).month, month,
            reason: '${e.name}: ${e.day} is not a real date');
      }
    });

    test('every entry carries a name, a life and a source', () {
      expect(entries, isNotEmpty);
      for (final e in entries) {
        expect(e.name.trim(), isNotEmpty);
        expect(e.source.trim(), isNotEmpty,
            reason: '${e.name} must say where the life comes from');
        expect(e.biography.length, inInclusiveRange(3, 6),
            reason: '${e.name}: a life is 3–6 paragraphs');
        for (final p in e.biography) {
          expect(p.trim().length, greaterThan(60),
              reason: '${e.name}: no stub paragraphs');
        }
      }
    });

    test('the dataset declares its provenance', () {
      expect(raw['note'], isA<String>());
      expect('${raw['note']}', contains('domínio público'));
    });

    test('a thin entry is treated as absent rather than padded out', () {
      const thin = SaintEntry(
        day: '01-01',
        name: 'Alguém',
        title: '',
        century: '',
        biography: ['curto'],
        source: 'x',
      );
      expect(thin.isPresentable, isFalse);
    });

    test('the repository keys by MM-DD and is silent for uncovered days', () {
      final repo = BundledSaintsRepository({
        '10-04': [
          SaintEntry(
            day: '10-04',
            name: 'São Francisco de Assis',
            title: 'Fundador',
            century: 'XIII',
            biography: const ['a', 'b', 'c'],
            source: 'Butler',
          ),
        ],
      });
      expect(repo.forDate(DateTime(2026, 10, 4)).single.name,
          'São Francisco de Assis');
      // A day with no entry yields nothing — the UI then shows no section.
      expect(repo.forDate(DateTime(2026, 10, 5)), isEmpty);
      expect(BundledSaintsRepository.keyFor(DateTime(2026, 1, 7)), '01-07');
    });

    test('the empty repository never offers anything', () {
      expect(const EmptySaintsRepository().forDate(DateTime(2026, 10, 4)),
          isEmpty);
    });
  });

  // Minimal labels so the domain can be exercised without Flutter l10n.
  final labels = DirectoryLabels(
    season: 'Tempo Litúrgico',
    celebration: 'Celebração',
    color: 'Cor Litúrgica',
    week: 'Semana',
    year: 'Ano Litúrgico',
    cycle: 'Ciclo',
    preface: 'Prefácio',
    observances: 'Observações',
    ephemerides: 'Efemérides',
    seasonName: (s) => switch (s) {
      LiturgicalSeason.advent => 'Advento',
      LiturgicalSeason.christmas => 'Tempo do Natal',
      LiturgicalSeason.lent => 'Quaresma',
      LiturgicalSeason.triduum => 'Tríduo Pascal',
      LiturgicalSeason.easter => 'Tempo Pascal',
      LiturgicalSeason.ordinary => 'Tempo Comum',
    },
    colorName: (c) => switch (c) {
      LiturgicalColor.green => 'Verde',
      LiturgicalColor.red => 'Vermelho',
      LiturgicalColor.white => 'Branco',
      LiturgicalColor.purple => 'Roxo',
      LiturgicalColor.rose => 'Rosa',
    },
    rankName: (r) => r.name,
    weekOf: (w) => '$wª semana',
    yearOf: (y) => 'Ano $y',
    cycleOf: (c) => 'Ciclo $c',
  );

  DirectoryEntry explain(int y, int m, int d) =>
      directory.explain(cal.resolve(DateTime(y, m, d)), labels);

  String? valueOf(DirectoryEntry e, String label) =>
      e.cards.where((c) => c.label == label).map((c) => c.value).firstOrNull;

  group('liturgical directory', () {
    test('every day of a year yields a complete, non-empty card set', () {
      for (var d = DateTime(2026, 1, 1);
          d.year == 2026;
          d = DateTime(d.year, d.month, d.day + 1)) {
        final e = directory.explain(cal.resolve(d), labels);
        expect(e.cards, isNotEmpty, reason: '$d');
        for (final card in e.cards) {
          expect(card.label.trim(), isNotEmpty, reason: '$d');
          expect(card.value.trim(), isNotEmpty, reason: '$d ${card.label}');
        }
        // The five cards that must always be answerable.
        for (final label in const [
          'Tempo Litúrgico', 'Celebração', 'Cor Litúrgica',
          'Ano Litúrgico', 'Prefácio',
        ]) {
          expect(e.cards.any((c) => c.label == label), isTrue,
              reason: '$d missing $label');
        }
      }
    });

    test('cards stay concise — no essays', () {
      for (var d = DateTime(2026, 1, 1);
          d.year == 2026;
          d = DateTime(d.year, d.month, d.day + 1)) {
        for (final card in directory.explain(cal.resolve(d), labels).cards) {
          expect(card.value.length, lessThan(400), reason: '$d ${card.label}');
          expect((card.note ?? '').length, lessThan(240),
              reason: '$d ${card.label}');
        }
      }
    });

    test('names the season and the celebration', () {
      expect(valueOf(explain(2026, 3, 2), 'Tempo Litúrgico'), 'Quaresma');
      expect(valueOf(explain(2026, 2, 18), 'Celebração'), 'Quarta-feira de Cinzas');
    });

    test('reports the colour, the week and the year', () {
      expect(valueOf(explain(2026, 7, 8), 'Cor Litúrgica'), 'Verde');
      expect(valueOf(explain(2026, 3, 15), 'Cor Litúrgica'), 'Rosa'); // Laetare
      expect(valueOf(explain(2026, 11, 22), 'Semana'), '34ª semana do Tempo Comum');
      expect(valueOf(explain(2026, 3, 2), 'Ano Litúrgico'), 'Ano A');
    });

    test('names the preface family the Missal appoints', () {
      expect(valueOf(explain(2026, 12, 25), 'Prefácio'), contains('Natal'));
      expect(valueOf(explain(2026, 5, 24), 'Prefácio'), contains('Pentecostes'));
      expect(valueOf(explain(2026, 3, 2), 'Prefácio'), contains('Quaresma'));
      // An ordinary Sunday vs an ordinary weekday take different families.
      expect(valueOf(explain(2026, 7, 12), 'Prefácio'), contains('Domingos'));
      expect(valueOf(explain(2026, 7, 8), 'Prefácio'), contains('Comum'));
    });

    group('observances and ephemerides', () {
      test('Ash Wednesday states the fast and who it binds', () {
        expect(valueOf(explain(2026, 2, 18), 'Observações'), contains('Jejum'));
      });

      test('a universal holy day flags that conferences may differ', () {
        expect(valueOf(explain(2026, 8, 15), 'Observações'),
            contains('conferência episcopal'));
      });

      test('optional memorials appear as ephemerides, not as the celebration',
          () {
        final e = explain(2026, 1, 20);
        expect(valueOf(e, 'Efemérides'), contains('São Sebastião'));
        expect(valueOf(e, 'Celebração'), isNot(contains('Sebastião')));
      });

      test('a plain weekday carries neither card', () {
        final e = explain(2026, 7, 8);
        expect(valueOf(e, 'Observações'), isNull);
        expect(valueOf(e, 'Efemérides'), isNull);
      });
    });
  });
}
