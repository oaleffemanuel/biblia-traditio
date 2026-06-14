import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/providers.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/application/settings_providers.dart';
import 'router.dart';

class BibliaTraditioApp extends ConsumerWidget {
  const BibliaTraditioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate the app on the user DB being open so settings (and the onboarding
    // decision) are known before the first route is chosen.
    final dbReady = ref.watch(userDatabaseProvider);
    return dbReady.when(
      loading: () => const _Splash(),
      error: (_, _) => const _Splash(),
      data: (_) {
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
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    final c = BtColors.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Icon(Icons.menu_book, color: c.accent, size: 48),
        ),
      ),
    );
  }
}
