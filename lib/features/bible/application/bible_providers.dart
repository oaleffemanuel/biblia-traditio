import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/entities.dart';

/// All canonical books (from the content DB). Empty until a pack is installed.
final booksProvider = Provider<List<BibleBook>>((ref) {
  final db = ref.watch(contentDatabaseProvider);
  return db?.listBooks() ?? const [];
});

final booksByTestamentProvider =
    Provider.family<List<BibleBook>, Testament>((ref, t) {
  return ref.watch(booksProvider).where((b) => b.testament == t).toList();
});

final bookByIdProvider = Provider.family<BibleBook?, String>((ref, id) {
  final i = ref.watch(booksProvider).indexWhere((b) => b.id == id);
  return i == -1 ? null : ref.watch(booksProvider)[i];
});

/// A chapter's verses + headings for the active translation.
final chapterProvider =
    Provider.family<ChapterContent?, ({String bookId, int chapter})>((ref, key) {
  final db = ref.watch(contentDatabaseProvider);
  if (db == null) return null;
  final translation = ref.watch(resolvedTranslationIdProvider);
  // B5 guard: never query a translation that isn't actually installed (e.g. the
  // user removed the pack that backed their primary). Returning null surfaces
  // the clear "not installed" state instead of a silently blank chapter.
  final available = ref.watch(availableTranslationsProvider);
  if (!available.any((t) => t.id == translation)) return null;
  return db.getChapter(translation, key.bookId, key.chapter);
});

/// A chapter aligned across the primary and (optional) secondary translation
/// for Parallel Reading, joined by canonical verse number. When no secondary is
/// resolved the rows still carry the primary text, so callers can render a
/// graceful single-column fallback without branching.
final parallelChapterProvider =
    Provider.family<ParallelChapter?, ({String bookId, int chapter})>(
        (ref, key) {
  final db = ref.watch(contentDatabaseProvider);
  if (db == null) return null;
  final primaryId = ref.watch(resolvedTranslationIdProvider);
  final secondaryId = ref.watch(resolvedSecondaryTranslationIdProvider);
  final primary = db.getChapter(primaryId, key.bookId, key.chapter);
  final secondary = secondaryId == null
      ? null
      : db.getChapter(secondaryId, key.bookId, key.chapter);
  return ParallelChapter.align(primary, secondary);
});

/// Verses in a chapter that have patristic commentary (for the marginal glyph).
final commentaryMarkersProvider =
    Provider.family<Set<int>, ({String bookId, int chapter})>((ref, key) {
  final db = ref.watch(contentDatabaseProvider);
  return db?.versesWithCommentary(key.bookId, key.chapter) ?? const {};
});

/// Patristic commentaries attached to a single verse.
final commentariesProvider =
    Provider.family<List<Commentary>, VerseRef>((ref, vref) {
  final db = ref.watch(contentDatabaseProvider);
  return db?.commentariesFor(vref) ?? const [];
});
