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
      CREATE TABLE IF NOT EXISTS reading_plan_day(
        plan_id TEXT, day INTEGER, completed_at INTEGER,
        is_dirty INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0,
        PRIMARY KEY(plan_id, day));
      CREATE INDEX IF NOT EXISTS idx_note_ref ON note(book_id, chapter, verse);
      CREATE TABLE IF NOT EXISTS app_setting(key TEXT PRIMARY KEY, value TEXT);
    ''');
    // Excerpt highlights (a selected span inside a verse) — added later, so
    // existing databases get the columns on first open.
    final cols = _db
        .select('PRAGMA table_info(highlight)')
        .map((r) => r['name'] as String)
        .toSet();
    if (!cols.contains('start_offset')) {
      _db.execute('ALTER TABLE highlight ADD COLUMN start_offset INTEGER');
    }
    if (!cols.contains('end_offset')) {
      _db.execute('ALTER TABLE highlight ADD COLUMN end_offset INTEGER');
    }
    if (!cols.contains('excerpt')) {
      _db.execute('ALTER TABLE highlight ADD COLUMN excerpt TEXT');
    }
    // Text marks: any number of word/letter marks per verse. The highlight
    // table keeps one whole-verse colour per verse; excerpts written there by
    // earlier versions move here once, so nothing the reader painted is lost.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS text_mark(
        uuid TEXT PRIMARY KEY, book_id TEXT, chapter INTEGER, verse INTEGER,
        start_offset INTEGER, end_offset INTEGER, color_key TEXT,
        style TEXT DEFAULT 'highlight', excerpt TEXT,
        created_at INTEGER, updated_at INTEGER,
        is_dirty INTEGER DEFAULT 1, is_deleted INTEGER DEFAULT 0);
      CREATE INDEX IF NOT EXISTS idx_text_mark_ref
        ON text_mark(book_id, chapter, verse);
    ''');
    final legacy = _db.select(
      'SELECT COUNT(*) n FROM highlight WHERE is_deleted=0 AND start_offset IS NOT NULL AND end_offset > start_offset',
    );
    if ((legacy.first['n'] as int) > 0) {
      _db.execute('''
        INSERT OR IGNORE INTO text_mark(uuid,book_id,chapter,verse,start_offset,end_offset,color_key,style,excerpt,created_at,updated_at,is_dirty,is_deleted)
        SELECT uuid,book_id,chapter,verse,start_offset,end_offset,color_key,'highlight',excerpt,created_at,updated_at,1,0
        FROM highlight
        WHERE is_deleted=0 AND start_offset IS NOT NULL AND end_offset > start_offset
      ''');
      _db.execute(
        'UPDATE highlight SET is_deleted=1, is_dirty=1, updated_at=? WHERE is_deleted=0 AND start_offset IS NOT NULL AND end_offset > start_offset',
        [_now],
      );
    }
  }

  // ── Settings (key/value) ───────────────────────────────────────────────
  Map<String, String> allSettings() {
    final rows = _db.select('SELECT key, value FROM app_setting');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  void setSetting(String key, String value) => _db.execute(
    'INSERT INTO app_setting(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
    [key, value],
  );

  int get _now => DateTime.now().millisecondsSinceEpoch;
  DateTime _at(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch((ms as int?) ?? 0);

  // ── Highlights ─────────────────────────────────────────────────────────
  /// Whole verse when [start]/[end] are null; an excerpt inside the verse
  /// otherwise (character offsets into the verse text, [excerpt] the words).
  /// One highlight per verse: a new one replaces the old, range and all.
  void setHighlight(
    VerseRef r,
    HighlightColor color, {
    int? start,
    int? end,
    String? excerpt,
  }) {
    _db.execute(
      '''
      INSERT INTO highlight(uuid,book_id,chapter,verse,color_key,start_offset,end_offset,excerpt,created_at,updated_at,is_dirty,is_deleted)
      VALUES(?,?,?,?,?,?,?,?,?,?,1,0)
      ON CONFLICT(book_id,chapter,verse) DO UPDATE SET
        color_key=excluded.color_key, start_offset=excluded.start_offset,
        end_offset=excluded.end_offset, excerpt=excluded.excerpt,
        updated_at=excluded.updated_at, is_dirty=1, is_deleted=0
    ''',
      [
        _uuid.v4(),
        r.bookId,
        r.chapter,
        r.verse,
        color.key,
        start,
        end,
        excerpt,
        _now,
        _now,
      ],
    );
  }

  void removeHighlight(VerseRef r) => _db.execute(
    'UPDATE highlight SET is_deleted=1, is_dirty=1, updated_at=? WHERE book_id=? AND chapter=? AND verse=?',
    [_now, r.bookId, r.chapter, r.verse],
  );

  /// verse number → highlight mark (colour + optional excerpt range).
  Map<int, HighlightMark> highlightsForChapter(String bookId, int chapter) {
    final rows = _db.select(
      'SELECT verse,color_key,start_offset,end_offset FROM highlight WHERE book_id=? AND chapter=? AND is_deleted=0',
      [bookId, chapter],
    );
    return {
      for (final r in rows)
        r['verse'] as int: HighlightMark(
          HighlightColor.fromKey(r['color_key'] as String),
          start: r['start_offset'] as int?,
          end: r['end_offset'] as int?,
        ),
    };
  }

  List<Highlight> allHighlights() => _db
      .select(
        'SELECT * FROM highlight WHERE is_deleted=0 ORDER BY updated_at DESC',
      )
      .map(
        (r) => Highlight(
          r['uuid'] as String,
          VerseRef(
            r['book_id'] as String,
            r['chapter'] as int,
            r['verse'] as int,
          ),
          HighlightColor.fromKey(r['color_key'] as String),
          _at(r['created_at']),
          start: r['start_offset'] as int?,
          end: r['end_offset'] as int?,
          excerpt: r['excerpt'] as String?,
        ),
      )
      .toList();

  // ── Text marks (word / letter / phrase) ───────────────────────────────
  /// Adds a mark over [start, end) of the verse text. Marks accumulate: a
  /// verse can carry several words marked in different colours and styles.
  String addTextMark(
    VerseRef r, {
    required int start,
    required int end,
    required HighlightColor color,
    MarkStyle style = MarkStyle.highlight,
    String? excerpt,
  }) {
    final id = _uuid.v4();
    _db.execute(
      '''
      INSERT INTO text_mark(uuid,book_id,chapter,verse,start_offset,end_offset,color_key,style,excerpt,created_at,updated_at,is_dirty,is_deleted)
      VALUES(?,?,?,?,?,?,?,?,?,?,?,1,0)
    ''',
      [
        id,
        r.bookId,
        r.chapter,
        r.verse,
        start,
        end,
        color.key,
        style.key,
        excerpt,
        _now,
        _now,
      ],
    );
    return id;
  }

  void removeTextMark(String uuid) => _db.execute(
    'UPDATE text_mark SET is_deleted=1, is_dirty=1, updated_at=? WHERE uuid=?',
    [_now, uuid],
  );

  /// Restores a removed mark (Undo).
  void restoreTextMark(String uuid) => _db.execute(
    'UPDATE text_mark SET is_deleted=0, is_dirty=1, updated_at=? WHERE uuid=?',
    [_now, uuid],
  );

  /// Removes every mark of the verse that touches [start, end); returns the
  /// removed ids so the action can be undone.
  List<String> removeTextMarksIn(VerseRef r, int start, int end) {
    final ids = _db
        .select(
          'SELECT uuid FROM text_mark WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0 AND start_offset < ? AND end_offset > ?',
          [r.bookId, r.chapter, r.verse, end, start],
        )
        .map((row) => row['uuid'] as String)
        .toList();
    for (final id in ids) {
      removeTextMark(id);
    }
    return ids;
  }

  /// verse number → its marks, oldest first (so later ones paint on top).
  Map<int, List<TextMark>> textMarksForChapter(String bookId, int chapter) {
    final rows = _db.select(
      'SELECT * FROM text_mark WHERE book_id=? AND chapter=? AND is_deleted=0 ORDER BY created_at, rowid',
      [bookId, chapter],
    );
    final out = <int, List<TextMark>>{};
    for (final row in rows) {
      final m = _toTextMark(row);
      (out[m.ref.verse] ??= []).add(m);
    }
    return out;
  }

  List<TextMark> allTextMarks() => _db
      .select(
        'SELECT * FROM text_mark WHERE is_deleted=0 ORDER BY updated_at DESC',
      )
      .map(_toTextMark)
      .toList();

  TextMark _toTextMark(Row r) => TextMark(
    r['uuid'] as String,
    VerseRef(r['book_id'] as String, r['chapter'] as int, r['verse'] as int),
    start: r['start_offset'] as int,
    end: r['end_offset'] as int,
    color: HighlightColor.fromKey(r['color_key'] as String),
    style: MarkStyle.fromKey(r['style'] as String?),
    excerpt: r['excerpt'] as String?,
    createdAt: _at(r['created_at']),
  );

  // ── Bookmarks ──────────────────────────────────────────────────────────
  bool isBookmarked(VerseRef r) => _db.select(
    'SELECT 1 FROM bookmark WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0',
    [r.bookId, r.chapter, r.verse],
  ).isNotEmpty;

  void toggleBookmark(VerseRef r, {String? label}) {
    if (isBookmarked(r)) {
      _db.execute(
        'UPDATE bookmark SET is_deleted=1, is_dirty=1, updated_at=? WHERE book_id=? AND chapter=? AND verse=?',
        [_now, r.bookId, r.chapter, r.verse],
      );
    } else {
      _db.execute(
        '''
        INSERT INTO bookmark(uuid,book_id,chapter,verse,label,created_at,updated_at,is_dirty,is_deleted)
        VALUES(?,?,?,?,?,?,?,1,0)
        ON CONFLICT(book_id,chapter,verse) DO UPDATE SET
          is_deleted=0, is_dirty=1, updated_at=excluded.updated_at
      ''',
        [_uuid.v4(), r.bookId, r.chapter, r.verse, label, _now, _now],
      );
    }
  }

  List<Bookmark> allBookmarks() => _db
      .select(
        'SELECT * FROM bookmark WHERE is_deleted=0 ORDER BY updated_at DESC',
      )
      .map(
        (r) => Bookmark(
          r['uuid'] as String,
          VerseRef(
            r['book_id'] as String,
            r['chapter'] as int,
            r['verse'] as int,
          ),
          r['label'] as String?,
          _at(r['created_at']),
        ),
      )
      .toList();

  // ── Favorites ──────────────────────────────────────────────────────────
  bool isFavorite(VerseRef r) => _db.select(
    'SELECT 1 FROM favorite WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0',
    [r.bookId, r.chapter, r.verse],
  ).isNotEmpty;

  void toggleFavorite(VerseRef r, String snapshot) {
    if (isFavorite(r)) {
      _db.execute(
        'UPDATE favorite SET is_deleted=1, is_dirty=1, updated_at=? WHERE book_id=? AND chapter=? AND verse=?',
        [_now, r.bookId, r.chapter, r.verse],
      );
    } else {
      _db.execute(
        '''
        INSERT INTO favorite(uuid,book_id,chapter,verse,snapshot,created_at,updated_at,is_dirty,is_deleted)
        VALUES(?,?,?,?,?,?,?,1,0)
        ON CONFLICT(book_id,chapter,verse) DO UPDATE SET
          snapshot=excluded.snapshot, is_deleted=0, is_dirty=1, updated_at=excluded.updated_at
      ''',
        [_uuid.v4(), r.bookId, r.chapter, r.verse, snapshot, _now, _now],
      );
    }
  }

  List<Favorite> allFavorites() => _db
      .select(
        'SELECT * FROM favorite WHERE is_deleted=0 ORDER BY updated_at DESC',
      )
      .map(
        (r) => Favorite(
          r['uuid'] as String,
          VerseRef(
            r['book_id'] as String,
            r['chapter'] as int,
            r['verse'] as int,
          ),
          r['snapshot'] as String? ?? '',
          _at(r['created_at']),
        ),
      )
      .toList();

  // ── Notes ──────────────────────────────────────────────────────────────
  String addNote(VerseRef r, String body) {
    final id = _uuid.v4();
    _db.execute(
      '''
      INSERT INTO note(uuid,book_id,chapter,verse,body,created_at,updated_at,is_dirty,is_deleted)
      VALUES(?,?,?,?,?,?,?,1,0)
    ''',
      [id, r.bookId, r.chapter, r.verse, body, _now, _now],
    );
    return id;
  }

  void updateNote(String uuid, String body) => _db.execute(
    'UPDATE note SET body=?, updated_at=?, is_dirty=1 WHERE uuid=?',
    [body, _now, uuid],
  );

  void deleteNote(String uuid) => _db.execute(
    'UPDATE note SET is_deleted=1, is_dirty=1, updated_at=? WHERE uuid=?',
    [_now, uuid],
  );

  List<Note> notesForVerse(VerseRef r) => _db
      .select(
        'SELECT * FROM note WHERE book_id=? AND chapter=? AND verse=? AND is_deleted=0 ORDER BY updated_at DESC',
        [r.bookId, r.chapter, r.verse],
      )
      .map(_toNote)
      .toList();

  List<Note> allNotes({String? query}) {
    final hasQ = query != null && query.trim().isNotEmpty;
    final rows = hasQ
        ? _db.select(
            "SELECT * FROM note WHERE is_deleted=0 AND body LIKE ? ORDER BY updated_at DESC",
            ['%${query.trim()}%'],
          )
        : _db.select(
            'SELECT * FROM note WHERE is_deleted=0 ORDER BY updated_at DESC',
          );
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
  void setProgress(String translationId, VerseRef r) => _db.execute(
    '''
        INSERT INTO reading_progress(id,translation_id,book_id,chapter,verse,updated_at)
        VALUES(1,?,?,?,?,?)
        ON CONFLICT(id) DO UPDATE SET
          translation_id=excluded.translation_id, book_id=excluded.book_id,
          chapter=excluded.chapter, verse=excluded.verse, updated_at=excluded.updated_at
      ''',
    [translationId, r.bookId, r.chapter, r.verse, _now],
  );

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

  // ── Reading plan ───────────────────────────────────────────────────────
  // The plan's start (day 1) is stored as a UTC epoch-day in app_setting, so
  // "today's day" is a pure date difference. Per-day completion lives in its
  // own table (sync-ready). Both are scoped by plan_id for future plans.
  String _planStartKey(String planId) => 'readingPlan.$planId.startEpochDay';

  int? readingPlanStart(String planId) {
    final rows = _db.select('SELECT value FROM app_setting WHERE key=?', [
      _planStartKey(planId),
    ]);
    if (rows.isEmpty) return null;
    return int.tryParse(rows.first['value'] as String);
  }

  void setReadingPlanStart(String planId, int epochDay) =>
      setSetting(_planStartKey(planId), '$epochDay');

  Set<int> completedPlanDays(String planId) => _db
      .select(
        'SELECT day FROM reading_plan_day WHERE plan_id=? AND is_deleted=0',
        [planId],
      )
      .map((r) => r['day'] as int)
      .toSet();

  void setPlanDayCompleted(String planId, int day, bool completed) {
    if (completed) {
      _db.execute(
        '''
        INSERT INTO reading_plan_day(plan_id,day,completed_at,is_dirty,is_deleted)
        VALUES(?,?,?,1,0)
        ON CONFLICT(plan_id,day) DO UPDATE SET
          completed_at=excluded.completed_at, is_dirty=1, is_deleted=0
      ''',
        [planId, day, _now],
      );
    } else {
      _db.execute(
        'UPDATE reading_plan_day SET is_deleted=1, is_dirty=1, completed_at=? WHERE plan_id=? AND day=?',
        [_now, planId, day],
      );
    }
  }
}
