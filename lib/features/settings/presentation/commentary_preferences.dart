import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/domain/entities.dart';
import '../application/settings_providers.dart';

/// Which commentators the reader wants to meet when a verse is opened. Every
/// choice writes through immediately, so the preferences are already in force
/// the next time a commentary panel opens — there is nothing to "apply".
void showCommentaryPreferences(BuildContext context) {
  final c = context.bt;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _CommentaryPreferencesSheet(),
  );
}

/// The classification filters, in the order the corpus reads chronologically.
const _classSlugs = ['patristica', 'escolastica', 'santos'];

class _CommentaryPreferencesSheet extends ConsumerWidget {
  const _CommentaryPreferencesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final prefs = ref.watch(commentaryPrefsProvider);
    final ctrl = ref.read(settingsControllerProvider);
    final centuries = ref.watch(commentaryCenturiesProvider);

    String classLabel(String slug) => switch (slug) {
          'patristica' => l10n.filterFathers,
          'escolastica' => l10n.filterScholastic,
          _ => l10n.filterSaints,
        };

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.divider,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
              child: Text(l10n.commentaryPreferences,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l10n.commentaryPreferencesSubtitle,
                  style: TextStyle(color: c.textSecondary, height: 1.35)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.commentaryOnlySaints),
              subtitle: Text(l10n.commentaryOnlySaintsSubtitle),
              value: prefs.onlySaints,
              onChanged: (v) =>
                  ctrl.setCommentaryPrefs(prefs.copyWith(onlySaints: v)),
            ),
            // The other filters are meaningless while "saints only" is on, so
            // they dim rather than pretending to do something.
            Opacity(
              opacity: prefs.onlySaints ? 0.4 : 1,
              child: IgnorePointer(
                ignoring: prefs.onlySaints,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(c, l10n.commentaryClassification),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _chip(
                            c,
                            label: l10n.filterAll,
                            selected: prefs.classes.isEmpty,
                            onTap: () => ctrl.setCommentaryPrefs(
                                prefs.copyWith(classes: const {})),
                          ),
                          for (final slug in _classSlugs)
                            _chip(
                              c,
                              label: classLabel(slug),
                              selected: prefs.classes.contains(slug),
                              onTap: () => ctrl.setCommentaryPrefs(
                                  prefs.copyWith(
                                      classes: _toggled(prefs.classes, slug))),
                            ),
                        ],
                      ),
                    ),
                    if (centuries.isNotEmpty) ...[
                      _label(c, l10n.commentaryCenturies),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _chip(
                              c,
                              label: l10n.filterAll,
                              selected: prefs.centuries.isEmpty,
                              onTap: () => ctrl.setCommentaryPrefs(
                                  prefs.copyWith(centuries: const {})),
                            ),
                            for (final n in centuries)
                              _chip(
                                c,
                                label: l10n
                                    .century(Commentary.romanNumeral(n)),
                                selected: prefs.centuries.contains(n),
                                onTap: () => ctrl.setCommentaryPrefs(
                                    prefs.copyWith(
                                        centuries:
                                            _toggled(prefs.centuries, n))),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: TextButton.icon(
                onPressed: prefs.isDefault ? null : ctrl.resetCommentaryPrefs,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(l10n.commentaryResetDefaults),
                style: TextButton.styleFrom(foregroundColor: c.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Set<T> _toggled<T>(Set<T> current, T value) =>
      current.contains(value)
          ? ({...current}..remove(value))
          : {...current, value};

  Widget _label(BtColors c, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                color: c.textFaint,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600)),
      );

  Widget _chip(BtColors c,
          {required String label,
          required bool selected,
          required VoidCallback onTap}) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: c.surfaceHigh,
        selectedColor: c.accentSoft,
        side: BorderSide.none,
        labelStyle:
            TextStyle(color: selected ? c.accent : c.textSecondary),
      );
}
