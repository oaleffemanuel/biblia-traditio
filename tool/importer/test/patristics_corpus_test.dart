import 'dart:convert';
import 'dart:io';

import 'package:biblia_traditio_importer/parsers/patristics_merge.dart';
import 'package:biblia_traditio_importer/parsers/patristics_parser.dart';
import 'package:biblia_traditio_importer/parsers/patristics_roles.dart';
import 'package:test/test.dart';

void main() {
  group('função vocabulary', () {
    test('picks the era or office as the primary label, not "Santo"', () {
      expect(
        RoleInfo.parse('Doutor da Igreja; Santo; Patrística; Exegeta').primary,
        'doutor-da-igreja',
      );
      expect(RoleInfo.parse('Santo; Patrística; Bispo').primary, 'patristica');
      expect(RoleInfo.parse('Medieval; Exegeta; Monge; Bispo').primary,
          'medieval');
      expect(RoleInfo.parse('Documento Medieval').primary, 'documento-medieval');
      expect(RoleInfo.parse('Exegeta; Sacerdote').primary, 'exegeta');
    });

    test('groups an author for the commentary filters', () {
      expect(RoleInfo.parse('Doutor da Igreja; Santo; Patrística').groups,
          containsAll(['patristica', 'santos']));
      expect(RoleInfo.parse('Medieval; Exegeta').groups, ['escolastica']);
      expect(RoleInfo.parse('Documento Patrístico; Documento Histórico').groups,
          ['patristica']);
    });

    test('an unrecognised function yields no title rather than a made-up one',
        () {
      final r = RoleInfo.parse('Astronauta');
      expect(r.primary, '');
      expect(r.tags, isEmpty);
      expect(r.raw, 'Astronauta', reason: 'the source string is still kept');
    });

    test('an empty função is empty, not a placeholder', () {
      expect(RoleInfo.parse('').isEmpty, isTrue);
      expect(RoleInfo.parse('   ').primary, '');
    });

    test('accents and casing in the source do not matter', () {
      expect(RoleInfo.parse('PATRÍSTICA').primary, 'patristica');
      expect(RoleInfo.parse('patristica').primary, 'patristica');
    });

    test('tags serialise in a stable, splittable form', () {
      final r = RoleInfo.parse('Doutor da Igreja; Santo');
      expect(r.tagsColumn, 'doutor-da-igreja;santo');
      expect(r.groupsColumn, 'santos');
    });
  });

  group('author unification', () {
    test('folds an honorific/spelling variant onto the canonical name', () {
      final a = unifyAuthorNames(
        {'Santo Agostinho', 'São Tomás de Aquino'},
        {'Santo Agostinho de Hipona', 'Santo Tomás de Aquino'},
      );
      expect(a['Santo Agostinho'], 'Santo Agostinho de Hipona');
      expect(a['São Tomás de Aquino'], 'Santo Tomás de Aquino');
    });

    test('the same words beat a longer superset', () {
      // "Bíblia de Estudo de Santo Tomás de Aquino" is a different work and
      // must never swallow Aquinas himself.
      final a = unifyAuthorNames(
        {'São Tomás de Aquino'},
        {'Santo Tomás de Aquino', 'Bíblia de Estudo de Santo Tomás de Aquino'},
      );
      expect(a['São Tomás de Aquino'], 'Santo Tomás de Aquino');
    });

    test('an ambiguous short name is left alone', () {
      final a = unifyAuthorNames(
        {'São Gregório'},
        {'São Gregório Magno', 'São Gregório de Nissa', 'São Gregório, o Teólogo'},
      );
      expect(a.containsKey('São Gregório'), isFalse);
    });

    test('two distinct Fathers are never collapsed into one', () {
      final a = unifyAuthorNames(
        {'São Gregório Magno'},
        {'São Gregório de Nissa'},
      );
      expect(a, isEmpty);
    });

    test('a name already canonical is not aliased to itself', () {
      final a = unifyAuthorNames(
          {'Santo Agostinho de Hipona'}, {'Santo Agostinho de Hipona'});
      expect(a, isEmpty);
    });
  });

  group('corrected-corpus overlay', () {
    late Directory tmp;
    late Directory original;
    late Directory corrected;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('bt_patristics');
      original = Directory('${tmp.path}/original')..createSync();
      corrected = Directory('${tmp.path}/corrected')..createSync();

      // Original corpus: Mark 1:1 and 1:2, no função metadata.
      File('${original.path}/coment-mk.json').writeAsStringSync(jsonEncode({
        'id': 'mk',
        'language': 'pt-BR',
        'translation_engine': 'argos',
        'chapters': {
          '1': {
            '1': [
              {'author': 'Santo Agostinho', 'year': '430', 'text': 'antigo 1:1'},
            ],
            '2': [
              {'author': 'São Beda', 'year': '735', 'text': 'antigo 1:2'},
            ],
          },
        },
      }));

      // Corrected corpus: only 1:1, with função — 1:2 must survive from the
      // original.
      File('${corrected.path}/mk_pt.json').writeAsStringSync(jsonEncode({
        '1': {
          '1': [
            {
              'commentator': 'Santo Agostinho de Hipona',
              'função': 'Doutor da Igreja; Santo; Patrística',
              'year': '430',
              'comment': 'corrigido 1:1',
            },
          ],
          '3': null, // verses without commentary appear as null
        },
      }));
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    Future<OverlayResult> run() async {
      final base = await (await PatristicsParser.fromDir(original.path))
          .parseDir(original.path);
      final overlay = await (await PatristicsParser.fromDir(corrected.path))
          .parseCorrectedDir(corrected.path);
      return overlayPatristics(base, overlay);
    }

    test('the corrected text replaces the original for the verses it covers',
        () async {
      final r = await run();
      final at11 = r.merged.commentaries
          .where((c) => c.chapter == 1 && c.verse == 1)
          .toList();
      expect(at11, hasLength(1));
      expect(at11.single.text, 'corrigido 1:1');
      expect(at11.single.role.primary, 'doutor-da-igreja');
      expect(at11.single.century, 'V');
    });

    test('a verse the corrected corpus is silent about keeps its commentary',
        () async {
      final r = await run();
      final at12 = r.merged.commentaries
          .where((c) => c.chapter == 1 && c.verse == 2)
          .toList();
      expect(at12, hasLength(1));
      expect(at12.single.text, 'antigo 1:2');
      expect(r.retainedVerses, 1);
      expect(r.retainedCommentaries, 1);
    });

    test('the overlay can never reduce verse coverage', () async {
      final r = await run();
      expect(r.merged.coveredVerses.length, greaterThanOrEqualTo(r.baseVerses));
    });

    test('null verses in the corrected corpus are skipped, not imported',
        () async {
      final r = await run();
      expect(r.merged.commentaries.any((c) => c.verse == 3), isFalse);
    });

    test('a book where the corrected corpus covers less is reported', () async {
      // Blank the corrected file so it covers nothing for Mark.
      File('${corrected.path}/mk_pt.json').writeAsStringSync(jsonEncode({
        '1': {
          '1': [
            {
              'commentator': 'Santo Agostinho de Hipona',
              'função': 'Doutor da Igreja',
              'year': '430',
              'comment': 'corrigido 1:1',
            },
          ],
        },
      }));
      final r = await run();
      // 2 original verses → 1 corrected: a >10% loss, named rather than silent.
      expect(r.regressedBooks, isNotEmpty);
      expect(r.regressedBooks.single, contains('mk'));
    });
  });

  group('psalm numbering', () {
    test('the corrected corpus is Hebrew-numbered like the original', () {
      // Hebrew 23 (the Good Shepherd) is Vulgate 22.
      expect(psalmHebrewToVulgate(23, 1), (22, 1));
      // Hebrew 9/10 merge into Vulgate 9.
      expect(psalmHebrewToVulgate(10, 1).$1, 9);
      // Psalm 119 → 118, verse for verse.
      expect(psalmHebrewToVulgate(119, 176), (118, 176));
      // The first eight coincide.
      expect(psalmHebrewToVulgate(1, 1), (1, 1));
    });
  });

  group('book id resolution', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('bt_ids'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('the corrected corpus file-name variants resolve without an alias file',
        () async {
      // No aliases_normalizados.json here — the built-in variants must carry it.
      for (final stem in ['1mc', '2mc', 'ru', 'ti', 'jude']) {
        File('${tmp.path}/${stem}_pt.json').writeAsStringSync(jsonEncode({
          '1': {
            '1': [
              {
                'commentator': 'Autor',
                'função': 'Patrística',
                'year': '400',
                'comment': 'texto',
              },
            ],
          },
        }));
      }
      final r = await (await PatristicsParser.fromDir(tmp.path))
          .parseCorrectedDir(tmp.path);
      expect(r.orphans, 0);
      expect(r.commentaries.map((c) => c.bookId).toSet(),
          {'1mac', '2mac', 'rt', 'tit', 'jud'});
    });
  });
}
