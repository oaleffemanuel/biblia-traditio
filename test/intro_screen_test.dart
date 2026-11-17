import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/features/onboarding/presentation/intro_screen.dart';

Widget _host({required VoidCallback onDone}) => MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('pt'),
      home: IntroScreen(onDone: onDone),
    );

void main() {
  testWidgets('offers "Pular" from the first frame and hands over on tap',
      (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(onDone: () => done++));
    await tester.pump();
    expect(find.text('Pular'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('intro-skip')));
    await tester.pump();
    expect(done, 1);
    // A second trigger (clip end after a skip) must not fire twice.
    await tester.tap(find.byKey(const ValueKey('intro-skip')));
    await tester.pump();
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('falls through when the clip cannot play', (tester) async {
    // No video platform in widget tests: initialize() fails, which must hand
    // over to onboarding rather than leave the reader on a blank screen.
    var done = 0;
    await tester.pumpWidget(_host(onDone: () => done++));
    await tester.pump(const Duration(seconds: 5));
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
