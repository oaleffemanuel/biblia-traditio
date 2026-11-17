// Visual tour used only to capture screenshots from the host
// (xcrun simctl io <udid> screenshot) while the app sits on each screen.
import 'package:biblia_traditio/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<bool> until(WidgetTester t, Finder f,
      {Duration limit = const Duration(seconds: 20)}) async {
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
    await t.pump(const Duration(milliseconds: 450));
  }

  Future<void> hold(WidgetTester t, String name) async {
    await t.pump(const Duration(milliseconds: 600));
    debugPrint('SHOT:$name');
    final end = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Finder navItem(String label) => find.descendant(
      of: find.byType(BottomNavigationBar), matching: find.text(label));

  testWidgets('tour', (tester) async {
    app.main();
    await until(
        tester,
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == 'Pular' ||
                w.data == 'Continuar' ||
                w.data == 'Início')),
        limit: const Duration(seconds: 90));
    // The intro's skip, by key: onboarding has its own "Pular" (skip step).
    final introSkip = find.byKey(const ValueKey('intro-skip'));
    if (introSkip.evaluate().isNotEmpty) {
      await hold(tester, 'intro');
      await tap(tester, introSkip);
      await until(tester, find.text('Continuar'));
    }
    if (find.text('Continuar').evaluate().isNotEmpty) {
      await hold(tester, 'onboarding1');
      await tap(tester, find.text('Continuar'));
      await hold(tester, 'onboarding2');
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, 'Gabriel');
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (var i = 0; i < 9; i++) {
        final next = find.text('Continuar').evaluate().isNotEmpty
            ? find.text('Continuar')
            : find.text('Entrar');
        if (next.evaluate().isEmpty) break;
        await tap(tester, next);
      }
      await until(tester, find.text('Início'));
    }
    await hold(tester, 'home');
    await tap(tester, navItem('Liturgia'));
    await hold(tester, 'liturgy');
    await tap(tester, navItem('Bíblia'));
    await until(tester, find.text('Gênesis'));
    await hold(tester, 'library');
    await tap(tester, find.text('Gênesis'));
    await until(tester, find.text('1'));
    await hold(tester, 'chapters');
    await tap(tester, find.text('1'));
    await until(tester, find.textContaining('No princípio'));
    await hold(tester, 'reader');
    await tap(tester, find.textContaining('No princípio'));
    await hold(tester, 'verse_panel');
    await tester.tapAt(const Offset(200, 80));
    await tester.pump(const Duration(milliseconds: 500));
    // Parallel Reading with the Hebrew text, when it is installed.
    await tap(tester, find.byIcon(Icons.view_column_outlined));
    await until(tester, find.byType(SwitchListTile));
    await tap(tester, find.byType(SwitchListTile));
    // Preset: Hebrew OT | Greek NT — the companion column follows the Testament.
    final hasHebrew = await until(
        tester, find.textContaining('hebraico | Novo Testamento grego'),
        limit: const Duration(seconds: 4));
    if (hasHebrew) {
      await hold(tester, 'parallel_presets');
      await tap(tester, find.textContaining('hebraico | Novo Testamento grego'));
      await tester.tapAt(const Offset(200, 60));
      await tester.pump(const Duration(milliseconds: 600));
      await hold(tester, 'parallel_hebrew');
      await tap(tester, find.byIcon(Icons.view_column_outlined));
      if (await until(tester, find.byType(SwitchListTile),
          limit: const Duration(seconds: 4))) {
        await hold(tester, 'parallel_sheet_presets');
        await tap(tester, find.byType(SwitchListTile));
      }
      await tester.tapAt(const Offset(200, 60));
      await tester.pump(const Duration(milliseconds: 600));
    } else {
      await tap(tester, find.byType(SwitchListTile));
      await tester.tapAt(const Offset(200, 60));
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tap(tester, navItem('Início'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 600));
    expect(await until(tester, find.text('Biblioteca temática')), isTrue);
    await tap(tester, find.text('Biblioteca temática'));
    expect(await until(tester, find.textContaining('Santíssima Trindade')),
        isTrue,
        reason: 'themes screen did not open');
    await hold(tester, 'themes');
    await tester.scrollUntilVisible(find.textContaining('Eucaristia'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.pump(const Duration(milliseconds: 400));
    await tap(tester, find.textContaining('Eucaristia').first);
    await until(tester, find.textContaining('Jo 6'));
    await hold(tester, 'theme_eucaristia');
    await tap(tester, find.byType(BackButton));
    await tester.pump(const Duration(milliseconds: 500));
    await tap(tester, find.byType(BackButton));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.byType(ListView).first, const Offset(0, 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(await until(tester, find.byIcon(Icons.search)), isTrue,
        reason: 'did not return to Home');
    await tap(tester, find.byIcon(Icons.search));
    await hold(tester, 'search');
    final back = find.byType(BackButton).evaluate().isNotEmpty
        ? find.byType(BackButton)
        : find.byIcon(Icons.arrow_back_ios_new);
    await tap(tester, back);
    await tap(tester, find.byIcon(Icons.settings_outlined));
    await hold(tester, 'settings');
    await tap(tester, find.text('Tamanho da letra'));
    await until(tester, find.text('Máxima'));
    await hold(tester, 'settings_font_size');
    await tap(tester, find.text('Grande'));
    await tester.pump(const Duration(milliseconds: 500));
    // Back to the reader to see the larger type with the preset column.
    await tap(tester, find.byType(BackButton));
    await tester.pump(const Duration(milliseconds: 500));
    await tap(tester, navItem('Bíblia'));
    await until(tester, find.textContaining('No princípio'));
    await hold(tester, 'reader_large');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
