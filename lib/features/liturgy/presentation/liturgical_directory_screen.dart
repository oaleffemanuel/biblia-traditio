import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/liturgy_providers.dart';
import '../domain/liturgical_day.dart';
import '../domain/liturgical_directory.dart';
import 'liturgy_screen.dart' show colorLabel, rankLabel, seasonLabel;

/// Localised labels for the directory, built from the active locale.
DirectoryLabels directoryLabels(AppL10n l) => DirectoryLabels(
      season: l.directoryCardSeason,
      celebration: l.directoryCardCelebration,
      color: l.directoryCardColor,
      week: l.directoryCardWeek,
      year: l.directoryCardYear,
      cycle: l.directoryCardCycle,
      preface: l.directoryCardPreface,
      observances: l.directoryCardObservances,
      ephemerides: l.directoryCardEphemerides,
      seasonName: (s) => seasonLabel(l, s),
      colorName: (c) => colorLabel(l, c),
      rankName: (r) => rankLabel(l, r),
      weekOf: l.liturgyWeekOf,
      yearOf: l.liturgicalYear,
      cycleOf: l.liturgicalCycle,
    );

/// The Liturgical Directory: what today's celebration is, answered card by
/// card. Opened from the Liturgy screen as a sheet — the app keeps its three
/// tabs; this is a layer over the day, not a new destination.
void showLiturgicalDirectory(BuildContext context, DateTime date) {
  final c = context.bt;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (ctx, controller) =>
          _DirectoryBody(date: date, controller: controller),
    ),
  );
}

class _DirectoryBody extends ConsumerWidget {
  final DateTime date;
  final ScrollController controller;
  const _DirectoryBody({required this.date, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final light = Theme.of(context).brightness == Brightness.light;
    final day = ref.watch(liturgicalDayProvider(date));
    final entry =
        const LiturgicalDirectory().explain(day, directoryLabels(l10n));

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: c.divider, borderRadius: BorderRadius.circular(2))),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: day.color.dotColor(light: light),
                        shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.liturgicalDirectory,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
              ]),
              const SizedBox(height: 28),
              for (var i = 0; i < entry.cards.length; i++) ...[
                if (i > 0) _Rule(c),
                _Field(field: entry.cards[i]),
              ],
              const SizedBox(height: 24),
              Text(l10n.directorySource,
                  style:
                      TextStyle(color: c.textFaint, fontSize: 11.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A hairline between fields — the only separator the page uses. Cards were
/// louder than the content they held.
class _Rule extends StatelessWidget {
  final BtColors c;
  const _Rule(this.c);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Container(height: 1, color: c.divider.withValues(alpha: 0.6)),
      );
}

/// One field: a quiet label, the answer set in the serif, and at most a line
/// of explanation. No container — whitespace and the rule do the separating.
class _Field extends StatelessWidget {
  final DirectoryCard field;
  const _Field({required this.field});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label.toUpperCase(),
            style: TextStyle(
                color: c.textFaint,
                fontSize: 10.5,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(field.value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(height: 1.3)),
        if (field.note != null) ...[
          const SizedBox(height: 8),
          Text(field.note!,
              style: TextStyle(
                  color: c.textSecondary, fontSize: 13.5, height: 1.5)),
        ],
      ],
    );
  }
}
