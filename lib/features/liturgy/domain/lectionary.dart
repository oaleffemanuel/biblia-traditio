import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Lectionary (the daily Mass readings). Kept behind an interface so the data
/// source can grow. The MVP bundles a references-only dataset (Sundays +
/// principal solemnities) and shows it against the app's own bundled Bible —
/// never the copyrighted lectionary text, and never fabricated, since wrong
/// readings are worse than none in a Catholic app.
enum ReadingSlot { first, psalm, second, gospel }

extension ReadingSlotX on ReadingSlot {
  String get labelPt => switch (this) {
    ReadingSlot.first => '1ª leitura',
    ReadingSlot.psalm => 'Salmo',
    ReadingSlot.second => '2ª leitura',
    ReadingSlot.gospel => 'Evangelho',
  };

  static ReadingSlot? from(String s) => switch (s) {
    'first' => ReadingSlot.first,
    'psalm' => ReadingSlot.psalm,
    'second' => ReadingSlot.second,
    'gospel' => ReadingSlot.gospel,
    _ => null,
  };
}

class Reading {
  final ReadingSlot slot;
  final String reference; // display citation, e.g. 'Jr 20,10-13'
  final String? bookId; // resolved canonical book code, when known
  final int? chapter; // open target (Vulgate numbering for psalms)
  final int? verse; // first verse of the pericope
  final int? verseStart; // contiguous render span (start)…
  final int? verseEnd; // …and end, both in the target chapter's numbering

  /// The responsorial refrain, exactly as the Lectionary appoints it, and the
  /// verse it is drawn from ("Sl 22,1").
  ///
  /// Both are null today: the bundled source (cpbjr/catholic-readings-api)
  /// carries citations only — no refrain field exists in it. The refrain is NOT
  /// derivable from the psalm text: the Lectionary chooses it, sometimes adapts
  /// the wording, and sometimes takes it from outside the psalm. So the app
  /// renders it when a source supplies it and says where it lives when not,
  /// rather than printing a line that may not be the one sung.
  final String? refrain;
  final String? refrainRef;
  final String? refrainBookId;
  final int? refrainChapter;
  final int? refrainVerse;
  final String? acclamation;

  const Reading(
    this.slot,
    this.reference, {
    this.bookId,
    this.chapter,
    this.verse,
    this.verseStart,
    this.verseEnd,
    this.refrain,
    this.refrainRef,
    this.refrainBookId,
    this.refrainChapter,
    this.refrainVerse,
    this.acclamation,
  });

  bool get hasRefrain =>
      (refrain ?? '').trim().isNotEmpty ||
      (refrainBookId != null && refrainChapter != null && refrainVerse != null);

  bool get canOpen => bookId != null && chapter != null;

  /// The same reading with the day's refrain attached.
  Reading withRefrain(String text, {String? ref}) => Reading(
    slot,
    reference,
    bookId: bookId,
    chapter: chapter,
    verse: verse,
    verseStart: verseStart,
    verseEnd: verseEnd,
    refrain: text,
    refrainRef: ref ?? refrainRef,
    refrainBookId: refrainBookId,
    refrainChapter: refrainChapter,
    refrainVerse: refrainVerse,
    acclamation: acclamation,
  );

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
    ReadingSlotX.from(j['slot'] as String) ?? ReadingSlot.first,
    j['ref'] as String,
    bookId: j['book'] as String?,
    chapter: (j['chapter'] as num?)?.toInt(),
    verse: (j['verse'] as num?)?.toInt(),
    verseStart: (j['vStart'] as num?)?.toInt(),
    verseEnd: (j['vEnd'] as num?)?.toInt(),
    refrain: j['refrain'] as String?,
    refrainRef: j['refrainRef'] as String?,
    refrainBookId: j['refrainBook'] as String?,
    refrainChapter: (j['refrainChapter'] as num?)?.toInt(),
    refrainVerse: (j['refrainVerse'] as num?)?.toInt(),
    acclamation: j['acclamation'] as String?,
  );
}

abstract class LectionaryRepository {
  const LectionaryRepository();

  /// Readings for [date], or null when none are available for that day.
  List<Reading>? readingsFor(DateTime date);

  /// Whether the bundled refrains already cover [date] (matched or knowingly
  /// left out), so nothing should be fetched online for it.
  bool refrainsCover(DateTime date) => false;
}

