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
    expect(find.text('Biblia Traditio'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 1 — name (Continuar disabled until a name is typed)
    expect(find.text('Como devemos chamá-lo?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Gabriel');
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 2 — language
    expect(find.text('Idioma'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 3 — translation
    expect(find.text('Tradução'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 4 — notifications
    expect(find.text('Lembretes diários'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Step 5 — reading plan, final button reads "Entrar"
    expect(find.text('Plano de leitura'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.text('Entrar')); // completes without throwing
    await tester.pumpAndSettle();
  });
}
