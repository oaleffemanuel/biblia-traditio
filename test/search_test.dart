import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/search/application/search_providers.dart';
import 'package:flutter_test/flutter_test.dart';

BibleBook _book(String id, String name, String abbrev,
        {int chapters = 30, Testament t = Testament.nt}) =>
    BibleBook(
      id: id,
      testament: t,
      order: 1,
      isDeutero: false,
      chapterCount: chapters,
      emblemAsset: '',
      name: name,
      abbrev: abbrev,
    );

final _books = [
  _book('gn', 'Gênesis', 'Gn', chapters: 50, t: Testament.ot),
  _book('jo', 'Josué', 'Jos', chapters: 24, t: Testament.ot),
  _book('ps', 'Salmos', 'Sl', chapters: 150, t: Testament.ot),
  _book('jn', 'João', 'Jo', chapters: 21),
  _book('1cor', 'I Coríntios', '1Cor', chapters: 16),
];

void main() {
  group('book matching', () {
    test('finds a book by its exact name, ignoring case and accents', () {
      expect(matchBooks(_books, 'genesis').first.id, 'gn');
      expect(matchBooks(_books, 'GÊNESIS').first.id, 'gn');
    });

    test('exact matches lead prefix matches', () {
      // "Jo" is João's abbreviation and Josué's prefix — the abbreviation wins.
      expect(matchBooks(_books, 'jo').first.id, 'jn');
      expect(matchBooks(_books, 'jo').map((b) => b.id), contains('jo'));
    });

    test('a word that names no book matches nothing', () {
      expect(matchBooks(_books, 'graça'), isEmpty);
    });

    test('an empty query matches nothing', () {
      expect(matchBooks(_books, '   '), isEmpty);
    });
  });

  group('reference parsing', () {
    test('parses chapter-and-verse in either separator', () {
      for (final raw in ['João 3:16', 'João 3,16', 'João 3.16']) {
        final r = parseReference(raw);
        expect(r, isNotNull, reason: raw);
        expect(r!.book, 'João');
        expect(r.chapter, 3);
        expect(r.verse, 16);
      }
    });

    test('parses a chapter-only citation', () {
      final r = parseReference('Salmo 23');
      expect(r!.book, 'Salmo');
      expect(r.chapter, 23);
      expect(r.verse, isNull);
    });

    test('keeps a leading numeral with the book name', () {
      final r = parseReference('1 Coríntios 13');
      expect(r!.book, '1 Coríntios');
      expect(r.chapter, 13);
    });

    test('plain words are not citations and fall through to full-text search',
        () {
      for (final raw in ['amor', 'Espírito Santo', 'pastor']) {
        expect(parseReference(raw), isNull, reason: raw);
      }
    });
  });

  group('search results', () {
    test('a full-text query is not treated as a book or a citation', () {
      expect(parseReference('graça'), isNull);
      expect(matchBooks(_books, 'graça'), isEmpty);
    });

    test('empty results report themselves as empty', () {
      expect(SearchResults.empty.isEmpty, isTrue);
      expect(SearchResults.empty.total, 0);
    });

    test('a reference hit counts toward the total and labels itself', () {
      final hit = ReferenceHit(_books[3], 3, 16);
      expect(hit.label, 'João 3,16');
      expect(ReferenceHit(_books[3], 3, null).label, 'João 3');
      expect(SearchResults(hit, const [], const [], const [], const []).total, 1);
    });
  });
}
