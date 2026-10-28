import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/theme_library.dart';

final themeLibraryProvider = FutureProvider<ThemeLibrary>(
  (ref) => ThemeLibrary.load(),
);

/// How many patristic commentaries fall inside a passage — 0 when the
/// commentary pack isn't installed, so the UI simply omits the count.
final passageCommentaryCountProvider = Provider.family<int, ThemePassage>((
  ref,
  p,
) {
  final db = ref.watch(contentDatabaseProvider);
  if (db == null) return 0;
  return db.commentaryCountInRange(
    p.bookId,
    p.chapter,
    p.verseStart,
    p.verseEnd,
  );
});
