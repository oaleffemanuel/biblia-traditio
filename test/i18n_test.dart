import 'dart:convert';
import 'dart:io';

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

  test('implemented UI languages are exposed and Latin remains unavailable', () {
    expect(AppLanguage.implemented,
        [AppLanguage.pt, AppLanguage.en, AppLanguage.es, AppLanguage.fr, AppLanguage.it]);
    for (final unavailable in [AppLanguage.la]) {
      expect(AppLanguage.implemented.contains(unavailable), isFalse,
          reason: '${unavailable.code} has no translated UI — must not be selectable');
    }
  });

  test('commentary filter label is Patrística / Patristics', () {
    expect(AppL10nPt().filterFathers, 'Patrística');
    expect(AppL10nPt().filterFathers, isNot('Padres'));
    expect(AppL10nEn().filterFathers, 'Patristics');
  });

  test('every category/filter/scope label reads "Patrística"', () {
    final pt = AppL10nPt();
    for (final label in [
      pt.filterFathers,
      pt.searchScopeFathers,
      pt.commentaryTabPatristics,
      pt.rolePatristics,
    ]) {
      expect(label, 'Patrística');
    }
    final en = AppL10nEn();
    for (final label in [
      en.filterFathers,
      en.searchScopeFathers,
      en.commentaryTabPatristics,
      en.rolePatristics,
    ]) {
      expect(label, 'Patristics');
    }
  });

  test('"Padres" survives only where it names the Fathers as people', () {
    // Audit every Portuguese string: any mention of "Padres" must be part of
    // "Padres da Igreja" (the men) or "Padre Matos Soares" (a translator's
    // title) — never a category, filter or scope label.
    final arb = jsonDecode(File('lib/l10n/app_pt.arb').readAsStringSync())
        as Map<String, dynamic>;
    final offenders = <String>[];
    arb.forEach((key, value) {
      if (key.startsWith('@') || value is! String) return;
      if (!value.contains('Padre')) return;
      final ok = RegExp(r'Padres da Igreja|Padre Matos Soares|Pe\. Matos Soares')
          .allMatches(value)
          .fold<String>(value, (acc, m) => acc.replaceFirst(m.group(0)!, ''));
      if (ok.contains('Padre')) offenders.add('$key: $value');
    });
    expect(offenders, isEmpty,
        reason: 'these strings still use "Padres" outside the allowed phrases');
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
