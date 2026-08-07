import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/presentation/widgets/share_verse.dart';
import 'package:biblia_traditio/l10n/app_localizations_en.dart';
import 'package:biblia_traditio/l10n/app_localizations_pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(void Function(BuildContext) open) => MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('pt'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => open(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

void main() {
  group('excerpting', () {
    test('short text is untouched', () {
      expect(excerptFor('No princípio era o Verbo', 100),
          'No princípio era o Verbo');
    });

    test('long text is trimmed on a word boundary with an ellipsis', () {
      final long = List.filled(200, 'palavra').join(' ');
      final cut = excerptFor(long, 100);
      expect(cut.length, lessThanOrEqualTo(101));
      expect(cut.endsWith('…'), isTrue);
      expect(cut, isNot(contains('palav…'))); // never mid-word
    });

    test('the commentary limit keeps a card a quotation, not a document', () {
      expect(kMaxShareCommentaryChars, lessThan(kMaxShareSelectionChars * 2));
      final long = List.filled(4000, 'x').join();
      expect(excerptFor(long, kMaxShareCommentaryChars).length,
          lessThanOrEqualTo(kMaxShareCommentaryChars + 1));
    });
  });

  group('passage length', () {
    test('measures the whole selection, numbering included', () {
      final verses = [
        (number: 1, text: 'a' * 100),
        (number: 2, text: 'b' * 100),
      ];
      expect(passageLength(verses), greaterThanOrEqualTo(200));
    });

    test('a chapter-sized selection exceeds the share limit', () {
      final chapter = [
        for (var i = 1; i <= 40; i++) (number: i, text: 'x' * 120),
      ];
      expect(passageLength(chapter), greaterThan(kMaxShareSelectionChars));
    });

    test('a five-verse selection fits comfortably', () {
      final span = [
        for (var i = 1; i <= 5; i++) (number: i, text: 'x' * 120),
      ];
      expect(passageLength(span), lessThanOrEqualTo(kMaxShareSelectionChars));
    });
  });

  testWidgets('a multi-verse card keeps every verse number and the reference',
      (tester) async {
    await tester.pumpWidget(_harness((context) => showSharePassage(
          context,
          reference: 'João 1,1-3',
          verses: const [
            (number: 1, text: 'No princípio era o Verbo'),
            (number: 2, text: 'Ele estava no princípio junto de Deus'),
            (number: 3, text: 'Todas as coisas foram feitas por ele'),
          ],
        )));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No princípio era o Verbo'), findsWidgets);
    expect(find.text('JOÃO 1,1-3'), findsOneWidget);
    // Subtle branding, never a promotional caption.
    expect(find.text('Biblia Traditio'), findsOneWidget);
    expect(find.textContaining('Taken from'), findsNothing);
    expect(find.textContaining('Baixe'), findsNothing);
    // The three share actions.
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Texto'), findsOneWidget);
    expect(find.text('Imagem'), findsOneWidget);
  });

  testWidgets('a commentary card carries the author, their title and the verse',
      (tester) async {
    await tester.pumpWidget(_harness((context) => showShareCommentary(
          context,
          reference: 'João 1,1',
          author: 'Santo Agostinho de Hipona',
          authorMeta: 'Doutor da Igreja — séc. V',
          text: 'A palavra grega “logos” significa tanto Palavra quanto Razão.',
        )));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Santo Agostinho de Hipona'), findsOneWidget);
    expect(find.text('Doutor da Igreja — séc. V'), findsOneWidget);
    expect(find.textContaining('logos'), findsOneWidget);
    expect(find.text('JOÃO 1,1'), findsOneWidget);
    expect(find.text('Biblia Traditio'), findsOneWidget);
  });

  test('the over-limit message names the limit in both languages', () {
    expect(AppL10nPt().shareSelectionTooLong(kMaxShareSelectionChars),
        contains('$kMaxShareSelectionChars'));
    expect(AppL10nEn().shareSelectionTooLong(kMaxShareSelectionChars),
        contains('$kMaxShareSelectionChars'));
  });
}
