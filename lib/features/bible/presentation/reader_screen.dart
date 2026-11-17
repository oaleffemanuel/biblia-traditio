import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/snack.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/reading_style.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../annotations/domain/entities.dart';
import '../../settings/presentation/parallel_table.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/settings.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';
import '../domain/psalm_numbering.dart';
import '../../annotations/presentation/note_editor.dart';
import 'commentary_panel.dart';
import 'widgets/book_emblem.dart';
import 'widgets/navigation_pickers.dart';
import 'widgets/scripts.dart';
import 'widgets/share_verse.dart';
import 'widgets/mark_toolbar.dart';
import 'widgets/text_mark_sheet.dart';

/// Muted gold marking verses that carry Church Fathers commentary.
const Color _kGold = Color(0xFFCBA45A);

/// " (23)" beside a Vulgate psalm so readers who know the Hebrew/modern number
/// still recognise it; empty for non-psalms and for psalms that coincide.
String _psalmSuffix(String bookId, int chapter) {
  if (bookId != 'ps') return '';
  final h = PsalmNumbering.hebrewLabel(chapter);
  return h == null ? '' : ' ($h)';
}

/// Below this width phones get the stacked Parallel layout; at/above it (tablet,
/// landscape) side-by-side columns are the default.
const double _kSideBySideMinWidth = 600;

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;

  /// Whether opening this chapter updates Home → "Continue reading". True for
  /// personal Bible browsing; false when opened from a separate context
  /// (Liturgy, Reading Plan) so those never overwrite the user's own position.
  final bool recordProgress;

  /// Verse to open at, from `?v=`. The reader scrolls to it and marks it
  /// briefly so the eye lands where the tap promised.
  final int? focusVerse;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.recordProgress = true,
    this.focusVerse,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _scrollController = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  Timer? _progressTimer;

  /// Multi-verse selection. Long-pressing a verse sets the anchor; tapping
  /// another verse moves the far end, so the selection is a continuous span by
  /// construction — "John 1:1–5" can never come out as a scattered list.
  int? _selAnchor;
  int? _selEnd;

  /// The verse arrived at via `?v=`, highlighted until the reader moves on.
  int? _focused;
  Timer? _focusTimer;

  // Triple tap on a verse selects it whole, WhatsApp-style, ready to share
  // as an image. A single tap still opens the commentary, after a short wait
  // that lets a second or third tap arrive.
  int? _tapVerse;
  int _tapCount = 0;
  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _tapTimer;
  static const _multiTapWindow = Duration(milliseconds: 380);

  DateTime _downAt = DateTime.fromMillisecondsSinceEpoch(0);
  Offset _downPos = Offset.zero;

  void _onVersePointerDown(PointerDownEvent e) {
    _downAt = DateTime.now();
    _downPos = e.position;
  }

  /// Only quick, still taps count towards the triple tap — a long press, a
  /// drag of the selection handles or a scroll never does.
  void _onVersePointerUp(int number, PointerUpEvent e) {
    final quick =
        DateTime.now().difference(_downAt) < const Duration(milliseconds: 260);
    final still = (e.position - _downPos).distance < 14;
    if (!quick || !still) {
      _tapCount = 0;
      _tapTimer?.cancel();
      return;
    }
    _countTap(number);
  }

  void _countTap(int number) {
    final now = DateTime.now();
    if (_tapVerse == number && now.difference(_lastTapAt) < _multiTapWindow) {
      _tapCount++;
    } else {
      _tapVerse = number;
      _tapCount = 1;
    }
    _lastTapAt = now;
    if (_tapCount >= 2) _tapTimer?.cancel();
    if (_tapCount == 3) {
      _tapCount = 0;
      ContextMenuController.removeAny();
      if (_selecting) {
        _extendSelection(number);
      } else {
        _startSelection(number);
      }
    }
  }

  void _onVerseTap(int number, VoidCallback openCommentary) {
    if (_selecting) {
      _extendSelection(number);
      return;
    }
    _tapTimer?.cancel();
    _tapTimer = Timer(_multiTapWindow, () {
      if (mounted && !_selecting && _tapCount <= 1) openCommentary();
    });
  }

  bool get _selecting => _selAnchor != null;
  int get _selFrom => _selAnchor! <= _selEnd! ? _selAnchor! : _selEnd!;
  int get _selTo => _selAnchor! <= _selEnd! ? _selEnd! : _selAnchor!;
  bool _isSelected(int verse) =>
      _selecting && verse >= _selFrom && verse <= _selTo;

  void _startSelection(int verse) {
    // The long-press changes what a tap means, so it earns a tick of feedback.
    HapticFeedback.selectionClick();
    setState(() => _selAnchor = _selEnd = verse);
  }

  void _extendSelection(int verse) => setState(() => _selEnd = verse);
  void _clearSelection() => setState(() {
    _selAnchor = _selEnd = null;
    _showColors = false;
  });

  /// Used when the chapter changes underneath a live selection — the verses it
  /// pointed at are gone, so it must not survive into the new chapter.
  void _clearSelectionSilently() {
    _selAnchor = _selEnd = null;
    _showColors = false;
  }

  /// Whether the highlight colour bar is open under the action row.
  bool _showColors = false;

  /// The selected verses, in order, with their canonical text.
  List<({int number, String text})> _selectedVerses(
    List<Verse> verses,
    List<ParallelVerse> rows,
    bool parallelActive,
  ) {
    final all = parallelActive
        ? [for (final r in rows) (number: r.number, text: r.canonicalText)]
        : [for (final v in verses) (number: v.number, text: v.text)];
    return all.where((v) => _isSelected(v.number)).toList();
  }

  String _selectionReference(BibleBook? book) {
    final name = book?.name ?? widget.bookId;
    final span = _selFrom == _selTo ? '$_selFrom' : '$_selFrom-$_selTo';
    return '$name ${widget.chapter},$span';
  }

  void _copySelection(
    BibleBook? book,
    List<({int number, String text})> picked,
  ) {
    if (picked.isEmpty) return;
    Clipboard.setData(
      ClipboardData(
        text: formatPassageForClipboard(
          reference: _selectionReference(book),
          verses: picked,
        ),
      ),
    );
    _clearSelection();
    showSnack(context.l10n.copied);
  }

  /// One tap paints every selected verse and closes the bar — the whole point
  /// of the colour row is that it costs a single gesture.
  void _highlightSelection(
    List<({int number, String text})> picked,
    HighlightColor color,
  ) {
    HapticFeedback.lightImpact();
    final ctrl = ref.read(annotationControllerProvider);
    for (final v in picked) {
      ctrl.setHighlight(
        VerseRef(widget.bookId, widget.chapter, v.number),
        color,
      );
    }
    _clearSelection();
  }

  /// The selection menu's actions for one verse: a colour paints at once,
  /// "Sublinhar ou ajustar" opens the sheet, "Remover grifo" clears the span.
  VerseMarkActions _markActions(int number, String text, List<TextMark> marks) {
    final vref = VerseRef(widget.bookId, widget.chapter, number);
    return VerseMarkActions(
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
      more: (a, b) => _highlightRange(number, text, a, b),
      remove: (a, b) => _removeMarks(vref, a, b),
      note: () => showNoteEditor(context, ref, vref),
    );
  }

  void _removeMarks(VerseRef vref, int a, int b) {
    final ctrl = ref.read(annotationControllerProvider);
    final ids = ctrl.removeTextMarksIn(vref, a, b);
    if (ids.isEmpty || !mounted) return;
    showSnack(
      context.l10n.markRemoved,
      action: SnackBarAction(
        label: context.l10n.actionUndo,
        onPressed: () => ctrl.restoreTextMarks(ids),
      ),
    );
  }

  /// Word/letter mark: the reader selected text inside one verse and chose
  /// "Sublinhar ou ajustar" from the selection menu. The sheet lets them trim the
  /// span down to a single letter, pick highlighter or underline and a colour.
  /// Marks accumulate — marking another word never erases the first.
  Future<void> _highlightRange(
    int number,
    String text,
    int start,
    int end,
  ) async {
    final a = start.clamp(0, text.length);
    final b = end.clamp(0, text.length);
    if (b <= a) return;
    final vref = VerseRef(widget.bookId, widget.chapter, number);
    final existing =
        ref.read(
          textMarksForChapterProvider((
            bookId: widget.bookId,
            chapter: widget.chapter,
          )),
        )[number] ??
        const <TextMark>[];
    final action = await showTextMarkSheet(
      context,
      verseText: text,
      start: a,
      end: b,
      existing: existing,
      verseStyle: readingTextStyle(
        context,
        ref.read(settingsProvider).readingFont,
      ),
    );
    if (action == null || !mounted) return;
    HapticFeedback.lightImpact();
    final ctrl = ref.read(annotationControllerProvider);
    switch (action) {
      case AddTextMark(:final start, :final end, :final color, :final style):
        ctrl.addTextMark(
          vref,
          start: start,
          end: end,
          color: color,
          style: style,
          excerpt: text.substring(start, end),
        );
      case RemoveTextMarks(:final start, :final end):
        _removeMarks(vref, start, end);
    }
  }

  void _noteSelection(List<({int number, String text})> picked) {
    if (picked.isEmpty) return;
    final vref = VerseRef(widget.bookId, widget.chapter, picked.first.number);
    _clearSelection();
    showNoteEditor(context, ref, vref);
  }

  void _favoriteSelection(
    BibleBook? book,
    List<({int number, String text})> picked,
  ) {
    if (picked.isEmpty) return;
    final ctrl = ref.read(annotationControllerProvider);
    final reference = _selectionReference(book);
    for (final v in picked) {
      ctrl.toggleFavorite(
        VerseRef(widget.bookId, widget.chapter, v.number),
        '“${v.text}”  ($reference)',
      );
    }
    _clearSelection();
    showSnack(context.l10n.favorite);
  }

  /// Shares the selected span as one card, refusing politely when the passage
  /// is longer than an image can carry legibly.
  void _shareSelection(
    BibleBook? book,
    List<Verse> verses,
    List<ParallelVerse> rows,
    bool parallelActive,
  ) {
    final all = parallelActive
        ? [for (final r in rows) (number: r.number, text: r.canonicalText)]
        : [for (final v in verses) (number: v.number, text: v.text)];
    final picked = all.where((v) => _isSelected(v.number)).toList();
    if (picked.isEmpty) return;
    if (passageLength(picked) > kMaxShareSelectionChars) {
      showSnack(context.l10n.shareSelectionTooLong(kMaxShareSelectionChars));
      return;
    }
    final name = book?.name ?? widget.bookId;
    final span = _selFrom == _selTo ? '$_selFrom' : '$_selFrom-$_selTo';
    showSharePassage(
      context,
      reference: '$name ${widget.chapter},$span',
      verses: picked,
    );
    _clearSelection();
  }

  void _maybeRecord([int verse = 1]) {
    if (!widget.recordProgress) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final t = ref.read(resolvedTranslationIdProvider);
      ref
          .read(annotationControllerProvider)
          .recordProgress(t, VerseRef(widget.bookId, widget.chapter, verse));
    });
  }

  /// Records the verse actually at the top of the viewport, so "Continue
  /// reading" comes back to where the reader stopped rather than to verse 1.
  /// Debounced — scrolling a chapter shouldn't be hundreds of writes.
  void _onScroll() {
    if (!widget.recordProgress) return;
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final visible = _positions.itemPositions.value
          .where((p) => p.itemLeadingEdge < 0.5)
          .toList();
      if (visible.isEmpty) return;
      // Index 0 is the chapter header; verse n sits at index n.
      final top = visible
          .map((p) => p.index)
          .where((i) => i >= 1)
          .fold<int>(1 << 30, (a, b) => a < b ? a : b);
      if (top == 1 << 30) return;
      _maybeRecord(top);
    });
  }

  @override
  void initState() {
    super.initState();
    _maybeRecord();
    _focusRequestedVerse();
    _positions.itemPositions.addListener(_onScroll);
  }

  /// Scrolls to `?v=` once the list is attached, and marks the verse for a few
  /// seconds. Verse n sits at list index n (index 0 is the chapter header).
  void _focusRequestedVerse() {
    final v = widget.focusVerse;
    if (v == null || v < 1) return;
    setState(() => _focused = v);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.scrollTo(
          index: v,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _focused = null);
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _tapTimer?.cancel();
    _progressTimer?.cancel();
    _positions.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(ReaderScreen old) {
    super.didUpdateWidget(old);
    // GoRouter reuses this State across chapters; reset to the top and record
    // the new position when the book/chapter changes.
    if (old.bookId != widget.bookId || old.chapter != widget.chapter) {
      if (_scrollController.isAttached) _scrollController.jumpTo(index: 0);
      _maybeRecord();
      _clearSelectionSilently();
      _focusRequestedVerse();
    } else if (old.focusVerse != widget.focusVerse) {
      _focusRequestedVerse();
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
      context,
      book.name,
      book.chapterCount,
      widget.chapter,
    );
    if (n != null && mounted) _goTo(book.id, n);
  }

  Future<void> _pickVerse(int verseCount) async {
    final n = await showVersePicker(context, verseCount, 1);
    if (n != null && _scrollController.isAttached) {
      _scrollController.scrollTo(
        index: n,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showParallelOptions() {
    final c = context.bt;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ParallelOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final bookId = widget.bookId;
    final chapter = widget.chapter;
    final book = ref.watch(bookByIdProvider(bookId));
    final content = ref.watch(
      chapterProvider((bookId: bookId, chapter: chapter)),
    );
    final markers = ref.watch(
      commentaryMarkersProvider((bookId: bookId, chapter: chapter)),
    );
    final highlights = ref.watch(
      highlightsForChapterProvider((bookId: bookId, chapter: chapter)),
    );
    final textMarks = ref.watch(
      textMarksForChapterProvider((bookId: bookId, chapter: chapter)),
    );

    final settings = ref.watch(settingsProvider);
    final secondaryId = ref.watch(secondaryTranslationForBookProvider(bookId));
    final parallelWanted = settings.parallelReadingEnabled;
    final parallelActive = parallelWanted && secondaryId != null;
    final parallel = parallelActive
        ? ref.watch(parallelChapterProvider((bookId: bookId, chapter: chapter)))
        : null;

    // Language codes drive script handling (Hebrew RTL, Greek/Hebrew font
    // fallbacks). Empty when a translation isn't installed — then the ambient
    // left-to-right layout applies, unchanged.
    final translations = ref.watch(availableTranslationsProvider);
    String langOf(String? id) => id == null
        ? ''
        : translations
                  .where((t) => t.id == id)
                  .map((t) => t.lang)
                  .firstOrNull ??
              '';
    final primaryLang = langOf(ref.watch(resolvedTranslationIdProvider));
    final secondaryLang = langOf(secondaryId);

    final headingByVerse = <int, SectionHeading>{
      for (final h in content?.headings ?? const []) h.beforeVerse: h,
    };
    final verses = content?.verses ?? const <Verse>[];
    final rows = parallel?.rows ?? const <ParallelVerse>[];
    final verseCount = parallelActive ? rows.length : verses.length;

    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(
          mq.textScaler.scale(1) * settings.fontScale,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          // Book abbreviation + chapter only ("Gn · 1"): the Testament pill
          // was redundant with the book picker it opened.
          title: Row(
            children: [
              _pill(
                c,
                (book?.abbrev.isNotEmpty ?? false)
                    ? book!.abbrev
                    : (book?.name ?? bookId),
                onTap: _pickBook,
              ),
              const SizedBox(width: 6),
              if (book != null)
                _pill(
                  c,
                  '$chapter${_psalmSuffix(bookId, chapter)}',
                  onTap: () => _pickChapter(book),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.view_column_outlined,
                color: parallelActive ? c.accent : c.textSecondary,
                size: 20,
              ),
              tooltip: context.l10n.parallelReading,
              onPressed: _showParallelOptions,
            ),
            IconButton(
              icon: Icon(
                Icons.format_list_numbered,
                color: c.textSecondary,
                size: 20,
              ),
              tooltip: context.l10n.goToVerse,
              onPressed: verseCount == 0 ? null : () => _pickVerse(verseCount),
            ),
          ],
        ),
        body: SafeArea(
          child: (content == null)
              ? _NoText(c)
              : Column(
                  children: [
                    // Parallel requested but no second translation is installed:
                    // keep the primary readable, point the user to Settings.
                    if (parallelWanted && secondaryId == null)
                      const _SecondaryMissingBanner(),
                    Expanded(
                      child: _buildList(
                        context: context,
                        book: book,
                        bookId: bookId,
                        chapter: chapter,
                        verses: verses,
                        rows: rows,
                        parallelActive: parallelActive,
                        headingByVerse: headingByVerse,
                        markers: markers,
                        highlights: highlights,
                        textMarks: textMarks,
                        primaryLang: primaryLang,
                        secondaryLang: secondaryLang,
                      ),
                    ),
                    if (_selecting)
                      _SelectionBar(
                        count: _selTo - _selFrom + 1,
                        showColors: _showColors,
                        onClear: _clearSelection,
                        onToggleColors: () =>
                            setState(() => _showColors = !_showColors),
                        onCopy: () => _copySelection(
                          book,
                          _selectedVerses(verses, rows, parallelActive),
                        ),
                        onShare: () =>
                            _shareSelection(book, verses, rows, parallelActive),
                        onNote: () => _noteSelection(
                          _selectedVerses(verses, rows, parallelActive),
                        ),
                        onFavorite: () => _favoriteSelection(
                          book,
                          _selectedVerses(verses, rows, parallelActive),
                        ),
                        onPickColor: (color) => _highlightSelection(
                          _selectedVerses(verses, rows, parallelActive),
                          color,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildList({
    required BuildContext context,
    required BibleBook? book,
    required String bookId,
    required int chapter,
    required List<Verse> verses,
    required List<ParallelVerse> rows,
    required bool parallelActive,
    required Map<int, SectionHeading> headingByVerse,
    required Set<int> markers,
    required Map<int, HighlightMark> highlights,
    required Map<int, List<TextMark>> textMarks,
    required String primaryLang,
    required String secondaryLang,
  }) {
    final readingStyle = readingTextStyle(
      context,
      ref.watch(settingsProvider).readingFont,
    );
    final count = parallelActive ? rows.length : verses.length;
    final sideBySide = parallelActive && _sideBySide(context);

    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      itemPositionsListener: _positions,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
      itemCount: count + 2, // header + verses + footer
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Header(bookId: bookId, book: book, chapter: chapter);
        }
        if (index == count + 1) {
          return _ChapterNav(book: book, chapter: chapter, onGo: _goTo);
        }
        final number = parallelActive
            ? rows[index - 1].number
            : verses[index - 1].number;
        final heading = headingByVerse[number];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null)
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 10),
                child: Text(
                  _titleCase(heading.text),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            // While a selection is open, tapping extends it instead of opening
            // the commentary panel — one gesture, one meaning at a time.
            if (parallelActive)
              _ParallelVerseTile(
                row: rows[index - 1],
                baseStyle: readingStyle,
                hasCommentary: markers.contains(number),
                highlight: highlights[number],
                marks: textMarks[number] ?? const [],
                markActions: _markActions(
                  number,
                  rows[index - 1].canonicalText,
                  textMarks[number] ?? const [],
                ),
                selected: _isSelected(number),
                focused: number == _focused,
                sideBySide: sideBySide,
                primaryLang: primaryLang,
                secondaryLang: secondaryLang,
                onLongPress: () => _startSelection(number),
                onPointerDown: _onVersePointerDown,
                onPointerUp: (e) => _onVersePointerUp(number, e),
                onTap: () => _onVerseTap(
                  number,
                  () => showCommentaryPanel(
                    context,
                    ref,
                    VerseRef(bookId, chapter, number),
                    bookName: book?.name ?? bookId,
                    verseText: rows[index - 1].canonicalText,
                  ),
                ),
              )
            else
              _VerseTile(
                verse: verses[index - 1],
                baseStyle: readingStyle,
                hasCommentary: markers.contains(number),
                highlight: highlights[number],
                marks: textMarks[number] ?? const [],
                markActions: _markActions(
                  number,
                  verses[index - 1].text,
                  textMarks[number] ?? const [],
                ),
                selected: _isSelected(number),
                focused: number == _focused,
                lang: primaryLang,
                onLongPress: () => _startSelection(number),
                onPointerDown: _onVersePointerDown,
                onPointerUp: (e) => _onVersePointerUp(number, e),
                onTap: () => _onVerseTap(
                  number,
                  () => showCommentaryPanel(
                    context,
                    ref,
                    VerseRef(bookId, chapter, number),
                    bookName: book?.name ?? bookId,
                    verseText: verses[index - 1].text,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _sideBySide(BuildContext context) {
    final layout = ref.read(settingsProvider).parallelLayout;
    return switch (layout) {
      ParallelLayout.sideBySide => true,
      ParallelLayout.stacked => false,
      ParallelLayout.auto =>
        MediaQuery.of(context).size.width >= _kSideBySideMinWidth,
    };
  }

  static Widget _pill(BtColors c, String text, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.expand_more, size: 14, color: c.textFaint),
                ),
            ],
          ),
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
  const _Header({
    required this.bookId,
    required this.book,
    required this.chapter,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Column(
      children: [
        const SizedBox(height: 12),
        BookEmblem(bookId: bookId, abbrev: book?.abbrev ?? '', size: 96),
        const SizedBox(height: 16),
        Text(
          book?.name ?? bookId,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          '${context.l10n.chapterTitle(chapter)}${_psalmSuffix(bookId, chapter)}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _ChapterNav extends StatelessWidget {
  final BibleBook? book;
  final int chapter;
  final void Function(String, int) onGo;
  const _ChapterNav({
    required this.book,
    required this.chapter,
    required this.onGo,
  });
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
              foregroundColor: hasPrev ? c.accent : c.textFaint,
            ),
          ),
          Text(
            '${book!.name} $chapter${_psalmSuffix(book!.id, chapter)}',
            style: TextStyle(color: c.textFaint, fontSize: 12),
          ),
          TextButton.icon(
            onPressed: hasNext ? () => onGo(book!.id, chapter + 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(context.l10n.next),
            style: TextButton.styleFrom(
              foregroundColor: hasNext ? c.accent : c.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// The gold-dot + verse-number marker, shared by single and parallel tiles.
class _VerseNumber extends StatelessWidget {
  final int number;
  final bool hasCommentary;
  const _VerseNumber({required this.number, required this.hasCommentary});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    // The gold dot's footprint is always reserved (transparent when the verse
    // has no commentary) so verse numbers never shift horizontally as markers
    // appear/disappear.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: hasCommentary ? _kGold : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$number',
          style: TextStyle(
            color: c.accent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VerseTile extends StatelessWidget {
  final Verse verse;
  final TextStyle? baseStyle;
  final bool hasCommentary;
  final HighlightMark? highlight;

  /// Word/letter marks on this verse, oldest first.
  final List<TextMark> marks;
  final VerseMarkActions? markActions;
  final bool selected;
  final bool focused;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<PointerDownEvent>? onPointerDown;
  final ValueChanged<PointerUpEvent>? onPointerUp;
  const _VerseTile({
    required this.verse,
    this.baseStyle,
    required this.hasCommentary,
    required this.highlight,
    this.marks = const [],
    this.markActions,
    required this.selected,
    required this.focused,
    required this.lang,
    required this.onTap,
    required this.onLongPress,
    this.onPointerDown,
    this.onPointerUp,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Listener(
      onPointerDown: (e) => onPointerDown?.call(e),
      onPointerUp: (e) => onPointerUp?.call(e),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: selected || focused
              ? BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: c.accent.withValues(alpha: selected ? 0.5 : 0.3),
                  ),
                )
              : highlight == null || highlight!.isPartial
              ? null
              : BoxDecoration(
                  color: highlight!.color.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          margin: const EdgeInsets.symmetric(vertical: 2),
          // The verse body is selectable like a printed reader: a short tap on
          // the row still opens commentary, while a long press on the text lets
          // the platform selection toolbar copy an exact excerpt.
          child: scriptDirectionality(
            lang: lang,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: onLongPress,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _VerseNumber(
                        number: verse.number,
                        hasCommentary: hasCommentary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText.rich(
                    // A new key when the verse enters the selection drops any word
                    // selection left by the triple tap.
                    key: ValueKey('verse-${verse.number}-$selected'),
                    TextSpan(
                      children: applyTextMarks(
                        applyHighlightRange(
                          _verseSpans(context, verse, lang, baseStyle),
                          highlight,
                        ),
                        marks,
                        text: verse.text,
                      ),
                    ),
                    textAlign: scriptAlign(lang),
                    onTap: onTap,
                    // Long-press-and-drag selects words, as in a printed reader;
                    // the menu then offers colours that paint that span at once.
                    // Whole-verse selection lives on the verse number.
                    contextMenuBuilder: (ctx, state) =>
                        verseContextMenu(ctx, state, markActions),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Verse text as plain spans in the script's style. The chapter no longer
  /// opens with a raised initial (removed at the team's request).
  static List<InlineSpan> _verseSpans(
    BuildContext context,
    Verse verse,
    String lang,
    TextStyle? baseStyle,
  ) {
    final base = scriptStyle(
      baseStyle ?? Theme.of(context).textTheme.bodyLarge,
      lang,
    );
    return [TextSpan(text: verse.text, style: base)];
  }
}

/// A canonical verse rendered in two translations. Highlights/commentary/tap
/// all key off the canonical [VerseRef] (book, chapter, number) regardless of
/// which column the user looks at.
class _ParallelVerseTile extends StatelessWidget {
  final ParallelVerse row;
  final TextStyle? baseStyle;
  final bool hasCommentary;
  final HighlightMark? highlight;

  /// Word/letter marks on this verse, oldest first.
  final List<TextMark> marks;
  final VerseMarkActions? markActions;
  final bool selected;
  final bool focused;
  final bool sideBySide;
  final String primaryLang;
  final String secondaryLang;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<PointerDownEvent>? onPointerDown;
  final ValueChanged<PointerUpEvent>? onPointerUp;
  const _ParallelVerseTile({
    required this.row,
    this.baseStyle,
    required this.hasCommentary,
    required this.highlight,
    this.marks = const [],
    this.markActions,
    required this.selected,
    required this.focused,
    required this.sideBySide,
    required this.primaryLang,
    required this.secondaryLang,
    required this.onTap,
    required this.onLongPress,
    this.onPointerDown,
    this.onPointerUp,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final body = sideBySide ? _sideBySide(context, c) : _stacked(context, c);
    return Listener(
      onPointerDown: (e) => onPointerDown?.call(e),
      onPointerUp: (e) => onPointerUp?.call(e),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: selected || focused
              ? BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: c.accent.withValues(alpha: selected ? 0.5 : 0.3),
                  ),
                )
              : highlight == null || highlight!.isPartial
              ? null
              : BoxDecoration(
                  color: highlight!.color.color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: body,
        ),
      ),
    );
  }

  Widget _sideBySide(BuildContext context, BtColors c) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: _VerseNumber(
              number: row.number,
              hasCommentary: hasCommentary,
            ),
          ),
          Expanded(
            child: _columnText(context, c, row.primary?.text, primaryLang),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: c.divider,
          ),
          Expanded(
            child: _columnText(context, c, row.secondary?.text, secondaryLang),
          ),
        ],
      ),
    );
  }

  Widget _stacked(BuildContext context, BtColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: _VerseNumber(
                number: row.number,
                hasCommentary: hasCommentary,
              ),
            ),
            Expanded(
              child: _columnText(context, c, row.primary?.text, primaryLang),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 4),
          padding: const EdgeInsetsDirectional.only(start: 12),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: c.divider, width: 2),
            ),
          ),
          child: _columnText(
            context,
            c,
            row.secondary?.text,
            secondaryLang,
            secondary: true,
          ),
        ),
      ],
    );
  }

  /// One translation's column. A Hebrew column lays out right-to-left inside
  /// its own [Directionality] so it can sit beside a left-to-right one without
  /// flipping the whole row.
  Widget _columnText(
    BuildContext context,
    BtColors c,
    String? text,
    String lang, {
    bool secondary = false,
  }) {
    if (text == null) {
      return Text(
        context.l10n.verseNotInTranslation,
        style: TextStyle(
          color: c.textFaint,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      );
    }
    final base = baseStyle ?? Theme.of(context).textTheme.bodyLarge;
    final style = scriptStyle(
      secondary ? base?.copyWith(color: c.textSecondary) : base,
      lang,
    );
    return scriptDirectionality(
      lang: lang,
      child: SelectableText.rich(
        TextSpan(
          children: secondary
              ? [TextSpan(text: text, style: style)]
              : applyTextMarks(
                  applyHighlightRange([
                    TextSpan(text: text, style: style),
                  ], highlight),
                  marks,
                  text: text,
                ),
        ),
        textAlign: scriptAlign(lang),
        onTap: onTap,
        contextMenuBuilder: secondary
            ? null
            : (ctx, state) => verseContextMenu(ctx, state, markActions),
      ),
    );
  }
}

/// The bar that appears while verses are selected: how many are picked, a way
/// out, and the share action. Deliberately slim — the passage stays readable
/// underneath while the reader adjusts the span.
/// The long-press action bar — Kindle's gesture, in this app's clothes.
///
/// A long press selects the verse and raises this bar; tapping further verses
/// widens the span and every action applies to the whole of it. "Destacar"
/// swaps in a row of colours so painting a passage is press → tap → done.
class _SelectionBar extends StatelessWidget {
  final int count;
  final bool showColors;
  final VoidCallback onClear;
  final VoidCallback onToggleColors;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onNote;
  final VoidCallback onFavorite;
  final ValueChanged<HighlightColor> onPickColor;

  const _SelectionBar({
    required this.count,
    required this.showColors,
    required this.onClear,
    required this.onToggleColors,
    required this.onCopy,
    required this.onShare,
    required this.onNote,
    required this.onFavorite,
    required this.onPickColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.selectionCount(count),
                      style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                    ),
                  ),
                  // The forward box: one tap turns the selected verses into an
                  // image card, as WhatsApp forwards selected messages.
                  FilledButton.icon(
                    key: const ValueKey('selection-share-image'),
                    onPressed: onShare,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(l10n.shareSelection),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onClear,
                    style: TextButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      l10n.selectionClear,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            // The colour row takes the place of nothing — it slides in above the
            // actions, so the actions never move under the reader's thumb.
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: showColors
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final color in HighlightColor.values)
                            Semantics(
                              button: true,
                              label: color.key,
                              child: GestureDetector(
                                onTap: () => onPickColor(color),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  // 44pt touch target around a 30pt swatch.
                                  padding: const EdgeInsets.all(7),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: color.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: c.divider,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _act(c, Icons.copy, l10n.shareCopy, onCopy),
                  _act(c, Icons.ios_share, l10n.share, onShare),
                  _act(
                    c,
                    Icons.format_color_fill,
                    l10n.highlight,
                    onToggleColors,
                    active: showColors,
                  ),
                  _act(c, Icons.edit_note, l10n.note, onNote),
                  _act(c, Icons.favorite_border, l10n.favorite, onFavorite),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _act(
    BtColors c,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: active ? c.accent : c.textPrimary),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? c.accent : c.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shown in the reader when the user has Parallel Reading on but no second
/// translation is installed: keeps the primary text readable and routes to the
/// Offline Resources section to add one.
class _SecondaryMissingBanner extends StatelessWidget {
  const _SecondaryMissingBanner();
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Container(
      width: double.infinity,
      color: c.surfaceHigh.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Icon(Icons.view_column_outlined, size: 20, color: c.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.noSecondaryTranslation,
              style: TextStyle(color: c.textSecondary, height: 1.3),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/settings'),
            child: Text(
              context.l10n.openOfflineResources,
              style: TextStyle(color: c.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet controls for Parallel Reading: enable, pick the secondary
/// translation (or learn how to install one), and choose the layout.
class _ParallelOptionsSheet extends ConsumerWidget {
  const _ParallelOptionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsControllerProvider);
    final candidates = ref.watch(secondaryTranslationCandidatesProvider);
    final secondaryId = ref.watch(resolvedSecondaryTranslationIdProvider);
    final presets = ref.watch(availableParallelPresetsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                l10n.parallelOptionsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.view_column_outlined),
              title: Text(l10n.parallelReading),
              subtitle: Text(
                s.parallelReadingEnabled
                    ? l10n.parallelReading
                    : l10n.singleTranslation,
              ),
              value: s.parallelReadingEnabled,
              onChanged: ctrl.setParallelReading,
            ),
            if (s.parallelReadingEnabled) ...[
              const Divider(height: 1),
              _sectionLabel(c, l10n.parallelPresetLabel),
              for (final p in presets)
                RadioListTile<ParallelPreset>(
                  value: p,
                  groupValue: s.parallelPreset,
                  onChanged: (v) =>
                      ctrl.setParallelPreset(v ?? ParallelPreset.custom),
                  activeColor: c.accent,
                  dense: true,
                  title: Text(presetLabel(l10n, p)),
                  subtitle: presetHint(l10n, p) == null
                      ? null
                      : Text(
                          presetHint(l10n, p)!,
                          style: TextStyle(color: c.textFaint, fontSize: 12),
                        ),
                ),
            ],
            if (s.parallelReadingEnabled &&
                s.parallelPreset == ParallelPreset.byTestament)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Consumer(
                  builder: (context, ref, _) {
                    final avail = ref.watch(parallelTableAvailabilityProvider);
                    return ParallelTestamentTable(
                      ot: s.parallelOt,
                      nt: s.parallelNt,
                      availableOt: avail.ot,
                      availableNt: avail.nt,
                      onChanged: ctrl.setParallelByTestament,
                    );
                  },
                ),
              ),
            if (s.parallelReadingEnabled &&
                s.parallelPreset == ParallelPreset.custom) ...[
              const Divider(height: 1),
              _sectionLabel(c, l10n.secondaryTranslation),
              if (candidates.isEmpty)
                _EmptySecondary(
                  onOpenSettings: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                )
              else
                for (final t in candidates)
                  ListTile(
                    // "Latim — Vulgata Clementina", "Grego — Novo Testamento
                    // Grego (SBLGNT)": the script is what the reader is
                    // choosing, so it leads.
                    title: Text(translationLabel(l10n, t.lang, t.title)),
                    trailing: t.id == secondaryId
                        ? Icon(Icons.check, color: c.accent)
                        : null,
                    onTap: () => ctrl.setSecondaryTranslation(t.id),
                  ),
            ],
            if (s.parallelReadingEnabled) ...[
              const Divider(height: 1),
              _sectionLabel(c, l10n.parallelLayoutLabel),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in <(ParallelLayout, String)>[
                      (ParallelLayout.auto, l10n.layoutAuto),
                      (ParallelLayout.stacked, l10n.layoutStacked),
                      (ParallelLayout.sideBySide, l10n.layoutSideBySide),
                    ])
                      ChoiceChip(
                        label: Text(entry.$2),
                        selected: s.parallelLayout == entry.$1,
                        onSelected: (_) => ctrl.setParallelLayout(entry.$1),
                        backgroundColor: c.surfaceHigh,
                        selectedColor: c.accentSoft,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: s.parallelLayout == entry.$1
                              ? c.accent
                              : c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BtColors c, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        color: c.textFaint,
        fontSize: 12,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _EmptySecondary extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _EmptySecondary({required this.onOpenSettings});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.noSecondaryTranslation,
            style: TextStyle(color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(context.l10n.openOfflineResources),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.accent,
              side: BorderSide(color: c.accent.withValues(alpha: 0.5)),
            ),
          ),
        ],
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

String presetLabel(AppL10n l10n, ParallelPreset p) => switch (p) {
  ParallelPreset.custom => l10n.presetCustom,
  ParallelPreset.latin => l10n.presetLatin,
  ParallelPreset.greek => l10n.presetGreek,
  ParallelPreset.hebrewGreek => l10n.presetHebrewGreek,
  ParallelPreset.latinGreek => l10n.presetLatinGreek,
  ParallelPreset.byTestament => l10n.presetByTestament,
};

String? presetHint(AppL10n l10n, ParallelPreset p) => switch (p) {
  ParallelPreset.custom => null,
  ParallelPreset.latin => l10n.presetLatinHint,
  ParallelPreset.greek => l10n.presetGreekHint,
  ParallelPreset.hebrewGreek => l10n.presetHebrewGreekHint,
  ParallelPreset.latinGreek => l10n.presetLatinGreekHint,
  ParallelPreset.byTestament => l10n.presetByTestamentHint,
};

/// Paints an excerpt highlight over already-built verse spans by splitting
/// them at the range boundaries. Spans outside the range are untouched, so
/// the raised initial and script styling survive.
List<InlineSpan> applyHighlightRange(
  List<InlineSpan> spans,
  HighlightMark? mark,
) {
  if (mark == null || !mark.isPartial) return spans;
  final start = mark.start!, end = mark.end!;
  final bg = mark.color.color.withValues(alpha: 0.38);
  final out = <InlineSpan>[];
  var pos = 0;
  for (final sp in spans) {
    if (sp is! TextSpan || sp.text == null) {
      out.add(sp);
      continue;
    }
    final t = sp.text!;
    final a = pos, b = pos + t.length;
    pos = b;
    final s0 = start.clamp(a, b) - a, s1 = end.clamp(a, b) - a;
    if (s1 <= s0) {
      out.add(sp);
      continue;
    }
    if (s0 > 0) out.add(TextSpan(text: t.substring(0, s0), style: sp.style));
    out.add(
      TextSpan(
        text: t.substring(s0, s1),
        style: (sp.style ?? const TextStyle()).copyWith(backgroundColor: bg),
      ),
    );
    if (s1 < t.length) {
      out.add(TextSpan(text: t.substring(s1), style: sp.style));
    }
  }
  return out;
}
