import 'package:flutter/material.dart';

/// UI languages the app ships (content language follows the chosen translation).
enum AppLanguage {
  pt('pt', 'Português'),
  en('en', 'English'),
  es('es', 'Español'),
  it('it', 'Italiano'),
  la('la', 'Latina');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);

  static AppLanguage fromCode(String? c) =>
      values.firstWhere((l) => l.code == c, orElse: () => pt);
}

/// A selectable Bible translation (mirrors content-DB `translation` rows; the
/// catalogue is static until packs are downloadable).
class TranslationOption {
  final String id;
  final String title;
  final String langCode;
  const TranslationOption(this.id, this.title, this.langCode);

  static const catalogue = [
    TranslationOption('matos1932', 'Matos Soares (1932)', 'pt'),
    TranslationOption('vulgata', 'Vulgata Clementina', 'la'),
    TranslationOption('drb', 'Douay–Rheims (Challoner)', 'en'),
  ];
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

  const Settings({
    this.onboardingCompleted = false,
    this.displayName = '',
    this.language = AppLanguage.pt,
    this.primaryTranslationId = 'matos1932',
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = false,
    this.wantsReadingPlan = false,
  });

  factory Settings.fromMap(Map<String, String> m) => Settings(
        onboardingCompleted: m['onboardingCompleted'] == 'true',
        displayName: m['displayName'] ?? '',
        language: AppLanguage.fromCode(m['language']),
        primaryTranslationId: m['primaryTranslationId'] ?? 'matos1932',
        themeMode: switch (m['themeMode']) {
          'light' => ThemeMode.light,
          'system' => ThemeMode.system,
          _ => ThemeMode.dark,
        },
        notificationsEnabled: m['notificationsEnabled'] == 'true',
        wantsReadingPlan: m['wantsReadingPlan'] == 'true',
      );

  static String themeModeKey(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      };
}
