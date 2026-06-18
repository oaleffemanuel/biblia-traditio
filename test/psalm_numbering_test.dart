import 'package:biblia_traditio/features/bible/domain/psalm_numbering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hebrewToVulgate', () {
    test('Ps 1–8 coincide', () {
      for (var h = 1; h <= 8; h++) {
        expect(PsalmNumbering.hebrewToVulgate(h), h);
      }
    });
    test('the Good Shepherd: Hebrew 23 → Vulgate 22', () {
      expect(PsalmNumbering.hebrewToVulgate(23), 22);
    });
    test('Hebrew 9 and 10 both map to merged Vulgate 9', () {
      expect(PsalmNumbering.hebrewToVulgate(9), 9);
      expect(PsalmNumbering.hebrewToVulgate(10), 9);
    });
    test('offset range Hebrew 11–113 → Vulgate 10–112', () {
      expect(PsalmNumbering.hebrewToVulgate(11), 10);
      expect(PsalmNumbering.hebrewToVulgate(113), 112);
      expect(PsalmNumbering.hebrewToVulgate(119), 118); // the long acrostic
    });
    test('merge/split regions', () {
      expect(PsalmNumbering.hebrewToVulgate(114), 113);
      expect(PsalmNumbering.hebrewToVulgate(115), 113);
      expect(PsalmNumbering.hebrewToVulgate(116), 114);
      expect(PsalmNumbering.hebrewToVulgate(117), 116);
      expect(PsalmNumbering.hebrewToVulgate(146), 145);
      expect(PsalmNumbering.hebrewToVulgate(147), 146);
    });
    test('Ps 148–150 coincide', () {
      for (var h = 148; h <= 150; h++) {
        expect(PsalmNumbering.hebrewToVulgate(h), h);
      }
    });
  });

  group('hebrewLabel / dualLabel', () {
    test('no suffix where the systems agree', () {
      expect(PsalmNumbering.hebrewLabel(1), isNull);
      expect(PsalmNumbering.hebrewLabel(8), isNull);
      expect(PsalmNumbering.hebrewLabel(148), isNull);
      expect(PsalmNumbering.dualLabel(5), '5');
    });
    test('Vulgate 22 displays as "22 (23)"', () {
      expect(PsalmNumbering.dualLabel(22), '22 (23)');
      expect(PsalmNumbering.dualLabel(23), '23 (24)');
    });
    test('merged/split show ranges or shared numbers', () {
      expect(PsalmNumbering.hebrewLabel(9), '9-10');
      expect(PsalmNumbering.hebrewLabel(113), '114-115');
      expect(PsalmNumbering.hebrewLabel(114), '116');
      expect(PsalmNumbering.hebrewLabel(115), '116');
      expect(PsalmNumbering.hebrewLabel(146), '147');
      expect(PsalmNumbering.hebrewLabel(147), '147');
    });
  });

  test('navigation round-trips back to a sensible Vulgate chapter', () {
    // A reader looking for "Psalm 23" (shepherd) is sent to Vulgate 22, which
    // labels itself "22 (23)".
    final v = PsalmNumbering.hebrewToVulgate(23);
    expect(v, 22);
    expect(PsalmNumbering.dualLabel(v), '22 (23)');
  });
}
