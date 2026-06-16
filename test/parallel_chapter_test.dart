import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

ChapterContent chapter(List<Verse> verses,
        {List<SectionHeading> headings = const []}) =>
    ChapterContent('gn', 1, verses, headings);

void main() {
  group('ParallelChapter.align', () {
    test('pairs verses by canonical number', () {
      final p = chapter([const Verse(1, 'In principio'), const Verse(2, 'Terra autem')]);
      final s = chapter([const Verse(1, 'No princípio'), const Verse(2, 'A terra porém')]);

      final aligned = ParallelChapter.align(p, s);

      expect(aligned.rows, hasLength(2));
      expect(aligned.rows[0].number, 1);
      expect(aligned.rows[0].primary?.text, 'In principio');
      expect(aligned.rows[0].secondary?.text, 'No princípio');
      expect(aligned.rows[1].secondary?.text, 'A terra porém');
    });

    test('keeps primary order and inherits primary headings', () {
      final p = chapter(
        [const Verse(1, 'a'), const Verse(2, 'b')],
        headings: [const SectionHeading(1, 'title', 'A Criação')],
      );
      final aligned = ParallelChapter.align(p, chapter([const Verse(1, 'x')]));
      expect(aligned.headings, hasLength(1));
      expect(aligned.headings.first.text, 'A Criação');
    });

    test('missing verse in secondary leaves secondary null (placeholder case)', () {
      final p = chapter([const Verse(1, 'a'), const Verse(2, 'b'), const Verse(3, 'c')]);
      final s = chapter([const Verse(1, 'x'), const Verse(3, 'z')]); // no v2

      final aligned = ParallelChapter.align(p, s);

      expect(aligned.rows[1].number, 2);
      expect(aligned.rows[1].primary?.text, 'b');
      expect(aligned.rows[1].secondary, isNull);
    });

    test('verse only in secondary (different numbering) is appended, not dropped',
        () {
      final p = chapter([const Verse(1, 'a'), const Verse(2, 'b')]);
      final s = chapter([const Verse(1, 'x'), const Verse(2, 'y'), const Verse(3, 'z')]);

      final aligned = ParallelChapter.align(p, s);

      expect(aligned.rows, hasLength(3));
      final extra = aligned.rows.last;
      expect(extra.number, 3);
      expect(extra.primary, isNull);
      expect(extra.secondary?.text, 'z');
    });

    test('null secondary yields primary-only rows (no second translation)', () {
      final p = chapter([const Verse(1, 'a'), const Verse(2, 'b')]);
      final aligned = ParallelChapter.align(p, null);
      expect(aligned.rows, hasLength(2));
      expect(aligned.rows.every((r) => r.secondary == null), isTrue);
    });

    test('canonicalText falls back to secondary when primary absent', () {
      final extraOnly = const ParallelVerse(5, null, Verse(5, 'only secondary'));
      expect(extraOnly.canonicalText, 'only secondary');
      final both = const ParallelVerse(1, Verse(1, 'primary'), Verse(1, 'sec'));
      expect(both.canonicalText, 'primary');
    });
  });
}
