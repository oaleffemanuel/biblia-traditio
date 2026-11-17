import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/lectionary.dart';
import '../domain/online_refrains.dart';
import '../domain/liturgical_calendar.dart';
import '../domain/liturgical_day.dart';
import '../domain/saints.dart';

final _calendar = const LiturgicalCalendar();

/// Resolved liturgical day for any date (offline computation).
final liturgicalDayProvider = Provider.family<LiturgicalDay, DateTime>((
  ref,
  date,
) {
  return _calendar.resolve(date);
});

/// Colour dot for each day of the given month (for the calendar modal).
final monthColorsProvider =
    Provider.family<Map<int, LiturgicalColor>, ({int year, int month})>((
      ref,
      key,
    ) {
      final last = DateTime(key.year, key.month + 1, 0).day;
      return {
        for (var d = 1; d <= last; d++)
          d: _calendar.resolve(DateTime(key.year, key.month, d)).color,
      };
    });

/// Loads the bundled lectionary references (Sundays + solemnities) once.
final lectionaryProvider = FutureProvider<LectionaryRepository>(
  (ref) => BundledLectionaryRepository.load(),
);

/// Readings for a date, or null while loading / when none are available — the
/// screen renders the graceful empty state for null.
final readingsForProvider = Provider.family<List<Reading>?, DateTime>((
  ref,
  date,
) {
  final repo = ref.watch(lectionaryProvider).value;
  final list = repo?.readingsFor(date);
  if (list == null) return null;
  if (repo!.refrainsCover(date)) return list;
  // A day beyond the bundled years: fetch its refrain once, online.
  final i = list.indexWhere(
    (r) => r.slot == ReadingSlot.psalm && !r.hasRefrain,
  );
  if (i < 0) return list;
  final online = ref.watch(onlineRefrainProvider(date)).value;
  if (online == null) return list;
  return [...list]..[i] = list[i].withRefrain(online);
});

/// The psalm refrain of [date] from the liturgy API, cached on disk so each
/// day is asked once. Null offline or when the service has none — the card
/// then explains where the refrain lives.
final onlineRefrainProvider = FutureProvider.family<String?, DateTime>(
  (ref, date) => OnlineRefrains.instance.refrainFor(date),
);

/// Saints proposed for a date, from the bundled dataset. Empty when the day
/// isn't covered — the Liturgy screen then shows no section at all.
final saintsRepositoryProvider = FutureProvider<SaintsRepository>(
  (ref) => BundledSaintsRepository.load(),
);

final saintsForProvider = Provider.family<List<SaintEntry>, DateTime>((
  ref,
  date,
) {
  return ref.watch(saintsRepositoryProvider).value?.forDate(date) ?? const [];
});
