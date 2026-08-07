import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/di/providers.dart';
import '../../annotations/domain/entities.dart';
import '../../bible/application/bible_providers.dart';
import '../../bible/domain/entities.dart';
import '../../settings/application/settings_providers.dart';

/// The active global-search query (set debounced from the search field).
final searchQueryProvider = StateProvider<String>((_) => '');

/// A book the query names, so "João" reaches the book and not only the verses
/// that happen to mention John.
class BookHit {
  final BibleBook book;
  const BookHit(this.book);
}

/// A parsed citation — "João 3:16", "Salmo 23", "1 cor 13" — that the reader
/// can jump straight to.
class ReferenceHit {
  final BibleBook book;
  final int chapter;
  final int? verse;
  const ReferenceHit(this.book, this.chapter, this.verse);

  String get label =>
      verse == null ? '${book.name} $chapter' : '${book.name} $chapter,$verse';
}

class SearchResults {
  final ReferenceHit? reference;
  final List<BookHit> books;
  final List<VerseHit> verses;
  final List<CommentaryHit> commentaries;
  final List<Note> notes;
  const SearchResults(
      this.reference, this.books, this.verses, this.commentaries, this.notes);

  static const empty = SearchResults(null, [], [], [], []);

  bool get isEmpty =>
      reference == null &&
      books.isEmpty &&
      verses.isEmpty &&
      commentaries.isEmpty &&
      notes.isEmpty;

  int get total =>
      (reference == null ? 0 : 1) +
      books.length +
      verses.length +
      commentaries.length +
      notes.length;
}

/// Offline results across book names and citations, Scripture (FTS5),
/// patristics (FTS5), and notes.
final searchResultsProvider = Provider<SearchResults>((ref) {
  final q = ref.watch(searchQueryProvider).trim();
  if (q.length < 2) return SearchResults.empty;

  final content = ref.watch(contentDatabaseProvider);
  final user = ref.watch(userDbProvider);
  ref.watch(userDataRevisionProvider); // refresh notes after edits

  final translation = ref.watch(resolvedTranslationIdProvider);
  final books = ref.watch(booksProvider);

  final citation = parseReference(q);
  final reference = citation == null
      ? null
      : _resolveReference(books, citation);
  final bookHits = [
    for (final b in matchBooks(books, q)) BookHit(b),
  ];

  final verses = content?.searchVerseHits(translation, q, limit: 60) ?? const [];
  final commentaries = content?.searchCommentaryHits(q, limit: 60) ?? const [];
  final notes = user?.allNotes(query: q) ?? const <Note>[];
  return SearchResults(reference, bookHits, verses, commentaries, notes);
});

ReferenceHit? _resolveReference(List<BibleBook> books,
    ({String book, int chapter, int? verse}) citation) {
  final matches = matchBooks(books, citation.book);
  if (matches.isEmpty) return null;
  final book = matches.first;
  if (citation.chapter < 1 || citation.chapter > book.chapterCount) return null;
  return ReferenceHit(book, citation.chapter, citation.verse);
}

/// Splits a citation into its parts: "João 3:16" → (João, 3, 16),
/// "Salmo 23" → (Salmo, 23, null). Returns null when the text isn't a citation
/// at all, so plain words fall through to full-text search untouched.
({String book, int chapter, int? verse})? parseReference(String raw) {
  final m = RegExp(r'^(.+?)\s*[\s.]\s*(\d{1,3})(?:\s*[:,.]\s*(\d{1,3}))?$')
      .firstMatch(raw.trim());
  if (m == null) return null;
  final book = m.group(1)!.trim();
  if (book.isEmpty) return null;
  return (
    book: book,
    chapter: int.parse(m.group(2)!),
    verse: m.group(3) == null ? null : int.parse(m.group(3)!),
  );
}

/// Books the query names, best match first. The ranking is what a reader
/// expects when they type "jo": the book whose *abbreviation* is Jo (João) leads
/// the one that merely starts with those letters (Josué), and the internal book
/// id — which nobody types on purpose — ranks below both.
List<BibleBook> matchBooks(List<BibleBook> books, String query) {
  final q = _fold(query);
  if (q.isEmpty) return const [];
  final byName = <BibleBook>[],
      byAbbrev = <BibleBook>[],
      byId = <BibleBook>[],
      prefix = <BibleBook>[],
      contains = <BibleBook>[];
  for (final b in books) {
    final name = _fold(b.name);
    final abbrev = _fold(b.abbrev);
    if (name == q) {
      byName.add(b);
    } else if (abbrev.isNotEmpty && abbrev == q) {
      byAbbrev.add(b);
    } else if (_fold(b.id) == q) {
      byId.add(b);
    } else if (name.startsWith(q) || abbrev.startsWith(q)) {
      prefix.add(b);
    } else if (name.contains(q)) {
      contains.add(b);
    }
  }
  return [...byName, ...byAbbrev, ...byId, ...prefix, ...contains];
}

/// Lowercase, accent-folded: "Gênesis" and "genesis" must find each other.
String _fold(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[áàâãä]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[íìîï]'), 'i')
    .replaceAll(RegExp(r'[óòôõö]'), 'o')
    .replaceAll(RegExp(r'[úùûü]'), 'u')
    .replaceAll(RegExp(r'[ç]'), 'c')
    .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
    .trim();
