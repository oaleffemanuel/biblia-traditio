import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/l10n_ext.dart';
import '../core/snack.dart';
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
              Icon(error ? Icons.error_outline : Icons.menu_book,
                  color: c.accent, size: 48),
              const SizedBox(height: 24),
              Text('Biblia Traditio',
                  style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 16,
                      letterSpacing: 1)),
              const SizedBox(height: 24),
              if (!error)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.accent.withValues(alpha: 0.7)),
                )
              else if (onRetry != null)
                IconButton.outlined(
                  onPressed: onRetry,
                  iconSize: 26,
                  icon: const Icon(Icons.refresh),
                  color: c.accent,
                  style: IconButton.styleFrom(
                      side: BorderSide(color: c.accent.withValues(alpha: 0.5))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
