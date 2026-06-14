import 'dart:io';

import 'package:biblia_traditio/core/storage/user/user_database.dart';
import 'package:biblia_traditio/features/annotations/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late UserDatabase db;
  const r = VerseRef('gn', 1, 1);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bt_user');
    db = UserDatabase.open('${dir.path}/user.db');
  });
  tearDown(() {
    db.dispose();
    dir.deleteSync(recursive: true);
  });

  test('highlight set / query / remove', () {
    db.setHighlight(r, HighlightColor.gold);
    expect(db.highlightsForChapter('gn', 1)[1], HighlightColor.gold);
    db.setHighlight(r, HighlightColor.rose); // upsert, no duplicate
    expect(db.highlightsForChapter('gn', 1)[1], HighlightColor.rose);
    expect(db.allHighlights(), hasLength(1));
    db.removeHighlight(r);
    expect(db.highlightsForChapter('gn', 1), isEmpty);
  });

  test('bookmark and favorite toggle', () {
    expect(db.isBookmarked(r), isFalse);
    db.toggleBookmark(r);
    expect(db.isBookmarked(r), isTrue);
    db.toggleBookmark(r);
    expect(db.isBookmarked(r), isFalse);

    db.toggleFavorite(r, 'Gênesis 1,1 — No princípio…');
    expect(db.isFavorite(r), isTrue);
    expect(db.allFavorites().single.snapshot, contains('princípio'));
  });

  test('notes crud + search', () {
    final id = db.addNote(r, 'Sobre a criação do mundo');
    db.addNote(const VerseRef('jn', 1, 1), 'O Verbo eterno');
    expect(db.notesForVerse(r), hasLength(1));
    expect(db.allNotes(), hasLength(2));
    expect(db.allNotes(query: 'verbo'), hasLength(1));
    db.updateNote(id, 'Reflexão revista');
    expect(db.notesForVerse(r).single.body, 'Reflexão revista');
    db.deleteNote(id);
    expect(db.notesForVerse(r), isEmpty);
    expect(db.allNotes(), hasLength(1)); // soft-deleted excluded
  });

  test('reading progress is single-row latest', () {
    expect(db.latestProgress(), isNull);
    db.setProgress('matos1932', const VerseRef('gn', 1, 1));
    db.setProgress('matos1932', const VerseRef('ps', 23, 1));
    final p = db.latestProgress()!;
    expect(p.bookId, 'ps');
    expect(p.chapter, 23);
  });
}
