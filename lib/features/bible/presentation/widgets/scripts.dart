/// Script handling for the original-language texts Parallel Reading can show.
///
/// Nothing here fabricates a text: it only makes sure that *when* a Greek or
/// Hebrew package is installed, its verses lay out correctly — Hebrew right to
/// left, both with a font that actually has the glyphs.
///
/// The fallbacks are platform fonts rather than bundled or downloaded ones:
/// Biblia Traditio reads offline, so fetching a webfont at render time is not
/// an option, and shipping full Hebrew/Greek faces would cost more than the
/// texts they'd serve until those packages exist.
library;

import 'package:flutter/widgets.dart';

/// Right-to-left for Hebrew (and Aramaic); left-to-right for everything else.
TextDirection scriptDirection(String lang) => switch (lang) {
      'he' || 'hbo' || 'arc' => TextDirection.rtl,
      _ => TextDirection.ltr,
    };

bool isRtlScript(String lang) => scriptDirection(lang) == TextDirection.rtl;

/// Which side a column of [lang] text should align to.
TextAlign scriptAlign(String lang) =>
    isRtlScript(lang) ? TextAlign.right : TextAlign.left;

const _hebrewFallback = [
  'Noto Sans Hebrew', 'Noto Serif Hebrew', 'David', 'Arial Hebrew',
  'Times New Roman',
];
const _greekFallback = [
  'Noto Serif', 'Times New Roman', 'Helvetica',
];

/// Adds a glyph-bearing fallback for scripts the app's own serif doesn't cover.
/// EB Garamond carries Greek, so the Greek list is a safety net; Hebrew needs
/// a real fallback.
TextStyle? scriptStyle(TextStyle? base, String lang) => switch (lang) {
      'he' || 'hbo' || 'arc' =>
        (base ?? const TextStyle()).copyWith(fontFamilyFallback: _hebrewFallback),
      'grc' || 'el' =>
        (base ?? const TextStyle()).copyWith(fontFamilyFallback: _greekFallback),
      _ => base,
    };

/// Wraps [child] in the reading direction of [lang]. A no-op for left-to-right
/// texts, so ordinary verses keep the ambient directionality.
Widget scriptDirectionality({required String lang, required Widget child}) =>
    isRtlScript(lang)
        ? Directionality(textDirection: TextDirection.rtl, child: child)
        : child;
