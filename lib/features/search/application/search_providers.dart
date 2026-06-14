import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/di/providers.dart';
import '../../annotations/domain/entities.dart';
import '../../bible/domain/entities.dart';
import '../../settings/application/settings_providers.dart';

/// The active global-search query (set debounced from the search field).
final searchQueryProvider = StateProvider<String>((_) => '');

class SearchResults {
  final List<VerseHit> verses;
  final List<CommentaryHit> commentaries;
  final List<Note> notes;
  const SearchResults(this.verses, this.commentaries, this.notes);

  bool get isEmpty =>
      verses.isEmpty && commentaries.isEmpty && notes.isEmpty;
  int get total => verses.length + commentaries.length + notes.length;
}

/// Offline results across Scripture (FTS5), patristics (FTS5), and notes.
final searchResultsProvider = Provider<SearchResults>((ref) {
  final q = ref.watch(searchQueryProvider).trim();
  if (q.length < 2) return const SearchResults([], [], []);

  final content = ref.watch(contentDatabaseProvider);
  final user = ref.watch(userDbProvider);
  ref.watch(userDataRevisionProvider); // refresh notes after edits

  final translation = ref.watch(settingsProvider).primaryTranslationId;
  final verses = content?.searchVerseHits(translation, q, limit: 60) ?? const [];
  final commentaries = content?.searchCommentaryHits(q, limit: 60) ?? const [];
  final notes = user?.allNotes(query: q) ?? const <Note>[];
  return SearchResults(verses, commentaries, notes);
});
