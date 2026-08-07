import 'dart:io';

import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/storage/user/user_database.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/annotations/domain/entities.dart';
import 'package:biblia_traditio/features/annotations/presentation/note_editor.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart' as bible;
import 'package:biblia_traditio/features/bible/presentation/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressions for the bugs found in the pre-release bug bash.
void main() {
  group('a note is never deleted silently', () {
    late Directory dir;
    late UserDatabase db;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('bt_note_editor');
      db = UserDatabase.open('${dir.path}/user.db');
    });
    tearDown(() {
      db.dispose();
      dir.deleteSync(recursive: true);
    });

    Future<void> pumpEditor(WidgetTester tester, {Note? existing}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(null),
          userDbProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showNoteEditor(
                      context, ref, const VerseRef('jn', 3, 16),
                      existing: existing),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('clearing the text and saving leaves the note untouched',
        (tester) async {
      final uuid = db.addNote(const VerseRef('jn', 3, 16), 'reflexão original');
      final existing = db.allNotes().single;
      expect(existing.uuid, uuid);

      await pumpEditor(tester, existing: existing);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // The note survives: deleting stays behind the confirmed delete action.
      final after = db.allNotes();
      expect(after, hasLength(1));
      expect(after.single.body, 'reflexão original');
    });

    testWidgets('editing the text updates the note', (tester) async {
      db.addNote(const VerseRef('jn', 3, 16), 'antes');
      await pumpEditor(tester, existing: db.allNotes().single);
      await tester.enterText(find.byType(TextField), 'depois');
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(db.allNotes().single.body, 'depois');
    });

    testWidgets('deleting asks first, and honours a cancel', (tester) async {
      db.addNote(const VerseRef('jn', 3, 16), 'reflexão');
      await pumpEditor(tester, existing: db.allNotes().single);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Excluir nota?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(db.allNotes(), hasLength(1));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir').last);
      await tester.pumpAndSettle();
      expect(db.allNotes(), isEmpty);
    });

    testWidgets('an empty new note is not created', (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(db.allNotes(), isEmpty);
    });
  });

  group('a tapped reference opens the verse, not the top of the chapter', () {
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

    bible.ChapterContent chapter() => bible.ChapterContent(
          'jn',
          3,
          [
            for (var i = 1; i <= 36; i++)
              bible.Verse(i, 'Versículo $i de João 3 com algum texto.'),
          ],
          const [],
        );

    Future<void> pumpReader(WidgetTester tester, {int? focusVerse}) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          contentDatabaseProvider.overrideWithValue(null),
          userDbProvider.overrideWithValue(null),
          booksProvider.overrideWithValue([book]),
          chapterProvider.overrideWith((ref, key) => chapter()),
          commentaryMarkersProvider.overrideWith((ref, key) => const <int>{}),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: ReaderScreen(
              bookId: 'jn',
              chapter: 3,
              recordProgress: false,
              focusVerse: focusVerse),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('without ?v= the reader opens at the chapter header',
        (tester) async {
      await pumpReader(tester);
      expect(find.text('Capítulo 3'), findsOneWidget);
      expect(find.textContaining('Versículo 30 de João', findRichText: true),
          findsNothing);
    });

    testWidgets('?v= scrolls the requested verse into view', (tester) async {
      await pumpReader(tester, focusVerse: 30);
      expect(find.textContaining('Versículo 30 de João', findRichText: true),
          findsOneWidget);
      // …and it is no longer showing the top of the chapter.
      expect(find.text('Capítulo 3'), findsNothing);
    });

    testWidgets('the focused verse is marked, then quietly released',
        (tester) async {
      await pumpReader(tester, focusVerse: 5);
      final marked = tester
          .widgetList<Container>(find.byType(Container))
          .where((w) => w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null)
          .length;
      expect(marked, greaterThan(0), reason: 'the verse should stand out');

      // The mark is temporary — it must not linger as a permanent highlight.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final after = tester
          .widgetList<Container>(find.byType(Container))
          .where((w) => w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null)
          .length;
      expect(after, lessThan(marked));
    });

    testWidgets('an out-of-range ?v= is ignored rather than crashing',
        (tester) async {
      await pumpReader(tester, focusVerse: 9999);
      expect(tester.takeException(), isNull);
      await pumpReader(tester, focusVerse: 0);
      expect(tester.takeException(), isNull);
    });
  });
}
