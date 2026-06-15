import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../annotations/domain/entities.dart';
import '../../annotations/presentation/note_editor.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';
import 'widgets/share_verse.dart';

/// Verse-tap experience, redesigned around Tradition: the Church Fathers tab is
/// primary, personal notes are secondary, and the read/share/highlight actions
/// live in a slim bar at the bottom. "Read Scripture with the Church."
void showCommentaryPanel(BuildContext context, WidgetRef ref, VerseRef vref,
    {required String bookName, required String verseText}) {
  final c = context.bt;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _CommentaryPanel(
          vref: vref, bookName: bookName, verseText: verseText),
    ),
  );
}

enum _Filter { all, fathers, medieval, augustine, aquinas }

class _CommentaryPanel extends ConsumerStatefulWidget {
  final VerseRef vref;
  final String bookName;
  final String verseText;
  const _CommentaryPanel(
      {required this.vref, required this.bookName, required this.verseText});
  @override
  ConsumerState<_CommentaryPanel> createState() => _CommentaryPanelState();
}

class _CommentaryPanelState extends ConsumerState<_CommentaryPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  _Filter _filter = _Filter.all;
  bool _showColors = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _ref =>
      '${widget.bookName} ${widget.vref.chapter},${widget.vref.verse}';

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final commentaries = ref.watch(commentariesProvider(widget.vref));

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: c.divider, borderRadius: BorderRadius.circular(2))),
        // Header: the verse, quoted.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ref,
                        style: TextStyle(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('“${widget.verseText}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontSize: 16, height: 1.35)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: c.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          labelColor: c.accent,
          unselectedLabelColor: c.textSecondary,
          indicatorColor: c.accent,
          tabs: [Tab(text: l10n.churchFathers), Tab(text: l10n.myNotes)],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _FathersTab(
                commentaries: commentaries,
                filter: _filter,
                onFilter: (f) => setState(() => _filter = f),
                hasPatristics:
                    ref.watch(contentDatabaseProvider)?.hasPatristics ?? false,
              ),
              _NotesTab(vref: widget.vref),
            ],
          ),
        ),
        if (_showColors) _ColorRow(vref: widget.vref, onPick: _closeColors),
        _ActionBar(
          vref: widget.vref,
          reference: _ref,
          verseText: widget.verseText,
          onHighlight: () => setState(() => _showColors = !_showColors),
        ),
      ],
    );
  }

  void _closeColors() => setState(() => _showColors = false);
}

// ── Church Fathers tab ──────────────────────────────────────────────────────
class _FathersTab extends StatelessWidget {
  final List<Commentary> commentaries;
  final _Filter filter;
  final ValueChanged<_Filter> onFilter;
  final bool hasPatristics;
  const _FathersTab(
      {required this.commentaries,
      required this.filter,
      required this.onFilter,
      required this.hasPatristics});

  static int? _centuryInt(String roman) {
    if (roman.isEmpty) return null;
    const map = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100};
    var total = 0, prev = 0;
    for (var i = roman.length - 1; i >= 0; i--) {
      final v = map[roman[i].toUpperCase()];
      if (v == null) return null;
      if (v < prev) {
        total -= v;
      } else {
        total += v;
        prev = v;
      }
    }
    return total == 0 ? null : total;
  }

  static bool _matches(_Filter f, Commentary c) {
    final name = c.fatherName.toLowerCase();
    final cent = _centuryInt(c.century);
    return switch (f) {
      _Filter.all => true,
      _Filter.fathers => cent != null && cent <= 8,
      _Filter.medieval => cent != null && cent >= 9,
      _Filter.augustine =>
        name.contains('agostinho') || name.contains('augustin'),
      _Filter.aquinas => name.contains('aquin') || name.contains('tomás de aqu'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;

    if (commentaries.isEmpty) {
      return _Empty(
        icon: hasPatristics ? Icons.auto_stories_outlined : Icons.download,
        message:
            hasPatristics ? l10n.noCommentaryForVerse : l10n.patristicsNotInstalled,
      );
    }

    // Only offer filters that actually have results for THIS verse.
    final available = <_Filter>[
      _Filter.all,
      for (final f in [
        _Filter.fathers,
        _Filter.medieval,
        _Filter.augustine,
        _Filter.aquinas,
      ])
        if (commentaries.any((cm) => _matches(f, cm))) f,
    ];
    final effective = available.contains(filter) ? filter : _Filter.all;
    final shown =
        commentaries.where((cm) => _matches(effective, cm)).toList();

    String label(_Filter f) => switch (f) {
          _Filter.all => l10n.filterAll,
          _Filter.fathers => l10n.filterFathers,
          _Filter.medieval => l10n.filterMedieval,
          _Filter.augustine => l10n.filterAugustine,
          _Filter.aquinas => l10n.filterAquinas,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (available.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final f in available)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label(f)),
                      selected: effective == f,
                      onSelected: (_) => onFilter(f),
                      backgroundColor: c.surfaceHigh,
                      selectedColor: c.accentSoft,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                          color: effective == f ? c.accent : c.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Text(l10n.commentaryCount(shown.length),
              style: TextStyle(color: c.textFaint, fontSize: 12)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 22),
            itemBuilder: (_, i) => _CommentaryCard(shown[i]),
          ),
        ),
      ],
    );
  }
}

