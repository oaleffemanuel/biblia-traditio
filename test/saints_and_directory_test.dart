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

  group('liturgical directory', () {
    test('explains every day of a year without gaps or throwing', () {
      for (var d = DateTime(2026, 1, 1);
          d.year == 2026;
          d = DateTime(d.year, d.month, d.day + 1)) {
        final e = directory.explain(cal.resolve(d));
        expect(e.season.paragraphs, isNotEmpty, reason: '$d');
        expect(e.color.paragraphs, isNotEmpty, reason: '$d');
        expect(e.rank.paragraphs, isNotEmpty, reason: '$d');
      }
    });

    test('names the season and its meaning', () {
      final lent = directory.explain(cal.resolve(DateTime(2026, 3, 2)));
      expect(lent.season.title, 'Quaresma');
      expect(lent.season.paragraphs.join(), contains('quarenta dias'));
    });

    test('explains the particular celebration when it knows one', () {
      final ash = directory.explain(cal.resolve(DateTime(2026, 2, 18)));
      expect(ash.celebration, isNotNull);
      expect(ash.celebration!.title, 'Quarta-feira de Cinzas');
    });

    test('an ordinary weekday has no celebration topic, only the season', () {
      final feria = directory.explain(cal.resolve(DateTime(2026, 7, 8)));
      expect(feria.celebration, isNull);
      expect(feria.season.title, 'Tempo Comum');
    });

    test('the colour explanation matches the day', () {
      expect(directory.explain(cal.resolve(DateTime(2026, 7, 8))).color.title,
          'Verde');
      expect(directory.explain(cal.resolve(DateTime(2026, 5, 24))).color.title,
          'Vermelho'); // Pentecost
      expect(directory.explain(cal.resolve(DateTime(2026, 3, 15))).color.title,
          'Rosa'); // Laetare
    });

    test('the rank explanation matches the grade', () {
      expect(directory.explain(cal.resolve(DateTime(2026, 8, 15))).rank.title,
          'Solenidade');
      expect(directory.explain(cal.resolve(DateTime(2026, 1, 28))).rank.title,
          'Memória obrigatória');
      expect(directory.explain(cal.resolve(DateTime(2026, 7, 8))).rank.title,
          'Féria');
    });

    group('practical notes', () {
      test('Ash Wednesday states the fast and who it binds', () {
        final notes =
            directory.explain(cal.resolve(DateTime(2026, 2, 18))).practical;
        expect(notes.join(), contains('jejum'));
        expect(notes.join(), contains('abstinência'));
      });

      test('a Sunday states the precept', () {
        final notes =
            directory.explain(cal.resolve(DateTime(2026, 6, 14))).practical;
        expect(notes.join(), contains('preceito'));
      });

      test('a universal holy day flags that conferences may differ', () {
        final notes =
            directory.explain(cal.resolve(DateTime(2026, 8, 15))).practical;
        expect(notes.join(), contains('conferências episcopais'));
      });

      test('optional memorials are listed as available, not imposed', () {
        final notes =
            directory.explain(cal.resolve(DateTime(2026, 1, 20))).practical;
        expect(notes.join(), contains('pode celebrar-se também'));
        expect(notes.join(), contains('São Sebastião'));
      });

      test('an octave day says so', () {
        final notes =
            directory.explain(cal.resolve(DateTime(2026, 4, 7))).practical;
        expect(notes.join(), contains('oitava'));
      });

      test('a plain weekday has nothing to add', () {
        // 8 July 2026: a Wednesday in Ordinary Time with no memorial at all,
        // no precept and no Friday abstinence.
        final notes =
            directory.explain(cal.resolve(DateTime(2026, 7, 8))).practical;
        expect(notes, isEmpty);
      });

      test('a weekday that carries an optional memorial offers it', () {
        // 9 July 2026 has one; the day itself stays a feria.
        final day = cal.resolve(DateTime(2026, 7, 9));
        expect(day.rank, LiturgicalRank.weekday);
        expect(directory.explain(day).practical.join(),
            contains('Agostinho Zhao Rong'));
      });
    });
  });
}
