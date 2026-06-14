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
  return db.getChapter(translation, key.bookId, key.chapter);
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
