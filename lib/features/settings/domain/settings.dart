import 'package:flutter/material.dart';

import 'commentary_prefs.dart';

export 'commentary_prefs.dart';

/// Every UI language the app is built to carry.
///
/// [values] is the roadmap; [implemented] is what actually ships. Only
/// [implemented] is offered in onboarding and Settings **and** handed to
/// `MaterialApp.supportedLocales` — the second half matters: without it, merely
/// dropping `app_es.arb` into `lib/l10n/` would put a Spanish phone into a
/// half-translated UI without anyone choosing it.
///
/// To activate a language: translate its ARB, run `flutter gen-l10n`, add it to
/// [implemented], and add its assertions to `test/i18n_test.dart`. Nothing else
/// in the app needs to change. See `docs/localization.md`.
enum AppLanguage {
  pt('pt', 'Português'),
  en('en', 'English'),
  it('it', 'Italiano'),
  es('es', 'Español'),
  fr('fr', 'Français'),
  la('la', 'Latina');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);

  Locale get locale => Locale(code);

  /// UI languages actually translated and selectable today.
  static const List<AppLanguage> implemented = [pt, en];

  /// Built but not yet translated — visible on the roadmap, never to a user.
  static List<AppLanguage> get planned =>
      values.where((l) => !implemented.contains(l)).toList();

  /// The locales the app advertises to the platform. Deliberately derived from
  /// [implemented] rather than from the generated `AppL10n.supportedLocales`,
  /// which grows the moment an ARB file appears.
  static List<Locale> get supportedLocales =>
      implemented.map((l) => l.locale).toList();

  static AppLanguage fromCode(String? c) =>
      values.firstWhere((l) => l.code == c, orElse: () => pt);
}

/// How Parallel Reading arranges the two translation columns. [auto] picks
/// side-by-side on wide layouts (tablets) and stacked on phones.
enum ParallelLayout { auto, stacked, sideBySide }

/// The reader's preferred register, asked once in onboarding. It only ever
/// *suggests* a primary translation — every installed translation stays
/// selectable in Settings.
enum TranslationStyle {
  academic('academic'),
  simple('simple'),
  balanced('balanced'),
  liturgical('liturgical'),
  unset('');

  final String key;
  const TranslationStyle(this.key);

  static const List<TranslationStyle> choices = [
    academic, simple, balanced, liturgical
  ];

  static TranslationStyle fromKey(String? k) =>
      values.firstWhere((s) => s.key == k, orElse: () => unset);
}

/// The original-language column the reader asked for in onboarding. Options are
/// offered only when a matching translation is actually installed — the app
/// never advertises a text it doesn't ship.
enum ParallelPreference {
  none('none'),
  latin('la'),
  greek('grc'),
  hebrew('he');

  /// The BCP-47-ish language code a translation must carry to satisfy this
  /// preference. Empty for [none].
  final String langCode;
  const ParallelPreference(this.langCode);

  static ParallelPreference fromKey(String? k) =>
      values.firstWhere((p) => p.langCode == k, orElse: () => none);
}

@immutable
class Settings {
  final bool onboardingCompleted;
  final String displayName;
  final AppLanguage language;
  final String primaryTranslationId;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool wantsReadingPlan;
  final bool parallelReadingEnabled;
  final String secondaryTranslationId;
  final ParallelLayout parallelLayout;
  final TranslationStyle translationStyle;
  final ParallelPreference parallelPreference;
  final CommentaryPrefs commentaryPrefs;

  const Settings({
    this.onboardingCompleted = false,
    this.displayName = '',
    this.language = AppLanguage.pt,
    this.primaryTranslationId = 'pt_matos_soares',
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = false,
    this.wantsReadingPlan = false,
    this.parallelReadingEnabled = false,
    this.secondaryTranslationId = '',
    this.parallelLayout = ParallelLayout.auto,
    this.translationStyle = TranslationStyle.unset,
    this.parallelPreference = ParallelPreference.none,
    this.commentaryPrefs = CommentaryPrefs.defaults,
  });

  factory Settings.fromMap(Map<String, String> m) => Settings(
        onboardingCompleted: m['onboardingCompleted'] == 'true',
        displayName: m['displayName'] ?? '',
        language: AppLanguage.fromCode(m['language']),
        primaryTranslationId: m['primaryTranslationId'] ?? 'pt_matos_soares',
        themeMode: switch (m['themeMode']) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system, // default + unknown → follow the OS
        },
        notificationsEnabled: m['notificationsEnabled'] == 'true',
        wantsReadingPlan: m['wantsReadingPlan'] == 'true',
        parallelReadingEnabled: m['parallelReadingEnabled'] == 'true',
        secondaryTranslationId: m['secondaryTranslationId'] ?? '',
        parallelLayout: switch (m['parallelLayout']) {
          'stacked' => ParallelLayout.stacked,
          'sideBySide' => ParallelLayout.sideBySide,
          _ => ParallelLayout.auto,
        },
        translationStyle: TranslationStyle.fromKey(m['translationStyle']),
        parallelPreference: ParallelPreference.fromKey(m['parallelPreference']),
        commentaryPrefs: CommentaryPrefs.fromMap(m),
      );

  static String themeModeKey(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      };

  static String parallelLayoutKey(ParallelLayout l) => switch (l) {
        ParallelLayout.auto => 'auto',
        ParallelLayout.stacked => 'stacked',
        ParallelLayout.sideBySide => 'sideBySide',
      };
}
