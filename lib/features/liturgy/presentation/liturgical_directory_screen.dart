import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/liturgy_providers.dart';
import '../domain/liturgical_day.dart';
import '../domain/liturgical_directory.dart';
import 'liturgy_screen.dart' show colorLabel, rankLabel, seasonLabel;

/// The Liturgical Directory: what today's celebration *is*, and why.
///
/// Opened from the Liturgy screen as a sheet — the app keeps its three tabs;
/// this is a layer over the day, not a new destination.
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
    final entry = ref.watch(directoryForProvider(date));

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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              Text(l10n.liturgicalDirectory.toUpperCase(),
                  style: TextStyle(
                      color: c.accent,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(day.celebration,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: day.color.dotColor(light: light),
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      seasonLabel(l10n, day.season),
                      if (day.week != null) l10n.liturgyWeekOf(day.week!),
                      l10n.liturgicalYear(day.sundayCycle),
                      colorLabel(l10n, day.color),
                    ].join('  ·  '),
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              if (entry.celebration != null)
                _Topic(l10n.directoryCelebration, entry.celebration!),
              _Topic(l10n.directorySeason, entry.season),
              _Topic(l10n.directoryRank, entry.rank),
              _Topic(l10n.directoryColor, entry.color),
              if (entry.practical.isNotEmpty) ...[
                _Label(l10n.directoryPractical, c),
                for (final note in entry.practical)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 10),
                          child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: c.accent, shape: BoxShape.circle)),
                        ),
                        Expanded(
                          child: Text(note,
                              style: TextStyle(
                                  color: c.textSecondary, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              Divider(color: c.divider),
              const SizedBox(height: 8),
              Text(l10n.directorySource,
                  style:
                      TextStyle(color: c.textFaint, fontSize: 12, height: 1.4)),
              const SizedBox(height: 4),
              Text(rankLabel(l10n, day.rank),
                  style: TextStyle(color: c.textFaint, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Topic extends StatelessWidget {
  final String label;
  final DirectoryTopic topic;
  const _Topic(this.label, this.topic);

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, c),
        Text(topic.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final p in topic.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(p,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.6)),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final BtColors c;
  const _Label(this.text, this.c);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: c.textFaint,
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w600)),
      );
}
