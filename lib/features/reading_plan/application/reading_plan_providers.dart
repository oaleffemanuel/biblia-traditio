import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/reading_plan.dart';

/// The bundled plan, loaded once from its asset.
final readingPlanProvider =
    FutureProvider<ReadingPlan>((ref) => ReadingPlan.loadDefault());

int _todayEpochDay() {
  final n = DateTime.now();
  return DateTime.utc(n.year, n.month, n.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// Live state of a plan for the UI: whether it has been started, which day is
/// "today" (1-based, clamped to the plan length), and the set of completed days.
class PlanState {
  final bool started;
  final int currentDay;
  final Set<int> completed;
  final int totalDays;
  const PlanState({
    required this.started,
    required this.currentDay,
    required this.completed,
    required this.totalDays,
  });

  int get completedCount => completed.length;
}

/// Reads plan state for a given (planId, totalDays). Re-queries on every
/// user-data write via the shared revision.
final planStateProvider =
    Provider.family<PlanState, ({String planId, int totalDays})>((ref, key) {
  ref.watch(userDataRevisionProvider);
  final db = ref.watch(userDbProvider);
  if (db == null) {
    return PlanState(
        started: false, currentDay: 1, completed: const {}, totalDays: key.totalDays);
  }
  final start = db.readingPlanStart(key.planId);
  final day = start == null
      ? 1
      : (_todayEpochDay() - start + 1).clamp(1, key.totalDays);
  return PlanState(
    started: start != null,
    currentDay: day,
    completed: db.completedPlanDays(key.planId),
    totalDays: key.totalDays,
  );
});

/// Writes plan state, then bumps the revision so reads refresh.
class ReadingPlanController {
  final Ref _ref;
  ReadingPlanController(this._ref);

  void _bump() => _ref.read(userDataRevisionProvider.notifier).state++;

  /// Sets day 1 = today if the plan has not been started yet.
  void startIfNeeded(String planId) {
    final db = _ref.read(userDbProvider);
    if (db == null) return;
    if (db.readingPlanStart(planId) == null) {
      db.setReadingPlanStart(planId, _todayEpochDay());
      _bump();
    }
  }

  void setDayCompleted(String planId, int day, bool completed) {
    _ref.read(userDbProvider)?.setPlanDayCompleted(planId, day, completed);
    _bump();
  }
}

final readingPlanControllerProvider =
    Provider((ref) => ReadingPlanController(ref));
