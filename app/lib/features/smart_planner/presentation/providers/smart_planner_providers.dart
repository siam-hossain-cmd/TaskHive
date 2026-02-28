import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../data/smart_planner_engine.dart';
import '../../domain/models/planner_models.dart';

/// The best task to work on right now
final bestTaskNowProvider = Provider<ScoredTask?>((ref) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) => SmartPlannerEngine.getBestTaskNow(tasks),
    loading: () => null,
    error: (_, _) => null,
  );
});

/// All tasks scored and ranked
final rankedTasksProvider = Provider<List<ScoredTask>>((ref) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) => SmartPlannerEngine.scoreAndRankTasks(tasks),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Today's optimized schedule
final todayScheduleProvider = Provider<List<ScheduleSlot>>((ref) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) => SmartPlannerEngine.generateTodaySchedule(tasks),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Active risk alerts
final riskAlertsProvider = Provider<List<RiskAlert>>((ref) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) => SmartPlannerEngine.generateRiskAlerts(tasks),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Weekly workload distribution
final weeklyWorkloadProvider = Provider<List<WorkloadSummary>>((ref) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) => SmartPlannerEngine.getWeeklyWorkload(tasks),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Weekly statistics for analytics screen
final weeklyStatsProvider = Provider<WeeklyStats?>((ref) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) =>
        tasks.isEmpty ? null : SmartPlannerEngine.computeWeeklyStats(tasks),
    loading: () => null,
    error: (_, _) => null,
  );
});
