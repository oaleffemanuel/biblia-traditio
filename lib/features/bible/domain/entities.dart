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
