import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/reading_plan/application/reading_plan_providers.dart';
import 'package:biblia_traditio/features/reading_plan/domain/reading_plan.dart';
import 'package:biblia_traditio/features/reading_plan/presentation/reading_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _plan = ReadingPlan(
  id: 'test_plan',
  days: 3,
  title: const {'pt': 'Plano', 'en': 'Plan'},
  source: 'teste',
  entries: const [
    PlanDay(1, [
      PlanReading('São Marcos 1', [PlanTarget('mk', 1)]),
      PlanReading('Provérbios 1,1-3', [
        PlanTarget('prv', 1, verseStart: 1, verseEnd: 3),
      ], section: PlanSection.wisdom),
    ]),
    PlanDay(2, [PlanReading('São Marcos 2', [PlanTarget('mk', 2)])]),
    PlanDay(3, [PlanReading('São Marcos 3', [PlanTarget('mk', 3)])]),
  ],
);

/// A chapter with far more verses than the plan assigns, so the screen is
/// forced to prove it renders only the assigned span.
ChapterContent _chapter(String bookId, int chapter) => ChapterContent(
      bookId,
      chapter,
      [for (var i = 1; i <= 12; i++) Verse(i, 'Versículo $i de $bookId')],
      const [],
    );

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      contentDatabaseProvider.overrideWithValue(null),
      userDbProvider.overrideWithValue(null),
      readingPlanProvider.overrideWith((ref) async => _plan),
      chapterProvider.overrideWith((ref, key) => _chapter(key.bookId, key.chapter)),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const ReadingPlanScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens with a day strip, the day card and collapsed readings',
      (tester) async {
    await _pump(tester);

    // Liturgy-style day selector across the top.
    expect(find.text('Dia 1 de 3'), findsOneWidget);
    expect(find.text('Dia 1'), findsWidgets);
    // Progress lives with the day.
    expect(find.text('0 de 3 dias lidos'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Readings are reference cards, labelled by section.
    expect(find.text('LEITURA'), findsOneWidget);
    expect(find.text('SAPIENCIAL'), findsOneWidget);
    expect(find.text('São Marcos 1'), findsOneWidget);
    expect(find.text('Provérbios 1,1-3'), findsOneWidget);
    // Nothing is dumped on screen before the reader opens a card.
    expect(find.textContaining('Versículo', findRichText: true), findsNothing);
  });

  testWidgets('expanding a partial reading shows only the assigned verses',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Provérbios 1,1-3'));
    await tester.pumpAndSettle();

    for (final n in [1, 2, 3]) {
      expect(find.textContaining('Versículo $n de prv', findRichText: true), findsOneWidget);
    }
    // The rest of the chapter stays out of it — this is the whole point.
    for (final n in [4, 8, 12]) {
      expect(find.textContaining('Versículo $n de prv', findRichText: true), findsNothing);
    }
  });

  testWidgets('expanding a whole-chapter reading shows the chapter',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.text('São Marcos 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Versículo 12 de mk', findRichText: true), findsOneWidget);
  });

  testWidgets('a reading collapses again on a second tap', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('São Marcos 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Versículo 1 de mk', findRichText: true), findsOneWidget);

    await tester.tap(find.text('São Marcos 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Versículo 1 de mk', findRichText: true), findsNothing);
  });

  testWidgets('every reading offers "open in Bible"', (tester) async {
    await _pump(tester);
    expect(find.byIcon(Icons.menu_book_outlined), findsNWidgets(2));
  });

  testWidgets('picking another day in the strip swaps the readings',
      (tester) async {
    await _pump(tester);
    expect(find.text('São Marcos 1'), findsOneWidget);

    // Tap day 2 in the strip (the large numeral).
    await tester.tap(find.text('2').first);
    await tester.pumpAndSettle();

    expect(find.text('Dia 2 de 3'), findsOneWidget);
    expect(find.text('São Marcos 2'), findsOneWidget);
    expect(find.text('São Marcos 1'), findsNothing);
  });
}
