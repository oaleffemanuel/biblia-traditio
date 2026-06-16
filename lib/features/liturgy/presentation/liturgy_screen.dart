import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
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
                                  color: dayColor.color,
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
            // Until the Lectionary pack ships, `readings` is always null — show
            // only the notice, never chips that look tappable but do nothing.
            if (readings != null) ...[
              _ReadingChips(readings: readings),
              const SizedBox(height: 20),
            ] else
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
                    color: day.color.color, shape: BoxShape.circle)),
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

class _ReadingChips extends StatelessWidget {
  final List<Reading>? readings;
  const _ReadingChips({required this.readings});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final slot in ReadingSlot.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(slotLabel(context.l10n, slot)),
                backgroundColor: c.surfaceHigh,
                side: BorderSide.none,
                labelStyle: TextStyle(color: c.textPrimary),
                onPressed: () {},
              ),
            ),
        ],
      ),
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
                                  .color,
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
