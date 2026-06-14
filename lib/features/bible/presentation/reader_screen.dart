import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../annotations/application/annotation_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../annotations/domain/entities.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';
import '../../annotations/presentation/note_editor.dart';
import 'widgets/book_emblem.dart';
import 'patristic_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapter;
  const ReaderScreen({super.key, required this.bookId, required this.chapter});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    // Record "Continue Reading" position once the DB is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translation = ref.read(settingsProvider).primaryTranslationId;
      ref.read(annotationControllerProvider).recordProgress(
          translation, VerseRef(widget.bookId, widget.chapter, 1));
    });
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          _pill(c, book?.testament == Testament.nt ? 'NT' : 'AT'),
          const SizedBox(width: 8),
          _pill(c, book?.name ?? bookId),
        ]),
        actions: [
          _pill(c, '$chapter'),
          IconButton(
            icon: Icon(Icons.more_horiz, color: c.textSecondary),
            onPressed: () => _showTypeSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: (content == null)
            ? _NoText(c)
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                children: [
                  const SizedBox(height: 12),
                  Center(
                      child: BookEmblem(
                          bookId: bookId,
                          abbrev: book?.abbrev ?? '',
                          size: 96)),
                  const SizedBox(height: 16),
                  Center(
                      child: Text(book?.name ?? bookId,
                          style: Theme.of(context).textTheme.headlineMedium)),
                  Center(
                      child: Text('Capítulo $chapter',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: c.textSecondary))),
                  const SizedBox(height: 28),
                  if (content.isEmpty)
                    _NoText(c)
                  else
                    for (final v in content.verses) ...[
                      if (headingByVerse[v.number] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 10),
                          child: Text(
                            _titleCase(headingByVerse[v.number]!.text),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      _VerseTile(
                        verse: v,
                        hasCommentary: markers.contains(v.number),
                        highlight: highlights[v.number],
                        onTap: () => _showVerseActions(
                            context, book?.name ?? bookId, v),
                      ),
                    ],
                ],
              ),
      ),
    );
  }

  void _showVerseActions(BuildContext context, String bookName, Verse v) {
    final c = context.bt;
    final vref = VerseRef(widget.bookId, widget.chapter, v.number);
    final count = ref.read(commentariesProvider(vref)).length;
    final ctrl = ref.read(annotationControllerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Consumer(builder: (ctx, r, _) {
        final bookmarked = r.watch(isBookmarkedProvider(vref));
        final favorite = r.watch(isFavoriteProvider(vref));
        final notes = r.watch(notesForVerseProvider(vref));
        final highlighted =
            r.watch(highlightsForChapterProvider((bookId: vref.bookId, chapter: vref.chapter)))
                .containsKey(v.number);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.divider, borderRadius: BorderRadius.circular(2))),
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
                leading: Icon(Icons.copy, color: c.textPrimary),
                title: const Text('Copiar versículo'),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: '$bookName ${widget.chapter},${v.number} — ${v.text}'));
                  Navigator.pop(sheetCtx);
                },
              ),
              ListTile(
                leading: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? c.accent : c.textPrimary),
                title: Text(favorite ? 'Remover dos favoritos' : 'Favoritar'),
                onTap: () {
                  ctrl.toggleFavorite(vref,
                      '$bookName ${widget.chapter},${v.number} — ${v.text}');
                  Navigator.pop(sheetCtx);
                },
              ),
              ListTile(
                leading: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: bookmarked ? c.accent : c.textPrimary),
                title: Text(bookmarked ? 'Remover marcador' : 'Marcar'),
                onTap: () {
                  ctrl.toggleBookmark(vref);
                  Navigator.pop(sheetCtx);
                },
              ),
              ListTile(
                leading: Icon(Icons.note_add_outlined, color: c.textPrimary),
                title: Text(notes.isEmpty ? 'Nota' : 'Notas (${notes.length})'),
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
                title: Text('Padres da Igreja',
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
                                color: c.accent, fontWeight: FontWeight.w600)))
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
        );
      }),
    );
  }

  void _showTypeSheet(BuildContext context) {
    final c = context.bt;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Modo de cor', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Tamanho da fonte (em breve)',
              style: TextStyle(color: c.textSecondary)),
        ]),
      ),
    );
  }

  static Widget _pill(BtColors c, String text) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: TextStyle(color: c.textSecondary, fontSize: 13)),
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
            'Texto bíblico ainda não instalado.\n'
            'O comentário patrístico já está disponível ao tocar num versículo, '
            'quando a tradução for instalada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, height: 1.5),
          ),
        ),
      );
}
