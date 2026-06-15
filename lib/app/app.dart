import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/l10n_ext.dart';
import '../core/theme/app_theme.dart';
import '../features/packages/application/package_providers.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/domain/settings.dart';
import 'router.dart';

class BibliaTraditioApp extends ConsumerWidget {
  const BibliaTraditioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate on (a) the user DB being open and (b) the required Bible package
    // being installed/decompressed, so the first route is chosen with content
    // ready. Decompression runs off the main isolate — the UI never freezes.
    final dbReady = ref.watch(userDatabaseProvider);
    final content = ref.watch(contentReadyProvider);

    if (dbReady.isLoading || content.isLoading) {
      return const _Splash();
    }
    if (dbReady.hasError) {
      return const _Splash(error: true);
    }

    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider(settings.onboardingCompleted));
    return MaterialApp.router(
      title: 'Biblia Traditio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: _localeFor(settings.language),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: router,
    );
  }

  /// Only pt/en are translated; other selections fall back to Portuguese.
  Locale _localeFor(AppLanguage l) =>
      l == AppLanguage.en ? const Locale('en') : const Locale('pt');
}

class _Splash extends StatelessWidget {
  final bool error;
  const _Splash({this.error = false});
  @override
  Widget build(BuildContext context) {
    final c = BtColors.dark;
    // Shown before MaterialApp/Localizations exist, so it is language-neutral.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(error ? Icons.error_outline : Icons.menu_book,
                  color: c.accent, size: 48),
              const SizedBox(height: 24),
              if (!error)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.accent.withValues(alpha: 0.7)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
