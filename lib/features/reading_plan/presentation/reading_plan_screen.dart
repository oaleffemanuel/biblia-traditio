import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../bible/application/bible_providers.dart';
import '../../bible/domain/entities.dart';
import '../application/reading_plan_providers.dart';
import '../domain/reading_plan.dart';

/// The bundled reading plan, laid out like the Liturgy tab: a horizontal day
/// strip on top, the day's information and progress under it, then the day's
/// readings as collapsed reference cards. Opening a card renders only the
/// passage the plan assigns — never the surrounding chapter — so the screen
/// stays a schedule rather than a wall of Scripture.
class ReadingPlanScreen extends ConsumerStatefulWidget {
  const ReadingPlanScreen({super.key});
  @override
  ConsumerState<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends ConsumerState<ReadingPlanScreen> {
  bool _autostarted = false;

  /// The day being viewed. Null until the plan loads, then pinned to today's
  /// day so the screen opens where the reader actually is.
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final planAsync = ref.watch(readingPlanProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingPlan)),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.readingPlan)),
        data: _buildPlan,
      ),
    );
  }

  Widget _buildPlan(ReadingPlan plan) {
    final c = context.bt;
    final l10n = context.l10n;
    final key = (planId: plan.id, totalDays: plan.days);
    final st = ref.watch(planStateProvider(key));

    // Day 1 = first time the plan is opened. Done once, after the frame.
    if (!st.started && !_autostarted) {
      _autostarted = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(readingPlanControllerProvider).startIfNeeded(plan.id));
    }

    final day = (_selected ?? st.currentDay).clamp(1, plan.days);
    final entry = plan.dayAt(day);
    final done = st.completed.contains(day);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _DayStrip(
          selected: day,
          totalDays: plan.days,
          today: st.currentDay,
          completed: st.completed,
          onSelect: (d) => setState(() => _selected = d),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DayCard(
            day: day,
            isToday: day == st.currentDay,
            done: done,
            completedCount: st.completedCount,
            totalDays: plan.days,
            onToggle: (v) => ref
                .read(readingPlanControllerProvider)
                .setDayCompleted(plan.id, day, v),
          ),
        ),
        const SizedBox(height: 16),
        if (entry.readings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(l10n.readingTextUnavailable,
                style: TextStyle(color: c.textFaint)),
          )
        else
          _ReadingsSection(key: ValueKey(day), readings: entry.readings),
      ],
    );
  }
}

/// The horizontal day selector — the plan's counterpart to Liturgy's date
/// strip. A day carries a dot when it has been read.
class _DayStrip extends StatefulWidget {
  final int selected;
  final int totalDays;
  final int today;
  final Set<int> completed;
  final ValueChanged<int> onSelect;
  const _DayStrip({
    required this.selected,
    required this.totalDays,
    required this.today,
    required this.completed,
    required this.onSelect,
  });

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  static const _itemExtent = 68.0; // width + horizontal margin
  late final _controller =
      ScrollController(initialScrollOffset: _offsetFor(widget.selected));

  double _offsetFor(int day) => ((day - 1) * _itemExtent - 120).clamp(
      0, (widget.totalDays * _itemExtent - 200).clamp(0, double.infinity));

