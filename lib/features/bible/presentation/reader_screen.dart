import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../annotations/domain/entities.dart';
import '../../annotations/presentation/note_editor.dart';
import '../../settings/application/settings_providers.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';
import 'widgets/book_emblem.dart';
import 'widgets/navigation_pickers.dart';
import 'widgets/share_verse.dart';
import 'patristic_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;
  const ReaderScreen({super.key, required this.bookId, required this.chapter});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _scrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translation = ref.read(resolvedTranslationIdProvider);
      ref.read(annotationControllerProvider).recordProgress(
          translation, VerseRef(widget.bookId, widget.chapter, 1));
    });
  }

  @override
  void didUpdateWidget(ReaderScreen old) {
    super.didUpdateWidget(old);
    // GoRouter reuses this State across chapters; reset to the top and record
    // the new position when the book/chapter changes.
    if (old.bookId != widget.bookId || old.chapter != widget.chapter) {
      if (_scrollController.isAttached) _scrollController.jumpTo(index: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final t = ref.read(resolvedTranslationIdProvider);
        ref.read(annotationControllerProvider).recordProgress(
            t, VerseRef(widget.bookId, widget.chapter, 1));
      });
    }
  }

  void _goTo(String bookId, int chapter) =>
      context.go('/bible/$bookId/$chapter');

  Future<void> _pickBook() async {
    final id = await showBookPicker(context, ref, widget.bookId);
    if (id != null && mounted) _goTo(id, 1);
  }

  Future<void> _pickChapter(BibleBook book) async {
    final n = await showChapterPicker(
        context, book.name, book.chapterCount, widget.chapter);
    if (n != null && mounted) _goTo(book.id, n);
  }

  Future<void> _pickVerse(int verseCount) async {
    final n = await showVersePicker(context, verseCount, 1);
    if (n != null && _scrollController.isAttached) {
      _scrollController.scrollTo(
          index: n, duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final bookId = widget.bookId;
    final chapter = widget.chapter;
    final book = ref.watch(bookByIdProvider(bookId));
    final content =
        ref.watch(chapterProvider((bookId: bookId, chapter: chapter)));
    final markers =
        ref.watch(commentaryMarkersProvider((bookId: bookId, chapter: chapter)));
    final highlights =
        ref.watch(highlightsForChapterProvider((bookId: bookId, chapter: chapter)));

    final headingByVerse = <int, SectionHeading>{
      for (final h in content?.headings ?? const []) h.beforeVerse: h,
    };
    final verses = content?.verses ?? const <Verse>[];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          _pill(
              c,
              book?.testament == Testament.nt
                  ? context.l10n.newTestamentShort
                  : context.l10n.oldTestamentShort,
              onTap: _pickBook),
          const SizedBox(width: 6),
          Flexible(
              child: _pill(c, book?.name ?? bookId, onTap: _pickBook)),
        ]),
        actions: [
          if (book != null)
            _pill(c, '$chapter', onTap: () => _pickChapter(book)),
          IconButton(
            icon: Icon(Icons.format_list_numbered,
                color: c.textSecondary, size: 20),
            tooltip: context.l10n.goToVerse,
            onPressed: verses.isEmpty ? null : () => _pickVerse(verses.length),
          ),
        ],
      ),
      body: SafeArea(
        child: (content == null)
            ? _NoText(c)
            : ScrollablePositionedList.builder(
                itemScrollController: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                itemCount: verses.length + 2, // header + verses + footer
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _Header(bookId: bookId, book: book, chapter: chapter);
                  }
                  if (index == verses.length + 1) {
                    return _ChapterNav(
                      book: book,
                      chapter: chapter,
                      onGo: _goTo,
                    );
                  }
                  final v = verses[index - 1];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (headingByVerse[v.number] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 10),
                          child: Text(_titleCase(headingByVerse[v.number]!.text),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      _VerseTile(
                        verse: v,
                        hasCommentary: markers.contains(v.number),
                        highlight: highlights[v.number],
                        onTap: () =>
                            _showVerseActions(context, book?.name ?? bookId, v),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  void _showVerseActions(BuildContext context, String bookName, Verse v) {
    final c = context.bt;
    final vref = VerseRef(widget.bookId, widget.chapter, v.number);
    final ctrl = ref.read(annotationControllerProvider);
    final fullRef = '$bookName ${widget.chapter},${v.number}';
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Consumer(builder: (ctx, r, _) {
        // Reactive: if a patristics pack is installed while this sheet is open,
        // the "Padres da Igreja" entry enables itself without a reopen.
        final count = r.watch(commentariesProvider(vref)).length;
        final bookmarked = r.watch(isBookmarkedProvider(vref));
        final favorite = r.watch(isFavoriteProvider(vref));
        final notes = r.watch(notesForVerseProvider(vref));
        final highlighted = r
            .watch(highlightsForChapterProvider(
                (bookId: vref.bookId, chapter: vref.chapter)))
            .containsKey(v.number);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: c.divider,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                _HighlightRow(
                  active: highlighted,
                  onPick: (color) {
                    ctrl.setHighlight(vref, color);
                    Navigator.pop(sheetCtx);
                  },
                  onClear: () {
                    ctrl.removeHighlight(vref);
                    Navigator.pop(sheetCtx);
                  },
                ),
                Divider(height: 1, color: c.divider),
                ListTile(
                  leading: Icon(Icons.ios_share, color: c.textPrimary),
                  title: Text(ctx.l10n.share),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    showShareVerse(context, reference: fullRef, text: v.text);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy, color: c.textPrimary),
                  title: Text(ctx.l10n.copyVerse),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: '“${v.text}”\n— $fullRef'));
                    Navigator.pop(sheetCtx);
                  },
                ),
                ListTile(
                  leading: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: favorite ? c.accent : c.textPrimary),
                  title: Text(favorite ? ctx.l10n.unfavorite : ctx.l10n.favorite),
                  onTap: () {
                    ctrl.toggleFavorite(vref, '“${v.text}”  ($fullRef)');
                    Navigator.pop(sheetCtx);
                  },
                ),
                ListTile(
                  leading: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: bookmarked ? c.accent : c.textPrimary),
                  title: Text(bookmarked ? ctx.l10n.unbookmark : ctx.l10n.bookmark),
                  onTap: () {
                    ctrl.toggleBookmark(vref);
                    Navigator.pop(sheetCtx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.note_add_outlined, color: c.textPrimary),
                  title: Text(notes.isEmpty
                      ? ctx.l10n.note
                      : ctx.l10n.notesWithCount(notes.length)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    showNoteEditor(context, ref, vref,
                        existing: notes.isEmpty ? null : notes.first);
                  },
                ),
                ListTile(
                  enabled: count > 0,
                  leading: Icon(Icons.auto_stories,
                      color: count > 0 ? c.accent : c.textFaint),
                  title: Text(ctx.l10n.churchFathers,
                      style: TextStyle(
                          color: count > 0 ? c.textPrimary : c.textFaint)),
                  trailing: count > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: c.accentSoft,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('$count',
                              style: TextStyle(
                                  color: c.accent,
                                  fontWeight: FontWeight.w600)))
                      : null,
                  onTap: count == 0
                      ? null
                      : () {
                          Navigator.pop(sheetCtx);
                          showPatristicSheet(context, vref, bookName);
                        },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }),
    );
  }

  static Widget _pill(BtColors c, String text, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: c.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textSecondary, fontSize: 13))),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.expand_more, size: 14, color: c.textFaint),
              ),
          ]),
        ),
      );

  static String _titleCase(String s) {
    if (s != s.toUpperCase()) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _Header extends StatelessWidget {
  final String bookId;
  final BibleBook? book;
  final int chapter;
  const _Header({required this.bookId, required this.book, required this.chapter});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Column(children: [
      const SizedBox(height: 12),
      BookEmblem(bookId: bookId, abbrev: book?.abbrev ?? '', size: 96),
      const SizedBox(height: 16),
      Text(book?.name ?? bookId,
          style: Theme.of(context).textTheme.headlineMedium),
      Text(context.l10n.chapterTitle(chapter),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: c.textSecondary)),
      const SizedBox(height: 28),
    ]);
  }
}

