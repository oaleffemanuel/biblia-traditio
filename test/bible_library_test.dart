import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/bible_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BibleBook _book(String id, String name, Testament t, int order) => BibleBook(
      id: id,
      testament: t,
      order: order,
      isDeutero: false,
      chapterCount: 10,
      emblemAsset: '',
      name: name,
      abbrev: id,
    );

final _books = [
  _book('gn', 'Gênesis', Testament.ot, 1),
  _book('ex', 'Êxodo', Testament.ot, 2),
  _book('mt', 'São Mateus', Testament.nt, 47),
  _book('mk', 'São Marcos', Testament.nt, 48),
];

Future<void> _pumpLibrary(WidgetTester tester,
    {List<BibleBook> books = const []}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      contentDatabaseProvider.overrideWithValue(null),
      booksProvider.overrideWithValue(books),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const BibleLibraryScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Bible screen no longer shows the three-dot overflow menu',
      (tester) async {
    await _pumpLibrary(tester);
    // The "⋯" → Settings shortcut was removed; Settings lives on Home.
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    // The screen still renders its title.
    expect(find.text('Bíblia'), findsOneWidget);
  });

  testWidgets('opens on the Old Testament with the selector visible',
      (tester) async {
    await _pumpLibrary(tester, books: _books);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Antigo testamento'), findsOneWidget);
    expect(find.text('Novo testamento'), findsOneWidget);
    expect(find.text('Gênesis'), findsOneWidget);
    expect(find.text('São Mateus'), findsNothing);
  });

  testWidgets('swiping left moves to the New Testament', (tester) async {
    await _pumpLibrary(tester, books: _books);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('São Mateus'), findsOneWidget);
    expect(find.text('Gênesis'), findsNothing);
  });

  testWidgets('swiping right comes back to the Old Testament', (tester) async {
    await _pumpLibrary(tester, books: _books);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Gênesis'), findsOneWidget);
    expect(find.text('São Mateus'), findsNothing);
  });

  testWidgets('tapping the selector still switches testament', (tester) async {
    await _pumpLibrary(tester, books: _books);

    await tester.tap(find.text('Novo testamento'));
    await tester.pumpAndSettle();
    expect(find.text('São Marcos'), findsOneWidget);

    await tester.tap(find.text('Antigo testamento'));
    await tester.pumpAndSettle();
    expect(find.text('Êxodo'), findsOneWidget);
  });

  testWidgets('the selector stays a labelled, selectable control for a11y',
      (tester) async {
    await _pumpLibrary(tester, books: _books);

    Semantics segment(String label) => tester.widgetList<Semantics>(
          find.byType(Semantics),
        ).firstWhere((s) => s.properties.label == label);

    expect(segment('Antigo testamento').properties.button, isTrue);
    expect(segment('Antigo testamento').properties.selected, isTrue);
    expect(segment('Novo testamento').properties.button, isTrue);
    expect(segment('Novo testamento').properties.selected, isFalse);

    await tester.tap(find.text('Novo testamento'));
    await tester.pumpAndSettle();
    expect(segment('Novo testamento').properties.selected, isTrue);
    expect(segment('Antigo testamento').properties.selected, isFalse);
  });
}
