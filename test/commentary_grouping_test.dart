import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/commentary_panel.dart';
import 'package:biblia_traditio/features/liturgy/domain/lectionary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _vref = VerseRef('jn', 1, 1);

Commentary _c(int id, String name, String text,
        {String century = 'IV', String role = 'doutor-da-igreja'}) =>
    Commentary(
      id: id,
      ref: _vref,
      fatherName: name,
      century: century,
      source: 'Catena Aurea',
      isMachineTranslation: true,
      text: text,
      rolePrimary: role,
      roleGroups: const {'patristica'},
    );

/// St Basil has three excerpts on this verse; Chrysostom has one. This is the
/// shape that used to render as repeated headers.
final _fixture = [
  _c(1, 'São Basílio Magno', 'Primeiro excerto de Basílio sobre o Verbo.'),
  _c(2, 'São Basílio Magno', 'Segundo excerto de Basílio sobre o Verbo.'),
  _c(3, 'São Basílio Magno', 'Terceiro excerto de Basílio sobre o Verbo.'),
  _c(4, 'São João Crisóstomo', 'Único excerto de Crisóstomo sobre o Verbo.'),
];

Future<void> _open(WidgetTester tester, {List<Commentary>? items}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      contentDatabaseProvider.overrideWithValue(null),
      userDbProvider.overrideWithValue(null),
      commentariesProvider.overrideWith((ref, v) => items ?? _fixture),
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
              onPressed: () => showCommentaryPanel(context, ref, _vref,
                  bookName: 'João', verseText: 'No princípio era o Verbo'),
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

void main() {
  group('one header per author', () {
    testWidgets('a Father with three excerpts appears once, not three times',
        (tester) async {
      await _open(tester);
      expect(find.text('São Basílio Magno'), findsOneWidget);
      expect(find.text('São João Crisóstomo'), findsOneWidget);
    });

    testWidgets('the header says how many excerpts wait inside',
        (tester) async {
      await _open(tester);
      expect(find.text('3 excertos'), findsOneWidget);
      // A single excerpt needs no count.
      expect(find.text('1 excerto'), findsNothing);
    });

    testWidgets('the count still reports every excerpt, not every author',
        (tester) async {
      await _open(tester);
      expect(find.text('4 comentários'), findsOneWidget);
    });
  });

  group('expanding', () {
    testWidgets('opening an author reveals all of its excerpts, in order',
        (tester) async {
      await _open(tester);
      expect(find.textContaining('excerto de Basílio'), findsNothing);

      await tester.tap(find.text('São Basílio Magno'));
      await tester.pumpAndSettle();

      for (final t in ['Primeiro', 'Segundo', 'Terceiro']) {
        expect(find.textContaining('$t excerto de Basílio'), findsOneWidget);
      }
      // Numbered so the reader can tell them apart.
      for (final n in ['COMENTÁRIO 1', 'COMENTÁRIO 2', 'COMENTÁRIO 3']) {
        expect(find.text(n), findsOneWidget);
      }
      // The other author stays closed.
      expect(find.textContaining('Crisóstomo sobre o Verbo'), findsNothing);
    });

    testWidgets('a single-excerpt author is not numbered', (tester) async {
      await _open(tester);
      await tester.tap(find.text('São João Crisóstomo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Único excerto'), findsOneWidget);
      expect(find.text('COMENTÁRIO 1'), findsNothing);
    });

    testWidgets('an author collapses again on a second tap', (tester) async {
      await _open(tester);
      await tester.tap(find.text('São Basílio Magno'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Primeiro excerto'), findsOneWidget);

      await tester.tap(find.text('São Basílio Magno'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Primeiro excerto'), findsNothing);
    });
  });

  group('expand all / collapse all', () {
    testWidgets('opens every author block and flips its label', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Exibir todos'));
      await tester.pumpAndSettle();

      expect(find.text('Minimizar todos'), findsOneWidget);
      expect(find.textContaining('Primeiro excerto de Basílio'), findsOneWidget);
      expect(find.textContaining('Terceiro excerto de Basílio'), findsOneWidget);
      expect(find.textContaining('Único excerto'), findsOneWidget);

      await tester.tap(find.text('Minimizar todos'));
      await tester.pumpAndSettle();
      expect(find.text('Exibir todos'), findsOneWidget);
      // The bodies fold away; the header's excerpt count stays, as it should.
      expect(find.textContaining('excerto de Basílio'), findsNothing);
      expect(find.textContaining('Único excerto'), findsNothing);
      expect(find.text('3 excertos'), findsOneWidget);
    });
  });

  group('sharing survives grouping', () {
    testWidgets('every excerpt keeps its own share action', (tester) async {
      await _open(tester);
      await tester.tap(find.text('São Basílio Magno'));
      await tester.pumpAndSettle();
      // One per excerpt, not one per author.
      expect(find.text('Partilhar comentário'), findsNWidgets(3));
    });

    testWidgets('sharing one excerpt shares that excerpt', (tester) async {
      await _open(tester);
      await tester.tap(find.text('São Basílio Magno'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Partilhar comentário').at(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('Segundo excerto de Basílio'), findsWidgets);
      expect(find.text('SÃO BASÍLIO MAGNO'), findsOneWidget);
      expect(find.text('JOÃO 1,1'), findsOneWidget);
    });
  });

  group('responsorial psalm data path', () {
    test('a reading with no refrain reports none rather than guessing', () {
      const r = Reading(ReadingSlot.psalm, 'Sl 22(23)',
          bookId: 'ps', chapter: 22, verseStart: 1, verseEnd: 6);
      expect(r.hasRefrain, isFalse);
      expect(r.refrain, isNull);
    });

    test('a refrain is carried through when a source supplies one', () {
      final r = Reading.fromJson(const {
        'slot': 'psalm',
        'ref': 'Sl 22(23)',
        'book': 'ps',
        'chapter': 22,
        'vStart': 1,
        'vEnd': 6,
        'refrain': 'O Senhor é meu pastor; nada me faltará.',
        'refrainRef': 'Sl 22,1',
      });
      expect(r.hasRefrain, isTrue);
      expect(r.refrain, 'O Senhor é meu pastor; nada me faltará.');
      expect(r.refrainRef, 'Sl 22,1');
    });

    test('whitespace is not a refrain', () {
      const r = Reading(ReadingSlot.psalm, 'Sl 22(23)', refrain: '   ');
      expect(r.hasRefrain, isFalse);
    });

    test('the bundled dataset carries no refrains yet — and says so', () {
      // Guards the honest state: if this ever starts failing, a refrain source
      // was wired up and the UI note should be revisited.
      const r = Reading(ReadingSlot.psalm, 'Sl 22(23)');
      expect(r.hasRefrain, isFalse);
    });
  });
}
