import 'dart:io';

import 'package:biblia_traditio/features/bible/presentation/widgets/share_verse.dart';
import 'package:biblia_traditio/features/themes/domain/theme_library.dart';
import 'package:flutter_test/flutter_test.dart';

const _canon = {
  'gn',
  'ex',
  'lv',
  'nm',
  'dt',
  'jo',
  'jgs',
  'rt',
  '1sm',
  '2sm',
  '1kgs',
  '2kgs',
  '1chr',
  '2chr',
  'ezr',
  'neh',
  'tb',
  'jdt',
  'est',
  '1mac',
  '2mac',
  'jb',
  'ps',
  'prv',
  'eccl',
  'sg',
  'ws',
  'sir',
  'is',
  'jer',
  'lam',
  'bar',
  'ez',
  'dn',
  'hos',
  'jl',
  'am',
  'ob',
  'jon',
  'mi',
  'na',
  'hb',
  'zep',
  'hg',
  'zec',
  'mal',
  'mt',
  'mk',
  'lk',
  'jn',
  'acts',
  'rom',
  '1cor',
  '2cor',
  'gal',
  'eph',
  'phil',
  'col',
  '1thes',
  '2thes',
  '1tm',
  '2tm',
  'tit',
  'phlm',
  'heb',
  'jas',
  '1pt',
  '2pt',
  '1jn',
  '2jn',
  '3jn',
  'jud',
  'rv',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('thematic library asset', () {
    final lib = ThemeLibrary.parse(
      File('assets/themes/themes.json').readAsStringSync(),
    );

    test('every theme belongs to a declared group and has passages', () {
      final groups = lib.groups.map((g) => g.id).toSet();
      expect(lib.themes, isNotEmpty);
      for (final t in lib.themes) {
        expect(groups, contains(t.groupId), reason: t.id);
        expect(t.passageCount, greaterThan(0), reason: t.id);
        expect(t.title.trim(), isNotEmpty);
      }
    });

    test('ids are unique and every passage points at a canonical book', () {
      expect(lib.themes.map((t) => t.id).toSet().length, lib.themes.length);
      for (final t in lib.themes) {
        for (final p in [
          ...t.passages,
          for (final st in t.subtopics) ...st.passages,
        ]) {
          expect(_canon, contains(p.bookId), reason: '${t.id} ${p.ref}');
          expect(p.chapter, greaterThan(0));
          expect(p.verseStart, greaterThan(0));
          expect(
            p.verseEnd,
            greaterThanOrEqualTo(p.verseStart),
            reason: '${t.id} ${p.ref}',
          );
        }
      }
    });

    test('the Eucharist theme exists and carries passages', () {
      final e = lib.themes.firstWhere((t) => t.title.contains('Eucaristia'));
      expect(e.passageCount, greaterThan(0));
      final all = [...e.passages, for (final st in e.subtopics) ...st.passages];
      expect(all.any((p) => p.bookId == 'jn' && p.chapter == 6), isTrue);
    });

    test('psalms are stored in Vulgate chapters', () {
      final ps = [
        for (final t in lib.themes)
          for (final p in t.passages)
            if (p.bookId == 'ps') p,
      ];
      expect(ps, isNotEmpty);
      for (final p in ps) {
        expect(p.chapter, lessThanOrEqualTo(150));
        expect(p.chapter, greaterThan(0));
      }
    });

    test('the bundled asset loads through Flutter asset resolution', () async {
      final loaded = await ThemeLibrary.load();
      expect(loaded.themes.length, lib.themes.length);
      expect(
        loaded.themes.any((t) => t.title.contains('Eucaristia')),
        isTrue,
      );
    });
  });

  group('commentary excerpt picker', () {
    test('splits on sentence ends and keeps text intact', () {
      final s = splitSentences(
        'Primeira frase. Segunda frase! Terceira; quarta.',
      );
      expect(s, ['Primeira frase.', 'Segunda frase!', 'Terceira;', 'quarta.']);
    });

    test('joins adjacent sentences with a space and gaps with an ellipsis', () {
      final s = ['A.', 'B.', 'C.', 'D.'];
      expect(joinExcerpt(s, {0, 1}), 'A. B.');
      expect(joinExcerpt(s, {0, 2, 3}), 'A. […] C. D.');
    });

    test('default selection stops before the card limit', () {
      final s = List.generate(20, (i) => 'Frase número $i com texto.');
      final sel = defaultExcerptSelection(s, 100);
      expect(sel, isNotEmpty);
      expect(joinExcerpt(s, sel).length, lessThanOrEqualTo(100));
      expect(joinExcerpt(s, {...sel, sel.length}).length, greaterThan(100));
    });
  });
}
