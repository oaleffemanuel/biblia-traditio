import '../models/blocks.dart';
import '../models/canon.dart';

enum Severity { error, warning }

class Finding {
  final Severity severity;
  final String code;
  final String message;
  final int? chapter;
  final int? verse;
  final String? sample;

  Finding(this.severity, this.code, this.message,
      {this.chapter, this.verse, this.sample});

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'code': code,
        'message': message,
        if (chapter != null) 'chapter': chapter,
        if (verse != null) 'verse': verse,
        if (sample != null) 'sample': sample,
      };
}

class ValidationReport {
  final String bookId;
  final List<Finding> findings;
  ValidationReport(this.bookId, this.findings);

  bool get hasErrors => findings.any((f) => f.severity == Severity.error);
  int get errorCount =>
      findings.where((f) => f.severity == Severity.error).length;
  int get warningCount =>
      findings.where((f) => f.severity == Severity.warning).length;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'errors': errorCount,
        'warnings': warningCount,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}

/// Validates parsed chapters. Errors block the DB build; warnings need review.
class VerseValidator {
  static final _upperRatio = RegExp(r'\p{Lu}', unicode: true);
  static final _anyLetter = RegExp(r'\p{L}', unicode: true);

  static final _suspiciousTitles = RegExp(
      r'^(LIVRO|PRIMEIRA|SEGUNDA|TERCEIRA|PARTE|DISCURSO|CAP[IÍ]TULO|'
      r'PROVERBIOS|PROVÉRBIOS|PROL[OÓ]GO|INTRODU[ÇC][ÃA]O)\b',
      caseSensitive: false);

  ValidationReport validate(String bookId, List<ParsedChapter> chapters) {
    final f = <Finding>[];
    final canon = kCanonById[bookId];

    if (canon == null) {
      f.add(Finding(Severity.error, 'unknown_book',
          'Book id "$bookId" is not in the canonical registry.'));
    }

    // Chapter-count sanity (hint only — versification varies).
    if (canon != null && chapters.isNotEmpty) {
      final maxCh = chapters.map((c) => c.chapter).reduce((a, b) => a > b ? a : b);
      if (maxCh != canon.chapterCount) {
        f.add(Finding(Severity.warning, 'chapter_count',
            'Parsed $maxCh chapters; registry expects ${canon.chapterCount}.'));
      }
    }

    for (final ch in chapters) {
      // Heading leaked into verses?
      for (final h in ch.headings) {
        // headings are fine by definition; nothing to flag here.
        if (h.kind == 'section' && h.text.trim().isEmpty) {
          f.add(Finding(Severity.warning, 'empty_heading',
              'Empty section heading.', chapter: ch.chapter));
        }
      }

      final numbers = ch.verses.map((v) => v.verse).toList();

      // Duplicates.
      final seen = <int>{};
      for (final n in numbers) {
        if (!seen.add(n)) {
          f.add(Finding(Severity.error, 'duplicate_verse',
              'Duplicate verse number $n.',
              chapter: ch.chapter, verse: n));
        }
      }

      // Jumps / missing.
      for (var i = 1; i < numbers.length; i++) {
        final gap = numbers[i] - numbers[i - 1];
        if (gap > 1) {
          f.add(Finding(Severity.warning, 'verse_gap',
              'Verse numbering jumps from ${numbers[i - 1]} to ${numbers[i]}.',
              chapter: ch.chapter, verse: numbers[i]));
        } else if (gap <= 0) {
          f.add(Finding(Severity.error, 'verse_order',
              'Verse $i out of order (${numbers[i - 1]} → ${numbers[i]}).',
              chapter: ch.chapter, verse: numbers[i]));
        }
      }
      if (numbers.isNotEmpty && numbers.first != 1) {
        f.add(Finding(Severity.warning, 'missing_first',
            'Chapter starts at verse ${numbers.first}, not 1.',
            chapter: ch.chapter, verse: numbers.first));
      }

      // Per-verse content checks.
      for (final v in ch.verses) {
        final text = v.text.trim();
        final letters = _anyLetter.allMatches(text).length;
        final uppers = _upperRatio.allMatches(text).length;
        final ratio = letters == 0 ? 0 : uppers / letters;
        final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

        if (ratio >= 0.80 && letters > 0) {
          f.add(Finding(Severity.error, 'allcaps_verse',
              'Verse looks like a heading (mostly uppercase).',
              chapter: ch.chapter, verse: v.verse, sample: text));
        }
        // Only a heading if it BOTH starts with a title word AND actually
        // looks like a heading (mostly uppercase, or a short label with no
        // sentence punctuation) — sentence-case verses that merely begin with
        // "Provérbios"/"Segunda" are real Scripture, not headings.
        final headingLike = ratio >= 0.6 ||
            (words <= 4 &&
                !text.contains(',') &&
                !text.endsWith('.') &&
                !text.endsWith(';') &&
                !text.endsWith(':'));
        if (_suspiciousTitles.hasMatch(text) && headingLike) {
          f.add(Finding(Severity.error, 'heading_as_verse',
              'Verse text matches an editorial-title pattern.',
              chapter: ch.chapter, verse: v.verse, sample: text));
        }
        if (words < 5) {
          f.add(Finding(Severity.warning, 'short_verse',
              'Very short verse (<5 words) — review.',
              chapter: ch.chapter, verse: v.verse, sample: text));
        }
        if (text.isEmpty) {
          f.add(Finding(Severity.error, 'empty_verse', 'Empty verse text.',
              chapter: ch.chapter, verse: v.verse));
        }
      }
    }
    return ValidationReport(bookId, f);
  }
}