/// No readings available (fallback / Latin-only builds).
class EmptyLectionaryRepository extends LectionaryRepository {
  const EmptyLectionaryRepository();
  @override
  List<Reading>? readingsFor(DateTime date) => null;
}

/// Reads the bundled references dataset (built by tool/build_lectionary.py),
/// keyed by ISO date. Missing dates return null → the UI shows the graceful
/// "not available yet" state.
class BundledLectionaryRepository extends LectionaryRepository {
  final Map<String, List<Reading>> _byDate;
  final Set<String> _refrainDays;
  BundledLectionaryRepository(this._byDate, [this._refrainDays = const {}]);

  @override
  bool refrainsCover(DateTime date) => _refrainDays.contains(_key(date));

  static const asset = 'assets/lectionary/readings.json';
  static const refrainsAsset = 'assets/lectionary/refrains.json';

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  List<Reading>? readingsFor(DateTime date) => _byDate[_key(date)];

  /// The refrain option whose psalm is the one this reading shows (in either
  /// numbering, "Sl 14(15)"). Brazil sometimes keeps a different feast than
  /// the reference calendar; a refrain from another psalm is never shown.
  static Map? _refrainFor(Map<String, dynamic> psalm, List options) {
    final ch = (psalm['chapter'] as num?)?.toInt();
    // Hebrew and Vulgate numbers, plus the split psalms (116 → 114/115).
    final want = {
      ch,
      (psalm['displayChapter'] as num?)?.toInt(),
      if (ch != null) ch + 1,
    }..remove(null);
    // Canticles ("Jr 31", "Dn 3", "Lc 1") match on book and chapter.
    final book = '${psalm['ref'] ?? ''}'.trim().split(RegExp(r'[\s\d]')).first;
    for (final o in options) {
      final ref = '${(o as Map)['ref'] ?? ''}'.trim();
      final optBook = ref.split(RegExp(r'[\s\d]')).first;
      if (optBook.isEmpty || optBook != book) continue;
      final nums = RegExp(
        r'\d+',
      ).allMatches(ref).take(2).map((m) => int.parse(m.group(0)!));
      if (nums.any(want.contains)) return o;
    }
    return null;
  }

  static Future<BundledLectionaryRepository> load() async {
    final Map<String, List<Reading>> byDate = {};
    Map<String, dynamic> refrains = const {};
    try {
      final raw = await rootBundle.loadString(asset);
      Map<String, dynamic> acclamations = const {};
      try {
        acclamations =
            jsonDecode(
                  await rootBundle.loadString(
                    'assets/lectionary/acclamations.json',
                  ),
                )
                as Map<String, dynamic>;
      } on Exception {
        // The references-only lectionary remains usable without enrichment.
      }
      // The day's psalm refrain, baked by tool/fetch_psalm_refrains.py.
      try {
        final r =
            jsonDecode(await rootBundle.loadString(refrainsAsset))
                as Map<String, dynamic>;
        refrains = r['days'] as Map<String, dynamic>? ?? const {};
      } on Object {
        // No refrains bundled (asset missing is a FlutterError, not an
        // Exception): the psalm card says where the refrain lives.
      }
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final entries = j['entries'] as Map<String, dynamic>? ?? const {};
      for (final e in entries.entries) {
        final dayExtra =
            acclamations[e.key] as Map<String, dynamic>? ?? const {};
        final list = (e.value['readings'] as List).map((r) {
          final source = Map<String, dynamic>.from(r as Map<String, dynamic>);
          final extra = dayExtra[source['slot']] as Map<String, dynamic>?;
          if (extra != null) source.addAll(extra);
          final day = refrains[e.key] as List?;
          if (source['slot'] == 'psalm' &&
              source['refrain'] == null &&
              day != null) {
            final match = _refrainFor(source, day);
            if (match != null) {
              source['refrain'] = match['refrain'];
              source['refrainRef'] ??= match['ref'];
            }
          }
          return Reading.fromJson(source);
        }).toList();
        byDate[e.key] = list;
      }
    } on Exception {
      // No dataset bundled → behaves like the empty repository.
    }
    return BundledLectionaryRepository(byDate, refrains.keys.toSet());
  }
}
