import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../../features/annotations/domain/entities.dart';

/// Writable, app-private store for user data (notes, highlights, bookmarks,
/// favorites, reading progress). Lives in the OS app sandbox.
///
/// Every row carries `uuid + updated_at + is_dirty + is_deleted` so optional
/// Supabase sync (last-write-wins) can be layered later with no schema change.
/// (At-rest encryption — SQLCipher or field-level — is a documented follow-up.)
class UserDatabase {
  final Database _db;
  static const _uuid = Uuid();
  UserDatabase._(this._db);

  static UserDatabase open(String path) {
    final db = sqlite3.open(path);
    db.execute('PRAGMA journal_mode = WAL;');
    final u = UserDatabase._(db);
    u._migrate();
    return u;
  }

  void dispose() => _db.dispose(); // ignore: deprecated_member_use

  void _migrate() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS highlight(
        uuid TEXT PRIMARY KEY, book_id TEXT, chapter INTEGER, verse INTEGER,
        color_key TEXT, created_at INTEGER, updated_at INTEGER,
        is_dirty INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0,
        UNIQUE(book_id, chapter, verse));
      CREATE TABLE IF NOT EXISTS bookmark(
        uuid TEXT PRIMARY KEY, book_id TEXT, chapter INTEGER, verse INTEGER,
        label TEXT, created_at INTEGER, updated_at INTEGER,
        is_dirty INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0,
        UNIQUE(book_id, chapter, verse));
      CREATE TABLE IF NOT EXISTS favorite(
        uuid TEXT PRIMARY KEY, book_id TEXT, chapter INTEGER, verse INTEGER,
        snapshot TEXT, created_at INTEGER, updated_at INTEGER,
        is_dirty INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0,
        UNIQUE(book_id, chapter, verse));
      CREATE TABLE IF NOT EXISTS note(
        uuid TEXT PRIMARY KEY, book_id TEXT, chapter INTEGER, verse INTEGER,
        body TEXT, created_at INTEGER, updated_at INTEGER,
        is_dirty INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0);
      CREATE TABLE IF NOT EXISTS reading_progress(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        translation_id TEXT, book_id TEXT, chapter INTEGER, verse INTEGER,
        updated_at INTEGER);
      CREATE INDEX IF NOT EXISTS idx_note_ref ON note(book_id, chapter, verse);
      CREATE TABLE IF NOT EXISTS app_setting(key TEXT PRIMARY KEY, value TEXT);
    ''');
  }

  // ── Settings (key/value) ───────────────────────────────────────────────
  Map<String, String> allSettings() {
    final rows = _db.select('SELECT key, value FROM app_setting');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  void setSetting(String key, String value) => _db.execute(
      'INSERT INTO app_setting(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
      [key, value]);

  int get _now => DateTime.now().millisecondsSinceEpoch;
  DateTime _at(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch((ms as int?) ?? 0);

  // ── Highlights ─────────────────────────────────────────────────────────
  void setHighlight(VerseRef r, HighlightColor color) {
    _db.execute('''
      INSERT INTO highlight(uuid,book_id,chapter,verse,color_key,created_at,updated_at,is_dirty,is_deleted)
      VALUES(?,?,?,?,?,?,?,1,0)
      ON CONFLICT(book_id,chapter,verse) DO UPDATE SET
        color_key=excluded.color_key, updated_at=excluded.updated_at,
        is_dirty=1, is_deleted=0
    ''', [_uuid.v4(), r.bookId, r.chapter, r.verse, color.key, _now, _now]);
  }

  void removeHighlight(VerseRef r) => _db.execute(
      'UPDATE highlight SET is_deleted=1, is_dirty=1, updated_at=? WHERE book_id=? AND chapter=? AND verse=?',
      [_now, r.bookId, r.chapter, r.verse]);

  /// verse number → highlight color, for one chapter.
  Map<int, HighlightColor> highlightsForChapter(String bookId, int chapter) {
    final rows = _db.select(
        'SELECT verse,color_key FROM highlight WHERE book_id=? AND chapter=? AND is_deleted=0',
        [bookId, chapter]);
    return {
      for (final r in rows)
        r['verse'] as int: HighlightColor.fromKey(r['color_key'] as String)
    };
  }

  List<Highlight> allHighlights() => _db
      .select(
          'SELECT * FROM highlight WHERE is_deleted=0 ORDER BY updated_at DESC')
      .map((r) => Highlight(
            r['uuid'] as String,
            VerseRef(r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
            HighlightColor.fromKey(r['color_key'] as String),
            _at(r['created_at']),
          ))
      .toList();

  // ── Bookmarks ──────────────────────────────────────────────────────────
  bool isBookmarked(VerseRef r) => _db.select(
      'SELECT 1 FROM bookmark WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0',
      [r.bookId, r.chapter, r.verse]).isNotEmpty;

  void toggleBookmark(VerseRef r, {String? label}) {
    if (isBookmarked(r)) {
      _db.execute(
          'UPDATE bookmark SET is_deleted=1, is_dirty=1, updated_at=? WHERE book_id=? AND chapter=? AND verse=?',
          [_now, r.bookId, r.chapter, r.verse]);
    } else {
      _db.execute('''
        INSERT INTO bookmark(uuid,book_id,chapter,verse,label,created_at,updated_at,is_dirty,is_deleted)
        VALUES(?,?,?,?,?,?,?,1,0)
        ON CONFLICT(book_id,chapter,verse) DO UPDATE SET
          is_deleted=0, is_dirty=1, updated_at=excluded.updated_at
      ''', [_uuid.v4(), r.bookId, r.chapter, r.verse, label, _now, _now]);
    }
  }

  List<Bookmark> allBookmarks() => _db
      .select('SELECT * FROM bookmark WHERE is_deleted=0 ORDER BY updated_at DESC')
      .map((r) => Bookmark(
            r['uuid'] as String,
            VerseRef(r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
            r['label'] as String?,
            _at(r['created_at']),
          ))
      .toList();

  // ── Favorites ──────────────────────────────────────────────────────────
  bool isFavorite(VerseRef r) => _db.select(
      'SELECT 1 FROM favorite WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0',
      [r.bookId, r.chapter, r.verse]).isNotEmpty;

  void toggleFavorite(VerseRef r, String snapshot) {
    if (isFavorite(r)) {
      _db.execute(
          'UPDATE favorite SET is_deleted=1, is_dirty=1, updated_at=? WHERE book_id=? AND chapter=? AND verse=?',
          [_now, r.bookId, r.chapter, r.verse]);
    } else {
      _db.execute('''
        INSERT INTO favorite(uuid,book_id,chapter,verse,snapshot,created_at,updated_at,is_dirty,is_deleted)
        VALUES(?,?,?,?,?,?,?,1,0)
        ON CONFLICT(book_id,chapter,verse) DO UPDATE SET
          snapshot=excluded.snapshot, is_deleted=0, is_dirty=1, updated_at=excluded.updated_at
      ''', [_uuid.v4(), r.bookId, r.chapter, r.verse, snapshot, _now, _now]);
    }
  }

  List<Favorite> allFavorites() => _db
      .select('SELECT * FROM favorite WHERE is_deleted=0 ORDER BY updated_at DESC')
      .map((r) => Favorite(
            r['uuid'] as String,
            VerseRef(r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
            r['snapshot'] as String? ?? '',
            _at(r['created_at']),
          ))
      .toList();

  // ── Notes ──────────────────────────────────────────────────────────────
  String addNote(VerseRef r, String body) {
    final id = _uuid.v4();
    _db.execute('''
      INSERT INTO note(uuid,book_id,chapter,verse,body,created_at,updated_at,is_dirty,is_deleted)
      VALUES(?,?,?,?,?,?,?,1,0)
    ''', [id, r.bookId, r.chapter, r.verse, body, _now, _now]);
    return id;
  }

  void updateNote(String uuid, String body) => _db.execute(
      'UPDATE note SET body=?, updated_at=?, is_dirty=1 WHERE uuid=?',
      [body, _now, uuid]);

  void deleteNote(String uuid) => _db.execute(
      'UPDATE note SET is_deleted=1, is_dirty=1, updated_at=? WHERE uuid=?',
      [_now, uuid]);

  List<Note> notesForVerse(VerseRef r) => _db
      .select(
          'SELECT * FROM note WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0 ORDER BY updated_at DESC',
          [r.bookId, r.chapter, r.verse])
      .map(_toNote)
      .toList();

  List<Note> allNotes({String? query}) {
    final hasQ = query != null && query.trim().isNotEmpty;
    final rows = hasQ
        ? _db.select(
            "SELECT * FROM note WHERE is_deleted=0 AND body LIKE ? ORDER BY updated_at DESC",
            ['%${query.trim()}%'])
        : _db.select(
            'SELECT * FROM note WHERE is_deleted=0 ORDER BY updated_at DESC');
    return rows.map(_toNote).toList();
  }

  int countFor(String table) =>
      _db.select('SELECT COUNT(*) n FROM $table WHERE is_deleted=0').first['n']
          as int;

  Note _toNote(Row r) => Note(
        r['uuid'] as String,
        VerseRef(r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
        r['body'] as String? ?? '',
        _at(r['created_at']),
        _at(r['updated_at']),
      );

  // ── Reading progress ───────────────────────────────────────────────────
  void setProgress(String translationId, VerseRef r) => _db.execute('''
        INSERT INTO reading_progress(id,translation_id,book_id,chapter,verse,updated_at)
        VALUES(1,?,?,?,?,?)
        ON CONFLICT(id) DO UPDATE SET
          translation_id=excluded.translation_id, book_id=excluded.book_id,
          chapter=excluded.chapter, verse=excluded.verse, updated_at=excluded.updated_at
      ''', [translationId, r.bookId, r.chapter, r.verse, _now]);

  ReadingPosition? latestProgress() {
    final rows = _db.select('SELECT * FROM reading_progress WHERE id=1');
    if (rows.isEmpty) return null;
    final r = rows.first;
    return ReadingPosition(
      r['translation_id'] as String,
      r['book_id'] as String,
      r['chapter'] as int,
      r['verse'] as int,
      _at(r['updated_at']),
    );
  }
}