class _ChapterNav extends StatelessWidget {
  final BibleBook? book;
  final int chapter;
  final void Function(String, int) onGo;
  const _ChapterNav(
      {required this.book, required this.chapter, required this.onGo});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    if (book == null) return const SizedBox.shrink();
    final hasPrev = chapter > 1;
    final hasNext = chapter < book!.chapterCount;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: hasPrev ? () => onGo(book!.id, chapter - 1) : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(context.l10n.previous),
            style: TextButton.styleFrom(
                foregroundColor: hasPrev ? c.accent : c.textFaint),
          ),
          Text('${book!.name} $chapter',
              style: TextStyle(color: c.textFaint, fontSize: 12)),
          TextButton.icon(
            onPressed: hasNext ? () => onGo(book!.id, chapter + 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(context.l10n.next),
            style: TextButton.styleFrom(
                foregroundColor: hasNext ? c.accent : c.textFaint),
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final bool active;
  final ValueChanged<HighlightColor> onPick;
  final VoidCallback onClear;
  const _HighlightRow(
      {required this.active, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          for (final color in HighlightColor.values)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => onPick(color),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.divider),
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (active)
            IconButton(
              onPressed: onClear,
              icon: Icon(Icons.format_color_reset, color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  final Verse verse;
  final bool hasCommentary;
  final HighlightColor? highlight;
  final VoidCallback onTap;
  const _VerseTile(
      {required this.verse,
      required this.hasCommentary,
      required this.highlight,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: highlight == null
            ? null
            : BoxDecoration(
                color: highlight!.color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: Text('${verse.number}',
                    style: TextStyle(
                        color: c.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            TextSpan(
                text: verse.text,
                style: Theme.of(context).textTheme.bodyLarge),
            if (hasCommentary)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.auto_stories,
                      size: 14, color: c.accent.withValues(alpha: 0.7)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _NoText extends StatelessWidget {
  final BtColors c;
  const _NoText(this.c);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.scriptureNotInstalled,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, height: 1.5),
          ),
        ),
      );
}
