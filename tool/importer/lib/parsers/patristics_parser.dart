import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/canon.dart';

class CommentaryRecord {
  final String bookId;
  final int chapter;
  final int verse;
  final String fatherName;
  final String year; // raw year string from source
  final String century; // derived, e.g. "V"
  final String? source;
  final String lang;
  final bool isMachineTranslation;
  final String text;

  CommentaryRecord({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.fatherName,
    required this.year,
    required this.century,
    required this.source,
    required this.lang,
    required this.isMachineTranslation,
    required this.text,
  });
}

class PatristicsParseResult {
  final List<CommentaryRecord> commentaries = [];
  final Set<String> fathers = {};
  final List<String> warnings = [];
  int filesProcessed = 0;
  int orphans = 0; // refs whose book id could not be resolved
}

/// Maps a Hebrew/Masoretic psalm (chapter, verse) to the Vulgate/Septuagint
/// numbering used by the app's scripture. Most psalms differ by one (Vulgate
/// merges Heb 9+10, so everything after shifts); the merge/split regions around
/// 113–117 and 147 are handled explicitly. Verse offsets are derived from the
/// Vulgate verse counts and reconcile exactly except Vulgate 9 (the Heb 9/10
/// boundary is off by one due to the Vulgate title verse — a documented edge).
(int, int) psalmHebrewToVulgate(int hc, int hv) {
  if (hc <= 8) return (hc, hv);
  if (hc == 9) return (9, hv); // Heb 9 → Vulgate 9 (first part)
  if (hc == 10) return (9, hv + 21); // Heb 10 appended into Vulgate 9
  if (hc <= 113) return (hc - 1, hv); // 11..113 → 10..112
  if (hc == 114) return (113, hv); // Heb 114 → Vulgate 113 (first part)
  if (hc == 115) return (113, hv + 8); // Heb 115 appended (after Heb 114's 8 vv)
  if (hc == 116) return hv <= 9 ? (114, hv) : (115, hv - 9); // split
  if (hc <= 146) return (hc - 1, hv); // 117..146 → 116..145
  if (hc == 147) return hv <= 11 ? (146, hv) : (147, hv - 11); // split
  return (hc, hv); // 148..150 coincide
}

/// Ingests the verse-keyed patristic corpus:
///   { id, name, language, translation_engine, format,
///     chapters: { "<ch>": { "<verse>": [ {author, year, text}, ... ] } } }
class PatristicsParser {
  final Map<String, String> aliases; // source-code variant -> canonical
  PatristicsParser(this.aliases);

  static Future<PatristicsParser> fromDir(String dir) async {
    final aliasFile = File(p.join(dir, 'aliases_normalizados.json'));
    var aliases = <String, String>{};
    if (await aliasFile.exists()) {
      final raw = jsonDecode(await aliasFile.readAsString()) as Map;
      aliases = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return PatristicsParser(aliases);
  }

  String? _resolveBookId(String rawId) {
    final id = rawId.toLowerCase().trim();
    if (kCanonById.containsKey(id)) return id;
    final aliased = aliases[id];
    if (aliased != null && kCanonById.containsKey(aliased)) return aliased;
    return null;
  }

  Future<PatristicsParseResult> parseDir(String dir) async {
    final result = PatristicsParseResult();
    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('coment-') &&
            f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      } catch (e) {
        result.warnings.add('Skipped ${p.basename(file.path)}: parse error $e');
        continue;
      }
      result.filesProcessed++;

      final rawId = (data['id'] ?? '').toString();
      final bookId = _resolveBookId(rawId);
      final lang = (data['language'] ?? 'pt-BR').toString();
      final engine = (data['translation_engine'] ?? '').toString();
      final isMt = engine.toLowerCase().contains('argos') ||
          engine.toLowerCase().contains('local');

      if (bookId == null) {
        result.warnings.add(
            'Unresolved book id "$rawId" in ${p.basename(file.path)} — skipped.');
        result.orphans++;
        continue;
      }

      final chapters = data['chapters'] as Map<String, dynamic>? ?? const {};
      for (final chEntry in chapters.entries) {
        final ch = int.tryParse(chEntry.key);
        if (ch == null) continue;
        final verses = chEntry.value as Map<String, dynamic>? ?? const {};
        for (final vEntry in verses.entries) {
          final vs = int.tryParse(vEntry.key);
          if (vs == null) continue;
          final list = vEntry.value;
          if (list is! List) continue;
          // The Psalms commentary corpus is Hebrew/Masoretic-numbered; the app's
          // scripture is Vulgate/Septuagint-numbered. Remap so commentary lands
          // on the matching Vulgate psalm (otherwise it's offset by one).
          final (rch, rvs) =
              bookId == 'ps' ? psalmHebrewToVulgate(ch, vs) : (ch, vs);
          for (final item in list) {
            if (item is! Map) continue;
            final author = (item['author'] ?? '').toString().trim();
            final year = (item['year'] ?? '').toString().trim();
            final text = (item['text'] ?? '').toString().trim();
            if (author.isEmpty || text.isEmpty) continue;
            result.fathers.add(author);
            result.commentaries.add(CommentaryRecord(
              bookId: bookId,
              chapter: rch,
              verse: rvs,
              fatherName: author,
              year: year,
              century: _centuryFromYear(year),
              source: engine.isEmpty ? null : engine,
              lang: lang,
              isMachineTranslation: isMt,
              text: text,
            ));
          }
        }
      }
    }
    return result;
  }

  /// Derives a roman-numeral century from a year string (e.g. "430" -> "V").
  static String _centuryFromYear(String year) {
    final m = RegExp(r'(\d{1,4})').firstMatch(year);
    if (m == null) return '';
    final y = int.parse(m.group(1)!);
    final century = ((y - 1) ~/ 100) + 1;
    return _toRoman(century);
  }

  static String _toRoman(int n) {
    if (n <= 0) return '';
    const vals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const syms = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    final sb = StringBuffer();
    var x = n;
    for (var i = 0; i < vals.length; i++) {
      while (x >= vals[i]) {
        sb.write(syms[i]);
        x -= vals[i];
      }
    }
    return sb.toString();
  }
}
