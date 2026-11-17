import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/liquid_tab_bar.dart';

import '../core/l10n_ext.dart';
import '../features/annotations/presentation/annotation_screens.dart';
import '../features/bible/presentation/bible_library_screen.dart';
import '../features/bible/presentation/chapters_screen.dart';
import '../features/bible/presentation/reader_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/liturgy/presentation/liturgy_screen.dart';
import '../features/onboarding/presentation/intro_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/reading_plan/presentation/reading_plan_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/themes/presentation/theme_detail_screen.dart';
import '../features/themes/presentation/themes_icon.dart';
import '../features/themes/presentation/themes_screen.dart';
import '../features/settings/presentation/attributions_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'back_navigation.dart';

/// The router, keyed on whether onboarding is complete. `Provider.family`
/// caches per value, so the instance is stable across unrelated rebuilds and
/// is recreated only when onboarding flips (→ initial route becomes /home).
final routerProvider = Provider.family<GoRouter, bool>((ref, completed) {
  return GoRouter(
    // A fresh install opens on the intro clip, which hands over to onboarding.
    initialLocation: completed ? '/home' : '/intro',
    routes: [
      GoRoute(path: '/intro', builder: (_, _) => const IntroScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => _Scaffold(navShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/liturgy',
                builder: (_, _) => const LiturgyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/themes',
                builder: (_, _) => const ThemesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, st) =>
                        ThemeDetailScreen(themeId: st.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bible',
                builder: (_, _) => const BibleLibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':bookId',
                    builder: (_, s) =>
                        ChaptersScreen(bookId: s.pathParameters['bookId']!),
                    routes: [
                      GoRoute(
                        path: ':chapter',
                        builder: (_, s) => ReaderScreen(
                          bookId: s.pathParameters['bookId']!,
                          chapter: int.parse(s.pathParameters['chapter']!),
                          // ?src=liturgy|plan opens the reader in a separate
                          // context that must not overwrite "Continue reading".
                          recordProgress: s.uri.queryParameters['src'] == null,
                          // ?v=16 scrolls to (and briefly marks) that verse, so
                          // a note/favorite/search hit lands on the verse the
                          // reader asked for, not the top of the chapter.
                          focusVerse: int.tryParse(
                            s.uri.queryParameters['v'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/licenses', builder: (_, _) => const AttributionsScreen()),
      GoRoute(
        path: '/reading-plan',
        builder: (_, _) => const ReadingPlanScreen(),
      ),
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/highlights', builder: (_, _) => const HighlightsScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    ],
  );
});

class _Scaffold extends StatelessWidget {
  final StatefulNavigationShell navShell;
  const _Scaffold({required this.navShell});

  @override
  Widget build(BuildContext context) {
    return BackNavigationScope(
      navShell: navShell,
      child: Scaffold(
        // The glass bar floats over the content, which scrolls beneath it.
        extendBody: true,
        body: navShell,
        bottomNavigationBar: LiquidTabBar(
          index: navShell.currentIndex,
          onChanged: (i) => navShell.goBranch(i),
          onReselect: (i) => navShell.goBranch(i, initialLocation: true),
          tabs: [
            LiquidTab(
              label: context.l10n.navHome,
              icon: (c) => Icon(Icons.home_outlined, color: c, size: 26),
              selectedIcon: (c) => Icon(Icons.home, color: c, size: 26),
            ),
            LiquidTab(
              label: context.l10n.navLiturgy,
              icon: (c) =>
                  Icon(Icons.calendar_month_outlined, color: c, size: 25),
              selectedIcon: (c) =>
                  Icon(Icons.calendar_month, color: c, size: 25),
            ),
            LiquidTab(
              label: context.l10n.navThemes,
              icon: (c) => ImageIcon(kThemesIcon, color: c, size: 27),
              selectedIcon: (c) => ImageIcon(kThemesIcon, color: c, size: 27),
            ),
            LiquidTab(
              label: context.l10n.navBible,
              icon: (c) => Icon(Icons.menu_book_outlined, color: c, size: 26),
              selectedIcon: (c) => Icon(Icons.menu_book, color: c, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
