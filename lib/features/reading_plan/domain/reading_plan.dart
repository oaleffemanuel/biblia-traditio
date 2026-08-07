import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One openable destination inside a reading: a book + chapter the Reader can
/// jump to directly, optionally narrowed to the verses the plan actually
/// assigns (Proverbs and Psalm 119 are read a few verses at a time).
class PlanTarget {
  final String bookId;
  final int chapter;
  final int? verseStart;
  final int? verseEnd;
  const PlanTarget(this.bookId, this.chapter, {this.verseStart, this.verseEnd});

  /// Whether this target is a verse span rather than a whole chapter.
  bool get isPartial => verseStart != null;

  bool includes(int verse) =>
      verseStart == null ||
      (verse >= verseStart! && verse <= (verseEnd ?? verseStart!));

  factory PlanTarget.fromJson(Map<String, dynamic> j) => PlanTarget(
        j['book'] as String,
        (j['chapter'] as num).toInt(),
        verseStart: (j['verseStart'] as num?)?.toInt(),
        verseEnd: (j['verseEnd'] as num?)?.toInt(),
      );
}

/// Which strand of the plan a reading belongs to. The schedule runs a narrative
/// book alongside a wisdom book each day; the labels mirror that.
enum PlanSection {
  book('livro'),
  wisdom('sapiencial');

  final String key;
  const PlanSection(this.key);

  static PlanSection fromKey(String? k) =>
      values.firstWhere((s) => s.key == k, orElse: () => book);
}

/// A single reading line for a day (e.g. "São Marcos 1-2" or "Salmo 11"),
/// with its resolved chapter targets.
class PlanReading {
  final String ref; // human label, exactly as the plan presents it
  final List<PlanTarget> targets;
  final PlanSection section;
  const PlanReading(this.ref, this.targets,
      {this.section = PlanSection.book});

  factory PlanReading.fromJson(Map<String, dynamic> j) => PlanReading(
        j['ref'] as String,
        (j['targets'] as List)
            .map((e) => PlanTarget.fromJson(e as Map<String, dynamic>))
            .toList(),
        section: PlanSection.fromKey(j['section'] as String?),
      );
}

class PlanDay {
  final int day;
  final List<PlanReading> readings;
  const PlanDay(this.day, this.readings);

  factory PlanDay.fromJson(Map<String, dynamic> j) => PlanDay(
        (j['day'] as num).toInt(),
        (j['readings'] as List)
            .map((e) => PlanReading.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A fixed-sequence reading plan bundled as an asset. The single plan shipping
/// today is "Bible in a Year"; the model is plan-id scoped so more can be added
/// later with no schema change.
class ReadingPlan {
  final String id;
  final int days;
  final Map<String, String> title; // lang -> title
  final String source;
  final List<PlanDay> entries;

  const ReadingPlan({
    required this.id,
    required this.days,
    required this.title,
    required this.source,
    required this.entries,
  });

  String titleFor(String lang) => title[lang] ?? title['pt'] ?? id;

  PlanDay dayAt(int day) => entries[day.clamp(1, days) - 1];

  static const asset = 'assets/plans/bible_in_a_year.json';

  static Future<ReadingPlan> loadDefault() async {
    final raw = await rootBundle.loadString(asset);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return ReadingPlan(
      id: j['id'] as String,
      days: (j['days'] as num).toInt(),
      title: (j['title'] as Map).map((k, v) => MapEntry('$k', '$v')),
      source: j['source'] as String? ?? '',
      entries: (j['entries'] as List)
          .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
