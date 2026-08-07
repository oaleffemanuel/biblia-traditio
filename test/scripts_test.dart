import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/features/bible/presentation/widgets/scripts.dart';
import 'package:biblia_traditio/l10n/app_localizations_en.dart';
import 'package:biblia_traditio/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('direction', () {
    test('Hebrew and Aramaic read right to left', () {
      for (final lang in ['he', 'hbo', 'arc']) {
        expect(scriptDirection(lang), TextDirection.rtl, reason: lang);
        expect(isRtlScript(lang), isTrue, reason: lang);
        expect(scriptAlign(lang), TextAlign.right, reason: lang);
      }
    });

    test('Latin, Greek and the vernacular read left to right', () {
      for (final lang in ['la', 'grc', 'el', 'pt', 'en', '']) {
        expect(scriptDirection(lang), TextDirection.ltr, reason: lang);
        expect(scriptAlign(lang), TextAlign.left, reason: lang);
      }
    });
  });

  group('fonts', () {
    test('Hebrew gets a glyph-bearing fallback', () {
      final s = scriptStyle(const TextStyle(fontSize: 17), 'he');
      expect(s!.fontFamilyFallback, isNotEmpty);
      expect(s.fontSize, 17, reason: 'the base style must survive');
    });

    test('Greek gets a fallback too', () {
      expect(scriptStyle(const TextStyle(), 'grc')!.fontFamilyFallback,
          isNotEmpty);
    });

    test('the vernacular is left exactly as the theme styled it', () {
      const base = TextStyle(fontSize: 17);
      expect(scriptStyle(base, 'pt'), same(base));
    });
  });

  testWidgets('an RTL text lays out inside its own Directionality',
      (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: scriptDirectionality(
        lang: 'he',
        child: const Text('בְּרֵאשִׁית'),
      ),
    ));
    final d = tester.widget<Directionality>(
        find.byType(Directionality).last);
    expect(d.textDirection, TextDirection.rtl);
  });

  testWidgets('an LTR text does not add a Directionality of its own',
      (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: scriptDirectionality(lang: 'la', child: const Text('In principio')),
    ));
    expect(find.byType(Directionality), findsOneWidget);
  });

  group('translation labelling', () {
    test('names the script before the edition', () {
      final pt = AppL10nPt();
      expect(translationLabel(pt, 'la', 'Vulgata Clementina'),
          'Latim — Vulgata Clementina');
      expect(translationLabel(pt, 'grc', 'Novo Testamento Grego (SBLGNT)'),
          'Grego — Novo Testamento Grego (SBLGNT)');
      expect(translationLabel(pt, 'he', 'Texto Massorético'),
          'Hebraico — Texto Massorético');
      expect(translationLabel(AppL10nEn(), 'la', 'Clementine Vulgate'),
          'Latin — Clementine Vulgate');
    });

    test('an unknown language keeps the bare title rather than a raw code', () {
      expect(translationLabel(AppL10nPt(), 'xx', 'Alguma Edição'),
          'Alguma Edição');
    });
  });

  group('commentator role labels', () {
    test('every slug the importer can emit has a localised label', () {
      const slugs = [
        'doutor-da-igreja', 'papa', 'bispo', 'monge', 'sacerdote', 'diacono',
        'exegeta', 'teologo', 'historiador', 'poeta', 'patristica', 'medieval',
        'cristao-primitivo', 'santo', 'santa', 'liturgia',
        'documento-patristico', 'documento-medieval', 'documento-historico',
        'documento-geral',
      ];
      for (final slug in slugs) {
        expect(roleLabel(AppL10nPt(), slug), isNotNull, reason: slug);
        expect(roleLabel(AppL10nEn(), slug), isNotNull, reason: slug);
      }
    });

    test('an unknown slug yields null, so no title is invented', () {
      expect(roleLabel(AppL10nPt(), ''), isNull);
      expect(roleLabel(AppL10nPt(), 'astronauta'), isNull);
    });
  });
}
