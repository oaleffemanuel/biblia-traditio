import 'package:biblia_traditio/features/liturgy/domain/lectionary.dart';
import 'package:flutter_test/flutter_test.dart';

const _canon = {
  'gn', 'ex', 'lv', 'nm', 'dt', 'jo', 'jgs', 'rt', '1sm', '2sm', '1kgs',
  '2kgs', '1chr', '2chr', 'ezr', 'neh', 'tb', 'jdt', 'est', '1mac', '2mac',
  'jb', 'ps', 'prv', 'eccl', 'sg', 'ws', 'sir', 'is', 'jer', 'lam', 'bar',
  'ez', 'dn', 'hos', 'jl', 'am', 'ob', 'jon', 'mi', 'na', 'hb', 'zep', 'hg',
  'zec', 'mal', 'mt', 'mk', 'lk', 'jn', 'acts', 'rom', '1cor', '2cor', 'gal',
  'eph', 'phil', 'col', '1thes', '2thes', '1tm', '2tm', 'tit', 'phlm', 'heb',
  'jas', '1pt', '2pt', '1jn', '2jn', '3jn', 'jud', 'rv',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BundledLectionaryRepository repo;
  setUpAll(() async => repo = await BundledLectionaryRepository.load());

  void expectAllOpenableCanonical(List<Reading> readings) {
    for (final r in readings) {
      expect(_canon.contains(r.bookId), isTrue, reason: r.reference);
      expect(r.chapter, greaterThanOrEqualTo(1));
      expect(r.canOpen, isTrue);
    }
  }

  test('ordinary weekday has first + psalm + gospel (no second)', () {
    final day = repo.readingsFor(DateTime(2026, 6, 22)); // Monday, Ordinary Time
    expect(day, isNotNull);
    final slots = day!.map((r) => r.slot).toSet();
    expect(slots, containsAll([ReadingSlot.first, ReadingSlot.psalm, ReadingSlot.gospel]));
    expect(slots.contains(ReadingSlot.second), isFalse);
    expectAllOpenableCanonical(day);
  });

  test('Sunday has all four readings', () {
    final day = repo.readingsFor(DateTime(2026, 6, 21)); // 12th Sunday OT (A)
    expect(day, isNotNull);
    expect(day!.map((r) => r.slot),
        containsAll(ReadingSlot.values));
    expectAllOpenableCanonical(day);
  });

  test('solemnity (Christmas) has all four readings', () {
    final day = repo.readingsFor(DateTime(2026, 12, 25));
    expect(day, isNotNull);
    expect(day!.map((r) => r.slot), containsAll(ReadingSlot.values));
    final gospel = day.firstWhere((r) => r.slot == ReadingSlot.gospel);
    expect(gospel.bookId, 'jn'); // John 1:1-18
  });

  test('Lent weekday resolves and opens the reader', () {
    final day = repo.readingsFor(DateTime(2026, 2, 19)); // Thu after Ash Wed
    expect(day, isNotNull);
    final gospel = day!.firstWhere((r) => r.slot == ReadingSlot.gospel);
    expect(gospel.bookId, 'lk');
    expectAllOpenableCanonical(day);
  });

  test('Easter weekday resolves', () {
    final day = repo.readingsFor(DateTime(2026, 4, 6)); // Easter Monday
    expect(day, isNotNull);
    final gospel = day!.firstWhere((r) => r.slot == ReadingSlot.gospel);
    expect(gospel.bookId, 'mt');
    expectAllOpenableCanonical(day);
  });

  test('responsorial psalm maps Hebrew→Vulgate, display keeps Hebrew', () {
    final day = repo.readingsFor(DateTime(2026, 6, 21));
    final psalm = day!.firstWhere((r) => r.slot == ReadingSlot.psalm);
    expect(psalm.bookId, 'ps');
    expect(psalm.chapter, 68); // Hebrew 69 → Vulgate 68
    expect(psalm.reference, contains('69')); // displayed as the lectionary cites
  });

  test('every reading carries a deep-link target', () {
    final day = repo.readingsFor(DateTime(2026, 12, 25))!;
    for (final r in day) {
      expect(r.canOpen, isTrue);
      expect(r.verse, isNotNull); // first verse of the pericope
    }
  });

  test('coverage is full-year: a random weekday in each season resolves', () {
    for (final dt in [
      DateTime(2026, 1, 14), // Christmas/Ordinary
      DateTime(2026, 3, 4), // Lent
      DateTime(2026, 4, 22), // Easter
      DateTime(2026, 7, 15), // Ordinary
      DateTime(2026, 12, 3), // Advent
    ]) {
      expect(repo.readingsFor(dt), isNotNull, reason: '$dt');
    }
  });

  test('out-of-coverage date returns null (graceful empty state)', () {
    expect(repo.readingsFor(DateTime(2030, 6, 17)), isNull);
    expect(const EmptyLectionaryRepository().readingsFor(DateTime(2026, 1, 1)),
        isNull);
  });
}
