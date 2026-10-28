import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/snack.dart';
import '../../../../core/theme/app_theme.dart';

/// How much text a share image may carry before it stops being readable.
/// A 320pt card at 19px EB Garamond fits roughly this much without the type
/// shrinking to nothing — past it we ask the reader to narrow the selection
/// rather than silently rendering a chapter-sized wall.
const int kMaxShareSelectionChars = 900;

/// Commentaries run to thousands of words; the card carries an excerpt and
/// trims on a word boundary so the image stays a quotation, not a document.
const int kMaxShareCommentaryChars = 700;

String formatCommentaryForClipboard({
  required String author,
  required String reference,
  required String text,
}) => '“${text.trim()}”\n— $author, $reference';

/// Opens the share sheet for a verse: copy, share text, or share a beautiful
/// card image. Deliberately understated — the shared text is just the verse and
/// its reference (no "sent from app" line); only the card carries a small,
/// elegant wordmark so people naturally ask where it came from.
void showShareVerse(
  BuildContext context, {
  required String reference,
  required String text,
}) {
  _showShareSheet(
    context,
    plainText: '“$text”\n— $reference',
    card: _ShareCard(reference: reference, body: '“$text”'),
  );
}

/// Keeps copied passages readable outside the app. Verse numbers stay on
/// separate lines for multi-verse selections, while a single verse remains a
/// clean quotation.
String formatPassageForClipboard({
  required String reference,
  required List<({int number, String text})> verses,
}) {
  final body = verses.length == 1
      ? verses.single.text
      : verses.map((v) => '${v.number} ${v.text}').join('\n');
  return '“$body”\n— $reference';
}

/// Shares a continuous span of verses as one card — "John 1:1–5" — keeping the
/// verse numbers so the passage still reads as Scripture. Callers must check
/// [kMaxShareSelectionChars] first (see [passageLength]).
void showSharePassage(
  BuildContext context, {
  required String reference,
  required List<({int number, String text})> verses,
}) {
  final plain = formatPassageForClipboard(reference: reference, verses: verses);
  _showShareSheet(
    context,
    plainText: plain,
    card: _ShareCard(reference: reference, verses: verses),
  );
}

/// Shares a single commentary. Short commentaries go straight to the share
/// sheet. Long ones first ask the reader to **choose the sentences** that go
/// on the card — a card can carry about [kMaxShareCommentaryChars] before the
/// type becomes unreadable — while *copying as text* always takes the whole
/// commentary, never a trimmed version.
void showShareCommentary(
  BuildContext context, {
  required String reference,
  required String author,
  required String authorMeta,
  required String text,
}) {
  final full = text.trim();
  final plainText = formatCommentaryForClipboard(
    author: author,
    reference: reference,
    text: full,
  );
  if (full.length <= kMaxShareCommentaryChars) {
    _showShareSheet(
      context,
      plainText: plainText,
      card: _ShareCard(
        reference: reference,
        body: '“$full”',
        author: author,
        authorMeta: authorMeta,
      ),
    );
    return;
  }
  _showExcerptPicker(
    context,
    reference: reference,
    author: author,
    authorMeta: authorMeta,
    text: full,
  );
}

/// Splits a commentary into sentences the reader can pick from. Splits after
/// terminal punctuation followed by whitespace; abbreviations may over-split,
/// which only means one more tap.
List<String> splitSentences(String text) => text
    .split(RegExp(r'(?<=[.!?…;:])\s+'))
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// Joins the selected sentences in order; a gap between non-adjacent
/// selections is marked with an ellipsis in brackets, as a quotation would.
String joinExcerpt(List<String> sentences, Set<int> selected) {
  final idx = selected.toList()..sort();
  final buf = StringBuffer();
  int? prev;
  for (final i in idx) {
    if (prev != null) buf.write(i == prev + 1 ? ' ' : ' […] ');
    buf.write(sentences[i]);
    prev = i;
  }
  return buf.toString();
}

/// Preselects sentences from the start until the card limit is reached, so
/// the common case is one tap on Continue.
Set<int> defaultExcerptSelection(List<String> sentences, int max) {
  final out = <int>{};
  var len = 0;
  for (var i = 0; i < sentences.length; i++) {
    final add = sentences[i].length + (i == 0 ? 0 : 1);
    if (len + add > max) break;
    out.add(i);
    len += add;
  }
  return out;
}

