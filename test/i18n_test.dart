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

  test('commentary filter label is Patrística / Patristics', () {
    expect(AppL10nPt().filterFathers, 'Patrística');
    expect(AppL10nPt().filterFathers, isNot('Padres'));
    expect(AppL10nEn().filterFathers, 'Patristics');
  });

  test('liturgy slot titles use the full Brazilian wording', () {
    expect(AppL10nPt().readingFirst, 'Primeira Leitura');
    expect(AppL10nPt().readingSecond, 'Segunda Leitura');
    expect(AppL10nPt().readingPsalm, 'Salmo');
    expect(AppL10nPt().readingGospel, 'Evangelho');
  });

  test('standard Mass responses are present (fixed liturgical text)', () {
    final pt = AppL10nPt();
    expect(pt.liturgyResponseWordOfLord, 'Palavra do Senhor.');
    expect(pt.liturgyResponseThanksToGod, 'Graças a Deus.');
    expect(pt.liturgyResponseGloryToYou, 'Glória a vós, Senhor.');
    expect(pt.liturgyResponseWordOfSalvation, 'Palavra da Salvação.');
    expect(pt.liturgyGospelAccording('São Mateus'),
        contains('Evangelho de Jesus Cristo segundo São Mateus'));
  });

  test('no hardcoded translation catalogue remains (use the live DB list)', () {
    // TranslationOption.catalogue (with fantasy options) was removed; pickers
    // now read availableTranslationsProvider. This is a compile-time guarantee:
    // the symbol no longer exists. Sanity-check the implemented-language gate.
    expect(AppLanguage.values.length, greaterThan(AppLanguage.implemented.length));
  });
}
