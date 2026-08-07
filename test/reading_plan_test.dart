import 'package:flutter_test/flutter_test.dart';
import 'package:biblia_traditio/features/reading_plan/domain/reading_plan.dart';

/// The 73 canonical book ids (Catholic) the plan targets must stay within.
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

  test('bundled plan loads with 365 well-formed days', () async {
    final plan = await ReadingPlan.loadDefault();
    expect(plan.id, 'bible_in_a_year');
    expect(plan.days, 365);
    expect(plan.entries.length, 365);
    // Days are 1..365 in order.
    for (var i = 0; i < plan.entries.length; i++) {
      expect(plan.entries[i].day, i + 1);
      expect(plan.entries[i].readings, isNotEmpty);
    }
  });

  test('every reading target resolves to a canonical book + valid chapter',
      () async {
    final plan = await ReadingPlan.loadDefault();
    final seen = <String>{};
    for (final d in plan.entries) {
      for (final r in d.readings) {
        expect(r.targets, isNotEmpty, reason: 'day ${d.day} "${r.ref}"');
        for (final t in r.targets) {
          expect(_canon.contains(t.bookId), isTrue,
              reason: 'day ${d.day}: unknown book ${t.bookId}');
          expect(t.chapter, greaterThanOrEqualTo(1));
          seen.add(t.bookId);
        }
      }
    }
    // A "Bible in a year" plan should touch all 73 books.
    expect(seen.length, 73);
  });

  test('dayAt clamps out-of-range days', () async {
    final plan = await ReadingPlan.loadDefault();
    expect(plan.dayAt(1).day, 1);
    expect(plan.dayAt(0).day, 1);
    expect(plan.dayAt(999).day, 365);
    expect(plan.titleFor('pt'), 'Bíblia em um ano');
    expect(plan.titleFor('xx'), 'Bíblia em um ano'); // falls back to pt
  });

  test('readings carry the plan section they belong to', () async {
    final plan = await ReadingPlan.loadDefault();
    final sections = {
      for (final d in plan.entries)
        for (final r in d.readings) r.section,
    };
    // The schedule runs a narrative book alongside a wisdom book each day.
    expect(sections, {PlanSection.book, PlanSection.wisdom});
  });

  test('partial readings carry the exact verse span the plan assigns',
      () async {
    final plan = await ReadingPlan.loadDefault();
    final partial = [
      for (final d in plan.entries)
        for (final r in d.readings)
          for (final t in r.targets)
            if (t.isPartial) (day: d.day, ref: r.ref, target: t),
    ];
    // Proverbs and Psalm 119 are read a few verses at a time — that is what
    // lets the screen render the assigned passage instead of a whole chapter.
    expect(partial, isNotEmpty);
    for (final p in partial) {
      expect(p.target.verseStart, greaterThanOrEqualTo(1),
          reason: 'day ${p.day} "${p.ref}"');
      expect(p.target.verseEnd, greaterThanOrEqualTo(p.target.verseStart!),
          reason: 'day ${p.day} "${p.ref}"');
      // The label must state the same span it opens.
      expect(p.ref, contains('${p.target.verseStart}'),
          reason: 'day ${p.day} "${p.ref}"');
    }
  });

  test('a whole-chapter target includes every verse; a span includes only its own',
      () async {
    const whole = PlanTarget('mk', 1);
    expect(whole.isPartial, isFalse);
    for (final v in [1, 20, 200]) {
      expect(whole.includes(v), isTrue);
    }

    const span = PlanTarget('prv', 1, verseStart: 1, verseEnd: 7);
    expect(span.isPartial, isTrue);
    expect(span.includes(1), isTrue);
    expect(span.includes(7), isTrue);
    expect(span.includes(8), isFalse);
    expect(span.includes(0), isFalse);
  });

  test('Psalm labels keep the Hebrew number while opening the Vulgate chapter',
      () async {
    final plan = await ReadingPlan.loadDefault();
    // Day 1's wisdom reading is "Salmo 11" (Hebrew) → Vulgate Psalm 10.
    final psalm = plan.dayAt(1).readings.firstWhere((r) => r.ref.startsWith('Salmo'));
    expect(psalm.ref, 'Salmo 11');
    expect(psalm.targets.single.bookId, 'ps');
    expect(psalm.targets.single.chapter, 10);
  });
}
