import 'package:sqlite3/sqlite3.dart';

import '../models/blocks.dart';
import '../models/canon.dart';
import '../parsers/patristics_parser.dart';

/// Builds / populates the bundled read-only content database (SQLite + FTS5).
class ContentDbBuilder {
  final Database db;
  ContentDbBuilder(this.db);

  static ContentDbBuilder open(String path) {
    final db = sqlite3.open(path);
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA foreign_keys = ON;');
    final b = ContentDbBuilder(db);
    b._createSchema();
    b._seedBooks();
    return b;
  }

  void _createSchema() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS book (
        id TEXT PRIMARY KEY, testament TEXT NOT NULL, canon_order INTEGER NOT NULL,
        is_deutero INTEGER NOT NULL DEFAULT 0, chapter_count INTEGER NOT NULL,
        emblem_asset TEXT
      );
      CREATE TABLE IF NOT EXISTS book_name (
        book_id TEXT NOT NULL, lang TEXT NOT NULL, name TEXT NOT NULL, abbrev TEXT,
        PRIMARY KEY (book_id, lang)
      );
      CREATE TABLE IF NOT EXISTS translation (
        id TEXT PRIMARY KEY, lang TEXT NOT NULL, title TEXT NOT NULL,
        license TEXT, source TEXT, versification TEXT NOT NULL DEFAULT 'vulgate'
      );
      CREATE TABLE IF NOT EXISTS verse (
        translation_id TEXT NOT NULL, book_id TEXT NOT NULL, chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL, verse_suffix TEXT NOT NULL DEFAULT '', text TEXT NOT NULL,
        PRIMARY KEY (translation_id, book_id, chapter, verse, verse_suffix)
      );
      CREATE TABLE IF NOT EXISTS section_heading (
        translation_id TEXT NOT NULL, book_id TEXT NOT NULL, chapter INTEGER NOT NULL,
        before_verse INTEGER NOT NULL, kind TEXT NOT NULL, text TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS father (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, century TEXT, year TEXT
      );
      CREATE TABLE IF NOT EXISTS commentary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL, chapter INTEGER NOT NULL, verse INTEGER NOT NULL,
        father_id TEXT NOT NULL, source TEXT, lang TEXT NOT NULL,
        is_machine_translation INTEGER NOT NULL DEFAULT 1, text TEXT NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_comm_ref ON commentary(book_id, chapter, verse);
      CREATE INDEX IF NOT EXISTS idx_verse_ref ON verse(book_id, chapter, verse);

      -- External-content FTS5: the index references the base tables and does
      -- NOT store a second copy of the text (keeps the DB roughly half-size).
      CREATE VIRTUAL TABLE IF NOT EXISTS verse_fts USING fts5(
        text, content='verse', content_rowid='rowid',
        tokenize='unicode61 remove_diacritics 2');
      CREATE VIRTUAL TABLE IF NOT EXISTS commentary_fts USING fts5(
        text, content='commentary', content_rowid='id',
        tokenize='unicode61 remove_diacritics 2');

      CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT);
    ''');
  }

  void _seedBooks() {
    final book = db.prepare(
        'INSERT OR REPLACE INTO book(id,testament,canon_order,is_deutero,chapter_count,emblem_asset) VALUES(?,?,?,?,?,?)');
    final name = db.prepare(
        'INSERT OR REPLACE INTO book_name(book_id,lang,name,abbrev) VALUES(?,?,?,?)');
    db.execute('BEGIN');
    for (final b in kCanon) {
      book.execute([
        b.id,
        b.testament == Testament.ot ? 'OT' : 'NT',
        b.order,
        b.deutero ? 1 : 0,
        b.chapterCount,
        'assets/emblems/${b.id}.svg',
      ]);
      name.execute([b.id, 'pt', b.namePt, b.abbrevPt]);
    }
    db.execute('COMMIT');
    book.dispose();
    name.dispose();
  }

  void upsertTranslation(String id, String lang, String title,
      {String? license, String? source, String versification = 'vulgate'}) {
    db.prepare('''INSERT OR REPLACE INTO translation(id,lang,title,license,source,versification)
                  VALUES(?,?,?,?,?,?)''')
      ..execute([id, lang, title, license, source, versification])
      ..dispose();
  }

  /// Insert parsed scripture for one book/translation.
  void insertScripture(
      String translationId, String bookId, List<ParsedChapter> chapters) {
    final v = db.prepare(
        'INSERT INTO verse(translation_id,book_id,chapter,verse,verse_suffix,text) VALUES(?,?,?,?,?,?)');
    final vfts = db.prepare('INSERT INTO verse_fts(rowid,text) VALUES(?,?)');
    final h = db.prepare(
        'INSERT INTO section_heading(translation_id,book_id,chapter,before_verse,kind,text) VALUES(?,?,?,?,?,?)');
    db.execute('BEGIN');
    for (final ch in chapters) {
      for (final verse in ch.verses) {
        v.execute([
          translationId, bookId, ch.chapter, verse.verse, verse.suffix, verse.text
        ]);
        vfts.execute([db.lastInsertRowId, verse.text]);
      }
      for (final hd in ch.headings) {
        h.execute([translationId, bookId, ch.chapter, hd.beforeVerse, hd.kind, hd.text]);
      }
    }
    db.execute('COMMIT');
    v.dispose();
    vfts.dispose();
    h.dispose();
  }

  /// Insert the patristic corpus.
  void insertPatristics(PatristicsParseResult result) {
    // Fathers registry (stable id = slug of name).
    final fa = db.prepare(
        'INSERT OR REPLACE INTO father(id,name,century,year) VALUES(?,?,?,?)');
    final firstByName = <String, CommentaryRecord>{};
    for (final c in result.commentaries) {
      firstByName.putIfAbsent(c.fatherName, () => c);
    }
    db.execute('BEGIN');
    for (final entry in firstByName.entries) {
      fa.execute([_slug(entry.key), entry.key, entry.value.century, entry.value.year]);
    }
    db.execute('COMMIT');
    fa.dispose();

    final c = db.prepare(
        '''INSERT INTO commentary(book_id,chapter,verse,father_id,source,lang,is_machine_translation,text)
           VALUES(?,?,?,?,?,?,?,?)''');
    final cfts = db.prepare('INSERT INTO commentary_fts(rowid,text) VALUES(?,?)');
    db.execute('BEGIN');
    for (final rec in result.commentaries) {
      c.execute([
        rec.bookId, rec.chapter, rec.verse, _slug(rec.fatherName),
        rec.source, rec.lang, rec.isMachineTranslation ? 1 : 0, rec.text,
      ]);
      cfts.execute([db.lastInsertRowId, rec.text]);
    }
    db.execute('COMMIT');
    c.dispose();
    cfts.dispose();
  }

  void setMeta(String key, String value) {
    db.prepare('INSERT OR REPLACE INTO meta(key,value) VALUES(?,?)')
      ..execute([key, value])
      ..dispose();
  }

  void finish() {
    db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
    db.execute('VACUUM;');
    db.dispose();
  }

  static String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
