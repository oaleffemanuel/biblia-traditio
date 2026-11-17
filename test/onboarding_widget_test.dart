import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding walks through all steps to "Entrar"', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('pt'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const OnboardingScreen(),
        ),
      ),
    );

    // Step 0 — welcome
    expect(find.text('Bíblia Patrística'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 1 — name (Continuar disabled until a name is typed)
    expect(find.text('Como podemos chamar você?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Gabriel');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Language, translation style and translation are no longer asked: they
    // follow the device language (editable in Settings).
    expect(find.text('Idioma'), findsNothing);
    expect(find.text('Qual estilo de tradução você prefere?'), findsNothing);

    // Step 2 — parallel text as a table: one language per Testament. No
    // content DB is open in this test, so every cell is shown but disabled —
    // tapping one selects nothing (no promise of a text that isn't there).
    expect(find.text('Deseja utilizar um texto paralelo?'), findsOneWidget);
    expect(find.text('Selecione o idioma da leitura paralela'), findsOneWidget);
    expect(find.text('Antigo testamento'), findsOneWidget);
    expect(find.text('Novo testamento'), findsOneWidget);
    expect(find.text('Hebraico'), findsOneWidget); // OT only
    expect(find.text('Grego'), findsNWidgets(2));
    expect(find.text('Latim'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('parallel-ot-he')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 3 — notifications
    expect(find.text('Lembretes diários'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 4 — reading plan, final button reads "Entrar"
    expect(find.text('Plano de leitura'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.text('Entrar')); // completes without throwing
    await tester.pumpAndSettle();
  });
}
