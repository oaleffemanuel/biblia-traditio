import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/snack.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_style.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../annotations/domain/entities.dart';
import '../../annotations/presentation/note_editor.dart';
import '../../bible/application/bible_providers.dart';
import '../../bible/domain/entities.dart';
import '../../bible/presentation/widgets/mark_toolbar.dart';
import '../../bible/presentation/widgets/text_mark_sheet.dart';
import '../../settings/application/settings_providers.dart';
import '../application/theme_providers.dart';
import '../domain/theme_library.dart';

/// One theme, in two tabs set out like the Bible's Old | New Testament
/// switch: **Versículos** (every passage, in full, where a word or phrase can
/// be highlighted by holding and dragging) | **Comentários** (the Fathers and
/// Doctors the compilers chose, with the work and place quoted).
class ThemeDetailScreen extends ConsumerStatefulWidget {
  final String themeId;
  const ThemeDetailScreen({super.key, required this.themeId});

  @override
  ConsumerState<ThemeDetailScreen> createState() => _ThemeDetailScreenState();
}

class _ThemeDetailScreenState extends ConsumerState<ThemeDetailScreen> {
  final _pages = PageController();
  int _tab = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() => _tab = i);
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final state = ref.watch(themeLibraryProvider);
    final theme = state.value?.byId(widget.themeId);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SegmentedPills(
              labels: [l10n.themeTabVerses, l10n.themeTabComments],
              value: _tab,
              onChanged: _select,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _tab = i),
              children: [
                _VersesTab(theme: theme),
                _CommentsTab(theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-or-more pill segments, the same control as the Bible's Testament
/// switch.
class SegmentedPills extends StatelessWidget {
  final List<String> labels;
  final int value;
  final ValueChanged<int> onChanged;
  const SegmentedPills({
    super.key,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == i,
                label: labels[i],
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: value == i ? c.surfaceHigh : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: value == i ? c.textPrimary : c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _label(BtColors c, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
  child: Text(
    text.toUpperCase(),
    style: TextStyle(
      color: c.gold,
      fontSize: 11,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w700,
    ),
  ),
);

// ── Versículos ─────────────────────────────────────────────────────────────

class _VersesTab extends StatelessWidget {
  final BibleTheme theme;
  const _VersesTab({required this.theme});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return ListView(
      key: const PageStorageKey('theme-verses'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (theme.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              theme.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
            ),
          ),
        if (theme.passages.isNotEmpty) ...[
          _label(c, l10n.themePassagesLabel),
          for (final p in theme.passages) _PassageCard(passage: p),
        ],
        for (final st in theme.subtopics)
          if (st.passages.isNotEmpty) ...[
            _label(c, st.title),
            for (final p in st.passages) _PassageCard(passage: p),
          ],
      ],
    );
  }
}

/// A passage in full. The reference opens it in the Bible; the verses are
/// selectable, and the selection menu paints just the chosen words (stored
/// with the reader's marks, so they show in the Bible too).
class _PassageCard extends ConsumerWidget {
  final ThemePassage passage;
  const _PassageCard({required this.passage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final key = (bookId: passage.bookId, chapter: passage.chapter);
    final content = ref.watch(chapterProvider(key));
    final marks = ref.watch(textMarksForChapterProvider(key));
    final count = ref.watch(passageCommentaryCountProvider(passage));
    final style = readingTextStyle(
      context,
      ref.watch(settingsProvider).readingFont,
    )?.copyWith(fontSize: 17, height: 1.5);
    final verses = [
      for (final v in content?.verses ?? const <Verse>[])
        if (v.number >= passage.verseStart && v.number <= passage.verseEnd) v,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            // The Bible reader lives inside the stateful bottom-navigation
            // shell: replace this route instead of pushing a second branch.
            onTap: () => context.go(
              '/bible/${passage.bookId}/${passage.chapter}'
              '${passage.verseStart > 1 ? '?v=${passage.verseStart}' : ''}',
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    passage.ref,
                    style: TextStyle(
                      color: c.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (count > 0) ...[
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
                    style: TextStyle(color: c.textSecondary, fontSize: 12),
                  ),
                ],
                Icon(Icons.chevron_right, color: c.textFaint, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (verses.isEmpty)
            Text(l10n.themeNoText, style: TextStyle(color: c.textFaint))
          else
            for (final v in verses)
              _MarkableVerse(
                vref: VerseRef(passage.bookId, passage.chapter, v.number),
                verse: v,
                marks: marks[v.number] ?? const [],
                style: style,
              ),
        ],
      ),
    );
  }
}

class _MarkableVerse extends ConsumerWidget {
  final VerseRef vref;
  final Verse verse;
  final List<TextMark> marks;
  final TextStyle? style;
  const _MarkableVerse({
    required this.vref,
    required this.verse,
    required this.marks,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final text = verse.text;
    final actions = VerseMarkActions(
      marks: marks,
      quick: (a, b, color) {
        final s = a.clamp(0, text.length), e = b.clamp(0, text.length);
        if (e <= s) return;
        ref
            .read(annotationControllerProvider)
            .addTextMark(
              vref,
              start: s,
              end: e,
              color: color,
              style: MarkStyle.highlight,
              excerpt: text.substring(s, e),
            );
      },
      more: (a, b) async {
        final s = a.clamp(0, text.length), e = b.clamp(0, text.length);
        if (e <= s) return;
        final action = await showTextMarkSheet(
          context,
          verseText: text,
          start: s,
          end: e,
          existing: marks,
          verseStyle: style,
        );
        if (action == null) return;
        HapticFeedback.lightImpact();
        final ctrl = ref.read(annotationControllerProvider);
        switch (action) {
          case AddTextMark(
            :final start,
            :final end,
            :final color,
            :final style,
          ):
            ctrl.addTextMark(
              vref,
              start: start,
              end: end,
              color: color,
              style: style,
              excerpt: text.substring(start, end),
            );
          case RemoveTextMarks(:final start, :final end):
            ctrl.removeTextMarksIn(vref, start, end);
        }
      },
      remove: (a, b) {
        final ctrl = ref.read(annotationControllerProvider);
        final ids = ctrl.removeTextMarksIn(vref, a, b);
        if (ids.isEmpty) return;
        showSnack(
          context.l10n.markRemoved,
          action: SnackBarAction(
            label: context.l10n.actionUndo,
            onPressed: () => ctrl.restoreTextMarks(ids),
          ),
        );
      },
      note: () => showNoteEditor(context, ref, vref),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${verse.number}',
                style: TextStyle(
                  color: c.accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: applyTextMarks(
                  [TextSpan(text: text, style: style)],
                  marks,
                  text: text,
                ),
              ),
              contextMenuBuilder: (ctx, state) =>
                  verseContextMenu(ctx, state, actions),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comentários ────────────────────────────────────────────────────────────

class _CommentsTab extends StatelessWidget {
  final BibleTheme theme;
  const _CommentsTab({required this.theme});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    if (theme.commentCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.themeNoComments,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary),
          ),
        ),
      );
    }
    return ListView(
      key: const PageStorageKey('theme-comments'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (theme.comments.isNotEmpty) ...[
          _label(c, theme.title),
          for (final cm in theme.comments) _CommentCard(comment: cm),
        ],
        for (final st in theme.subtopics)
          if (st.comments.isNotEmpty) ...[
            _label(c, st.title),
            for (final cm in st.comments) _CommentCard(comment: cm),
          ],
      ],
    );
  }
}

/// A commentary on the theme: author, role and date always visible, then the
/// work and place quoted; the text folds to a few lines until tapped.
class _CommentCard extends StatefulWidget {
  final ThemeComment comment;
  const _CommentCard({required this.comment});
  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final cm = widget.comment;
    final meta = [cm.role, cm.edition].where((x) => x.isNotEmpty).join(' · ');
    final source = [
      cm.document,
      cm.location,
    ].where((x) => x.isNotEmpty).join(' — ');
    return InkWell(
      onTap: () => setState(() => _open = !_open),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cm.author,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (meta.isNotEmpty)
              Text(meta, style: TextStyle(color: c.textFaint, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              cm.text,
              maxLines: _open ? null : 6,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 16.5, height: 1.45),
            ),
            if (_open && source.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                source,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (!_open) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.themeReadMore,
                style: TextStyle(color: c.accent, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
