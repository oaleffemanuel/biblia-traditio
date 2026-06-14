import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';

/// Opens the share sheet for a verse: copy, share text, or share a beautiful
/// card image. Deliberately understated — the shared text is just the verse and
/// its reference (no "sent from app" line); only the card carries a small,
/// elegant wordmark so people naturally ask where it came from.
void showShareVerse(BuildContext context,
    {required String reference, required String text}) {
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
            RepaintBoundary(
              key: cardKey,
              child: _ShareCard(reference: reference, text: text),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.copy,
                    label: 'Copiar',
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: '“$text”\n— $reference'));
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Action(
                    icon: Icons.notes,
                    label: 'Texto',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      SharePlus.instance
                          .share(ShareParams(text: '“$text”\n— $reference'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Action(
                    icon: Icons.image_outlined,
                    label: 'Imagem',
                    onTap: () async {
                      await _shareCardImage(cardKey, reference);
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

Future<void> _shareCardImage(GlobalKey key, String reference) async {
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

/// The share card — dark, serif, reverent; a small wordmark, never an ad.
class _ShareCard extends StatelessWidget {
  final String reference;
  final String text;
  const _ShareCard({required this.reference, required this.text});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0C);
    const accent = Color(0xFFC2492E);
    const ivory = Color(0xFFEDE9E3);
    final serif = GoogleFonts.ebGaramond();
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories, color: accent.withValues(alpha: 0.8), size: 22),
          const SizedBox(height: 20),
          Text(
            '“$text”',
            textAlign: TextAlign.center,
            style: serif.copyWith(
                color: ivory, fontSize: 19, height: 1.5),
          ),
          const SizedBox(height: 18),
          Text(reference.toUpperCase(),
              style: serif.copyWith(
                  color: accent,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Container(width: 28, height: 1, color: accent.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Biblia Traditio',
              style: serif.copyWith(
                  color: ivory.withValues(alpha: 0.5),
                  fontSize: 12,
                  letterSpacing: 1)),
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
