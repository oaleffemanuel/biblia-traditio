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
