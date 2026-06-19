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

  test('bundled lectionary loads and is well-formed', () async {
    final repo = await BundledLectionaryRepository.load();
    // Every reading points at a canonical book + sane chapter, and is openable.
    final christmas = repo.readingsFor(DateTime(2026, 12, 25));
    expect(christmas, isNotNull);
    expect(christmas!.map((r) => r.slot),
        containsAll([ReadingSlot.first, ReadingSlot.psalm, ReadingSlot.gospel]));
    for (final r in christmas) {
      expect(_canon.contains(r.bookId), isTrue, reason: r.reference);
      expect(r.chapter, greaterThanOrEqualTo(1));
      expect(r.canOpen, isTrue);
    }
  });

  test('psalm references open the Vulgate-numbered chapter', () async {
    final repo = await BundledLectionaryRepository.load();
    // 12th Sunday in Ordinary Time, Year A: responsorial psalm 69 (Hebrew) →
    // the app's Vulgate Psalm 68; the display keeps the lectionary's "Sl 69".
    final day = repo.readingsFor(DateTime(2026, 6, 21));
    expect(day, isNotNull);
    final psalm = day!.firstWhere((r) => r.slot == ReadingSlot.psalm);
    expect(psalm.bookId, 'ps');
    expect(psalm.chapter, 68); // Vulgate
    expect(psalm.reference, contains('69')); // Hebrew, as the lectionary cites
  });

  test('a day with no readings returns null (graceful empty state)', () async {
    final repo = await BundledLectionaryRepository.load();
    // An ordinary weekday not in the Sundays+solemnities MVP set.
    expect(repo.readingsFor(DateTime(2026, 6, 17)), isNull);
  });

  test('empty repository yields null', () {
    expect(const EmptyLectionaryRepository().readingsFor(DateTime(2026, 1, 1)),
        isNull);
  });
}
