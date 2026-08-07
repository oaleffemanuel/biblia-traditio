import 'patristics_parser.dart';

/// Result of overlaying the corrected corpus on top of the original one, plus
/// the numbers needed for the before/after coverage report.
class OverlayResult {
  final PatristicsParseResult merged;

  final int baseCommentaries;
  final int overlayCommentaries;
  final int baseVerses;
  final int overlayVerses;

  /// Verses the corrected corpus does not cover, kept from the original so the
  /// overlay can never reduce coverage.
  final int retainedVerses;
  final int retainedCommentaries;

  /// Original-corpus author names folded into a corrected-corpus author
  /// (`old name` → `canonical name`).
  final Map<String, String> unifiedAuthors;

  /// Books where the corrected corpus covers noticeably fewer verses than the
  /// original — reported, never silently accepted.
  final List<String> regressedBooks;

  const OverlayResult({
    required this.merged,
    required this.baseCommentaries,
    required this.overlayCommentaries,
    required this.baseVerses,
    required this.overlayVerses,
    required this.retainedVerses,
    required this.retainedCommentaries,
    required this.unifiedAuthors,
    required this.regressedBooks,
  });
}

/// What [dedupeCommentaries] removed, for the build report.
class DedupeReport {
  /// Rows whose text was byte-identical to one already kept on the same verse
  /// from the same author.
  final int exact;

  /// Rows identical once case, accents, punctuation and whitespace are
  /// ignored — the same excerpt re-typeset ("«E Deus formou…»" vs "E Deus
  /// formou…").
  final int normalised;

  /// Kept, but worth knowing about: one excerpt sits entirely inside another
  /// from the same author on the same verse. These are NOT removed — in a
  /// catena a short quotation and the longer passage it came from are often
  /// both genuine — but a curator should eyeball them.
  final List<String> containedSamples;
  final int contained;

  const DedupeReport(
      this.exact, this.normalised, this.contained, this.containedSamples);

  int get removed => exact + normalised;
}

/// Drops entries that repeat the *same text* from the *same author* on the
/// *same verse*.
///
/// It deliberately does not touch the case the corpus is full of: one Father
/// with several **different** excerpts on one verse. That is what a catena is —
/// Cyril of Alexandria has five distinct comments on John 1:1 — and collapsing
/// them would destroy the corpus, not clean it.
///
/// When two rows normalise to the same text the longer original is kept, so
/// the better-typeset variant survives rather than whichever happened to be
/// parsed first.
(PatristicsParseResult, DedupeReport) dedupeCommentaries(
    PatristicsParseResult input) {
  final kept = <String, CommentaryRecord>{}; // key → winner
  final order = <String>[]; // preserves corpus order
  var exact = 0, normalised = 0;

  for (final rec in input.commentaries) {
    final base = '${rec.bookId}|${rec.chapter}|${rec.verse}|${rec.fatherName}';
    final exactKey = '$base|${rec.text}';
    final normKey = '$base|${_normaliseText(rec.text)}';

    if (kept.containsKey(exactKey)) {
      exact++;
      continue;
    }
    final rival = kept[normKey];
    if (rival != null) {
      normalised++;
      // Keep whichever carries more of the original typesetting.
      if (rec.text.length > rival.text.length) {
        kept[normKey] = rec;
        kept['$base|${rival.text}'] = rec;
      }
      kept[exactKey] = kept[normKey]!;
      continue;
    }
    kept[exactKey] = rec;
    kept[normKey] = rec;
    order.add(exactKey);
  }

  // Report (but keep) excerpts that contain one another.
  final byVerseAuthor = <String, List<String>>{};
  for (final key in order) {
    final rec = kept[key]!;
    byVerseAuthor
        .putIfAbsent(
            '${rec.bookId}|${rec.chapter}|${rec.verse}|${rec.fatherName}',
            () => [])
        .add(_normaliseText(rec.text));
  }
  var contained = 0;
  final samples = <String>[];
  for (final entry in byVerseAuthor.entries) {
    final texts = entry.value;
    if (texts.length < 2) continue;
    for (var i = 0; i < texts.length; i++) {
      for (var j = i + 1; j < texts.length; j++) {
        final a = texts[i], b = texts[j];
        if (a.length < 40 || b.length < 40) continue;
        if (a.contains(b) || b.contains(a)) {
          contained++;
          if (samples.length < 10) samples.add(entry.key);
          break;
        }
      }
    }
  }

  final out = PatristicsParseResult()
    ..filesProcessed = input.filesProcessed
    ..orphans = input.orphans
    ..warnings.addAll(input.warnings);
  for (final key in order) {
    out.commentaries.add(kept[key]!);
  }
  out.fathers.addAll(out.commentaries.map((c) => c.fatherName));

  return (out, DedupeReport(exact, normalised, contained, samples));
}

