import 'package:flutter/foundation.dart';

enum Testament { ot, nt }

@immutable
class BibleBook {
  final String id;
  final Testament testament;
  final int order;
  final bool isDeutero;
  final int chapterCount;
  final String emblemAsset;
  final String name;
  final String abbrev;

  const BibleBook({
    required this.id,
    required this.testament,
    required this.order,
    required this.isDeutero,
    required this.chapterCount,
    required this.emblemAsset,
    required this.name,
    required this.abbrev,
  });
}

@immutable
class VerseRef {
  final String bookId;
  final int chapter;
  final int verse;
  const VerseRef(this.bookId, this.chapter, this.verse);

  @override
  bool operator ==(Object other) =>
      other is VerseRef &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);
}

@immutable
class Verse {
  final int number;
  final String suffix;
  final String text;
  const Verse(this.number, this.text, {this.suffix = ''});
}

@immutable
class SectionHeading {
  final int beforeVerse;
  final String kind;
  final String text;
  const SectionHeading(this.beforeVerse, this.kind, this.text);
}

/// A chapter ready to render: verses interleaved with their headings.
@immutable
class ChapterContent {
  final String bookId;
  final int chapter;
  final List<Verse> verses;
  final List<SectionHeading> headings;
  const ChapterContent(this.bookId, this.chapter, this.verses, this.headings);

  bool get isEmpty => verses.isEmpty;
}

/// One row of Parallel Reading: a single canonical verse number paired with its
/// rendering in each translation. Either side may be `null` when that
/// translation lacks the verse (different versification, deuterocanonical gaps,
/// Psalms numbering, etc.) — the UI then shows a "not available" placeholder.
@immutable
class ParallelVerse {
  final int number;
  final Verse? primary;
  final Verse? secondary;
  const ParallelVerse(this.number, this.primary, this.secondary);

  /// Text used for the canonical snapshot (commentary header, share, favorite):
  /// the primary reading, falling back to the secondary when primary is absent.
  String get canonicalText => primary?.text ?? secondary?.text ?? '';
}

/// Two single-translation chapters aligned by canonical verse number for
/// side-by-side / stacked reading. The primary chapter is the spine: its order
/// and section headings win. Notes/highlights/favorites are unaffected — they
/// always key off the canonical [VerseRef] (bookId, chapter, verse), never a
/// column.
@immutable
class ParallelChapter {
  final String bookId;
  final int chapter;
  final List<ParallelVerse> rows;
  final List<SectionHeading> headings; // from the primary translation
  const ParallelChapter(this.bookId, this.chapter, this.rows, this.headings);

  bool get isEmpty => rows.isEmpty;

  /// Aligns [primary] and [secondary] by verse number. Primary verses keep
  /// their native order (including suffix splits); each is paired with the
  /// secondary verse of the same number when one exists. Verses present only in
  /// the secondary translation are appended in numeric order so nothing is
  /// silently dropped. A null [secondary] yields rows with no secondary side
  /// (the "no secondary translation" case still renders the primary cleanly).
  factory ParallelChapter.align(
      ChapterContent primary, ChapterContent? secondary) {
    final secVerses = secondary?.verses ?? const <Verse>[];
    final secByNum = <int, Verse>{for (final v in secVerses) v.number: v};
    final primaryNums = <int>{for (final v in primary.verses) v.number};

    final rows = <ParallelVerse>[
      for (final v in primary.verses)
        ParallelVerse(v.number, v, secByNum[v.number]),
    ];
    final extras = secVerses
        .where((v) => !primaryNums.contains(v.number))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    rows.addAll(extras.map((v) => ParallelVerse(v.number, null, v)));

    return ParallelChapter(
        primary.bookId, primary.chapter, rows, primary.headings);
  }
}

/// A search result. `snippet` may contain U+2068…U+2069 markers around matched
/// terms for emphasis in the UI.
@immutable
class VerseHit {
  final VerseRef ref;
  final String snippet;
  const VerseHit(this.ref, this.snippet);
}

@immutable
class CommentaryHit {
  final VerseRef ref;
  final String fatherName;
  final String century;
  final String snippet;
  const CommentaryHit(this.ref, this.fatherName, this.century, this.snippet);
}

@immutable
class Commentary {
  final int id;
  final VerseRef ref;
  final String fatherName;
  final String century;
  final String? source;
  final bool isMachineTranslation;
  final String text;

  const Commentary({
    required this.id,
    required this.ref,
    required this.fatherName,
    required this.century,
    required this.source,
    required this.isMachineTranslation,
    required this.text,
  });
}
