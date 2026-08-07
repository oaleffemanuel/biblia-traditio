import 'package:biblia_traditio/app/back_navigation.dart';
import 'package:biblia_traditio/l10n/app_localizations_en.dart';
import 'package:biblia_traditio/l10n/app_localizations_pt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 7, 10, 0, 0);

  test('Back from a non-Home tab goes Home before anything else', () {
    for (final index in [1, 2]) {
      expect(
        resolveBackAction(currentIndex: index, lastPress: null, now: now),
        BackAction.goHome,
        reason: 'tab $index must land on Home first, not exit',
      );
    }
  });

  test('a non-Home tab never exits, even right after a Home warning', () {
    expect(
      resolveBackAction(
          currentIndex: 1,
          lastPress: now.subtract(const Duration(milliseconds: 300)),
          now: now),
      BackAction.goHome,
    );
  });

  test('first Back on Home warns instead of closing the app', () {
    expect(
      resolveBackAction(currentIndex: 0, lastPress: null, now: now),
      BackAction.warnBeforeExit,
    );
  });

  test('second Back on Home within the window exits', () {
    expect(
      resolveBackAction(
          currentIndex: 0,
          lastPress: now.subtract(const Duration(milliseconds: 900)),
          now: now),
      BackAction.exit,
    );
    // Exactly at the boundary still counts as a confirmation.
    expect(
      resolveBackAction(
          currentIndex: 0, lastPress: now.subtract(kExitConfirmWindow), now: now),
      BackAction.exit,
    );
  });

  test('a stale press warns again rather than exiting', () {
    expect(
      resolveBackAction(
          currentIndex: 0,
          lastPress: now.subtract(kExitConfirmWindow + const Duration(seconds: 1)),
          now: now),
      BackAction.warnBeforeExit,
    );
  });

  test('the confirmation copy is the requested Brazilian wording', () {
    expect(AppL10nPt().pressBackAgainToExit, 'Pressione novamente para sair.');
    expect(AppL10nEn().pressBackAgainToExit, 'Press back again to exit.');
  });
}
