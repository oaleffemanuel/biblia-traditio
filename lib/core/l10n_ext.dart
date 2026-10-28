import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// Convenience accessor: `context.l10n.navHome`.
extension L10nX on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}

/// The human name of a text's language, or null for languages the UI has no
/// word for (they're then shown by title alone rather than a code).
String? languageName(AppL10n l, String code) => switch (code) {
      'la' => l.langLatin,
      'grc' || 'el' => l.langGreek,
      'he' || 'hbo' => l.langHebrew,
      'pt' => l.langPortuguese,
      'en' => l.langEnglish,
      'it' => l.langItalian,
      'es' => l.langSpanish,
      'fr' => l.langFrench,
      _ => null,
    };

/// "Latim — Vulgata Clementina", "Grego — Novo Testamento Grego (SBLGNT)".
/// Falls back to the bare title when the language has no label, so a text is
/// never mislabelled just to fit the pattern.
String translationLabel(AppL10n l, String lang, String title) {
  final name = languageName(l, lang);
  return name == null ? title : l.translationWithLanguage(name, title);
}

/// The localised label for a commentator's function/title slug, or null when
/// the corpus supplied none — the UI then shows the century alone rather than
/// inventing a title.
String? roleLabel(AppL10n l, String slug) => switch (slug) {
      'doutor-da-igreja' => l.roleDoctor,
      'papa' => l.rolePope,
      'bispo' => l.roleBishop,
      'monge' => l.roleMonk,
      'sacerdote' => l.rolePriest,
      'diacono' => l.roleDeacon,
      'exegeta' => l.roleExegete,
      'teologo' => l.roleTheologian,
      'historiador' => l.roleHistorian,
      'poeta' => l.rolePoet,
      'patristica' => l.rolePatristics,
      'medieval' => l.roleMedieval,
      'cristao-primitivo' => l.roleEarlyChristian,
      'santo' => l.roleSaint,
      'santa' => l.roleSaintFem,
      'liturgia' => l.roleLiturgy,
      'documento-patristico' => l.roleDocPatristic,
      'documento-medieval' => l.roleDocMedieval,
      'documento-historico' => l.roleDocHistorical,
      'documento-geral' => l.roleDocGeneral,
      _ => null,
    };