void _showExcerptPicker(
  BuildContext context, {
  required String reference,
  required String author,
  required String authorMeta,
  required String text,
}) {
  final c = context.bt;
  final sentences = splitSentences(text);
  final selected = defaultExcerptSelection(sentences, kMaxShareCommentaryChars);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setState) {
        final l10n = ctx.l10n;
        final excerpt = joinExcerpt(sentences, selected);
        final over = excerpt.length > kMaxShareCommentaryChars;
        final ok = selected.isNotEmpty && !over;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 18),
                Text(
                  l10n.shareChooseExcerpt,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.shareExcerptHint,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sentences.length,
                    itemBuilder: (_, i) {
                      final on = selected.contains(i);
                      return Semantics(
                        button: true,
                        selected: on,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            on ? selected.remove(i) : selected.add(i);
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: on ? c.accentSoft : c.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: on
                                    ? c.accent.withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              sentences[i],
                              style: Theme.of(ctx).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: on ? c.textPrimary : c.textSecondary,
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected.isEmpty
                            ? l10n.shareExcerptNone
                            : over
                            ? l10n.shareExcerptTooLong
                            : l10n.shareExcerptCount(
                                excerpt.length,
                                kMaxShareCommentaryChars,
                              ),
                        style: TextStyle(
                          color: ok ? c.textSecondary : c.accent,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: ok
                          ? () {
                              Navigator.pop(sheetCtx);
                              _showShareSheet(
                                context,
                                plainText: '“$text”\n— $author, $reference',
                                card: _ShareCard(
                                  reference: reference,
                                  body: '“$excerpt”',
                                  author: author,
                                  authorMeta: authorMeta,
                                ),
                              );
                            }
                          : null,
                      child: Text(l10n.shareContinue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Character length of a passage as the card will render it.
int passageLength(List<({int number, String text})> verses) =>
    verses.fold(0, (sum, v) => sum + v.text.length + 3);

/// Trims [text] to at most [max] characters on a word boundary, appending an
/// ellipsis when anything was dropped.
String excerptFor(String text, int max) {
  final t = text.trim();
  if (t.length <= max) return t;
  final cut = t.substring(0, max);
  final lastSpace = cut.lastIndexOf(' ');
  return '${(lastSpace > max * 0.6 ? cut.substring(0, lastSpace) : cut).trimRight()}…';
}

void _showShareSheet(
  BuildContext context, {
  required String plainText,
  required Widget card,
}) {
  final c = context.bt;
  final cardKey = GlobalKey();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Live preview = the exact thing we rasterise for the image share.
            // Long cards scroll here; the rasterised image is never clipped
            // because RepaintBoundary captures the full laid-out card.
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(key: cardKey, child: card),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.copy,
                    label: sheetCtx.l10n.shareCopy,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: plainText));
                      final copied = sheetCtx.l10n.copied;
                      Navigator.pop(sheetCtx);
                      showSnack(copied);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Action(
                    icon: Icons.notes,
                    label: sheetCtx.l10n.shareText,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      SharePlus.instance.share(ShareParams(text: plainText));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Action(
                    icon: Icons.image_outlined,
                    label: sheetCtx.l10n.shareImage,
                    onTap: () async {
                      await _shareCardImage(cardKey);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _shareCardImage(GlobalKey key) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  final image = await boundary.toImage(pixelRatio: 3.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;
  final file = XFile.fromData(
    bytes.buffer.asUint8List(),
    mimeType: 'image/png',
    name: 'biblia-traditio.png',
  );
  await SharePlus.instance.share(ShareParams(files: [file]));
}

/// The share card.
///
/// Deliberately **light**: the app reads dark, but an exported image lands in a
/// feed, a print, a parish bulletin — places where ivory paper and ink read as
/// considered and a black rectangle reads as a screenshot. Wide margins, a
/// hairline rule, small-caps reference, and a wordmark quiet enough to be a
/// colophon rather than an advertisement.
///
/// One frame serves all three shapes: a single verse, a numbered passage, and
/// a commentary (which adds the commentator above the text).
class _ShareCard extends StatelessWidget {
  final String reference;
  final String? body;
  final List<({int number, String text})>? verses;
  final String? author;
  final String? authorMeta;

  const _ShareCard({
    required this.reference,
    this.body,
    this.verses,
    this.author,
    this.authorMeta,
  });

  // Paper, ink and a single accent — the app's terracotta, darkened enough to
  // hold its own on a light ground.
  static const _paper = Color(0xFFFBF8F3);
  static const _ink = Color(0xFF1C1A18);
  static const _muted = Color(0xFF6B635B);
  static const _accent = Color(0xFFA33B22);
  static const _rule = Color(0xFFDCD3C7);

  @override
  Widget build(BuildContext context) {
    final serif = GoogleFonts.ebGaramond();
    final rows = verses;

    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 30),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _rule),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (author != null) ...[
            Text(
              author!.toUpperCase(),
              textAlign: TextAlign.center,
              style: serif.copyWith(
                color: _accent,
                fontSize: 12,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if ((authorMeta ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                authorMeta!,
                textAlign: TextAlign.center,
                style: serif.copyWith(
                  color: _muted,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 22),
          ],
          if (rows != null)
            // Numbered passage: the verse numbers stay, set small and raised in
            // the accent, so "John 1:1–5" still reads as Scripture.
            Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    TextSpan(
                      text: '${rows[i].number}\u2009',
                      style: serif.copyWith(
                        color: _accent,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.superscripts()],
                      ),
                    ),
                    TextSpan(
                      text: rows[i].text + (i == rows.length - 1 ? '' : ' '),
                    ),
                  ],
                ],
              ),
              textAlign: TextAlign.center,
              style: serif.copyWith(color: _ink, fontSize: 19, height: 1.62),
            )
          else
            Text(
              body ?? '',
              textAlign: TextAlign.center,
              style: serif.copyWith(color: _ink, fontSize: 20, height: 1.62),
            ),
          const SizedBox(height: 26),
          Container(width: 44, height: 1, color: _rule),
          const SizedBox(height: 14),
          Text(
            reference.toUpperCase(),
            textAlign: TextAlign.center,
            style: serif.copyWith(
              color: _accent,
              fontSize: 11.5,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          // The colophon: present, never promotional.
          Text(
            'BIBLIA TRADITIO',
            style: serif.copyWith(
              color: _muted.withValues(alpha: 0.55),
              fontSize: 9,
              letterSpacing: 2.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: c.textPrimary, size: 22),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: c.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
