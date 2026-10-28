import 'dart:io';

import 'package:biblia_traditio/features/bible/presentation/widgets/share_verse.dart';
import 'package:biblia_traditio/features/themes/domain/theme_library.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/services.dart';

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
        expect(t.passages, isNotEmpty, reason: t.id);
        expect(t.title.trim(), isNotEmpty);
      }
    });

    test('ids are unique and every passage points at a canonical book', () {
      expect(lib.themes.map((t) => t.id).toSet().length, lib.themes.length);
      for (final t in lib.themes) {
        for (final p in t.passages) {
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

    test('the Eucharist theme leads with John 6', () {
      final e = lib.byId('eucaristia')!;
      expect(e.passages.first.bookId, 'jn');
      expect(e.passages.first.chapter, 6);
    });

    test('the bundled asset loads through Flutter asset resolution', () async {
      final loaded = await ThemeLibrary.load();
      expect(loaded.themes.length, lib.themes.length);
      expect(loaded.byId('eucaristia'), isNotNull);
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
