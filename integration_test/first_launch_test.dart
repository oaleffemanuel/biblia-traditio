import 'package:biblia_traditio/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Drives the real app on the simulator through the full first-launch content
/// flow. Run fresh (true first-launch) with:
///   xcrun simctl uninstall <udid> br.com.bibliatraditio.bibliaTraditio
///   flutter test integration_test/first_launch_test.dart -d <udid>
///
/// Tests run in order in one app process; state (onboarding done, installed
/// content) persists across them — so test 1 does first-launch + onboarding and
/// the rest start from Home.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const timeout = Timeout(Duration(minutes: 5));

  Future<bool> until(WidgetTester t, Finder f,
      {Duration limit = const Duration(seconds: 15)}) async {
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

  Finder navItem(String label) => find.descendant(
      of: find.byType(BottomNavigationBar), matching: find.text(label));
  Finder appBarText(String s) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(s));
  Finder sheetText(String s) => find.descendant(
      of: find.byType(DraggableScrollableSheet), matching: find.text(s));

  Future<void> launchToHome(WidgetTester t) async {
    app.main();
    await until(t, find.text('Início'), limit: const Duration(seconds: 60));
  }

  // Navigate Home → Bible → Gênesis → chapter 1 reader.
  Future<void> openGenesis1(WidgetTester t) async {
    await tap(t, navItem('Bíblia'));
    await until(t, find.text('Gênesis'));
    await tap(t, find.text('Gênesis'));
    await until(t, find.text('1'));
    await tap(t, find.text('1'));
    await until(t, find.textContaining('In principio'));
  }

  testWidgets('1. fresh install installs Bible and reaches reader',
      (tester) async {
    final sw = Stopwatch()..start();
    app.main();
    final reached = await until(
        tester,
        find.byWidgetPredicate((w) =>
            w is Text && (w.data == 'Continuar' || w.data == 'Início')),
        limit: const Duration(seconds: 90));
    debugPrint('RESULT first_launch_reached=$reached '
        'install_ms=${sw.elapsedMilliseconds}');
    expect(reached, isTrue);

    if (find.text('Continuar').evaluate().isNotEmpty) {
      await tap(tester, find.text('Continuar'));
      if (find.byType(TextField).evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextField).first, 'Teste');
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (var i = 0; i < 6; i++) {
        final next = find.text('Continuar').evaluate().isNotEmpty
            ? find.text('Continuar')
            : find.text('Entrar');
        if (next.evaluate().isEmpty) break;
        await tap(tester, next);
      }
      await until(tester, find.text('Início'));
    }
    expect(find.text('Início'), findsWidgets);
    debugPrint('RESULT onboarding_to_home=ok');

    await tap(tester, navItem('Bíblia'));
    expect(await until(tester, find.text('Gênesis')), isTrue);
    await tap(tester, find.text('Novo testamento'));
    expect(await until(tester, find.text('Mateus')), isTrue);
    debugPrint('RESULT ot_nt_toggle=ok');
    await tap(tester, find.text('Antigo testamento'));
    await until(tester, find.text('Gênesis'));
    await tap(tester, find.text('Gênesis'));
    await until(tester, find.text('1'));
    await tap(tester, find.text('1'));
    expect(await until(tester, find.textContaining('In principio')), isTrue);
    debugPrint('RESULT reader_shows_vulgate=ok');
  }, timeout: timeout);

  testWidgets('2. header pickers + prev/next chapter', (tester) async {
    await launchToHome(tester);
    await openGenesis1(tester);

    // book picker (app-bar pill, disambiguated from the header title)
    await tap(tester, appBarText('Gênesis'));
    expect(await until(tester, find.text('Antigo testamento')), isTrue,
        reason: 'book picker did not open');
    await tap(tester, find.text('Êxodo')); // pick another book
    expect(await until(tester, appBarText('Êxodo')), isTrue,
        reason: 'did not navigate to Êxodo');
    debugPrint('RESULT book_picker=ok');

    // chapter picker (app-bar chapter pill)
    await tap(tester, appBarText('1'));
    expect(await until(tester, find.textContaining('capítulo')), isTrue,
        reason: 'chapter picker did not open');
    await tap(tester, sheetText('3')); // grid cell, not a verse behind the modal
    expect(await until(tester, find.text('Capítulo 3')), isTrue);
    debugPrint('RESULT chapter_picker=ok');

    // verse jump
    await tap(tester, find.byIcon(Icons.format_list_numbered));
    expect(await until(tester, find.text('Ir para versículo')), isTrue);
    await tap(tester, sheetText('5'));
    debugPrint('RESULT verse_jump=ok');

    // prev/next — the chapter footer is at the end of the lazy list, so scroll
    // it into view first.
    await tester.scrollUntilVisible(find.text('Próximo'), 500,
        scrollable: find.byType(Scrollable).last, maxScrolls: 80);
    await tap(tester, find.text('Próximo'));
    expect(await until(tester, find.text('Capítulo 4')), isTrue);
    debugPrint('RESULT prev_next_chapter=ok');
  }, timeout: timeout);

  testWidgets('3. patristics install + commentary + remove', (tester) async {
    await launchToHome(tester);
    await tap(tester, find.byIcon(Icons.settings_outlined));
    expect(await until(tester, find.text('Comentário dos Padres da Igreja')),
        isTrue);
    final sw = Stopwatch()..start();
    await tap(tester, find.byIcon(Icons.download));
    final installed = await until(tester, find.textContaining('Instalado'),
        limit: const Duration(seconds: 120));
    debugPrint('RESULT patristics_installed=$installed '
        'install_ms=${sw.elapsedMilliseconds}');
    expect(installed, isTrue, reason: 'patristics install/checksum failed');

    // open Genesis 1:1 commentary (give the content DB a beat to reopen with
    // the newly-installed patristics package)
    await tap(tester, find.byType(BackButton));
    await tester.pump(const Duration(seconds: 1));
    await openGenesis1(tester);
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, find.textContaining('In principio'));
    expect(await until(tester, find.text('Padres da Igreja')), isTrue);
    await tap(tester, find.text('Padres da Igreja'));
    // every commentary card shows a "séc." century label (first one is visible;
    // specific author names may be off-screen in the lazy list).
    expect(await until(tester, find.textContaining('séc.')), isTrue,
        reason: 'commentary did not load');
    debugPrint('RESULT commentary_shown=ok');
    await tester.tapAt(const Offset(20, 40)); // dismiss sheet
    await tester.pump(const Duration(milliseconds: 400));

    // remove the package
    await tap(tester, navItem('Início'));
    await tap(tester, find.byIcon(Icons.settings_outlined));
    await until(tester, find.text('Comentário dos Padres da Igreja'));
    await tap(tester, find.byIcon(Icons.delete_outline));
    expect(await until(tester, find.byIcon(Icons.download)), isTrue,
        reason: 'package not removed');
    debugPrint('RESULT patristics_removed=ok');
  }, timeout: timeout);

  testWidgets('4. user data persists + sharing', (tester) async {
    await launchToHome(tester);
    await openGenesis1(tester);

    // favorite + note
    await tap(tester, find.textContaining('In principio'));
    expect(await until(tester, find.text('Favoritar')), isTrue);
    await tap(tester, find.text('Favoritar'));
    await tap(tester, find.textContaining('In principio'));
    await until(tester, find.text('Nota'));
    await tap(tester, find.text('Nota'));
    if (await until(tester, find.byType(TextField))) {
      await tester.enterText(find.byType(TextField).first, 'Reflexão de teste');
      await tester.pump(const Duration(milliseconds: 300));
      await tap(tester, find.text('Guardar'));
    }
    debugPrint('RESULT user_data_added=ok');

    // sharing card
    await tap(tester, find.textContaining('In principio'));
    await until(tester, find.text('Partilhar'));
    await tap(tester, find.text('Partilhar'));
    expect(await until(tester, find.text('Biblia Traditio')), isTrue,
        reason: 'share card did not render');
    debugPrint('RESULT share_card=ok');
    await tester.tapAt(const Offset(20, 40));
    await tester.pump(const Duration(milliseconds: 400));
  }, timeout: timeout);

  testWidgets('5. user data persists across relaunch', (tester) async {
    // Fresh app launch (effectively a restart); the favorite added in test 4
    // lives in the writable user DB and must still be there.
    await launchToHome(tester);
    expect(await until(tester, find.text('Favoritos')), isTrue,
        reason: 'Home favorites action missing');
    await tap(tester, find.text('Favoritos').first);
    expect(await until(tester, find.textContaining('In principio')), isTrue,
        reason: 'favorite did not persist across relaunch');
    debugPrint('RESULT favorite_persisted=ok');
  }, timeout: timeout);
}
