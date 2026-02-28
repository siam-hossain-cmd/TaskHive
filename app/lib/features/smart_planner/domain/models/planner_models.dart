import '../../../tasks/domain/models/task_model.dart';

/// A scored task with computed priority score and reason
class ScoredTask {
  final TaskModel task;
  final double score;
  final String reason;
  final Map<String, double> breakdown;

  ScoredTask({
    required this.task,
    required this.score,
    required this.reason,
    required this.breakdown,
  });
}

/// A time slot in the daily schedule
class ScheduleSlot {
  final DateTime startTime;
  final DateTime endTime;
  final TaskModel task;
  final String label; // e.g. "Morning Focus", "Afternoon Work"
  final double score;

  ScheduleSlot({
    required this.startTime,
    required this.endTime,
    required this.task,
    required this.label,
    required this.score,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;
}

/// Risk alert for workload issues
enum RiskLevel { critical, warning, info }

class RiskAlert {
  final RiskLevel level;
  final String title;
  final String message;
  final String suggestion;
  final List<TaskModel> relatedTasks;
  final IconType iconType;

  RiskAlert({
    required this.level,
    required this.title,
    required this.message,
    required this.suggestion,
    this.relatedTasks = const [],
    this.iconType = IconType.warning,
  });
}

enum IconType { warning, overload, deadline, streak, tip }

/// Daily workload summary
class WorkloadSummary {
  final DateTime date;
  final int taskCount;
  final int totalMinutes;
  final double loadPercentage; // 0-1, above 0.8 = overloaded
  final List<TaskModel> tasks;

  WorkloadSummary({
    required this.date,
    required this.taskCount,
    required this.totalMinutes,
    required this.loadPercentage,
    required this.tasks,
  });

  bool get isOverloaded => loadPercentage > 0.8;
  bool get isHeavy => loadPercentage > 0.6 && loadPercentage <= 0.8;
  bool get isLight => loadPercentage <= 0.3;
}

/// Weekly analytics data
class WeeklyStats {
  final int totalTasks;
  final int completedTasks;
  final int missedDeadlines;
  final int currentStreak;
  final int bestStreak;
  final double avgCompletionRate;
  final Map<String, int> tasksByDay; // Mon: 3, Tue: 5...
  final Map<String, int> completedByDay;
  final String mostProductiveDay;
  final String mostProductiveHour;
  final Map<String, double> subjectMastery; // subject → completion %

  WeeklyStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.missedDeadlines,
    required this.currentStreak,
    required this.bestStreak,
    required this.avgCompletionRate,
    required this.tasksByDay,
    required this.completedByDay,
    required this.mostProductiveDay,
    required this.mostProductiveHour,
    required this.subjectMastery,
  });
}
