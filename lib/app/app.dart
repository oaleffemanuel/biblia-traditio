import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/l10n_ext.dart';
import '../core/snack.dart';
import '../core/theme/app_theme.dart';
import '../features/liturgy/application/liturgy_providers.dart';
import '../features/packages/application/package_providers.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/domain/settings.dart';
import '../features/themes/application/theme_providers.dart';
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
    // Preload the bundled lectionary and saints during the splash. The Liturgy
    // tab is kept alive in the shell's IndexedStack, so resolving these small
    // assets before any screen builds avoids an async provider notifying
    // mid-build later — which surfaces as a Riverpod "setState during build"
    // assertion when a tab change toggles TickerMode and resumes the tab's
    // paused subscriptions. Any new always-alive async asset belongs here too.
    final lectionary = ref.watch(lectionaryProvider);
    final saints = ref.watch(saintsRepositoryProvider);
    final themes = ref.watch(themeLibraryProvider);

    if (dbReady.isLoading ||
        content.isLoading ||
        lectionary.isLoading ||
        saints.isLoading ||
        themes.isLoading) {
      return const _Splash();
    }
    // Surface a clear, recoverable error instead of falling through to an empty
    // library: (a) the user DB failed to open, or (b) the required Bible package
    // failed to install/decompress.
    if (dbReady.hasError || content.hasError) {
      return _Splash(
        error: true,
        onRetry: () {
          ref.invalidate(contentReadyProvider);
          ref.invalidate(userDatabaseProvider);
        },
      );
    }

    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider(settings.onboardingCompleted));
    return MaterialApp.router(
      title: 'Biblia Traditio',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: _localeFor(settings.language),
      // Only translated languages are advertised — see AppLanguage.
      supportedLocales: AppLanguage.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routerConfig: router,
    );
  }

  /// A language that isn't translated yet falls back to Portuguese rather than
  /// rendering a half-localised UI.
  Locale _localeFor(AppLanguage l) =>
      AppLanguage.implemented.contains(l) ? l.locale : AppLanguage.pt.locale;
}

class _Splash extends StatelessWidget {
  final bool error;
  final VoidCallback? onRetry;
  const _Splash({this.error = false, this.onRetry});
  @override
  Widget build(BuildContext context) {
    final c = BtColors.dark;
    // Shown before MaterialApp/Localizations exist, so it is language-neutral:
    // the wordmark + an icon-only retry, never an untranslated sentence.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                error ? Icons.error_outline : Icons.menu_book,
                color: c.accent,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                'Biblia Traditio',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              if (!error)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.accent.withValues(alpha: 0.7),
                  ),
                )
              else if (onRetry != null)
                IconButton.outlined(
                  onPressed: onRetry,
                  iconSize: 26,
                  icon: const Icon(Icons.refresh),
                  color: c.accent,
                  style: IconButton.styleFrom(
                    side: BorderSide(color: c.accent.withValues(alpha: 0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
