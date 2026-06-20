import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../../bible/domain/entities.dart';
import '../application/liturgy_providers.dart';
import '../domain/lectionary.dart';
import '../domain/liturgical_day.dart';

const _monthsPt = [
  '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];
const _weekdaysShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String seasonLabel(AppL10n l, LiturgicalSeason s) => switch (s) {
      LiturgicalSeason.advent => l.seasonAdvent,
      LiturgicalSeason.christmas => l.seasonChristmas,
      LiturgicalSeason.ordinary => l.seasonOrdinary,
      LiturgicalSeason.lent => l.seasonLent,
      LiturgicalSeason.triduum => l.seasonTriduum,
      LiturgicalSeason.easter => l.seasonEaster,
    };

String slotLabel(AppL10n l, ReadingSlot s) => switch (s) {
      ReadingSlot.first => l.readingFirst,
      ReadingSlot.psalm => l.readingPsalm,
      ReadingSlot.second => l.readingSecond,
      ReadingSlot.gospel => l.readingGospel,
    };

class LiturgyScreen extends ConsumerStatefulWidget {
  const LiturgyScreen({super.key});
  @override
  ConsumerState<LiturgyScreen> createState() => _LiturgyScreenState();
}

class _LiturgyScreenState extends ConsumerState<LiturgyScreen> {
  late DateTime _selected = _today();

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final light = Theme.of(context).brightness == Brightness.light;
    final day = ref.watch(liturgicalDayProvider(_selected));
    final readings = ref.watch(readingsForProvider(_selected));
    final strip =
        List.generate(15, (i) => _selected.add(Duration(days: i - 4)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.liturgyTitle,
                      style: Theme.of(context).textTheme.displaySmall),
                  IconButton(
                    icon: Icon(Icons.calendar_today_outlined,
                        color: c.textSecondary),
                    onPressed: _openCalendar,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('${_monthsPt[_selected.month]} ${_selected.year}',
                  style: TextStyle(color: c.textSecondary)),
            ),
            SizedBox(
              height: 84,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: strip.length,
                itemBuilder: (_, i) {
                  final d = strip[i];
                  final on = d == _selected;
                  final dayColor = ref.watch(liturgicalDayProvider(d)).color;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = d),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: on ? c.textPrimary : c.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_weekdaysShort[(d.weekday - 1) % 7],
                              style: TextStyle(
                                  color: on ? c.background : c.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${d.day}',
                              style: TextStyle(
                                  color: on ? c.background : c.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: dayColor.dotColor(light: light),
                                  shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CelebrationCard(day: day),
            ),
            const SizedBox(height: 16),
            // Readings render inline (resolved from the app's own Bible text);
            // null → the day isn't in the dataset, show the graceful notice.
            if (readings != null)
              _ReadingsSection(readings: readings)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _LectionaryNotice(c),
              ),
          ],
        ),
      ),
    );
  }

  void _openCalendar() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bt.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CalendarModal(initial: _selected),
    );
    if (picked != null) setState(() => _selected = picked);
  }
}

