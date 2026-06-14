import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../../features/bible/domain/entities.dart';

/// Read-only access to the bundled content, now split across two installed
/// package DBs: Scripture (always present) and patristics (optional). The app
/// never writes to either. User data lives in a separate writable DB.
class ContentDatabase {
  final Database _bible;
  final Database? _patristics;
  ContentDatabase._(this._bible, this._patristics);

  static ContentDatabase open(
      {required String biblePath, String? patristicsPath}) {
    final bible = sqlite3.open(biblePath, mode: OpenMode.readOnly);
    bible.execute('PRAGMA query_only = ON;');
    Database? patr;
    if (patristicsPath != null && File(patristicsPath).existsSync()) {
      patr = sqlite3.open(patristicsPath, mode: OpenMode.readOnly);
      patr.execute('PRAGMA query_only = ON;');
    }
    return ContentDatabase._(bible, patr);
  }

  bool get hasPatristics => _patristics != null;

  void dispose() {
    _bible.dispose(); // ignore: deprecated_member_use
    _patristics?.dispose(); // ignore: deprecated_member_use
  }

  // ── Library (Scripture DB) ───────────────────────────────────────────────
  List<BibleBook> listBooks({String lang = 'pt'}) {
    final rows = _bible.select('''
      SELECT b.id, b.testament, b.canon_order, b.is_deutero, b.chapter_count,
             b.emblem_asset, n.name, n.abbrev
      FROM book b
      LEFT JOIN book_name n ON n.book_id = b.id AND n.lang = ?
      ORDER BY b.canon_order
    ''', [lang]);
    return rows.map((r) {
      return BibleBook(
        id: r['id'] as String,
        testament:
            (r['testament'] as String) == 'OT' ? Testament.ot : Testament.nt,
        order: r['canon_order'] as int,
        isDeutero: (r['is_deutero'] as int) == 1,
        chapterCount: r['chapter_count'] as int,
        emblemAsset: r['emblem_asset'] as String? ?? '',
        name: (r['name'] as String?) ?? (r['id'] as String),
        abbrev: (r['abbrev'] as String?) ?? '',
      );
    }).toList();
  }

  List<({String id, String lang, String title})> listTranslations() {
    return _bible
        .select('SELECT id, lang, title FROM translation ORDER BY id')
        .map((r) => (
              id: r['id'] as String,
              lang: r['lang'] as String,
              title: r['title'] as String,
            ))
        .toList();
  }

  ChapterContent getChapter(String translationId, String bookId, int chapter) {
    final vRows = _bible.select('''
      SELECT verse, verse_suffix, text FROM verse
      WHERE translation_id = ? AND book_id = ? AND chapter = ?
      ORDER BY verse, verse_suffix
    ''', [translationId, bookId, chapter]);
    final hRows = _bible.select('''
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
          .map((r) => SectionHeading(r['before_verse'] as int,
              r['kind'] as String, r['text'] as String))
          .toList(),
    );
  }

  List<({VerseRef ref, String text})> searchVerses(
      String translationId, String query,
      {int limit = 50}) {
    if (query.trim().isEmpty) return const [];
    final rows = _bible.select('''
      SELECT v.book_id, v.chapter, v.verse, v.text
      FROM verse_fts ft JOIN verse v ON v.rowid = ft.rowid
      WHERE verse_fts MATCH ? AND v.translation_id = ?
      LIMIT ?
    ''', [_ftsQuery(query), translationId, limit]);
    return rows
        .map((r) => (
              ref: VerseRef(r['book_id'] as String, r['chapter'] as int,
                  r['verse'] as int),
              text: r['text'] as String,
            ))
        .toList();
  }

  List<VerseHit> searchVerseHits(String translationId, String query,
      {int limit = 40}) {
    if (query.trim().isEmpty) return const [];
    final rows = _bible.select('''
      SELECT v.book_id, v.chapter, v.verse,
             snippet(verse_fts, 0, char(8296), char(8297), char(8230), 14) AS snip
      FROM verse_fts ft JOIN verse v ON v.rowid = ft.rowid
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

  String? meta(String key) => _metaOf(_bible, key);
  String? patristicsMeta(String key) =>
      _patristics == null ? null : _metaOf(_patristics, key);

  // ── Patristics (optional DB) ─────────────────────────────────────────────
  List<Commentary> commentariesFor(VerseRef ref) {
    final db = _patristics;
    if (db == null) return const [];
    final rows = db.select('''
      SELECT c.id, c.book_id, c.chapter, c.verse, c.source, c.is_machine_translation,
             c.text, f.name AS father, f.century
      FROM commentary c JOIN father f ON f.id = c.father_id
      WHERE c.book_id = ? AND c.chapter = ? AND c.verse = ?
      ORDER BY f.century, f.name
    ''', [ref.bookId, ref.chapter, ref.verse]);
    return rows.map(_toCommentary).toList();
  }

  Set<int> versesWithCommentary(String bookId, int chapter) {
    final db = _patristics;
    if (db == null) return const {};
    final rows = db.select(
        'SELECT DISTINCT verse FROM commentary WHERE book_id = ? AND chapter = ?',
        [bookId, chapter]);
    return rows.map((r) => r['verse'] as int).toSet();
  }

  List<Commentary> searchCommentary(String query, {int limit = 50}) {
    final db = _patristics;
    if (db == null || query.trim().isEmpty) return const [];
    final rows = db.select('''
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

  List<CommentaryHit> searchCommentaryHits(String query, {int limit = 40}) {
    final db = _patristics;
    if (db == null || query.trim().isEmpty) return const [];
    final rows = db.select('''
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

  static String? _metaOf(Database db, String key) {
    final rows = db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

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
