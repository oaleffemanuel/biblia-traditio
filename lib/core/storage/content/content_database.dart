import 'package:sqlite3/sqlite3.dart';

import '../../../features/bible/domain/entities.dart';

/// Read-only access to the bundled content DB (Scripture + patristics + FTS5).
/// Built offline by `tool/importer`. The app never writes to it.
class ContentDatabase {
  final Database _db;
  ContentDatabase._(this._db);

  static ContentDatabase open(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    db.execute('PRAGMA query_only = ON;');
    return ContentDatabase._(db);
  }

  void dispose() => _db.dispose(); // ignore: deprecated_member_use

  // ── Library ──────────────────────────────────────────────────────────────
  List<BibleBook> listBooks({String lang = 'pt'}) {
    final rows = _db.select('''
      SELECT b.id, b.testament, b.canon_order, b.is_deutero, b.chapter_count,
             b.emblem_asset, n.name, n.abbrev
      FROM book b
      LEFT JOIN book_name n ON n.book_id = b.id AND n.lang = ?
      ORDER BY b.canon_order
    ''', [lang]);
    return rows.map((r) {
      return BibleBook(
        id: r['id'] as String,
        testament: (r['testament'] as String) == 'OT' ? Testament.ot : Testament.nt,
        order: r['canon_order'] as int,
        isDeutero: (r['is_deutero'] as int) == 1,
        chapterCount: r['chapter_count'] as int,
        emblemAsset: r['emblem_asset'] as String? ?? '',
        name: (r['name'] as String?) ?? (r['id'] as String),
        abbrev: (r['abbrev'] as String?) ?? '',
      );
    }).toList();
  }

  // ── Reading ──────────────────────────────────────────────────────────────
  ChapterContent getChapter(String translationId, String bookId, int chapter) {
    final vRows = _db.select('''
      SELECT verse, verse_suffix, text FROM verse
      WHERE translation_id = ? AND book_id = ? AND chapter = ?
      ORDER BY verse, verse_suffix
    ''', [translationId, bookId, chapter]);
    final hRows = _db.select('''
      SELECT before_verse, kind, text FROM section_heading
      WHERE translation_id = ? AND book_id = ? AND chapter = ?
      ORDER BY before_verse
    ''', [translationId, bookId, chapter]);
    return ChapterContent(
      bookId,
      chapter,
      vRows
          .map((r) => Verse(r['verse'] as int, r['text'] as String,
              suffix: (r['verse_suffix'] as String?) ?? ''))
          .toList(),
      hRows
          .map((r) => SectionHeading(
              r['before_verse'] as int, r['kind'] as String, r['text'] as String))
          .toList(),
    );
  }

  // ── Patristics ───────────────────────────────────────────────────────────
  List<Commentary> commentariesFor(VerseRef ref) {
    final rows = _db.select('''
      SELECT c.id, c.book_id, c.chapter, c.verse, c.source, c.is_machine_translation,
             c.text, f.name AS father, f.century
      FROM commentary c JOIN father f ON f.id = c.father_id
      WHERE c.book_id = ? AND c.chapter = ? AND c.verse = ?
      ORDER BY f.century, f.name
    ''', [ref.bookId, ref.chapter, ref.verse]);
    return rows.map(_toCommentary).toList();
  }

  /// Verse numbers in a chapter that have at least one commentary
  /// (used to render the marginal "Fathers available" glyph).
  Set<int> versesWithCommentary(String bookId, int chapter) {
    final rows = _db.select('''
      SELECT DISTINCT verse FROM commentary WHERE book_id = ? AND chapter = ?
    ''', [bookId, chapter]);
    return rows.map((r) => r['verse'] as int).toSet();
  }