class _CommentaryCard extends StatelessWidget {
  final Commentary item;
  const _CommentaryCard(this.item);
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(item.fatherName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: c.accent, fontWeight: FontWeight.w600)),
          ),
          if (item.century.isNotEmpty)
            Text(context.l10n.century(item.century),
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(item.text,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontSize: 17, height: 1.5)),
        if (item.isMachineTranslation) ...[
          const SizedBox(height: 8),
          Text('${context.l10n.machineTranslation} · ${item.source ?? ''}',
              style: TextStyle(color: c.textFaint, fontSize: 11)),
        ],
      ],
    );
  }
}

// ── My Notes tab ────────────────────────────────────────────────────────────
class _NotesTab extends ConsumerWidget {
  final VerseRef vref;
  const _NotesTab({required this.vref});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final notes = ref.watch(notesForVerseProvider(vref));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showNoteEditor(context, ref, vref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.writeReflection),
              style: OutlinedButton.styleFrom(
                  foregroundColor: c.accent,
                  side: BorderSide(color: c.accent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ),
        if (notes.isEmpty)
          Expanded(
              child: _Empty(
                  icon: Icons.note_outlined, message: l10n.noNotesForVerse))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: notes.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
              itemBuilder: (_, i) {
                final n = notes[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(n.body,
                      maxLines: 4, overflow: TextOverflow.ellipsis),
                  onTap: () =>
                      showNoteEditor(context, ref, vref, existing: n),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Highlight color row (revealed from the action bar) ───────────────────────
class _ColorRow extends ConsumerWidget {
  final VerseRef vref;
  final VoidCallback onPick;
  const _ColorRow({required this.vref, required this.onPick});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final ctrl = ref.read(annotationControllerProvider);
    final highlighted = ref
        .watch(highlightsForChapterProvider(
            (bookId: vref.bookId, chapter: vref.chapter)))
        .containsKey(vref.verse);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: c.surfaceHigh.withValues(alpha: 0.4),
      child: Row(children: [
        for (final color in HighlightColor.values)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                ctrl.setHighlight(vref, color);
                onPick();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: color.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.divider)),
              ),
            ),
          ),
        const Spacer(),
        if (highlighted)
          IconButton(
            icon: Icon(Icons.format_color_reset, color: c.textSecondary),
            onPressed: () {
              ctrl.removeHighlight(vref);
              onPick();
            },
          ),
      ]),
    );
  }
}

// ── Slim verse-action bar ────────────────────────────────────────────────────
class _ActionBar extends ConsumerWidget {
  final VerseRef vref;
  final String reference;
  final String verseText;
  final VoidCallback onHighlight;
  const _ActionBar(
      {required this.vref,
      required this.reference,
      required this.verseText,
      required this.onHighlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final ctrl = ref.read(annotationControllerProvider);
    final favorite = ref.watch(isFavoriteProvider(vref));
    final bookmarked = ref.watch(isBookmarkedProvider(vref));

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.divider))),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _act(c, Icons.format_color_fill, c.textPrimary, onHighlight),
            _act(c, favorite ? Icons.favorite : Icons.favorite_border,
                favorite ? c.accent : c.textPrimary, () {
              ctrl.toggleFavorite(vref, '“$verseText”  ($reference)');
            }),
            _act(c, Icons.ios_share, c.textPrimary, () {
              showShareVerse(context, reference: reference, text: verseText);
            }),
            _act(c, Icons.copy, c.textPrimary, () {
              Clipboard.setData(
                  ClipboardData(text: '“$verseText”\n— $reference'));
            }),
            _act(c, bookmarked ? Icons.bookmark : Icons.bookmark_border,
                bookmarked ? c.accent : c.textPrimary,
                () => ctrl.toggleBookmark(vref)),
          ],
        ),
      ),
    );
  }

  Widget _act(BtColors c, IconData icon, Color color, VoidCallback onTap) =>
      IconButton(icon: Icon(icon, color: color), onPressed: onTap);
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  const _Empty({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: c.textFaint),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
