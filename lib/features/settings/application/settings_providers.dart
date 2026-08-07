import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/settings.dart';

/// Current settings, read from the user DB and refreshed via the revision
/// counter after any write. Defaults apply until the DB opens.
final settingsProvider = Provider<Settings>((ref) {
  ref.watch(userDataRevisionProvider);
  final db = ref.watch(userDbProvider);
  if (db == null) return const Settings();
  return Settings.fromMap(db.allSettings());
});

class SettingsController {
  final Ref _ref;
  SettingsController(this._ref);

  void _set(String key, String value) {
    _ref.read(userDbProvider)?.setSetting(key, value);
    _ref.read(userDataRevisionProvider.notifier).state++;
  }

  void setDisplayName(String v) => _set('displayName', v);
  void setLanguage(AppLanguage l) => _set('language', l.code);
  void setTranslation(String id) => _set('primaryTranslationId', id);
  void setThemeMode(ThemeMode m) => _set('themeMode', Settings.themeModeKey(m));
  void setNotifications(bool v) => _set('notificationsEnabled', '$v');
  void setWantsReadingPlan(bool v) => _set('wantsReadingPlan', '$v');
  void completeOnboarding() => _set('onboardingCompleted', 'true');

  void setParallelReading(bool v) => _set('parallelReadingEnabled', '$v');
  void setSecondaryTranslation(String id) =>
      _set('secondaryTranslationId', id);
  void setParallelLayout(ParallelLayout l) =>
      _set('parallelLayout', Settings.parallelLayoutKey(l));

  void setTranslationStyle(TranslationStyle s) =>
      _set('translationStyle', s.key);
  void setParallelPreference(ParallelPreference p) =>
      _set('parallelPreference', p.langCode);

  /// Commentary display preferences are written as one unit so a partial write
  /// can never leave, say, a century filter on with its classification gone.
  void setCommentaryPrefs(CommentaryPrefs p) {
    final db = _ref.read(userDbProvider);
    db?.setSetting('commentaryClasses', CommentaryPrefs.joinStrings(p.classes));
    db?.setSetting(
        'commentaryCenturies', CommentaryPrefs.joinInts(p.centuries));
    db?.setSetting('commentaryOnlySaints', '${p.onlySaints}');
    _ref.read(userDataRevisionProvider.notifier).state++;
  }

  void resetCommentaryPrefs() => setCommentaryPrefs(CommentaryPrefs.defaults);
}

final settingsControllerProvider =
    Provider((ref) => SettingsController(ref));

/// Translations actually available in the bundled content DB.
final availableTranslationsProvider =
    Provider<List<({String id, String lang, String title})>>((ref) {
  return ref.watch(contentDatabaseProvider)?.listTranslations() ?? const [];
});

/// The translation to actually query: the user's preference if it exists in the
/// DB, otherwise the first available one (e.g. falls back to `vulgata` in a
/// release build that doesn't bundle the dev Portuguese text). Guarantees the
/// reader never queries a translation that isn't present.
final resolvedTranslationIdProvider = Provider<String>((ref) {
  final pref = ref.watch(settingsProvider).primaryTranslationId;
  final available = ref.watch(availableTranslationsProvider);
  if (available.any((t) => t.id == pref)) return pref;
  return available.isNotEmpty ? available.first.id : pref;
});

/// Installed translations eligible to be the Parallel Reading secondary column:
/// everything except the active primary. Empty until a second translation pack
/// is installed (the common case today, where only the Vulgate ships).
final secondaryTranslationCandidatesProvider =
    Provider<List<({String id, String lang, String title})>>((ref) {
  final primary = ref.watch(resolvedTranslationIdProvider);
  return ref
      .watch(availableTranslationsProvider)
      .where((t) => t.id != primary)
      .toList();
});

/// The translation to render in the secondary column, or `null` when the user
/// hasn't chosen one, it isn't installed, or it collides with the primary.
/// Guarantees Parallel Reading never queries a translation that isn't present.
final resolvedSecondaryTranslationIdProvider = Provider<String?>((ref) {
  final pref = ref.watch(settingsProvider).secondaryTranslationId;
  if (pref.isEmpty) return null;
  final candidates = ref.watch(secondaryTranslationCandidatesProvider);
  return candidates.any((t) => t.id == pref) ? pref : null;
});

/// The reader's commentary display preferences.
final commentaryPrefsProvider = Provider<CommentaryPrefs>(
    (ref) => ref.watch(settingsProvider).commentaryPrefs);

/// Centuries actually represented in the installed patristics pack, so the
/// filter chips never offer one that would return nothing. Empty when the pack
/// isn't installed.
final commentaryCenturiesProvider = Provider<List<int>>(
    (ref) => ref.watch(contentDatabaseProvider)?.commentaryCenturies() ?? const []);

/// Original-language options that are genuinely available: a [ParallelPreference]
/// is listed only when an installed translation carries its language code.
/// Greek and Hebrew therefore appear in onboarding exactly when their text
/// ships — never as a promise.
final availableParallelPreferencesProvider =
    Provider<List<ParallelPreference>>((ref) {
  final installed = ref.watch(availableTranslationsProvider);
  return [
    ParallelPreference.none,
    for (final p in [
      ParallelPreference.latin,
      ParallelPreference.greek,
      ParallelPreference.hebrew,
    ])
      if (installed.any((t) => _langMatches(t.lang, p))) p,
  ];
});

bool _langMatches(String lang, ParallelPreference p) => switch (p) {
      ParallelPreference.latin => lang == 'la',
      ParallelPreference.greek => lang == 'grc' || lang == 'el',
      ParallelPreference.hebrew => lang == 'he' || lang == 'hbo',
      ParallelPreference.none => false,
    };

/// Turns the onboarding style answer into a *suggestion* — the first of the
/// preferred editions that is actually installed. It only preselects the next
/// step's translation, which the reader then sees and confirms; the app's own
/// default (Padre Matos Soares) is never silently replaced, and no installed
/// translation is hidden.
///
/// The orderings reflect what each edition is: Matos Soares is the annotated
/// Catholic Portuguese translation, the internal Portuguese text is the plainer
/// reading, and the Clementine Vulgate is the Church's liturgical Latin.
String? suggestedTranslationId(TranslationStyle style,
    List<({String id, String lang, String title})> installed) {
  const preference = {
    TranslationStyle.academic: ['pt_matos_soares', 'vulgata', 'pt_beta'],
    TranslationStyle.simple: ['pt_beta', 'pt_matos_soares', 'vulgata'],
    TranslationStyle.balanced: ['pt_matos_soares', 'pt_beta', 'vulgata'],
    TranslationStyle.liturgical: ['vulgata', 'pt_matos_soares', 'pt_beta'],
  };
  for (final id in preference[style] ?? const <String>[]) {
    if (installed.any((t) => t.id == id)) return id;
  }
  return null;
}

/// The installed translation that satisfies [p], or null. Used to turn the
/// onboarding answer into a concrete secondary column.
({String id, String lang, String title})? translationForParallel(
    List<({String id, String lang, String title})> installed,
    ParallelPreference p) {
  for (final t in installed) {
    if (_langMatches(t.lang, p)) return t;
  }
  return null;
}
