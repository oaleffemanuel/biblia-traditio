import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/annotations/domain/entities.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart' as bible;
import 'package:biblia_traditio/features/bible/presentation/reader_screen.dart';
import 'package:biblia_traditio/features/bible/presentation/widgets/share_verse.dart';
import 'package:biblia_traditio/features/liturgy/domain/book_proclamation.dart';
import 'package:biblia_traditio/features/settings/domain/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('share cards are light and printable', () {
    testWidgets('the card sits on paper, not on the app\'s dark ground',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('pt'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showShareVerse(context,
                    reference: 'João 1,1', text: 'No princípio era o Verbo'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Inspect only the card — the sheet behind it is legitimately dark.
      final cardColours = tester
          .widgetList<Container>(find.ancestor(
              of: find.text('BIBLIA TRADITIO'), matching: find.byType(Container)))
          .where((w) =>
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color != null)
          .map((w) => (w.decoration as BoxDecoration).color!)
          .toList();

      expect(cardColours, isNotEmpty);
      // The card's own ground is paper, and nothing inside it is the app's
      // near-black surface.
      expect(cardColours.first.computeLuminance(), greaterThan(0.85),
          reason: 'an exported card must be on a light ground');
      expect(cardColours.where((c) => c.computeLuminance() < 0.02), isEmpty,
          reason: 'the dark theme must never be exported');
    });
  });

  group('highlight colours', () {
    test('the bar paints yellow, green, blue, pink, purple in that order', () {
      expect(HighlightColor.values.map((c) => c.key).toList(),
          ['gold', 'sage', 'sky', 'rose', 'lilac']);
    });

    test('stored keys are unchanged, so existing highlights survive', () {
      for (final key in ['gold', 'sage', 'sky', 'rose', 'lilac']) {
        expect(HighlightColor.fromKey(key).key, key);
      }
      // An unknown key still resolves rather than throwing.
      expect(HighlightColor.fromKey('chartreuse'), HighlightColor.gold);
    });
  });

  group('the long-press action bar', () {
    final book = bible.BibleBook(
      id: 'jn',
      testament: bible.Testament.nt,
      order: 50,
      isDeutero: false,
      chapterCount: 21,
      emblemAsset: '',
      name: 'João',
      abbrev: 'Jo',
    );

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(null),
          userDbProvider.overrideWithValue(null),
          booksProvider.overrideWithValue([book]),
          chapterProvider.overrideWith((ref, key) => bible.ChapterContent(
                'jn',
                1,
                [
                  for (var i = 1; i <= 10; i++)
                    bible.Verse(i, 'Versículo $i do capítulo.'),
                ],
                const [],
              )),
          commentaryMarkersProvider.overrideWith((ref, key) => const <int>{}),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const ReaderScreen(
              bookId: 'jn', chapter: 1, recordProgress: false),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Finder verse(int n) =>
        find.textContaining('Versículo $n do', findRichText: true).first;
    Finder verseNumber(int n) => find.text('$n').first;

    testWidgets('long press raises all five actions', (tester) async {
      await pump(tester);
      expect(find.text('Destacar'), findsNothing);

      await tester.longPress(verseNumber(2));
      await tester.pumpAndSettle();

      for (final label in ['Copiar', 'Partilhar', 'Destacar', 'Nota', 'Favoritar']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('Destacar opens the colour bar, and closes it again',
        (tester) async {
      await pump(tester);
      await tester.longPress(verseNumber(2));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsWidgets);
      await tester.tap(find.text('Destacar'));
      await tester.pumpAndSettle();

      // Five swatches, one per colour.
      final swatches = tester
          .widgetList<Container>(find.byType(Container))
          .where((w) =>
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle)
          .toList();
      expect(swatches.length, greaterThanOrEqualTo(5));

      await tester.tap(find.text('Destacar'));
      await tester.pumpAndSettle();
      // The actions stay put; only the colour row folds away.
      expect(find.text('Destacar'), findsOneWidget);
    });

    testWidgets('the bar acts on the whole selection, not just the anchor',
        (tester) async {
      await pump(tester);
      await tester.longPress(verseNumber(2));
      await tester.pumpAndSettle();
      expect(find.text('1 versículo selecionado'), findsOneWidget);

      await tester.tap(verse(5));
      await tester.pumpAndSettle();
      expect(find.text('4 versículos selecionados'), findsOneWidget);
      // …and the actions are still there for the wider span.
      expect(find.text('Destacar'), findsOneWidget);
    });

    testWidgets('clearing dismisses the bar entirely', (tester) async {
      await pump(tester);
      await tester.longPress(verseNumber(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();
      expect(find.text('Destacar'), findsNothing);
    });
  });

  group('liturgical book titles', () {
    test('every canonical book can be announced by name', () {
      const canon = [
        'gn','ex','lv','nm','dt','jo','jgs','rt','1sm','2sm','1kgs','2kgs',
        '1chr','2chr','ezr','neh','tb','jdt','est','1mac','2mac','jb','ps',
        'prv','eccl','sg','ws','sir','is','jer','lam','bar','ez','dn','hos',
        'jl','am','ob','jon','mi','na','hb','zep','hg','zec','mal','mt','mk',
        'lk','jn','acts','rom','1cor','2cor','gal','eph','phil','col','1thes',
        '2thes','1tm','2tm','tit','phlm','heb','jas','1pt','2pt','1jn','2jn',
        '3jn','jud','rv',
      ];
      expect(canon.length, 73);
      for (final id in canon) {
        final p = proclamationFor(id);
        expect(p, isNotNull, reason: id);
        expect(p!.title.trim(), isNotEmpty, reason: id);
        expect(p.ofForm.startsWith('do ') || p.ofForm.startsWith('da '), isTrue,
            reason: '$id → "${p.ofForm}"');
      }
    });

    test('the prophets and letters read as a lector would say them', () {
      expect(proclamationFor('na')!.title, 'Livro do Profeta Naum');
      expect(proclamationFor('na')!.ofForm, 'do Livro do Profeta Naum');
      expect(proclamationFor('rom')!.ofForm, 'da Carta de São Paulo aos Romanos');
      expect(proclamationFor('1cor')!.title,
          'Primeira Carta de São Paulo aos Coríntios');
    });

    test('an unknown id yields nothing rather than an invented title', () {
      expect(proclamationFor('zzz'), isNull);
    });
  });

  group('language roadmap', () {
    test('six languages are built for, five are shipped', () {
      expect(AppLanguage.values.map((l) => l.code).toSet(),
          {'pt', 'en', 'it', 'es', 'fr', 'la'});
      expect(AppLanguage.implemented,
          [AppLanguage.pt, AppLanguage.en, AppLanguage.es, AppLanguage.fr, AppLanguage.it]);
    });

    test('unfinished languages are never advertised to the platform', () {
      final advertised = AppLanguage.supportedLocales.map((l) => l.languageCode);
      expect(advertised, ['pt', 'en', 'es', 'fr', 'it']);
      for (final planned in AppLanguage.planned) {
        expect(advertised.contains(planned.code), isFalse,
            reason: '${planned.code} is not translated yet');
        expect(AppLanguage.implemented.contains(planned), isFalse);
      }
    });

    test('planned languages are exactly the untranslated ones', () {
      expect(AppLanguage.planned.map((l) => l.code).toSet(), {'la'});
    });

    test('each language carries a display label and a locale', () {
      for (final l in AppLanguage.values) {
        expect(l.label.trim(), isNotEmpty, reason: l.code);
        expect(l.locale.languageCode, l.code);
      }
    });
  });
}
