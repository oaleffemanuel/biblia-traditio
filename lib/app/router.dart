import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../core/theme/app_theme.dart';
import '../features/annotations/presentation/annotation_screens.dart';
import '../features/bible/presentation/bible_library_screen.dart';
import '../features/bible/presentation/chapters_screen.dart';
import '../features/bible/presentation/reader_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/liturgy/presentation/liturgy_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/reading_plan/presentation/reading_plan_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/attributions_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// The router, keyed on whether onboarding is complete. `Provider.family`
/// caches per value, so the instance is stable across unrelated rebuilds and
/// is recreated only when onboarding flips (→ initial route becomes /home).
final routerProvider = Provider.family<GoRouter, bool>((ref, completed) {
  return GoRouter(
    initialLocation: completed ? '/home' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) => _Scaffold(navShell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/liturgy', builder: (_, _) => const LiturgyScreen()),
          ]),
          StatefulShellBranch(routes: [
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
                        recordProgress:
                            s.uri.queryParameters['src'] == null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
          path: '/licenses', builder: (_, _) => const AttributionsScreen()),
      GoRoute(
          path: '/reading-plan',
          builder: (_, _) => const ReadingPlanScreen()),
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
    final c = context.bt;
    return Scaffold(
      body: navShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: navShell.currentIndex,
          onTap: (i) => navShell.goBranch(i,
              initialLocation: i == navShell.currentIndex),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: context.l10n.navHome),
            BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                activeIcon: const Icon(Icons.calendar_month),
                label: context.l10n.navLiturgy),
            BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_outlined),
                activeIcon: const Icon(Icons.menu_book),
                label: context.l10n.navBible),
          ],
        ),
      ),
    );
  }
}
