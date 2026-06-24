import 'package:biblia_traditio/core/di/providers.dart';
import 'package:biblia_traditio/core/l10n_ext.dart';
import 'package:biblia_traditio/core/theme/app_theme.dart';
import 'package:biblia_traditio/features/bible/presentation/bible_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bible screen no longer shows the three-dot overflow menu',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [contentDatabaseProvider.overrideWithValue(null)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('pt'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const BibleLibraryScreen(),
      ),
    ));
    await tester.pump();
    // The "⋯" → Settings shortcut was removed; Settings lives on Home.
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    // The screen still renders its title.
    expect(find.text('Bíblia'), findsOneWidget);
  });
}
