import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// Illuminated-initial medallion for a book: the abbreviation set in the
/// Scripture serif, gold on a soft gold ground with a hairline frame — the
/// look of a rubricated initial rather than a generic avatar.
class BookEmblem extends StatelessWidget {
  final String bookId;
  final String abbrev;
  final double size;
  const BookEmblem({
    super.key,
    required this.bookId,
    required this.abbrev,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final text = abbrev.isEmpty ? bookId.toUpperCase() : abbrev;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.goldSoft,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: c.gold.withValues(alpha: 0.55), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.ebGaramond(
          color: c.gold,
          fontSize: size * (text.length > 2 ? 0.34 : 0.42),
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
