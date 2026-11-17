import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/entities.dart';

/// Performs user-data writes, then bumps the revision so reads refresh.
class AnnotationController {
  final Ref _ref;
  AnnotationController(this._ref);

  void _bump() => _ref.read(userDataRevisionProvider.notifier).state++;

  void setHighlight(
    VerseRef r,
    HighlightColor c, {
    int? start,
    int? end,
    String? excerpt,
  }) {
    _ref
        .read(userDbProvider)
        ?.setHighlight(r, c, start: start, end: end, excerpt: excerpt);
    _bump();
  }

  void removeHighlight(VerseRef r) {
    _ref.read(userDbProvider)?.removeHighlight(r);
    _bump();
  }

  String? addTextMark(
    VerseRef r, {
    required int start,
    required int end,
    required HighlightColor color,
    MarkStyle style = MarkStyle.highlight,
    String? excerpt,
  }) {
    final id = _ref
        .read(userDbProvider)
        ?.addTextMark(
          r,
          start: start,
          end: end,
          color: color,
          style: style,
          excerpt: excerpt,
        );
    _bump();
    return id;
  }

  void removeTextMark(String uuid) {
    _ref.read(userDbProvider)?.removeTextMark(uuid);
    _bump();
  }

  void restoreTextMarks(List<String> uuids) {
    final db = _ref.read(userDbProvider);
    for (final id in uuids) {
      db?.restoreTextMark(id);
    }
    _bump();
  }

  List<String> removeTextMarksIn(VerseRef r, int start, int end) {
    final ids =
        _ref.read(userDbProvider)?.removeTextMarksIn(r, start, end) ??
        const <String>[];
    _bump();
    return ids;
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

final annotationControllerProvider = Provider(
  (ref) => AnnotationController(ref),
);

// ── Read providers (re-query whenever the revision changes) ────────────────
T _read<T>(Ref ref, T Function() compute, T fallback) {
  ref.watch(userDataRevisionProvider);
  final db = ref.watch(userDbProvider);
  return db == null ? fallback : compute();
}

final highlightsForChapterProvider =
    Provider.family<Map<int, HighlightMark>, ({String bookId, int chapter})>((
      ref,
      key,
    ) {
      return _read(
        ref,
        () => ref
            .read(userDbProvider)!
            .highlightsForChapter(key.bookId, key.chapter),
        const {},
      );
    });

final textMarksForChapterProvider =
    Provider.family<Map<int, List<TextMark>>, ({String bookId, int chapter})>((
      ref,
      key,
    ) {
      return _read(
        ref,
        () => ref
            .read(userDbProvider)!
            .textMarksForChapter(key.bookId, key.chapter),
        const {},
      );
    });

final allTextMarksProvider = Provider<List<TextMark>>(
  (ref) => _read(ref, () => ref.read(userDbProvider)!.allTextMarks(), const []),
);

final isBookmarkedProvider = Provider.family<bool, VerseRef>(
  (ref, r) =>
      _read(ref, () => ref.read(userDbProvider)!.isBookmarked(r), false),
);

final isFavoriteProvider = Provider.family<bool, VerseRef>(
  (ref, r) => _read(ref, () => ref.read(userDbProvider)!.isFavorite(r), false),
);

final notesForVerseProvider = Provider.family<List<Note>, VerseRef>(
  (ref, r) =>
      _read(ref, () => ref.read(userDbProvider)!.notesForVerse(r), const []),
);

final allNotesProvider = Provider.family<List<Note>, String?>(
  (ref, query) => _read(
    ref,
    () => ref.read(userDbProvider)!.allNotes(query: query),
    const [],
  ),
);

final allFavoritesProvider = Provider<List<Favorite>>(
  (ref) => _read(ref, () => ref.read(userDbProvider)!.allFavorites(), const []),
);

final allHighlightsProvider = Provider<List<Highlight>>(
  (ref) =>
      _read(ref, () => ref.read(userDbProvider)!.allHighlights(), const []),
);

final latestProgressProvider = Provider<ReadingPosition?>(
  (ref) => _read(ref, () => ref.read(userDbProvider)!.latestProgress(), null),
);

/// Counts for Home quick-action badges.
final userCountsProvider =
    Provider<({int notes, int favorites, int highlights})>((ref) {
      return _read(ref, () {
        final db = ref.read(userDbProvider)!;
        return (
          notes: db.countFor('note'),
          favorites: db.countFor('favorite'),
          highlights: db.countFor('highlight') + db.countFor('text_mark'),
        );
      }, (notes: 0, favorites: 0, highlights: 0));
    });
