import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/theme/app_theme.dart';
import '../features/packages/application/package_providers.dart';
import '../features/settings/application/settings_providers.dart';
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
      return const _Splash(message: 'Preparando a Bíblia…');
    }
    if (dbReady.hasError) {
      return const _Splash(message: 'Erro ao iniciar.');
    }

    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider(settings.onboardingCompleted));
    return MaterialApp.router(
      title: 'Biblia Traditio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}

class _Splash extends StatelessWidget {
  final String? message;
  const _Splash({this.message});
  @override
  Widget build(BuildContext context) {
    final c = BtColors.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, color: c.accent, size: 48),
              const SizedBox(height: 24),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: c.accent.withValues(alpha: 0.7)),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(message!, style: TextStyle(color: c.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