class _CelebrationCard extends StatelessWidget {
  final LiturgicalDay day;
  const _CelebrationCard({required this.day});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final light = Theme.of(context).brightness == Brightness.light;
    final rank = switch (day.rank) {
      LiturgicalRank.solemnity => l10n.rankSolemnity,
      LiturgicalRank.feast => l10n.rankFeast,
      LiturgicalRank.memorial => l10n.rankMemorial,
      LiturgicalRank.weekday => '',
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: day.color.dotColor(light: light),
                    shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(day.celebration,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            [
              seasonLabel(l10n, day.season),
              l10n.liturgicalYear(day.sundayCycle),
              if (rank.isNotEmpty) rank,
            ].join('  ·  '),
            style: TextStyle(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The day's readings as inline expandable cards. The first is expanded by
/// default; the rest open on tap. Reading text is resolved at runtime from the
/// app's own Bible (primary translation) — the dataset stores references only.
class _ReadingsSection extends StatefulWidget {
  final List<Reading> readings;
  const _ReadingsSection({required this.readings});
  @override
  State<_ReadingsSection> createState() => _ReadingsSectionState();
}

class _ReadingsSectionState extends State<_ReadingsSection> {
  final _expanded = {0}; // first reading open by default

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          for (var i = 0; i < widget.readings.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReadingCard(
                reading: widget.readings[i],
                expanded: _expanded.contains(i),
                onToggle: () => setState(() =>
                    _expanded.contains(i) ? _expanded.remove(i) : _expanded.add(i)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends ConsumerWidget {
  final Reading reading;
  final bool expanded;
  final VoidCallback onToggle;
  const _ReadingCard(
      {required this.reading, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slotLabel(l10n, reading.slot).toUpperCase(),
                            style: TextStyle(
                                color: c.accent,
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(reading.reference,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                  if (reading.canOpen)
                    IconButton(
                      icon: Icon(Icons.menu_book_outlined,
                          size: 20, color: c.textSecondary),
                      tooltip: l10n.liturgyOpenInBible,
                      // Separate context: ?src=liturgy so it never overwrites
                      // Home → "Continue reading".
                      onPressed: () => context
                          .go('/bible/${reading.bookId}/${reading.chapter}?src=liturgy'),
                    ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: c.textFaint),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _ReadingText(reading: reading),
            ),
        ],
      ),
    );
  }
}

/// Resolves the reading's verse span into Bible text (primary translation).
class _ReadingText extends ConsumerWidget {
  final Reading reading;
  const _ReadingText({required this.reading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    if (!reading.canOpen) {
      return Text(context.l10n.readingTextUnavailable,
          style: TextStyle(color: c.textFaint));
    }
    final content = ref.watch(chapterProvider(
        (bookId: reading.bookId!, chapter: reading.chapter!)));
    final start = reading.verseStart ?? 1;
    final end = reading.verseEnd ?? start;
    final verses = (content?.verses ?? const <Verse>[])
        .where((v) => v.number >= start && v.number <= end)
        .toList();
    if (verses.isEmpty) {
      return Text(context.l10n.readingTextUnavailable,
          style: TextStyle(color: c.textFaint));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final v in verses)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(
                      text: '${v.number}  ',
                      style: TextStyle(
                          color: c.accent,
                          fontSize: 12,
                          fontFeatures: const [])),
                  TextSpan(text: v.text),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LectionaryNotice extends StatelessWidget {
  final BtColors c;
  const _LectionaryNotice(this.c);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(Icons.menu_book_outlined, color: c.textFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.lectionaryNotice,
              style: TextStyle(color: c.textSecondary, height: 1.4),
            ),
          ),
        ]),
      );
}

class _CalendarModal extends ConsumerStatefulWidget {
  final DateTime initial;
  const _CalendarModal({required this.initial});
  @override
  ConsumerState<_CalendarModal> createState() => _CalendarModalState();
}

class _CalendarModalState extends ConsumerState<_CalendarModal> {
  late DateTime _month =
      DateTime(widget.initial.year, widget.initial.month, 1);
  late DateTime _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final light = Theme.of(context).brightness == Brightness.light;
    final colors =
        ref.watch(monthColorsProvider((year: _month.year, month: _month.month)));
    final firstWeekday = _month.weekday % 7; // Sun=0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('${_monthsPt[_month.month]} ${_month.year}',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.chevron_left, color: c.textSecondary),
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1, 1)),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: c.textSecondary),
                  onPressed: () => setState(() =>
                      _month = DateTime(_month.year, _month.month + 1, 1)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final w in const ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'])
                  Expanded(
                    child: Center(
                      child: Text(w,
                          style: TextStyle(color: c.textSecondary, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (_, i) {
                if (i < firstWeekday) return const SizedBox.shrink();
                final dayNum = i - firstWeekday + 1;
                final date = DateTime(_month.year, _month.month, dayNum);
                final on = date == DateTime(_picked.year, _picked.month, _picked.day);
                return GestureDetector(
                  onTap: () => setState(() => _picked = date),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: on ? c.textPrimary : Colors.transparent,
                            shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('$dayNum',
                            style: TextStyle(
                                color: on ? c.background : c.textPrimary)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: (colors[dayNum] ?? LiturgicalColor.green)
                                  .dotColor(light: light),
                              shape: BoxShape.circle)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                onPressed: () => Navigator.pop(context, _picked),
                child: Text(context.l10n.actionConfirm,
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
