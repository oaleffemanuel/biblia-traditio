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
    expect(db.highlightsForChapter('gn', 1)[1]!.color, HighlightColor.gold);
    db.setHighlight(r, HighlightColor.rose); // upsert, no duplicate
    expect(db.highlightsForChapter('gn', 1)[1]!.color, HighlightColor.rose);
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

  test(
    'excerpt highlight keeps its range and words; a whole-verse one clears them',
    () {
      db.setHighlight(
        r,
        HighlightColor.sky,
        start: 3,
        end: 12,
        excerpt: 'princípio',
      );
      final mark = db.highlightsForChapter('gn', 1)[1]!;
      expect(mark.isPartial, isTrue);
      expect((mark.start, mark.end), (3, 12));
      expect(db.allHighlights().single.excerpt, 'princípio');
      db.setHighlight(
        r,
        HighlightColor.sky,
      ); // whole verse replaces the excerpt
      expect(db.highlightsForChapter('gn', 1)[1]!.isPartial, isFalse);
      expect(db.allHighlights().single.excerpt, isNull);
    },
  );

  test('text marks accumulate per verse, down to a single letter', () {
    db.addTextMark(r, start: 3, end: 12, color: HighlightColor.sky);
    db.addTextMark(
      r,
      start: 0,
      end: 1,
      color: HighlightColor.rose,
      style: MarkStyle.underline,
      excerpt: 'N',
    );
    final marks = db.textMarksForChapter('gn', 1)[1]!;
    expect(marks, hasLength(2)); // the second did not replace the first
    expect((marks.first.start, marks.first.end), (3, 12));
    expect(marks.last.style, MarkStyle.underline);
    expect(marks.last.end - marks.last.start, 1);
    // A whole-verse colour lives alongside the marks.
    db.setHighlight(r, HighlightColor.gold);
    expect(db.textMarksForChapter('gn', 1)[1], hasLength(2));
    expect(db.allTextMarks(), hasLength(2));
  });

  test('removing marks in a span only clears those it touches; undo restores', () {
    db.addTextMark(r, start: 0, end: 2, color: HighlightColor.sky);
    db.addTextMark(r, start: 10, end: 15, color: HighlightColor.sage);
    final ids = db.removeTextMarksIn(r, 11, 12);
    expect(ids, hasLength(1));
    expect(db.textMarksForChapter('gn', 1)[1]!.single.start, 0);
    db.restoreTextMark(ids.single);
    expect(db.textMarksForChapter('gn', 1)[1], hasLength(2));
  });

  test('excerpt highlights from earlier versions move to text marks on open', () {
    db.setHighlight(
      r,
      HighlightColor.sky,
      start: 3,
      end: 12,
      excerpt: 'princípio',
    );
    db.dispose();
    db = UserDatabase.open('${dir.path}/user.db');
    expect(db.highlightsForChapter('gn', 1), isEmpty);
    final m = db.textMarksForChapter('gn', 1)[1]!.single;
    expect((m.start, m.end, m.excerpt), (3, 12, 'princípio'));
    expect(m.color, HighlightColor.sky);
  });
}
