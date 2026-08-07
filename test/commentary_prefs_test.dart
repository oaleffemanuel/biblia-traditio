import 'dart:io';

import 'package:biblia_traditio/core/storage/user/user_database.dart';
import 'package:biblia_traditio/features/bible/domain/entities.dart';
import 'package:biblia_traditio/features/settings/domain/settings.dart';
import 'package:flutter_test/flutter_test.dart';

Commentary _c({
  String name = 'Santo Agostinho de Hipona',
  String century = 'V',
  String role = 'doutor-da-igreja',
  Set<String> groups = const {'patristica', 'santos'},
}) =>
    Commentary(
      id: 1,
      ref: const VerseRef('jn', 1, 1),
      fatherName: name,
      century: century,
      source: null,
      isMachineTranslation: true,
      text: 'texto',
      rolePrimary: role,
      roleGroups: groups,
    );

void main() {
  group('defaults', () {
    test('show everything, so a new reader never loses the corpus', () {
      const p = CommentaryPrefs.defaults;
      expect(p.isDefault, isTrue);
      expect(p.activeFilterCount, 0);
      expect(p.allows(_c()), isTrue);
      expect(p.allows(_c(groups: const {}, role: '', century: '')), isTrue);
    });
  });

  group('classification filter', () {
    test('keeps only the chosen classifications', () {
      const p = CommentaryPrefs(classes: {'escolastica'});
      expect(p.allows(_c(groups: const {'patristica'})), isFalse);
      expect(p.allows(_c(groups: const {'escolastica'})), isTrue);
    });

    test('an author in several groups passes on any of them', () {
      const p = CommentaryPrefs(classes: {'santos'});
      expect(p.allows(_c(groups: const {'patristica', 'santos'})), isTrue);
    });
  });

  group('century filter', () {
    test('matches by roman numeral', () {
      const p = CommentaryPrefs(centuries: {4, 5});
      expect(p.allows(_c(century: 'V')), isTrue);
      expect(p.allows(_c(century: 'IV')), isTrue);
      expect(p.allows(_c(century: 'XIII')), isFalse);
    });

    test('a commentary with no century cannot satisfy a century filter', () {
      const p = CommentaryPrefs(centuries: {5});
      expect(p.allows(_c(century: '')), isFalse);
    });
  });

  test('"saints only" overrides the other filters', () {
    const p = CommentaryPrefs(
        classes: {'escolastica'}, centuries: {13}, onlySaints: true);
    expect(p.allows(_c(groups: const {'santos'}, century: 'V')), isTrue);
    expect(p.allows(_c(groups: const {'patristica'}, century: 'V')), isFalse);
  });

  test('filters compose: classification AND century', () {
    const p = CommentaryPrefs(classes: {'patristica'}, centuries: {5});
    expect(p.allows(_c(groups: const {'patristica'}, century: 'V')), isTrue);
    expect(p.allows(_c(groups: const {'patristica'}, century: 'IV')), isFalse);
    expect(p.allows(_c(groups: const {'escolastica'}, century: 'V')), isFalse);
    expect(p.activeFilterCount, 2);
  });

  group('persistence', () {
    late Directory dir;
    late UserDatabase db;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('bt_comm_prefs');
      db = UserDatabase.open('${dir.path}/user.db');
    });
    tearDown(() {
      db.dispose();
      dir.deleteSync(recursive: true);
    });

    test('a fresh install reads back the permissive default', () {
      expect(Settings.fromMap(db.allSettings()).commentaryPrefs,
          CommentaryPrefs.defaults);
    });

    test('preferences survive a round trip through the user DB', () {
      db.setSetting('commentaryClasses',
          CommentaryPrefs.joinStrings({'patristica', 'santos'}));
      db.setSetting('commentaryCenturies', CommentaryPrefs.joinInts({4, 13}));
      db.setSetting('commentaryOnlySaints', 'true');

      final p = Settings.fromMap(db.allSettings()).commentaryPrefs;
      expect(p.classes, {'patristica', 'santos'});
      expect(p.centuries, {4, 13});
      expect(p.onlySaints, isTrue);
      expect(p.isDefault, isFalse);
    });

    test('resetting clears every stored filter', () {
      db.setSetting('commentaryClasses', 'patristica');
      db.setSetting('commentaryCenturies', '5');
      db.setSetting('commentaryOnlySaints', 'true');

      const reset = CommentaryPrefs.defaults;
      db.setSetting('commentaryClasses', CommentaryPrefs.joinStrings(reset.classes));
      db.setSetting('commentaryCenturies', CommentaryPrefs.joinInts(reset.centuries));
      db.setSetting('commentaryOnlySaints', '${reset.onlySaints}');

      expect(Settings.fromMap(db.allSettings()).commentaryPrefs.isDefault, isTrue);
    });
  });

  group('roman numerals', () {
    test('round-trip the centuries the corpus actually uses', () {
      for (var n = 1; n <= 21; n++) {
        expect(Commentary.romanToInt(Commentary.romanNumeral(n)), n);
      }
    });

    test('an unparseable century is null, never zero', () {
      expect(Commentary.romanToInt(''), isNull);
      expect(Commentary.romanToInt('séc'), isNull);
    });
  });
}
