import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One openable destination inside a reading: a book + chapter the Reader can
/// jump to directly.
class PlanTarget {
  final String bookId;
  final int chapter;
  const PlanTarget(this.bookId, this.chapter);

  factory PlanTarget.fromJson(Map<String, dynamic> j) =>
      PlanTarget(j['book'] as String, (j['chapter'] as num).toInt());
}

/// A single reading line for a day (e.g. "São Marcos 1-2" or "Salmo 11"),
/// with its resolved chapter targets.
class PlanReading {
  final String ref; // human label, exactly as the plan presents it
  final List<PlanTarget> targets;
  const PlanReading(this.ref, this.targets);

  factory PlanReading.fromJson(Map<String, dynamic> j) => PlanReading(
        j['ref'] as String,
        (j['targets'] as List)
            .map((e) => PlanTarget.fromJson(e as Map<String, dynamic>))
            .toList(),
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
