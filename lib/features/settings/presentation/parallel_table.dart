import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/settings.dart';

/// The parallel-reading language as a small two-column table — one language
/// per Testament, as a printed polyglot sets it out:
///
/// | Antigo Testamento | Novo Testamento |
/// | Hebraico          | Grego           |
/// | Grego             | Latim           |
/// | Latim             |                 |
///
/// Each column is a single choice; tapping the chosen cell again clears it
/// (no companion text for that Testament). Languages whose text isn't
/// installed for that Testament are shown but cannot be picked.
class ParallelTestamentTable extends StatelessWidget {
  final ParallelPreference ot;
  final ParallelPreference nt;
  final Set<ParallelPreference> availableOt;
  final Set<ParallelPreference> availableNt;
  final void Function(ParallelPreference ot, ParallelPreference nt) onChanged;

  const ParallelTestamentTable({
    super.key,
    required this.ot,
    required this.nt,
    required this.availableOt,
    required this.availableNt,
    required this.onChanged,
  });

  static const otOptions = [
    ParallelPreference.hebrew,
    ParallelPreference.greek,
    ParallelPreference.latin,
  ];
  static const ntOptions = [ParallelPreference.greek, ParallelPreference.latin];

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    String label(ParallelPreference p) => switch (p) {
      ParallelPreference.hebrew => l10n.langHebrew,
      ParallelPreference.greek => l10n.parallelGreek,
      ParallelPreference.latin => l10n.parallelLatin,
      ParallelPreference.none => l10n.parallelNone,
    };
    final border = BorderSide(color: c.divider);

    Widget column({
      required String key,
      required String title,
      required List<ParallelPreference> options,
      required Set<ParallelPreference> available,
      required ParallelPreference selected,
      required void Function(ParallelPreference) onPick,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: border)),
            child: Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          for (final p in options)
            _Cell(
              key: ValueKey('parallel-$key-${p.langCode}'),
              label: label(p),
              selected: selected == p,
              enabled: available.contains(p),
              onTap: () => onPick(selected == p ? ParallelPreference.none : p),
            ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.fromBorderSide(border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: column(
                key: 'ot',
                title: l10n.oldTestament,
                options: otOptions,
                available: availableOt,
                selected: ot,
                onPick: (p) => onChanged(p, nt),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: c.divider),
            Expanded(
              child: column(
                key: 'nt',
                title: l10n.newTestament,
                options: ntOptions,
                available: availableNt,
                selected: nt,
                onPick: (p) => onChanged(ot, p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _Cell({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          color: selected ? c.accentSoft : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: !enabled
                        ? c.textFaint.withValues(alpha: 0.5)
                        : selected
                        ? c.accent
                        : c.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 18, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}