String _normaliseText(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buf.write(_foldChar(ch));
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

String _foldChar(String ch) => _accents[ch] ?? ch;

/// Merges [base] (the original corpus — the coverage floor) with [overlay] (the
/// corrected corpus). The corrected corpus wins **per verse**: wherever it has
/// any commentary for (book, chapter, verse), the original entries for that
/// verse are dropped and replaced. Verses the corrected corpus is silent about
/// keep their original commentary, so a partially-complete corrected corpus can
/// never shrink what the app already ships.
///
/// Retained original entries also inherit the corrected corpus's author
/// metadata (canonical name, year, função) whenever the two corpora clearly
/// name the same person — see [unifyAuthorNames].
OverlayResult overlayPatristics(
    PatristicsParseResult base, PatristicsParseResult overlay) {
  final overlayKeys = overlay.coveredVerses;
  final baseKeys = base.coveredVerses;

  final aliases = unifyAuthorNames(base.fathers, overlay.fathers);
  final metaByName = <String, CommentaryRecord>{};
  for (final c in overlay.commentaries) {
    metaByName.putIfAbsent(c.fatherName, () => c);
  }

  final merged = PatristicsParseResult()
    ..filesProcessed = overlay.filesProcessed
    ..orphans = base.orphans + overlay.orphans
    ..warnings.addAll([...base.warnings, ...overlay.warnings]);

  var retainedCommentaries = 0;
  for (final rec in base.commentaries) {
    if (overlayKeys.contains(rec.key)) continue; // corrected wins
    retainedCommentaries++;
    final canonical = aliases[rec.fatherName];
    final meta = canonical == null ? null : metaByName[canonical];
    merged.commentaries.add(meta == null
        ? rec
        : rec.withFather(canonical!, meta.role, meta.year));
  }
  merged.commentaries.addAll(overlay.commentaries);
  merged.fathers.addAll(merged.commentaries.map((c) => c.fatherName));

  // Per-book regression check on verse coverage (>10% loss is worth naming).
  final baseByBook = <String, int>{};
  for (final k in baseKeys) {
    baseByBook[k.bookId] = (baseByBook[k.bookId] ?? 0) + 1;
  }
  final overlayByBook = <String, int>{};
  for (final k in overlayKeys) {
    overlayByBook[k.bookId] = (overlayByBook[k.bookId] ?? 0) + 1;
  }
  final regressed = <String>[
    for (final e in baseByBook.entries)
      if ((overlayByBook[e.key] ?? 0) < e.value * 0.9)
        '${e.key}: ${e.value} → ${overlayByBook[e.key] ?? 0} verses',
  ]..sort();

  return OverlayResult(
    merged: merged,
    baseCommentaries: base.commentaries.length,
    overlayCommentaries: overlay.commentaries.length,
    baseVerses: baseKeys.length,
    overlayVerses: overlayKeys.length,
    retainedVerses: baseKeys.difference(overlayKeys).length,
    retainedCommentaries: retainedCommentaries,
    unifiedAuthors: aliases,
    regressedBooks: regressed,
  );
}

/// Maps original-corpus author names onto their corrected-corpus spelling when
/// the two unambiguously name the same person — "Santo Agostinho" →
/// "Santo Agostinho de Hipona". Matching is deliberately conservative and runs
/// in two passes over the honorific-stripped word sets:
///
///  1. **Same words** — "São Tomás de Aquino" and "Santo Tomás de Aquino" both
///     reduce to {tomas, aquino}. An exact set match wins outright, which also
///     stops the name being swallowed by a longer superset such as "Bíblia de
///     Estudo de Santo Tomás de Aquino".
///  2. **Strict subset of exactly one** — "Santo Agostinho" {agostinho} sits
///     inside "Santo Agostinho de Hipona" and nothing else.
///
/// "São Gregório" therefore stays put (subset of Magno, de Nissa and o Teólogo
/// alike), and no two distinct Fathers are ever collapsed into one.
Map<String, String> unifyAuthorNames(
    Set<String> oldNames, Set<String> newNames) {
  final newTokens = {for (final n in newNames) n: _tokens(n)};
  final aliases = <String, String>{};
  for (final old in oldNames) {
    if (newNames.contains(old)) continue; // already canonical
    final tokens = _tokens(old);
    if (tokens.isEmpty) continue;
    final exact = <String>[
      for (final e in newTokens.entries)
        if (e.value.length == tokens.length && tokens.every(e.value.contains))
          e.key,
    ];
    if (exact.length == 1) {
      aliases[old] = exact.first;
      continue;
    }
    if (exact.isNotEmpty) continue; // ambiguous — leave the name alone
    final subsets = <String>[
      for (final e in newTokens.entries)
        if (tokens.length < e.value.length && tokens.every(e.value.contains))
          e.key,
    ];
    if (subsets.length == 1) aliases[old] = subsets.first;
  }
  return aliases;
}

const _honorifics = {
  'sao', 'santo', 'santa', 's', 'beato', 'beata', 'papa', 'dom', 'o', 'a',
  'de', 'da', 'do', 'das', 'dos', 'e', 'the', 'saint', 'st',
};

Set<String> _tokens(String name) => _normaliseName(name)
    .split(' ')
    .where((t) => t.length > 1 && !_honorifics.contains(t))
    .toSet();

String _normaliseName(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[áàâãä]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[íìîï]'), 'i')
    .replaceAll(RegExp(r'[óòôõö]'), 'o')
    .replaceAll(RegExp(r'[úùûü]'), 'u')
    .replaceAll(RegExp(r'[ç]'), 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();
