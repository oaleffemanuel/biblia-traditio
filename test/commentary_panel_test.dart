import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/application/bible_providers.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/bible/presentation/commentary_panel.dart';
import 'package:biblia_traditio/l10n/app_localizations_en.dart';
import 'package:biblia_traditio/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _vref = VerseRef('jn', 1, 1);

Commentary _c(int id, String name,
        {String century = 'V', String role = 'doutor-da-igreja'}) =>
    Commentary(
      id: id,
      ref: _vref,
      fatherName: name,
      century: century,
      source: 'Catena Aurea / Haydock',
      isMachineTranslation: true,
      text: 'Comentário de $name sobre o Verbo. ' * 3,
      rolePrimary: role,
      roleGroups: const {'patristica', 'santos'},
    );

final _commentaries = [
  _c(1, 'Santo Agostinho de Hipona'),
  _c(2, 'São João Crisóstomo'),
  _c(3, 'Santo Tomás de Aquino', century: 'XIII', role: 'medieval'),
];

Future<void> _openPanel(WidgetTester tester,
    {List<Commentary>? commentaries}) async {
  // A tall surface so every commentary in these small fixtures is laid out —
  // the panel's list is lazy by design, and scrolling it in a test would fight
  // the tab view's own horizontal scrollable.
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      contentDatabaseProvider.overrideWithValue(null),
      userDbProvider.overrideWithValue(null),
      commentariesProvider
          .overrideWith((ref, vref) => commentaries ?? _commentaries),
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
  testWidgets('opens as an index of commentators, with no commentary body',
      (tester) async {
    await _openPanel(tester);

    for (final name in [
      'Santo Agostinho de Hipona',
      'São João Crisóstomo',
      'Santo Tomás de Aquino',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    // Bodies stay closed until asked for.
    expect(find.textContaining('sobre o Verbo'), findsNothing);
    // Every row offers a way in.
    expect(find.byIcon(Icons.expand_more), findsNWidgets(3));
  });

  testWidgets('each commentator carries their function and century',
      (tester) async {
    await _openPanel(tester);
    expect(find.text('Doutor da Igreja — séc. V'), findsNWidgets(2));
    expect(find.text('Medieval — séc. XIII'), findsOneWidget);
  });

  testWidgets('a commentator with no function shows the century alone',
      (tester) async {
    await _openPanel(tester, commentaries: [
      _c(1, 'Tertuliano', century: 'III', role: ''),
    ]);
    expect(find.text('séc. III'), findsOneWidget);
  });

  testWidgets('a commentator with neither shows no metadata line at all',
      (tester) async {
    await _openPanel(tester, commentaries: [
      _c(1, 'Anônimo', century: '', role: ''),
    ]);
    expect(find.text('Anônimo'), findsOneWidget);
    expect(find.textContaining('séc.'), findsNothing);
  });

  testWidgets('tapping a row expands that commentary and offers a way to close',
      (tester) async {
    await _openPanel(tester);
    await tester.tap(find.text('São João Crisóstomo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Comentário de São João Crisóstomo'),
        findsOneWidget);
    // Other commentaries stay closed.
    expect(find.textContaining('Comentário de Santo Agostinho'), findsNothing);
    // The "^" collapse action at the foot of the open commentary.
    expect(find.byIcon(Icons.expand_less), findsWidgets);
    expect(find.text('Partilhar comentário'), findsOneWidget);

    await tester.tap(find.text('São João Crisóstomo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Comentário de São João Crisóstomo'), findsNothing);
  });

  testWidgets('"Exibir todos" opens everything and becomes "Minimizar todos"',
      (tester) async {
    await _openPanel(tester);
    expect(find.text('Exibir todos'), findsOneWidget);

    await tester.tap(find.text('Exibir todos'));
    await tester.pumpAndSettle();

    expect(find.text('Minimizar todos'), findsOneWidget);
    expect(find.text('Exibir todos'), findsNothing);
    for (final name in [
      'Santo Agostinho de Hipona',
      'São João Crisóstomo',
      'Santo Tomás de Aquino',
    ]) {
      expect(find.textContaining('Comentário de $name'), findsOneWidget);
    }

    await tester.tap(find.text('Minimizar todos'));
    await tester.pumpAndSettle();
    expect(find.text('Exibir todos'), findsOneWidget);
    expect(find.textContaining('sobre o Verbo'), findsNothing);
  });

  testWidgets('the tab is labelled Patrística, not Padres', (tester) async {
    await _openPanel(tester);
    expect(find.text('Patrística'), findsWidgets);
    expect(find.text('Padres'), findsNothing);
    expect(find.text('Padres da Igreja'), findsNothing);
  });

  test('the localised tab/scope labels use the Patrística terminology', () {
    final pt = AppL10nPt();
    final en = AppL10nEn();
    expect(pt.commentaryTabPatristics, 'Patrística');
    expect(pt.searchScopeFathers, 'Patrística');
    expect(pt.filterFathers, 'Patrística');
    expect(pt.searchHint, contains('Patrística'));
    expect(pt.searchHint, isNot(contains('Padres')));
    expect(en.commentaryTabPatristics, 'Patristics');
    expect(en.searchScopeFathers, 'Patristics');
    // "Padres da Igreja" survives only where it names the Fathers as people.
    expect(pt.churchFathers, 'Padres da Igreja');
  });
}
