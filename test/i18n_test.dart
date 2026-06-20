import 'package:biblia_traditio/features/settings/domain/settings.dart';
import 'package:biblia_traditio/l10n/app_localizations_pt.dart';
import 'package:biblia_traditio/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding skip is Brazilian "Pular" (not European "Saltar")', () {
    expect(AppL10nPt().onbSkip, 'Pular');
    expect(AppL10nPt().onbSkip, isNot('Saltar'));
    expect(AppL10nEn().onbSkip, 'Skip');
  });

  test('only implemented UI languages are exposed (pt, en)', () {
    expect(AppLanguage.implemented, [AppLanguage.pt, AppLanguage.en]);
    for (final unavailable in [AppLanguage.es, AppLanguage.it, AppLanguage.la]) {
      expect(AppLanguage.implemented.contains(unavailable), isFalse,
          reason: '${unavailable.code} has no ARB yet — must not be selectable');
    }
  });

  test('no hardcoded translation catalogue remains (use the live DB list)', () {
    // TranslationOption.catalogue (with fantasy options) was removed; pickers
    // now read availableTranslationsProvider. This is a compile-time guarantee:
    // the symbol no longer exists. Sanity-check the implemented-language gate.
    expect(AppLanguage.values.length, greaterThan(AppLanguage.implemented.length));
  });
}
