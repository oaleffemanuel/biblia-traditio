import '../models/blocks.dart';

/// Classifies a single source line into a [BlockKind].
///
/// CORE SAFETY RULE: a line becomes a [BlockKind.verse] ONLY when it begins
/// with a real verse marker (a leading integer) AND the remaining text is
/// genuine scripture. Everything else is metadata. Because verse numbers are
/// always read from the marker — never inferred from position — a misclassified
/// heading can NEVER shift the numbering of following verses.
class HeadingDetector {
  // Leading verse marker: optional whitespace, digits, optional a/b suffix,
  // then a separator (space, dot, paren) and the verse text.
  static final RegExp _verseMarker =
      RegExp(r'^\s*(\d{1,3})([ab])?[\.\)\s]\s*(.+)$', dotAll: true);

  static final RegExp _chapterMarker = RegExp(
      r'^\s*(CAP[IÍ]TULO|CAP\.?|CHAPTER)\b',
      caseSensitive: false);

  // Editorial labels that are never scripture even if oddly formatted.
  static final RegExp _editorialLabel = RegExp(
      r'^\s*(INTRODU[ÇC][ÃA]O|PREF[ÁA]CIO|PROLOGO|PRÓLOGO|NOTA|NOTAS|'
      r'COMENT[ÁA]RIO|ADVERT[ÊE]NCIA|ARGUMENTO|SUM[ÁA]RIO|RESUMO)\b',
      caseSensitive: false);

  /// Fraction of letters that are uppercase (ignoring digits/punct/spaces).
  static double _uppercaseRatio(String s) {
    var letters = 0, upper = 0;
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      if (RegExp(r'\p{L}', unicode: true).hasMatch(c)) {
        letters++;
        if (c.toUpperCase() == c && c.toLowerCase() != c) upper++;
      }
    }
    return letters == 0 ? 0 : upper / letters;
  }

  static int _wordCount(String s) =>
      s.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Classify one already-trimmed, non-empty line.
  SourceBlock classify(String line, int sourceLine) {
    final raw = line;
    final trimmed = line.trim();

    // 1) Chapter marker — consumed, never a verse.
    if (_chapterMarker.hasMatch(trimmed)) {
      return SourceBlock(
          kind: BlockKind.chapterMarker, text: trimmed, sourceLine: sourceLine);
    }

    // 2) Explicit editorial label.
    if (_editorialLabel.hasMatch(trimmed)) {
      return SourceBlock(
          kind: BlockKind.editorialNote, text: trimmed, sourceLine: sourceLine);
    }

    // 3) Verse marker present?
    final m = _verseMarker.firstMatch(raw);
    if (m != null) {
      final number = int.parse(m.group(1)!);
      final suffix = m.group(2) ?? '';
      final body = m.group(3)!.trim();

      // Guard: a numbered line whose BODY is itself a heading
      // (e.g. "1 LIVRO SAPIENCIAL") must not pass as scripture.
      final bodyUpper = _uppercaseRatio(body);
      final looksLikeTitle =
          bodyUpper >= 0.80 && _wordCount(body) <= 6 && !body.contains(',');
      if (looksLikeTitle) {
        return SourceBlock(
            kind: BlockKind.sectionHeading,
            text: body,
            sourceLine: sourceLine);
      }
      return SourceBlock(
        kind: BlockKind.verse,
        text: body,
        verseNumber: number,
        verseSuffix: suffix,
        sourceLine: sourceLine,
      );
    }

    // 4) No verse marker → editorial. Distinguish a SECTION TITLE
    //    (short, mostly uppercase / title-case) from prose intro.
    final upper = _uppercaseRatio(trimmed);
    final words = _wordCount(trimmed);
    if (upper >= 0.60 && words <= 8) {
      return SourceBlock(
          kind: BlockKind.sectionHeading,
          text: trimmed,
          sourceLine: sourceLine);
    }
    if (words <= 10 && trimmed == _titleCase(trimmed)) {
      // e.g. "Primeiro dia da Criação" rendered as a paragraph title
      return SourceBlock(
          kind: BlockKind.sectionHeading,
          text: trimmed,
          sourceLine: sourceLine);
    }
    // Longer unnumbered prose → chapter/book introduction.
    return SourceBlock(
        kind: BlockKind.chapterIntro, text: trimmed, sourceLine: sourceLine);
  }

  static String _titleCase(String s) {
    final words = s.split(RegExp(r'\s+'));
    const minor = {'da', 'de', 'do', 'das', 'dos', 'e', 'a', 'o', 'em'};
    return words.asMap().entries.map((e) {
      final w = e.value;
      if (w.isEmpty) return w;
      if (e.key != 0 && minor.contains(w.toLowerCase())) return w.toLowerCase();
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
