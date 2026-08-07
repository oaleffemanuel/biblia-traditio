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

/// Opens the share sheet for a verse: copy, share text, or share a beautiful
/// card image. Deliberately understated — the shared text is just the verse and
/// its reference (no "sent from app" line); only the card carries a small,
/// elegant wordmark so people naturally ask where it came from.
void showShareVerse(BuildContext context,
    {required String reference, required String text}) {
  _showShareSheet(
    context,
    plainText: '“$text”\n— $reference',
    card: _ShareCard(reference: reference, body: '“$text”'),
  );
}

/// Shares a continuous span of verses as one card — "John 1:1–5" — keeping the
/// verse numbers so the passage still reads as Scripture. Callers must check
/// [kMaxShareSelectionChars] first (see [passageLength]).
void showSharePassage(BuildContext context,
    {required String reference,
    required List<({int number, String text})> verses}) {
  final plain = verses.map((v) => '${v.number} ${v.text}').join(' ');
  _showShareSheet(
    context,
    plainText: '“$plain”\n— $reference',
    card: _ShareCard(reference: reference, verses: verses),
  );
}

/// Shares a single commentary as a card: the commentator, their function and
/// century, the excerpt, and the verse it comments on.
void showShareCommentary(BuildContext context,
    {required String reference,
    required String author,
    required String authorMeta,
    required String text}) {
  final excerpt = excerptFor(text, kMaxShareCommentaryChars);
  _showShareSheet(
    context,
    plainText: '“$excerpt”\n— $author, $reference',
    card: _ShareCard(
      reference: reference,
      body: '“$excerpt”',
      author: author,
      authorMeta: authorMeta,
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

void _showShareSheet(BuildContext context,
    {required String plainText, required Widget card}) {
  final c = context.bt;
  final cardKey = GlobalKey();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    color: c.divider, borderRadius: BorderRadius.circular(2))),
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
            Text(author!.toUpperCase(),
                textAlign: TextAlign.center,
                style: serif.copyWith(
                    color: _accent,
                    fontSize: 12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                    height: 1.4)),
            if ((authorMeta ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(authorMeta!,
                  textAlign: TextAlign.center,
                  style: serif.copyWith(
                      color: _muted, fontSize: 12.5, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 22),
          ],
          if (rows != null)
            // Numbered passage: the verse numbers stay, set small and raised in
            // the accent, so "John 1:1–5" still reads as Scripture.
            Text.rich(
              TextSpan(children: [
                for (var i = 0; i < rows.length; i++) ...[
                  TextSpan(
                    text: '${rows[i].number}\u2009',
                    style: serif.copyWith(
                        color: _accent,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.superscripts()]),
                  ),
                  TextSpan(
                      text: rows[i].text + (i == rows.length - 1 ? '' : ' ')),
                ],
              ]),
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
          Text(reference.toUpperCase(),
              textAlign: TextAlign.center,
              style: serif.copyWith(
                  color: _accent,
                  fontSize: 11.5,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 26),
          // The colophon: present, never promotional.
          Text('BIBLIA TRADITIO',
              style: serif.copyWith(
                  color: _muted.withValues(alpha: 0.55),
                  fontSize: 9,
                  letterSpacing: 2.6)),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: c.surfaceHigh, borderRadius: BorderRadius.circular(16)),
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
