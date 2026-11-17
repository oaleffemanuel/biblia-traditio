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

class BibliaTraditioApp extends ConsumerStatefulWidget {
  const BibliaTraditioApp({super.key});

  @override
  ConsumerState<BibliaTraditioApp> createState() => _BibliaTraditioAppState();
}

class _BibliaTraditioAppState extends ConsumerState<BibliaTraditioApp> {
  /// The opening animation deserves to be seen: even when everything loads
  /// instantly, the splash stays up this long (the content gate still rules
  /// when loading takes longer).
  static const _minSplash = Duration(milliseconds: 2200);
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_minSplash).then((_) {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
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

    // On a fresh install the intro clip follows, which is the emblem animation
    // at full length — so the splash's minimum hold is waived there rather than
    // showing the emblem form twice in a row.
    final firstLaunch =
        dbReady.hasValue && !ref.watch(settingsProvider).onboardingCompleted;
    if ((!_splashDone && !firstLaunch) ||
        dbReady.isLoading ||
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
      title: 'Bíblia Patrística',
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

/// The opening: the black emblem rises on the brand gold inside a drawn
/// ring, the wordmark follows, and a thin progress line breathes until
/// content is ready. Same gold as the native launch screen and the intro
/// clip, so the hand-over between them is seamless. Shown before
/// MaterialApp/Localizations exist, so it is language-neutral.
class _Splash extends StatefulWidget {
  final bool error;
  final VoidCallback? onRetry;
  const _Splash({this.error = false, this.onRetry});
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final Animation<double> _emblemScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  );
  late final Animation<double> _emblemFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );
  late final Animation<double> _ring = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.15, 0.8, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// The brand gold of the logo and intro clip, and the ink drawn on it.
  static const _gold = Color(0xFFF0C11C);
  static const _ink = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _gold,
        body: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _pulse]),
            builder: (context, _) {
              final glow = 0.06 + 0.06 * _pulse.value;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The ring draws itself around the emblem.
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _RingPainter(
                            progress: _ring.value,
                            color: _ink,
                          ),
                        ),
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(
                                  alpha: glow * _emblemFade.value,
                                ),
                                blurRadius: 60,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        Opacity(
                          opacity: _emblemFade.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * _emblemScale.value,
                            child: widget.error
                                ? Icon(
                                    Icons.error_outline,
                                    color: _ink,
                                    size: 64,
                                  )
                                : Image.asset(
                                    'assets/branding/emblem_black.png',
                                    width: 118,
                                    excludeFromSemantics: true,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: _wordmark.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _wordmark.value)),
                      child: Column(
                        children: [
                          Text(
                            'BÍBLIA PATRÍSTICA',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 15,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A Escritura à luz da Tradição',
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.7),
                              fontSize: 12.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  if (!widget.error)
                    Opacity(
                      opacity: _wordmark.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 64,
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: _ink.withValues(alpha: 0.12),
                          color: _ink.withValues(
                            alpha: 0.55 + 0.35 * _pulse.value,
                          ),
                        ),
                      ),
                    )
                  else if (widget.onRetry != null)
                    IconButton.outlined(
                      onPressed: widget.onRetry,
                      iconSize: 26,
                      icon: const Icon(Icons.refresh),
                      color: _ink,
                      style: IconButton.styleFrom(
                        side: BorderSide(color: _ink.withValues(alpha: 0.5)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 2,
    );
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    // Starts at the top and closes clockwise.
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
