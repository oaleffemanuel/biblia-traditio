import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../application/reading_plan_providers.dart';
import '../domain/reading_plan.dart';

/// The single bundled reading plan: one scrollable list of all days, opened at
/// today, each day tappable into the Reader and toggleable as read. No new
/// navigation paradigm — reached from the existing Home "reading plan" card.
class ReadingPlanScreen extends ConsumerStatefulWidget {
  const ReadingPlanScreen({super.key});
  @override
  ConsumerState<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends ConsumerState<ReadingPlanScreen> {
  bool _autostarted = false;

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Text(l10n.planProgress(st.completedCount, plan.days),
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const Spacer(),
              Text('${((st.completedCount / plan.days) * 100).round()}%',
                  style: TextStyle(
                      color: c.accent, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: ScrollablePositionedList.builder(
            itemCount: plan.days,
            initialScrollIndex: (st.currentDay - 1).clamp(0, plan.days - 1),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemBuilder: (context, i) {
              final d = plan.entries[i];
              return _DayCard(
                day: d,
                isToday: d.day == st.currentDay,
                done: st.completed.contains(d.day),
                onToggle: (v) => ref
                    .read(readingPlanControllerProvider)
                    .setDayCompleted(plan.id, d.day, v),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final PlanDay day;
  final bool isToday;
  final bool done;
  final ValueChanged<bool> onToggle;
  const _DayCard(
      {required this.day,
      required this.isToday,
      required this.done,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: isToday ? Border.all(color: c.accent, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Text(l10n.planDay(day.day),
                    style: TextStyle(
                        color: isToday ? c.accent : c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (isToday) ...[
                  const SizedBox(width: 8),
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
                ],
                const Spacer(),
                Checkbox(
                  value: done,
                  onChanged: (v) => onToggle(v ?? false),
                  activeColor: c.accent,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          for (final r in day.readings)
            InkWell(
              // `go`, not `push`: opening a reading crosses from this top-level
              // route into the Bible shell branch. Pushing would duplicate the
              // branch's page key (NavigatorState._debugCheckDuplicatedPageKeys)
              // and fail to navigate; go activates the Bible tab at the verse.
              onTap: r.targets.isEmpty
                  ? null
                  : () => context.go(
                      '/bible/${r.targets.first.bookId}/${r.targets.first.chapter}?src=plan'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 18, color: c.textFaint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.ref,
                          style:
                              TextStyle(color: c.textPrimary, fontSize: 14)),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: c.textFaint),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
