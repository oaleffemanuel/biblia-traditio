import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/settings/domain/settings.dart';

/// Scripture text style for the reader: the theme's serif body, in the
/// typeface the reader chose. Size is handled separately, by scaling the
/// reader's MediaQuery, so verse numbers and headings grow together.
TextStyle? readingTextStyle(BuildContext context, ReadingFont font) {
  final base = Theme.of(context).textTheme.bodyLarge;
  if (base == null) return null;
  return switch (font) {
    ReadingFont.garamond => base,
    ReadingFont.inter => GoogleFonts.inter(textStyle: base, height: 1.5),
    ReadingFont.system => TextStyle(
      color: base.color,
      fontSize: base.fontSize,
      height: base.height,
      fontWeight: base.fontWeight,
    ),
  };
}