  @override
  void didUpdateWidget(_DayStrip old) {
    super.didUpdateWidget(old);
    // Keep the selected day in view when it changes from outside the strip.
    if (old.selected != widget.selected && _controller.hasClients) {
      _controller.animateTo(_offsetFor(widget.selected),
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(l10n.planDayProgress(widget.selected, widget.totalDays),
              style: TextStyle(color: c.textSecondary)),
        ),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: SizedBox(
          height: 84,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.totalDays,
            itemBuilder: (_, i) {
              final d = i + 1;
              final on = d == widget.selected;
              final read = widget.completed.contains(d);
              return Semantics(
                button: true,
                selected: on,
                child: GestureDetector(
                onTap: () => widget.onSelect(d),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: on ? c.textPrimary : c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: d == widget.today && !on
                        ? Border.all(color: c.accent, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Dia 5" / "Day 5" minus its number: the strip shows the
                      // word once and the number large, like Liturgy's dates.
                      Text(
                          l10n
                              .planDay(d)
                              .replaceAll(RegExp(r'[\d\s]+$'), ''),
                          style: TextStyle(
                              color: on ? c.background : c.textSecondary,
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$d',
                          style: TextStyle(
                              color: on ? c.background : c.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: read
                                ? c.accent
                                : (on ? c.background : c.surfaceHigh)
                                    .withValues(alpha: 0.5),
                            shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ),
        ),
      ],
    );
  }
}

/// The day's own card: which day it is, whether it's today, overall progress,
/// and the "read" toggle — Liturgy's celebration card, in plan terms.
class _DayCard extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool done;
  final int completedCount;
  final int totalDays;
  final ValueChanged<bool> onToggle;
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.done,
    required this.completedCount,
    required this.totalDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    final percent = ((completedCount / totalDays) * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(l10n.planDay(day),
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            if (isToday)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(l10n.planToday,
                    style: TextStyle(
                        color: c.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            Checkbox(
              value: done,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: c.accent,
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(l10n.planProgress(completedCount, totalDays),
                    style: TextStyle(color: c.textSecondary)),
              ),
              Text('$percent%',
                  style: TextStyle(
                      color: c.accent, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalDays == 0 ? 0 : completedCount / totalDays,
              minHeight: 4,
              backgroundColor: c.surfaceHigh,
              color: c.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// The day's readings as collapsed cards, mirroring the Liturgy readings.
class _ReadingsSection extends StatefulWidget {
  final List<PlanReading> readings;
  const _ReadingsSection({super.key, required this.readings});
  @override
  State<_ReadingsSection> createState() => _ReadingsSectionState();
}

class _ReadingsSectionState extends State<_ReadingsSection> {
  // Collapsed by default: clean reference cards, and no Scripture resolved
  // until the reader opens one.
  final _expanded = <int>{};

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
                onToggle: () => setState(() => _expanded.contains(i)
                    ? _expanded.remove(i)
                    : _expanded.add(i)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends ConsumerWidget {
  final PlanReading reading;
  final bool expanded;
  final VoidCallback onToggle;
  const _ReadingCard(
      {required this.reading, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final l10n = context.l10n;
    final label = switch (reading.section) {
      PlanSection.book => l10n.planSectionBook,
      PlanSection.wisdom => l10n.planSectionWisdom,
    };
    final first = reading.targets.isEmpty ? null : reading.targets.first;

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
                        Text(label.toUpperCase(),
                            style: TextStyle(
                                color: c.accent,
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(reading.ref,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                  if (first != null)
                    IconButton(
                      icon: Icon(Icons.menu_book_outlined,
                          size: 20, color: c.textSecondary),
                      tooltip: l10n.liturgyOpenInBible,
                      // `go`, not `push`: opening a reading crosses from this
                      // top-level route into the Bible shell branch, and
                      // ?src=plan keeps it out of Home → "Continue reading".
                      onPressed: () => context.go(
                          '/bible/${first.bookId}/${first.chapter}?src=plan'),
                    ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: c.textFaint),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in reading.targets) _PassageText(target: t),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders exactly the verses the plan assigns for one target — the whole
/// chapter when the plan says so, otherwise only the assigned span.
class _PassageText extends ConsumerWidget {
  final PlanTarget target;
  const _PassageText({required this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final content = ref.watch(
        chapterProvider((bookId: target.bookId, chapter: target.chapter)));
    final verses = (content?.verses ?? const <Verse>[])
        .where((v) => target.includes(v.number))
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
                      style: TextStyle(color: c.accent, fontSize: 12)),
                  TextSpan(text: v.text),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
