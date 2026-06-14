import '../detectors/heading_detector.dart';
import '../models/blocks.dart';

/// Parses a plain-text scripture source for ONE book into [ParsedChapter]s.
///
/// Convention (correctness-first, matches structured PD transcriptions):
///   • Chapter boundaries come from "CAPÍTULO N" markers (roman or arabic),
///     or — if the source has none — from an externally supplied chapter split.
///   • Each verse line begins with its source verse number.
///   • Unnumbered lines are classified by [HeadingDetector]: section titles and
///     intros become metadata; long prose immediately after a verse is treated
///     as a continuation and appended to that verse.
///
/// Verse numbers always come from the source marker, so editorial lines can
/// never shift subsequent verse numbering.
class ScriptureParser {
  final HeadingDetector _detector;
  ScriptureParser([HeadingDetector? detector])
      : _detector = detector ?? HeadingDetector();

  List<ParsedChapter> parseBook(String raw) {
    final lines = raw.split('\n');
    final chapters = <ParsedChapter>[];

    int? currentChapter;
    var verses = <ParsedVerse>[];
    var headings = <ParsedHeading>[];
    ParsedVerse? lastVerse;
    final pendingHeadings = <ParsedHeading>[]; // headings awaiting next verse

    void flushChapter() {
      if (currentChapter != null) {
        chapters.add(ParsedChapter(currentChapter!, verses, headings));
      }
      verses = <ParsedVerse>[];
      headings = <ParsedHeading>[];
      lastVerse = null;
      pendingHeadings.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      final block = _detector.classify(line, i + 1);

      switch (block.kind) {
        case BlockKind.chapterMarker:
          flushChapter();
          currentChapter = _parseChapterNumber(block.text) ??
              (chapters.length + 1);
          break;

        case BlockKind.verse:
          currentChapter ??= 1; // source with no explicit chapter marker
          final v = ParsedVerse(block.verseNumber!, block.text,
              suffix: block.verseSuffix);
          verses.add(v);
          lastVerse = v;
          // attach any headings that were waiting for this verse
          for (final h in pendingHeadings) {
            headings.add(ParsedHeading(h.kind, v.verse, h.text));
          }
          pendingHeadings.clear();
          break;

        case BlockKind.sectionHeading:
          pendingHeadings.add(ParsedHeading('section', -1, block.text));
          break;

        case BlockKind.chapterIntro:
          // Long unnumbered prose: continuation of the current verse if one is
          // open; otherwise a chapter introduction.
          if (lastVerse != null && pendingHeadings.isEmpty) {
            final merged = ParsedVerse(
                lastVerse!.verse, '${lastVerse!.text} ${block.text}'.trim(),
                suffix: lastVerse!.suffix);
            verses[verses.length - 1] = merged;
            lastVerse = merged;
          } else {
            pendingHeadings.add(ParsedHeading('chapterIntro', -1, block.text));
          }
          break;

        case BlockKind.bookIntro:
          pendingHeadings.add(ParsedHeading('bookIntro', -1, block.text));
          break;

        case BlockKind.editorialNote:
          pendingHeadings.add(ParsedHeading('note', -1, block.text));
          break;

        case BlockKind.unknown:
          pendingHeadings.add(ParsedHeading('note', -1, block.text));
          break;
      }
    }
    flushChapter();
    return chapters;
  }

  static final RegExp _chapterNum =
      RegExp(r'(\d+|[IVXLCDM]+)\s*$', caseSensitive: false);

  int? _parseChapterNumber(String marker) {
    final m = _chapterNum.firstMatch(marker.trim());
    if (m == null) return null;
    final token = m.group(1)!;
    final arabic = int.tryParse(token);
    if (arabic != null) return arabic;
    return _roman(token.toUpperCase());
  }

  int? _roman(String s) {
    const map = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000};
    var total = 0, prev = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      final v = map[s[i]];
      if (v == null) return null;
      if (v < prev) {
        total -= v;
      } else {
        total += v;
        prev = v;
      }
    }
    return total == 0 ? null : total;
  }
}
