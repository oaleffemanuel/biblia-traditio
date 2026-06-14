/// Lectionary (the daily Mass readings). Kept behind an interface because the
/// full 3-year Sunday + 2-year weekday lectionary is a large dataset shipped as
/// a downloadable pack — never fabricated, since wrong readings are worse than
/// none in a Catholic app.
enum ReadingSlot { first, psalm, second, gospel }

extension ReadingSlotX on ReadingSlot {
  String get labelPt => switch (this) {
        ReadingSlot.first => '1ª leitura',
        ReadingSlot.psalm => 'Salmo',
        ReadingSlot.second => '2ª leitura',
        ReadingSlot.gospel => 'Evangelho',
      };
}

class Reading {
  final ReadingSlot slot;
  final String reference; // e.g. 'Jo 3,16-21'
  final String? bookId; // resolved canonical book code, when known
  final int? chapter;
  const Reading(this.slot, this.reference, {this.bookId, this.chapter});
}

abstract class LectionaryRepository {
  /// Readings for [date], or null when no lectionary pack is installed.
  List<Reading>? readingsFor(DateTime date);
}

/// Default until a lectionary pack ships: no readings available.
class EmptyLectionaryRepository implements LectionaryRepository {
  const EmptyLectionaryRepository();
  @override
  List<Reading>? readingsFor(DateTime date) => null;
}
