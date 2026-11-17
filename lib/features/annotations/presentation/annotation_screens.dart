import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/snack.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../application/annotation_providers.dart';
import '../domain/entities.dart';
import 'note_editor.dart';

String _ref(WidgetRef ref, VerseRef r) {
  final b = ref.read(bookByIdProvider(r.bookId));
  return '${b?.name ?? r.bookId} ${r.chapter},${r.verse}';
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final notes = ref.watch(allNotesProvider(_q.isEmpty ? null : _q));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notesScreenTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.searchNotesHint,
                hintStyle: TextStyle(color: c.textFaint),
                prefixIcon: Icon(Icons.search, color: c.textFaint),
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (notes.isEmpty)
            Expanded(
              child: _empty(c, Icons.note_outlined, context.l10n.noNotesYet),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: notes.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: c.divider),
                itemBuilder: (_, i) {
                  final n = notes[i];
                  return ListTile(
                    title: Text(
                      _ref(ref, n.ref),
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () =>
                        showNoteEditor(context, ref, n.ref, existing: n),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final favorites = ref.watch(allFavoritesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favoritesTitle)),
      body: favorites.isEmpty
          ? _empty(c, Icons.favorite_border, context.l10n.noFavoritesYet)
          : ListView.separated(
              itemCount: favorites.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
              itemBuilder: (_, i) {
                final f = favorites[i];
                return ListTile(
                  leading: Icon(Icons.favorite, color: c.accent, size: 20),
                  title: Text(
                    f.snapshot,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: context.l10n.unfavorite,
                    icon: Icon(Icons.close, size: 18, color: c.textFaint),
                    // Undoable rather than confirmed: removing a favorite is
                    // cheap to reverse, and a dialog for it would nag.
                    onPressed: () {
                      final ctrl = ref.read(annotationControllerProvider);
                      ctrl.toggleFavorite(f.ref, f.snapshot);
                      showSnack(
                        context.l10n.favoriteRemoved,
                        action: SnackBarAction(
                          label: context.l10n.actionUndo,
                          onPressed: () =>
                              ctrl.toggleFavorite(f.ref, f.snapshot),
                        ),
                      );
                    },
                  ),
                  onTap: () => context.push(
                    '/bible/${f.ref.bookId}/${f.ref.chapter}?v=${f.ref.verse}',
                  ),
                );
              },
            ),
    );
  }
}

class HighlightsScreen extends ConsumerWidget {
  const HighlightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    // Whole-verse colours and word/letter marks, newest first.
    final items = <({DateTime at, Highlight? verse, TextMark? mark})>[
      for (final h in ref.watch(allHighlightsProvider))
        (at: h.createdAt, verse: h, mark: null),
      for (final m in ref.watch(allTextMarksProvider))
        (at: m.createdAt, verse: null, mark: m),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.highlightsTitle)),
      body: items.isEmpty
          ? _empty(c, Icons.format_color_fill, context.l10n.noHighlightsYet)
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
              itemBuilder: (_, i) {
                final it = items[i];
                final ctrl = ref.read(annotationControllerProvider);
                final h = it.verse;
                final m = it.mark;
                final vref = h?.ref ?? m!.ref;
                final color = h?.color ?? m!.color;
                final excerpt = h?.excerpt ?? m?.excerpt;
                final underline = m?.style == MarkStyle.underline;
                return ListTile(
                  leading: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: underline ? null : color.color,
                      shape: BoxShape.circle,
                      border: underline
                          ? Border.all(color: color.color, width: 3)
                          : null,
                    ),
                  ),
                  title: Text(_ref(ref, vref)),
                  subtitle: (excerpt ?? '').isEmpty
                      ? null
                      : Text(
                          '“$excerpt”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: underline
                              ? TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationColor: color.color,
                                  decorationThickness: 2,
                                )
                              : null,
                        ),
                  trailing: IconButton(
                    tooltip: context.l10n.actionRemove,
                    icon: Icon(Icons.close, size: 18, color: c.textFaint),
                    onPressed: () {
                      if (m != null) {
                        ctrl.removeTextMark(m.uuid);
                        showSnack(
                          context.l10n.markRemoved,
                          action: SnackBarAction(
                            label: context.l10n.actionUndo,
                            onPressed: () => ctrl.restoreTextMarks([m.uuid]),
                          ),
                        );
                        return;
                      }
                      ctrl.removeHighlight(h!.ref);
                      showSnack(
                        context.l10n.highlightRemoved,
                        action: SnackBarAction(
                          label: context.l10n.actionUndo,
                          onPressed: () => ctrl.setHighlight(
                            h.ref,
                            h.color,
                            start: h.start,
                            end: h.end,
                            excerpt: h.excerpt,
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () => context.push(
                    '/bible/${vref.bookId}/${vref.chapter}?v=${vref.verse}',
                  ),
                );
              },
            ),
    );
  }
}

Widget _empty(BtColors c, IconData icon, String msg) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 44, color: c.textFaint),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(color: c.textSecondary)),
    ],
  ),
);
