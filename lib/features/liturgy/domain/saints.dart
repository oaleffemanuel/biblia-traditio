import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A saint's entry for the day, as the app is willing to show it.
///
/// The app shows a life only when it has one that is actually sourced. There is
/// no generated or inferred text anywhere in this feature: a day the dataset
/// does not cover simply has no section, which is the correct answer.
class SaintEntry {
  /// Calendar key, `MM-DD`.
  final String day;

  final String name;

  /// Office/title as the calendar gives it — "Bispo e doutor da Igreja".
  final String title;

  /// Roman-numeral century of death, when known ("IV").
  final String century;

  /// Year of death as the sources give it, when known.
  final String? died;

  /// The life, in 3–6 paragraphs.
  final List<String> biography;

  /// Where the life comes from. Shown on the saint's page — the reader is
  /// always told what they are reading.
  final String source;

  const SaintEntry({
    required this.day,
    required this.name,
    required this.title,
    required this.century,
    required this.biography,
    required this.source,
    this.died,
  });

  factory SaintEntry.fromJson(Map<String, dynamic> j) => SaintEntry(
        day: j['day'] as String,
        name: j['name'] as String,
        title: (j['title'] as String?) ?? '',
        century: (j['century'] as String?) ?? '',
        died: j['died'] as String?,
        biography: [
          for (final p in (j['biography'] as List? ?? const [])) '$p',
        ],
        source: (j['source'] as String?) ?? '',
      );

  /// A life needs a name and at least three paragraphs to be worth a section.
  /// Anything thinner is treated as absent rather than padded out.
  bool get isPresentable =>
      name.trim().isNotEmpty && biography.length >= 3;
}

abstract class SaintsRepository {
  /// The saints proposed for [date], best first. Empty when the dataset has
  /// nothing for that day — the UI then shows no section at all.
  List<SaintEntry> forDate(DateTime date);
}

/// Nothing available (a build without the dataset).
class EmptySaintsRepository implements SaintsRepository {
  const EmptySaintsRepository();
  @override
  List<SaintEntry> forDate(DateTime date) => const [];
}

/// Reads the bundled `assets/saints/saints.json`, keyed `MM-DD`. Loaded once
/// and held in memory — the dataset is small and entirely offline.
class BundledSaintsRepository implements SaintsRepository {
  final Map<String, List<SaintEntry>> _byDay;
  const BundledSaintsRepository(this._byDay);

  static const asset = 'assets/saints/saints.json';

  static String keyFor(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  List<SaintEntry> forDate(DateTime date) => _byDay[keyFor(date)] ?? const [];

  int get entryCount => _byDay.values.fold(0, (n, l) => n + l.length);

  static Future<BundledSaintsRepository> load() async {
    final byDay = <String, List<SaintEntry>>{};
    try {
      final raw = await rootBundle.loadString(asset);
      final j = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in (j['entries'] as List? ?? const [])) {
        final entry = SaintEntry.fromJson(e as Map<String, dynamic>);
        // Anything that would render as a stub is dropped at load time, so the
        // UI never has to decide whether a life is good enough to show.
        if (!entry.isPresentable) continue;
        byDay.putIfAbsent(entry.day, () => []).add(entry);
      }
    } on Exception {
      // No dataset in this build → behaves like the empty repository.
    }
    return BundledSaintsRepository(byDay);
  }
}
