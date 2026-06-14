import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/lectionary.dart';
import '../domain/liturgical_calendar.dart';
import '../domain/liturgical_day.dart';

final _calendar = const LiturgicalCalendar();

/// Resolved liturgical day for any date (offline computation).
final liturgicalDayProvider =
    Provider.family<LiturgicalDay, DateTime>((ref, date) {
  return _calendar.resolve(date);
});

/// Colour dot for each day of the given month (for the calendar modal).
final monthColorsProvider =
    Provider.family<Map<int, LiturgicalColor>, ({int year, int month})>(
        (ref, key) {
  final last = DateTime(key.year, key.month + 1, 0).day;
  return {
    for (var d = 1; d <= last; d++)
      d: _calendar.resolve(DateTime(key.year, key.month, d)).color,
  };
});

/// The active lectionary (empty until a readings pack is installed).
final lectionaryProvider =
    Provider<LectionaryRepository>((ref) => const EmptyLectionaryRepository());

final readingsForProvider =
    Provider.family<List<Reading>?, DateTime>((ref, date) {
  return ref.watch(lectionaryProvider).readingsFor(date);
});
