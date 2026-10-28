import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../application/theme_providers.dart';
import '../domain/theme_library.dart';

/// One theme: its summary and the passages, each with the opening verse from
/// the installed Bible and the number of patristic commentaries it carries.
class ThemeDetailScreen extends ConsumerWidget {
  final String themeId;
  const ThemeDetailScreen({super.key, required this.themeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final state = ref.watch(themeLibraryProvider);
    final theme = state.value?.byId(themeId);
    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.hasError || theme == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.themeLibraryLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(theme.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (theme.summary.isNotEmpty)
            Text(
              theme.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
            ),
          const SizedBox(height: 20),
          Text(
            l10n.themePassagesLabel.toUpperCase(),
            style: TextStyle(
              color: c.gold,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final p in theme.passages) _PassageCard(passage: p),
        ],
      ),
    );
  }
}

class _PassageCard extends ConsumerWidget {
  final ThemePassage passage;
  const _PassageCard({required this.passage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final content = ref.watch(
      chapterProvider((bookId: passage.bookId, chapter: passage.chapter)),
    );
    final count = ref.watch(passageCommentaryCountProvider(passage));
    String? opening;
    if (content != null) {
      for (final v in content.verses) {
        if (v.number == passage.verseStart) {
          opening = _clamp(v.text, 150);
          break;
        }
      }
    }
    return Semantics(
      button: true,
      label: '${passage.ref}. ${opening ?? ''}',
      child: InkWell(
        // The Bible reader lives inside the stateful bottom-navigation shell.
        // Replace the current external theme route instead of pushing a second
        // shell branch, which gives Navigator duplicate page keys.
        onTap: () => context.go(
          '/bible/${passage.bookId}/${passage.chapter}'
          '${passage.verseStart > 1 ? '?v=${passage.verseStart}' : ''}',
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage.ref,
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opening ?? l10n.themeNoText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16.5,
                        height: 1.4,
                        color: opening == null ? c.textFaint : null,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.themeCommentaryCount(count),
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
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

  static String _clamp(String t, int max) {
    final s = t.trim();
    if (s.length <= max) return s;
    final cut = s.lastIndexOf(' ', max);
    return '${s.substring(0, cut > 60 ? cut : max).trimRight()}…';
  }
}
