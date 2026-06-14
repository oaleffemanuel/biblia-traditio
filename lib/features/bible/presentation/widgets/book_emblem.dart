import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Engraved-style book medallion. Falls back to a monogram when the SVG
/// emblem asset is not yet bundled (emblems are added per book over time).
class BookEmblem extends StatelessWidget {
  final String bookId;
  final String abbrev;
  final double size;
  const BookEmblem(
      {super.key, required this.bookId, required this.abbrev, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: c.accent.withValues(alpha: 0.35), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        abbrev.isEmpty ? bookId.toUpperCase() : abbrev,
        style: TextStyle(
          color: c.accent,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w600,
          fontFamily: 'serif',
        ),
      ),
    );
  }
}