  // ── Search (offline FTS5) ────────────────────────────────────────────────
  List<Commentary> searchCommentary(String query, {int limit = 50}) {
    if (query.trim().isEmpty) return const [];
    final rows = _db.select('''
      SELECT c.id, c.book_id, c.chapter, c.verse, c.source, c.is_machine_translation,
             c.text, f.name AS father, f.century
      FROM commentary_fts ft
      JOIN commentary c ON c.id = ft.rowid
      JOIN father f ON f.id = c.father_id
      WHERE commentary_fts MATCH ?
      LIMIT ?
    ''', [_ftsQuery(query), limit]);
    return rows.map(_toCommentary).toList();
  }

  List<({VerseRef ref, String text})> searchVerses(String translationId,
      String query, {int limit = 50}) {
    if (query.trim().isEmpty) return const [];
    final rows = _db.select('''
      SELECT v.book_id, v.chapter, v.verse, v.text
      FROM verse_fts ft
      JOIN verse v ON v.rowid = ft.rowid
      WHERE verse_fts MATCH ? AND v.translation_id = ?
      LIMIT ?
    ''', [_ftsQuery(query), translationId, limit]);
    return rows
        .map((r) => (
              ref: VerseRef(
                  r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
              text: r['text'] as String,
            ))
        .toList();
  }

  /// Commentary search returning a highlighted snippet (matched terms wrapped
  /// in U+2068…U+2069 so the UI can emphasise them).
  List<CommentaryHit> searchCommentaryHits(String query, {int limit = 40}) {
    if (query.trim().isEmpty) return const [];
    final rows = _db.select('''
      SELECT c.book_id, c.chapter, c.verse, f.name AS father, f.century,
             snippet(commentary_fts, 0, char(8296), char(8297), char(8230), 14) AS snip
      FROM commentary_fts ft
      JOIN commentary c ON c.id = ft.rowid
      JOIN father f ON f.id = c.father_id
      WHERE commentary_fts MATCH ?
      LIMIT ?
    ''', [_ftsQuery(query), limit]);
    return rows
        .map((r) => CommentaryHit(
              VerseRef(r['book_id'] as String, r['chapter'] as int,
                  r['verse'] as int),
              r['father'] as String,
              (r['century'] as String?) ?? '',
              r['snip'] as String,
            ))
        .toList();
  }

  /// Verse search returning a highlighted snippet (empty until scripture loads).
  List<VerseHit> searchVerseHits(String translationId, String query,
      {int limit = 40}) {
    if (query.trim().isEmpty) return const [];
    final rows = _db.select('''
      SELECT v.book_id, v.chapter, v.verse,
             snippet(verse_fts, 0, char(8296), char(8297), char(8230), 14) AS snip
      FROM verse_fts ft
      JOIN verse v ON v.rowid = ft.rowid
      WHERE verse_fts MATCH ? AND v.translation_id = ?
      LIMIT ?
    ''', [_ftsQuery(query), translationId, limit]);
    return rows
        .map((r) => VerseHit(
              VerseRef(r['book_id'] as String, r['chapter'] as int,
                  r['verse'] as int),
              r['snip'] as String,
            ))
        .toList();
  }

  String? meta(String key) {
    final rows = _db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// Translations actually present in the bundled DB.
  List<({String id, String lang, String title})> listTranslations() {
    return _db
        .select('SELECT id, lang, title FROM translation ORDER BY id')
        .map((r) => (
              id: r['id'] as String,
              lang: r['lang'] as String,
              title: r['title'] as String,
            ))
        .toList();
  }

  Commentary _toCommentary(Row r) => Commentary(
        id: r['id'] as int,
        ref: VerseRef(
            r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
        fatherName: r['father'] as String,
        century: (r['century'] as String?) ?? '',
        source: r['source'] as String?,
        isMachineTranslation: (r['is_machine_translation'] as int) == 1,
        text: r['text'] as String,
      );

  /// Escape user input into a safe FTS5 prefix query (token* per word).
  static String _ftsQuery(String raw) {
    final tokens = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"$t"*');
    return tokens.join(' ');
  }
}
