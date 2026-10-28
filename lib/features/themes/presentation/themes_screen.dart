import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/theme_providers.dart';
import '../domain/theme_library.dart';

/// The thematic index — themes grouped as a printed Bible's topical index is.
class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final state = ref.watch(themeLibraryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.themesTitle)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.themeLibraryLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
          ),
        ),
        data: (lib) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              l10n.themesSubtitle,
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            for (final g in lib.groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 26, 0, 8),
                child: Row(
                  children: [
                    Text(
                      g.title.toUpperCase(),
                      style: TextStyle(
                        color: c.gold,
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: c.gold.withValues(alpha: 0.28),
                      ),
                    ),
                  ],
                ),
              ),
              for (final t in lib.inGroup(g.id)) _ThemeRow(theme: t),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final BibleTheme theme;
  const _ThemeRow({required this.theme});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: theme.title,
      child: InkWell(
        onTap: () => context.push('/themes/${theme.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.themePassages(theme.passages.length),
                      style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
