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
              const SizedBox(height: 20),
              for (final card in entry.cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Card(card: card),
                ),
              const SizedBox(height: 4),
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

class _Card extends StatelessWidget {
  final DirectoryCard card;
  const _Card({required this.card});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c.surfaceHigh.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.label.toUpperCase(),
              style: TextStyle(
                  color: c.textFaint,
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(card.value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600, height: 1.35)),
          if (card.note != null) ...[
            const SizedBox(height: 6),
            Text(card.note!,
                style: TextStyle(
                    color: c.textSecondary, fontSize: 13, height: 1.45)),
          ],
        ],
      ),
    );
  }
}
