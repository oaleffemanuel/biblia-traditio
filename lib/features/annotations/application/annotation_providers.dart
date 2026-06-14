import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/entities.dart';

/// Performs user-data writes, then bumps the revision so reads refresh.
class AnnotationController {
  final Ref _ref;
  AnnotationController(this._ref);

  void _bump() =>
      _ref.read(userDataRevisionProvider.notifier).state++;

  void setHighlight(VerseRef r, HighlightColor c) {
    _ref.read(userDbProvider)?.setHighlight(r, c);
    _bump();
  }

  void removeHighlight(VerseRef r) {
    _ref.read(userDbProvider)?.removeHighlight(r);
    _bump();
  }

  void toggleBookmark(VerseRef r) {
    _ref.read(userDbProvider)?.toggleBookmark(r);
    _bump();
  }

  void toggleFavorite(VerseRef r, String snapshot) {
    _ref.read(userDbProvider)?.toggleFavorite(r, snapshot);
    _bump();
  }

  String? addNote(VerseRef r, String body) {
    final id = _ref.read(userDbProvider)?.addNote(r, body);
    _bump();
    return id;
  }

  void updateNote(String uuid, String body) {
    _ref.read(userDbProvider)?.updateNote(uuid, body);
    _bump();
  }

  void deleteNote(String uuid) {
    _ref.read(userDbProvider)?.deleteNote(uuid);
    _bump();
  }

  void recordProgress(String translationId, VerseRef r) {
    _ref.read(userDbProvider)?.setProgress(translationId, r);
    _bump();
  }
}

final annotationControllerProvider =
    Provider((ref) => AnnotationController(ref));

// ── Read providers (re-query whenever the revision changes) ────────────────
T _read<T>(Ref ref, T Function() compute, T fallback) {
  ref.watch(userDataRevisionProvider);
  final db = ref.watch(userDbProvider);
  return db == null ? fallback : compute();
}

final highlightsForChapterProvider = Provider.family<Map<int, HighlightColor>,
    ({String bookId, int chapter})>((ref, key) {
  return _read(ref,
      () => ref.read(userDbProvider)!.highlightsForChapter(key.bookId, key.chapter),
      const {});
});

final isBookmarkedProvider = Provider.family<bool, VerseRef>((ref, r) =>
    _read(ref, () => ref.read(userDbProvider)!.isBookmarked(r), false));

final isFavoriteProvider = Provider.family<bool, VerseRef>((ref, r) =>
    _read(ref, () => ref.read(userDbProvider)!.isFavorite(r), false));

final notesForVerseProvider = Provider.family<List<Note>, VerseRef>((ref, r) =>
    _read(ref, () => ref.read(userDbProvider)!.notesForVerse(r), const []));

final allNotesProvider = Provider.family<List<Note>, String?>((ref, query) =>
    _read(ref, () => ref.read(userDbProvider)!.allNotes(query: query), const []));

final allFavoritesProvider = Provider<List<Favorite>>((ref) =>
    _read(ref, () => ref.read(userDbProvider)!.allFavorites(), const []));

final allHighlightsProvider = Provider<List<Highlight>>((ref) =>
    _read(ref, () => ref.read(userDbProvider)!.allHighlights(), const []));

final latestProgressProvider = Provider<ReadingPosition?>((ref) =>
    _read(ref, () => ref.read(userDbProvider)!.latestProgress(), null));

/// Counts for Home quick-action badges.
final userCountsProvider =
    Provider<({int notes, int favorites, int highlights})>((ref) {
  return _read(ref, () {
    final db = ref.read(userDbProvider)!;
    return (
      notes: db.countFor('note'),
      favorites: db.countFor('favorite'),
      highlights: db.countFor('highlight'),
    );
  }, (notes: 0, favorites: 0, highlights: 0));
});
