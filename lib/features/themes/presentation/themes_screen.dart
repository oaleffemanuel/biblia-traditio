import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/theme_providers.dart';
import '../domain/theme_library.dart';

/// The thematic index, as the back of a printed Bible sets it out: a search
/// field on top, then each section (Sacramentos, Maria…) folding open onto its
/// themes (Batismo, Eucaristia…). Searching opens every section that matches.
class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});

  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  String _query = '';
  final Set<String> _open = {};

  @override
  Widget build(BuildContext context) {
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
        data: (lib) {
          final q = foldForSearch(_query.trim());
          final searching = q.isNotEmpty;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  key: const ValueKey('themes-search'),
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.themesSearchHint,
                    hintStyle: TextStyle(color: c.textFaint),
                    prefixIcon: Icon(Icons.search, color: c.textFaint),
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    for (final g in lib.groups)
                      ..._group(context, c, g, lib.inGroup(g.id), q, searching),
                    if (searching && !lib.themes.any((t) => _matches(t, q)))
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.themesNoResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _matches(BibleTheme t, String q) =>
      foldForSearch(t.title).contains(q) ||
      t.subtopics.any((s) => foldForSearch(s.title).contains(q));

  List<Widget> _group(
    BuildContext context,
    BtColors c,
    ThemeGroup g,
    List<BibleTheme> themes,
    String q,
    bool searching,
  ) {
    final groupHit = searching && foldForSearch(g.title).contains(q);
    final shown = searching && !groupHit
        ? themes.where((t) => _matches(t, q)).toList()
        : themes;
    if (shown.isEmpty) return const [];
    final open = searching || _open.contains(g.id);
    return [
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: searching
            ? null
            : () => setState(() => open ? _open.remove(g.id) : _open.add(g.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  g.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${themes.length}',
                style: TextStyle(color: c.textFaint, fontSize: 13),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: open ? 0.25 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(Icons.chevron_right, color: c.gold),
              ),
            ],
          ),
        ),
      ),
      if (open)
        for (final t in shown) _ThemeRow(theme: t, query: q),
      Divider(height: 1, color: c.divider),
    ];
  }
}

/// Lowercase, accent-free form so "eucaristia" finds "Eucaristia" and
/// "oracao" finds "Oração".
String foldForSearch(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

class _ThemeRow extends StatelessWidget {
  final BibleTheme theme;
  final String query;
  const _ThemeRow({required this.theme, required this.query});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    // While searching, name the subtopic that matched so the reader sees why
    // the theme is listed.
    final subHits = query.isEmpty
        ? const <String>[]
        : [
            for (final s in theme.subtopics)
              if (foldForSearch(s.title).contains(query)) s.title,
          ];
    return Semantics(
      button: true,
      label: theme.title,
      child: InkWell(
        onTap: () => context.push('/themes/${theme.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 9, 8, 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subHits.isNotEmpty)
                      Text(
                        subHits.join(' · '),
                        style: TextStyle(color: c.accent, fontSize: 12.5),
                      )
                    else
                      Text(
                        l10n.themePassages(theme.passageCount),
                        style: TextStyle(color: c.textFaint, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
