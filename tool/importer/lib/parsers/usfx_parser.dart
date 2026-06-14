import 'dart:io';

import 'package:xml/xml.dart';

import '../models/blocks.dart';

/// Parses a USFX Bible (e.g. the Clementine Vulgate from open-bibles) into
/// per-book chapters keyed by canonical id.
///
/// USFX is flat: `<book id="GEN"><h>Genesis</h><c id="1"/><v id="1"/>text<ve/>…`.
/// The `<h>` book title is editorial metadata and is never emitted as a verse;
/// verse numbers come straight from each `<v id>` marker.
class UsfxParser {
  final Map<String, List<ParsedChapter>> books = {};
  final List<String> warnings = [];
  int verseCount = 0;

  /// USFM book code -> canonical id (matches the patristic corpus' codes).
  static const Map<String, String> usfmToId = {
    'GEN': 'gn', 'EXO': 'ex', 'LEV': 'lv', 'NUM': 'nm', 'DEU': 'dt',
    'JOS': 'jo', 'JDG': 'jgs', 'RUT': 'rt', '1SA': '1sm', '2SA': '2sm',
    '1KI': '1kgs', '2KI': '2kgs', '1CH': '1chr', '2CH': '2chr', 'EZR': 'ezr',
    'NEH': 'neh', 'TOB': 'tb', 'JDT': 'jdt', 'EST': 'est', '1MA': '1mac',
    '2MA': '2mac', 'JOB': 'jb', 'PSA': 'ps', 'PRO': 'prv', 'ECC': 'eccl',
    'SNG': 'sg', 'WIS': 'ws', 'SIR': 'sir', 'ISA': 'is', 'JER': 'jer',
    'LAM': 'lam', 'BAR': 'bar', 'EZK': 'ez', 'DAN': 'dn', 'HOS': 'hos',
    'JOL': 'jl', 'AMO': 'am', 'OBA': 'ob', 'JON': 'jon', 'MIC': 'mi',
    'NAM': 'na', 'HAB': 'hb', 'ZEP': 'zep', 'HAG': 'hg', 'ZEC': 'zec',
    'MAL': 'mal', 'MAT': 'mt', 'MRK': 'mk', 'LUK': 'lk', 'JHN': 'jn',
    'ACT': 'acts', 'ROM': 'rom', '1CO': '1cor', '2CO': '2cor', 'GAL': 'gal',
    'EPH': 'eph', 'PHP': 'phil', 'COL': 'col', '1TH': '1thes', '2TH': '2thes',
    '1TI': '1tm', '2TI': '2tm', 'TIT': 'tit', 'PHM': 'phlm', 'HEB': 'heb',
    'JAS': 'jas', '1PE': '1pt', '2PE': '2pt', '1JN': '1jn', '2JN': '2jn',
    '3JN': '3jn', 'JUD': 'jud', 'REV': 'rv',
  };

  Future<void> parseFile(String path) async {
    final doc = XmlDocument.parse(await File(path).readAsString());
    for (final book in doc.findAllElements('book')) {
      final code = (book.getAttribute('id') ?? '').toUpperCase();
      final id = usfmToId[code];
      if (id == null) {
        warnings.add('Unmatched USFM code: "$code" — skipped.');
        continue;
      }

      final byChapter = <int, List<ParsedVerse>>{};
      int? chapter;
      int? verse;
      final buf = StringBuffer();

      void flush() {
        if (chapter != null && verse != null) {
          final t = buf.toString().trim();
          if (t.isNotEmpty) {
            byChapter.putIfAbsent(chapter!, () => []).add(ParsedVerse(verse!, t));
            verseCount++;
          }
        }
        buf.clear();
        verse = null;
      }

      for (final node in book.children) {
        if (node is XmlElement) {
          switch (node.name.local) {
            case 'c':
              flush();
              chapter = _leadingInt(node.getAttribute('id'));
              break;
            case 'v':
              flush();
              verse = _leadingInt(node.getAttribute('id'));
              break;
            case 've':
              flush();
              break;
            default:
              break; // <h> book title and any other markup: not Scripture
          }
        } else if (node is XmlText && verse != null) {
          buf.write(node.value);
        }
      }
      flush();

      final chapters = byChapter.entries
          .map((e) => ParsedChapter(e.key, e.value, const []))
          .toList()
        ..sort((a, b) => a.chapter.compareTo(b.chapter));
      books[id] = chapters;
    }
  }

  static int? _leadingInt(String? s) {
    if (s == null) return null;
    final m = RegExp(r'\d+').firstMatch(s);
    return m == null ? null : int.parse(m.group(0)!);
  }
}
