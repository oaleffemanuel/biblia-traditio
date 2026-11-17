// Drives the 2026-11-03 feedback batch on a real app: short intro, the
// parallel-language table in onboarding, the tab order (Início, Liturgia,
// Temas, Bíblia) and word/letter marks in the reader. `SHOT:<name>` lines
// tell the host when to take a screenshot (xcrun simctl io <udid> screenshot).
import 'package:biblia_traditio/features/annotations/domain/entities.dart';
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
    await t.pump(const Duration(milliseconds: 450));
  }

  Future<void> hold(WidgetTester t, String name) async {
    await t.pump(const Duration(milliseconds: 600));
    debugPrint('SHOT:$name');
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Finder navItem(String label) => find.descendant(
    of: find.byType(BottomNavigationBar),
    matching: find.text(label),
  );

  /// Selects the word at [charIndex] of the first selectable verse text
  /// containing [needle], then either taps a colour in the selection menu ([quick]) or opens
  /// the full mark sheet.
  Future<void> markWordAt(
    WidgetTester t,
    String needle,
    int charIndex, {
    HighlightColor? quick,
    String? shot,
  }) async {
    final sel = find.byWidgetPredicate(
      (w) =>
          w is SelectableText &&
          (w.textSpan?.toPlainText() ?? '').contains(needle),
    );
    expect(sel, findsWidgets);
    final state = t.state<EditableTextState>(
      find.descendant(of: sel.first, matching: find.byType(EditableText)),
    );
    // Select the word around [charIndex] exactly as a long press does, then
    // raise the selection toolbar.
    final text = state.textEditingValue.text;
    var a = charIndex, b = charIndex;
    bool letter(int k) => RegExp(r'\p{L}', unicode: true).hasMatch(text[k]);
    while (a > 0 && letter(a - 1)) {
      a--;
    }
    while (b < text.length && letter(b)) {
      b++;
    }
    state.userUpdateTextEditingValue(
      state.textEditingValue.copyWith(
        selection: TextSelection(baseOffset: a, extentOffset: b),
      ),
      SelectionChangedCause.longPress,
    );
    await t.pump(const Duration(milliseconds: 200));
    state.showToolbar();
    await t.pump(const Duration(milliseconds: 500));
    expect(
      await until(
        t,
        find.byKey(const ValueKey('menu-color-gold')),
        limit: const Duration(seconds: 3),
      ),
      isTrue,
      reason: 'selection menu with colours did not open',
    );
    if (shot != null) await hold(t, shot);
    if (quick != null) {
      await tap(t, find.byKey(ValueKey('menu-color-${quick.key}')));
      return;
    }
    await tap(t, find.byKey(const ValueKey('menu-more')));
    await until(t, find.byKey(const ValueKey('mark-excerpt')));
  }

  testWidgets('romulo batch', (tester) async {
    app.main();
    await until(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Pular' || w.data == 'Continuar' || w.data == 'Início'),
      ),
      limit: const Duration(seconds: 90),
    );
    final introSkip = find.byKey(const ValueKey('intro-skip'));
    if (introSkip.evaluate().isNotEmpty) {
      // Let the (now ~4 s) clip run out by itself: it must hand over to
      // onboarding without a tap.
      final started = DateTime.now();
      await until(
        tester,
        find.text('Continuar'),
        limit: const Duration(seconds: 12),
      );
      final took = DateTime.now().difference(started);
      debugPrint('RESULT intro_handover_ms=${took.inMilliseconds}');
      // Includes video start-up on a debug simulator build.
      expect(took, lessThan(const Duration(seconds: 9)));
    }

    // Onboarding up to the parallel table.
    if (find.text('Continuar').evaluate().isNotEmpty) {
      for (var i = 0; i < 8; i++) {
        if (find.byType(TextField).evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextField).first, 'Rômulo');
          await tester.pump(const Duration(milliseconds: 300));
        }
        if (find
            .text('Selecione o idioma da leitura paralela')
            .evaluate()
            .isNotEmpty) {
          break;
        }
        await tap(tester, find.text('Continuar'));
      }
      expect(
        find.text('Selecione o idioma da leitura paralela'),
        findsOneWidget,
      );
      await hold(tester, 'parallel_table_empty');
      await tap(tester, find.byKey(const ValueKey('parallel-ot-he')));
      await tap(tester, find.byKey(const ValueKey('parallel-nt-la')));
      expect(find.byIcon(Icons.check), findsNWidgets(2));
      await hold(tester, 'parallel_table_he_la');
      for (var i = 0; i < 4; i++) {
        final next = find.text('Continuar').evaluate().isNotEmpty
            ? find.text('Continuar')
            : find.text('Entrar');
        if (next.evaluate().isEmpty) break;
        await tap(tester, next);
      }
      await until(tester, find.text('Início'));
    }

    // Tab order: Início, Liturgia, Temas, Bíblia.
    final labels = tester
        .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
        .items
        .map((i) => i.label)
        .toList();
    debugPrint('RESULT tabs=$labels');
    expect(labels, ['Início', 'Liturgia', 'Temas', 'Bíblia']);
    await hold(tester, 'home_nav');
    await tap(tester, navItem('Temas'));
    await hold(tester, 'themes_tab');

    // Reader: Genesis 1 with Hebrew beside it (OT column of the table).
    await tap(tester, navItem('Bíblia'));
    await until(tester, find.text('Gênesis'));
    await tap(tester, find.text('Gênesis'));
    await until(tester, find.text('1'));
    await tap(tester, find.text('1'));
    await until(tester, find.textContaining('princípio'));
    await hold(tester, 'reader_parallel_he');

    // Play Books style: select a word, tap a colour in the menu — done.
    await markWordAt(
      tester,
      'princípio',
      36,
      quick: HighlightColor.sage,
      shot: 'selection_menu_colors',
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('menu-color-gold')), findsNothing);
    debugPrint('RESULT quick_mark=ok');

    // Mark one word, then trim it to a single letter.
    await markWordAt(tester, 'princípio', 4);
    final excerpt0 = tester
        .widget<Text>(find.byKey(const ValueKey('mark-excerpt')))
        .data;
    debugPrint('RESULT first_selection=$excerpt0');
    await hold(tester, 'mark_sheet_word');
    await tap(tester, find.byKey(const ValueKey('mark-color-gold')));
    await tester.pump(const Duration(milliseconds: 600));

    // A second word on the same verse, underlined — the first must stay.
    await markWordAt(tester, 'princípio', 21);
    await tap(tester, find.text('Sublinhar'));
    await hold(tester, 'mark_sheet_underline');
    await tap(tester, find.byKey(const ValueKey('mark-color-rose')));
    await tester.pump(const Duration(milliseconds: 600));

    // And a single letter: shrink a word from the end down to one character.
    await markWordAt(tester, 'princípio', 30);
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const ValueKey('mark-end-left')));
      await tester.pump(const Duration(milliseconds: 60));
    }
    final letter = tester
        .widget<Text>(find.byKey(const ValueKey('mark-excerpt')))
        .data!;
    debugPrint('RESULT letter=$letter');
    expect(letter.runes.length, 3); // “x” — one letter between the quotes
    await hold(tester, 'mark_sheet_letter');
    await tap(tester, find.byKey(const ValueKey('mark-color-sky')));
    await tester.pump(const Duration(milliseconds: 800));
    await hold(tester, 'reader_marks');

    // All three marks survive side by side.
    final painted = find.byWidgetPredicate((w) {
      if (w is! SelectableText) return false;
      var n = 0;
      w.textSpan?.visitChildren((s) {
        final st = s.style;
        if (st?.backgroundColor != null ||
            st?.decoration == TextDecoration.underline) {
          n++;
        }
        return true;
      });
      return n >= 4;
    });
    expect(painted, findsWidgets);
    debugPrint('RESULT four_marks=ok');
  });
}
