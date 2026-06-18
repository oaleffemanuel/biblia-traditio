import 'dart:convert';
import 'dart:io';

import '../models/blocks.dart';
import '../models/canon.dart';

/// Parses an already-structured Catholic Bible JSON into per-book chapters.
///
/// Supported shape (Ave Maria / similar):
///   { "antigoTestamento": [ {nome, capitulos:[{capitulo, versiculos:[{versiculo,texto}]}]} ],
///     "novoTestamento":   [ ... ] }
///
/// Books are matched to the canonical registry by normalised Portuguese name
/// (accents stripped, "São " dropped), so verse numbering comes straight from
/// the source `versiculo` field — never inferred from position.
class BibleJsonParser {
  /// canonical-id -> ordered chapters
  final Map<String, List<ParsedChapter>> books = {};
  final List<String> warnings = [];
  int verseCount = 0;

  static final Map<String, String> _normNameToId = {
    for (final b in kCanon) _norm(b.namePt): b.id,
  };

  static String _norm(String s) {
    var x = s.toLowerCase().trim();
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final sb = StringBuffer();
    for (final ch in x.split('')) {
      final i = from.indexOf(ch);
      sb.write(i == -1 ? ch : to[i]);
    }
    x = sb.toString();
    x = x.replaceAll(RegExp(r'\bsao\b'), ''); // "São Mateus" -> "mateus"
    x = x.replaceAll(RegExp(r'\s+'), ' ').trim();
    return x;
  }

  String? _resolve(String nome) => _normNameToId[_norm(nome)];

  /// Defensive scripture sanitizer: no source should ever leak markup into a
  /// verse. Strips HTML tags (keeping inner text, e.g. a cross-reference link
  /// '<a ...>Is 40, 3</a>' becomes 'Is 40, 3'), unescapes common entities, and
  /// collapses the whitespace left behind.
  static String _sanitize(String s) {
    var x = s.replaceAll(RegExp(r'<[^>]*>'), '');
    x = x
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
    x = x.replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');
    x = x.replaceAll(RegExp(r'\(\s+'), '(').replaceAll(RegExp(r'\s+\)'), ')');
    return x.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  Future<void> parseFile(String path) async {
    final data = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    for (final section in ['antigoTestamento', 'novoTestamento']) {
      final list = data[section] as List? ?? const [];
      for (final book in list) {
        if (book is! Map) continue;
        final nome = (book['nome'] ?? '').toString();
        final id = _resolve(nome);
        if (id == null) {
          warnings.add('Unmatched book name: "$nome" — skipped.');
          continue;
        }
        final chapters = <ParsedChapter>[];
        for (final ch in (book['capitulos'] as List? ?? const [])) {
          if (ch is! Map) continue;
          final chNum = (ch['capitulo'] as num?)?.toInt();
          if (chNum == null) continue;
          final verses = <ParsedVerse>[];
          for (final v in (ch['versiculos'] as List? ?? const [])) {
            if (v is! Map) continue;
            final n = (v['versiculo'] as num?)?.toInt();
            final text = _sanitize((v['texto'] ?? '').toString());
            if (n == null || text.isEmpty) continue;
            verses.add(ParsedVerse(n, text));
            verseCount++;
          }
          chapters.add(ParsedChapter(chNum, verses, const []));
        }
        chapters.sort((a, b) => a.chapter.compareTo(b.chapter));
        books[id] = chapters;
      }
    }
  }
}
