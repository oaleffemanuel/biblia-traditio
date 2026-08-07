import 'package:flutter/foundation.dart';

import '../../bible/domain/entities.dart';

/// Which commentators the reader wants to see when a verse is opened.
///
/// The default is deliberately permissive — every set empty, [onlySaints] off,
/// meaning "show everything". A new reader can therefore never land in a state
/// where most of the corpus is silently hidden; filters only ever narrow from
/// an explicit choice.
@immutable
class CommentaryPrefs {
  /// Coarse classification slugs (`patristica`, `escolastica`, `santos`).
  /// Empty ⇒ no classification filter.
  final Set<String> classes;

  /// Century numbers (1 = séc. I). Empty ⇒ no century filter.
  final Set<int> centuries;

  /// Simplified mode: show only saints, ignoring the other filters.
  final bool onlySaints;

  const CommentaryPrefs({
    this.classes = const {},
    this.centuries = const {},
    this.onlySaints = false,
  });

  static const defaults = CommentaryPrefs();

  bool get isDefault => classes.isEmpty && centuries.isEmpty && !onlySaints;

  /// Number of active narrowing choices, for the Settings subtitle.
  int get activeFilterCount =>
      (onlySaints ? 1 : 0) + classes.length + centuries.length;

  /// Whether [c] survives these preferences. Commentaries whose author carries
  /// no classification metadata (an older pack, or a source the corpus left
  /// unlabelled) are kept unless a filter explicitly excludes them — hiding
  /// them would punish the reader for missing metadata.
  bool allows(Commentary c) {
    if (onlySaints) return c.roleGroups.contains('santos');
    if (classes.isNotEmpty && !classes.any(c.roleGroups.contains)) return false;
    if (centuries.isNotEmpty) {
      final n = c.centuryNumber;
      if (n == null || !centuries.contains(n)) return false;
    }
    return true;
  }

  CommentaryPrefs copyWith({
    Set<String>? classes,
    Set<int>? centuries,
    bool? onlySaints,
  }) =>
      CommentaryPrefs(
        classes: classes ?? this.classes,
        centuries: centuries ?? this.centuries,
        onlySaints: onlySaints ?? this.onlySaints,
      );

  factory CommentaryPrefs.fromMap(Map<String, String> m) => CommentaryPrefs(
        classes: _splitStrings(m['commentaryClasses']),
        centuries: _splitInts(m['commentaryCenturies']),
        onlySaints: m['commentaryOnlySaints'] == 'true',
      );

  static String joinStrings(Set<String> v) => (v.toList()..sort()).join(';');
  static String joinInts(Set<int> v) =>
      (v.toList()..sort()).map((e) => '$e').join(';');

  static Set<String> _splitStrings(String? raw) => (raw ?? '')
      .split(';')
      .where((s) => s.isNotEmpty)
      .toSet();

  static Set<int> _splitInts(String? raw) => (raw ?? '')
      .split(';')
      .map(int.tryParse)
      .whereType<int>()
      .toSet();

  @override
  bool operator ==(Object other) =>
      other is CommentaryPrefs &&
      other.onlySaints == onlySaints &&
      setEquals(other.classes, classes) &&
      setEquals(other.centuries, centuries);

  @override
  int get hashCode => Object.hash(onlySaints, Object.hashAllUnordered(classes),
      Object.hashAllUnordered(centuries));
}
