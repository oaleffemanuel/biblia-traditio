/// Typed source blocks. A raw line becomes exactly one classified block.
/// Verses are NEVER created by position — only when a real verse marker exists.
library;

enum BlockKind {
  verse, // genuine scripture, carries a source-given verse number
  sectionHeading, // editorial title above verses ("LIVRO SAPIENCIAL")
  chapterMarker, // "CAPÍTULO I" — consumed, never stored as a verse
  chapterIntro, // prose summary opening a chapter
  bookIntro, // historical/translator preface to a book
  editorialNote, // footnote/study-note/label
  unknown, // could not classify — flagged for review, never a verse
}

class SourceBlock {
  final BlockKind kind;
  final String text;

  /// Verse number taken FROM THE SOURCE (never auto-incremented).
  /// Non-null only when [kind] == verse.
  final int? verseNumber;
  final String verseSuffix; // '', 'a', 'b'
  final int sourceLine;

  const SourceBlock({
    required this.kind,
    required this.text,
    required this.sourceLine,
    this.verseNumber,
    this.verseSuffix = '',
  });

  bool get isVerse => kind == BlockKind.verse;
  bool get isMetadata =>
      kind == BlockKind.sectionHeading ||
      kind == BlockKind.chapterIntro ||
      kind == BlockKind.bookIntro ||
      kind == BlockKind.editorialNote;
}

/// A fully parsed chapter: verses separated from editorial metadata.
class ParsedChapter {
  final int chapter;
  final List<ParsedVerse> verses;
  final List<ParsedHeading> headings;

  ParsedChapter(this.chapter, this.verses, this.headings);

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        if (headings.isNotEmpty)
          'metadata': {
            'headings': headings.map((h) => h.toJson()).toList(),
            // convenience: first section title, matching the spec example
            if (headings.any((h) => h.kind == 'section'))
              'sectionTitle': headings
                  .firstWhere((h) => h.kind == 'section')
                  .text,
          },
        'verses': verses.map((v) => v.toJson()).toList(),
      };
}

class ParsedVerse {
  final int verse;
  final String suffix;
  final String text;
  ParsedVerse(this.verse, this.text, {this.suffix = ''});

  Map<String, dynamic> toJson() => {
        'verse': verse,
        if (suffix.isNotEmpty) 'suffix': suffix,
        'text': text,
      };
}

class ParsedHeading {
  final String kind; // 'section'|'chapterIntro'|'bookIntro'|'note'
  final int beforeVerse; // heading appears above this verse number
  final String text;
  ParsedHeading(this.kind, this.beforeVerse, this.text);

  Map<String, dynamic> toJson() =>
      {'kind': kind, 'beforeVerse': beforeVerse, 'text': text};
}
