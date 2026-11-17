// Visual tour of the 2026-11-17 batch (screenshots taken from the host on
// each SHOT: line): shorter onboarding, Psalm wallpaper, icon-only nav,
// thematic index with search, theme tabs, reader top bar, triple-tap select.
import 'package:biblia_traditio/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<bool> until(
    WidgetTester t,
    Finder f, {
    Duration limit = const Duration(seconds: 20),
  }) async {
    final end = DateTime.now().add(limit);
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 150));
      if (f.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    expect(f, findsWidgets, reason: 'cannot tap (not found): $f');
    await t.tap(f.first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 500));
  }

  Future<void> hold(WidgetTester t, String name) async {
    await t.pump(const Duration(milliseconds: 700));
    debugPrint('SHOT:$name');
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('batch 11-17 tour', (tester) async {
    app.main();
    await until(
      tester,
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Pular' || w.data == 'Continuar'),
      ),
      limit: const Duration(seconds: 90),
    );
    final introSkip = find.byKey(const ValueKey('intro-skip'));
    if (introSkip.evaluate().isNotEmpty) {
      await tap(tester, introSkip);
      await until(tester, find.text('Continuar'));
    }
    if (find.text('Continuar').evaluate().isNotEmpty) {
      await hold(tester, '01-onb-welcome');
      await tap(tester, find.text('Continuar'));
      await tester.enterText(find.byType(TextField), 'Aleff');
      await tester.pump(const Duration(milliseconds: 300));
      await tap(tester, find.text('Continuar'));
      await hold(tester, '02-onb-parallel');
      await tap(tester, find.text('Continuar'));
      await tap(tester, find.text('Continuar'));
      await tap(tester, find.text('Entrar'));
    }
    await until(tester, find.byIcon(Icons.home), limit: const Duration(seconds: 30));
    await hold(tester, '03-home');

    // Thematic index: icon-only nav, search, folding sections.
    await tap(tester, find.byType(ImageIcon).last);
    await until(tester, find.byKey(const ValueKey('themes-search')));
    await hold(tester, '04-themes-index');
    await tap(tester, find.text('Sacramentos e Liturgia'));
    await hold(tester, '05-themes-open');
    await tester.enterText(find.byKey(const ValueKey('themes-search')), 'eucar');
    await tester.pump(const Duration(milliseconds: 500));
    await hold(tester, '06-themes-search');
    await tap(tester, find.textContaining('Eucaristia'));
    await until(tester, find.byType(PageView));
    await hold(tester, '07-theme-verses');
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pump(const Duration(milliseconds: 600));
    await hold(tester, '08-theme-comments');

    // Reader: abbreviation + chapter only; triple tap selects the verse.
    await tap(tester, find.byIcon(Icons.menu_book_outlined));
    final genesis = find.byWidgetPredicate(
      (w) => w is Text && (w.data == 'Gênesis' || w.data == 'Genesis'),
    );
    await until(tester, genesis);
    await tap(tester, genesis);
    await until(tester, find.text('1'));
    await tap(tester, find.text('1'));
    await tester.pump(const Duration(seconds: 2));
    await hold(tester, '09-reader');
    final verse = find.byType(SelectableText).at(1);
    for (var i = 0; i < 3; i++) {
      await tester.tap(verse, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 70));
    }
    await tester.pump(const Duration(milliseconds: 500));
    await hold(tester, '10-reader-triple-tap');
  });
}
