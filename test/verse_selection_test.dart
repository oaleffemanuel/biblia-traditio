import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/snack.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/reader_screen.dart';
import 'package:biblia_traditio/features/bible/presentation/widgets/share_verse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _bookId = 'jn';

final _book = BibleBook(
  id: _bookId,
  testament: Testament.nt,
  order: 50,
  isDeutero: false,
  chapterCount: 21,
  emblemAsset: '',
  name: 'João',
  abbrev: 'Jo',
);

/// Long verses, so a wide selection blows past the share limit and a narrow one
/// does not — both paths are exercised against the real constant.
ChapterContent _chapter({int verses = 8, int verseLength = 60}) =>
    ChapterContent(
      _bookId,
      1,
      [
        for (var i = 1; i <= verses; i++)
          Verse(i, 'Versículo $i ${'palavra ' * (verseLength ~/ 8)}'.trim()),
      ],
      const [],
    );

Future<void> _pump(WidgetTester tester, {ChapterContent? content}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      contentDatabaseProvider.overrideWithValue(null),
      userDbProvider.overrideWithValue(null),
      booksProvider.overrideWithValue([_book]),
      chapterProvider.overrideWith((ref, key) => content ?? _chapter()),
      commentaryMarkersProvider.overrideWith((ref, key) => const <int>{}),
    ],
    child: MaterialApp(
      // The app's own messenger, so the over-limit notice is observable here
      // exactly as it is in the running app.
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.dark(),
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const ReaderScreen(
          bookId: _bookId, chapter: 1, recordProgress: false),
    ),
  ));
  await tester.pumpAndSettle();
}

Finder _verse(int n) =>
    find.textContaining('Versículo $n ', findRichText: true).first;

void main() {
  testWidgets('the reader shows no selection bar until asked', (tester) async {
    await _pump(tester);
    expect(find.textContaining('selecionado'), findsNothing);
  });

  testWidgets('long-pressing a verse starts a one-verse selection',
      (tester) async {
    await _pump(tester);
    await tester.longPress(_verse(1));
    await tester.pumpAndSettle();

    expect(find.text('1 versículo selecionado'), findsOneWidget);
    expect(find.text('Limpar'), findsOneWidget);
  });

  testWidgets('tapping another verse extends the span, always consecutively',
      (tester) async {
    await _pump(tester);
    await tester.longPress(_verse(1));
    await tester.pumpAndSettle();

    await tester.tap(_verse(5));
    await tester.pumpAndSettle();
    expect(find.text('5 versículos selecionados'), findsOneWidget);

    // Extending backwards past the anchor still yields a continuous span.
    await tester.tap(_verse(3));
    await tester.pumpAndSettle();
    expect(find.text('3 versículos selecionados'), findsOneWidget);
  });

  testWidgets('sharing a short span opens the passage card', (tester) async {
    await _pump(tester, content: _chapter(verses: 8, verseLength: 40));
    await tester.longPress(_verse(1));
    await tester.pumpAndSettle();
    await tester.tap(_verse(3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(find.text('JOÃO 1,1-3'), findsOneWidget);
    expect(find.text('BIBLIA TRADITIO'), findsOneWidget);
  });

  testWidgets('an over-long span is refused with the limit named, not rendered',
      (tester) async {
    // Eight verses of ~200 characters comfortably exceed the limit.
    await _pump(tester, content: _chapter(verses: 8, verseLength: 200));
    await tester.longPress(_verse(1));
    await tester.pumpAndSettle();
    await tester.tap(_verse(8));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(find.textContaining('$kMaxShareSelectionChars'), findsOneWidget);
    // No card was built for a passage this long.
    expect(find.textContaining('JOÃO 1,'), findsNothing);
  });

  testWidgets('clearing the selection puts the reader back where it was',
      (tester) async {
    await _pump(tester);
    await tester.longPress(_verse(2));
    await tester.pumpAndSettle();
    expect(find.text('1 versículo selecionado'), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('selecionado'), findsNothing);
  });

  testWidgets('with no selection, tapping a verse still opens the commentary',
      (tester) async {
    await _pump(tester);
    await tester.tap(_verse(1));
    await tester.pumpAndSettle();
    // The verse panel, not a selection.
    expect(find.text('Patrística'), findsWidgets);
    expect(find.text('Minhas Notas'), findsOneWidget);
  });
}
