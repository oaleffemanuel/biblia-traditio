import 'package:flutter/material.dart';

/// UI languages. `values` keeps codes the parser may encounter; [implemented]
/// is the subset with real ARB/localization files and is the ONLY list exposed
/// in onboarding/Settings. Add a language to [implemented] once its ARB ships
/// (see docs/localization.md).
enum AppLanguage {
  pt('pt', 'Português'),
  en('en', 'English'),
  es('es', 'Español'),
  it('it', 'Italiano'),
  la('la', 'Latina');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);

  /// UI languages actually translated and selectable today.
  static const List<AppLanguage> implemented = [pt, en];

  static AppLanguage fromCode(String? c) =>
      values.firstWhere((l) => l.code == c, orElse: () => pt);
}

/// How Parallel Reading arranges the two translation columns. [auto] picks
/// side-by-side on wide layouts (tablets) and stacked on phones.
enum ParallelLayout { auto, stacked, sideBySide }

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
