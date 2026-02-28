import 'dart:math';
import '../../tasks/domain/models/task_model.dart';
import '../domain/models/planner_models.dart';

/// Core engine for smart task planning, scoring, and workload detection.
/// All computation is local — no backend calls needed.
class SmartPlannerEngine {
  // ─── Scoring Weights ───────────────────────────────────────────────
  static const double _urgencyWeight = 0.40;
  static const double _priorityWeight = 0.30;
  static const double _effortFitWeight = 0.20;
  static const double _freshnessWeight = 0.10;

  // ─── Workload Thresholds ───────────────────────────────────────────
  static const int _maxDailyMinutes = 480; // 8 hours max productive time
  static const int _deadlineClusterThreshold = 3; // tasks due same day

  // ═══════════════════════════════════════════════════════════════════
  //  TASK SCORING
  // ═══════════════════════════════════════════════════════════════════

  /// Score and rank all active tasks. Returns sorted list (highest first).
  static List<ScoredTask> scoreAndRankTasks(List<TaskModel> tasks) {
    final activeTasks = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    if (activeTasks.isEmpty) return [];

    final scored = activeTasks.map((t) => _scoreTask(t)).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Get the single best task to work on right now.
  static ScoredTask? getBestTaskNow(List<TaskModel> tasks) {
    final ranked = scoreAndRankTasks(tasks);
    return ranked.isEmpty ? null : ranked.first;
  }

  static ScoredTask _scoreTask(TaskModel task) {
    final urgency = _urgencyScore(task);
    final priority = _priorityScore(task);
    final effort = _effortFitScore(task);
    final freshness = _freshnessScore(task);

    final total =
        (urgency * _urgencyWeight) +
        (priority * _priorityWeight) +
        (effort * _effortFitWeight) +
        (freshness * _freshnessWeight);

    final breakdown = {
      'urgency': urgency,
      'priority': priority,
      'effort': effort,
      'freshness': freshness,
    };

    return ScoredTask(
      task: task,
      score: total,
      reason: _generateReason(task, breakdown),
      breakdown: breakdown,
    );
  }

  /// Urgency: 0–100 based on time until deadline
  static double _urgencyScore(TaskModel task) {
    final now = DateTime.now();
    final hoursLeft = task.dueDate.difference(now).inHours;

    if (hoursLeft < 0) return 100; // Overdue = max urgency
    if (hoursLeft < 6) return 95;
    if (hoursLeft < 12) return 85;
    if (hoursLeft < 24) return 75;
    if (hoursLeft < 48) return 60;
    if (hoursLeft < 72) return 45;
    if (hoursLeft < 168) return 30; // Within a week
    return 15;
  }

  /// Priority: 0–100 based on task priority
  static double _priorityScore(TaskModel task) {
    switch (task.priority) {
      case TaskPriority.high:
        return 100;
      case TaskPriority.medium:
        return 60;
      case TaskPriority.low:
        return 25;
    }
  }

  /// Effort fit: considers current time of day and task effort
  static double _effortFitScore(TaskModel task) {
    final hour = DateTime.now().hour;
    final minutes = task.estimatedMinutes;

    // Morning (6-12): best for long, hard tasks
    if (hour >= 6 && hour < 12) {
      if (minutes >= 60) return 90;
      if (minutes >= 30) return 70;
      return 50;
    }
    // Afternoon (12-17): medium tasks
    if (hour >= 12 && hour < 17) {
      if (minutes >= 30 && minutes <= 90) return 85;
      if (minutes < 30) return 70;
      return 55;
    }
    // Evening (17-22): short easy tasks
    if (hour >= 17 && hour < 22) {
      if (minutes <= 30) return 90;
      if (minutes <= 60) return 65;
      return 40;
    }
    // Night (22-6): only very short tasks
    if (minutes <= 15) return 80;
    return 30;
  }

  /// Freshness: newer tasks get a small boost to stay visible
  static double _freshnessScore(TaskModel task) {
    final daysSinceCreated = DateTime.now().difference(task.createdAt).inDays;
    if (daysSinceCreated < 1) return 80;
    if (daysSinceCreated < 3) return 60;
    if (daysSinceCreated < 7) return 40;
    return 20;
  }

  static String _generateReason(TaskModel task, Map<String, double> breakdown) {
    final urgency = breakdown['urgency']!;
    final hoursLeft = task.dueDate.difference(DateTime.now()).inHours;

    if (urgency >= 95) {
      return hoursLeft < 0
          ? '⚠️ Overdue! Complete this immediately'
          : '🔥 Due very soon — ${hoursLeft}h left';
    }
    if (urgency >= 75) {
      return '⏰ Due within 24 hours';
    }
    if (task.priority == TaskPriority.high && urgency >= 45) {
      return '🎯 High priority + approaching deadline';
    }

    final hour = DateTime.now().hour;
    final minutes = task.estimatedMinutes;
    if (hour < 12 && minutes >= 60) {
      return '🧠 Perfect for a morning deep-work session';
    }
    if (hour >= 17 && minutes <= 30) {
      return '⚡ Quick win — knock this out tonight';
    }

    if (task.priority == TaskPriority.high) return '🎯 High priority task';
    if (minutes <= 15) return '⚡ Quick task — easy win!';
    return '📋 Good time to work on this';
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DAILY SCHEDULE GENERATOR
  // ═══════════════════════════════════════════════════════════════════

  /// Generate an optimal schedule for today from active tasks.
  static List<ScheduleSlot> generateTodaySchedule(List<TaskModel> tasks) {
    final ranked = scoreAndRankTasks(tasks);
    if (ranked.isEmpty) return [];

    final now = DateTime.now();
    final slots = <ScheduleSlot>[];
    var currentTime = DateTime(
      now.year,
      now.month,
      now.day,
      max(now.hour + 1, 8),
      0,
    ); // Start from next hour or 8 AM

    // Cap at 10 PM
    final endOfDay = DateTime(now.year, now.month, now.day, 22, 0);

    for (final scored in ranked) {
      if (currentTime.isAfter(endOfDay)) break;

      final duration = scored.task.estimatedMinutes;
      final endTime = currentTime.add(Duration(minutes: duration));

      if (endTime.isAfter(endOfDay)) {
        // Try fitting a partial slot
        final remaining = endOfDay.difference(currentTime).inMinutes;
        if (remaining >= 15) {
          slots.add(
            ScheduleSlot(
              startTime: currentTime,
              endTime: endOfDay,
              task: scored.task,
              label: _getTimeLabel(currentTime.hour),
              score: scored.score,
            ),
          );
        }
        break;
      }

      slots.add(
        ScheduleSlot(
          startTime: currentTime,
          endTime: endTime,
          task: scored.task,
          label: _getTimeLabel(currentTime.hour),
          score: scored.score,
        ),
      );

      // Add 10 min break between tasks
      currentTime = endTime.add(const Duration(minutes: 10));
    }

    return slots;
  }

  static String _getTimeLabel(int hour) {
    if (hour < 12) return 'Morning Focus';
    if (hour < 17) return 'Afternoon Work';
    return 'Evening Session';
  }

  // ═══════════════════════════════════════════════════════════════════
  //  RISK ALERTS & WORKLOAD DETECTION
  // ═══════════════════════════════════════════════════════════════════

  /// Generate risk alerts based on task analysis
  static List<RiskAlert> generateRiskAlerts(List<TaskModel> allTasks) {
    final alerts = <RiskAlert>[];
    final active = allTasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    if (active.isEmpty) return alerts;

    // 1. Overdue tasks
    final overdue = active.where((t) => t.isOverdue).toList();
    if (overdue.isNotEmpty) {
      alerts.add(
        RiskAlert(
          level: RiskLevel.critical,
          title:
              '${overdue.length} Overdue Task${overdue.length > 1 ? 's' : ''}',
          message:
              'You have ${overdue.length} task${overdue.length > 1 ? 's' : ''} past the deadline.',
          suggestion:
              'Focus on completing these first, or reschedule if needed.',
          relatedTasks: overdue,
          iconType: IconType.deadline,
        ),
      );
    }

    // 2. Deadline clusters (3+ tasks due same day)
    final byDay = <String, List<TaskModel>>{};
    for (final t in active) {
      final key = '${t.dueDate.year}-${t.dueDate.month}-${t.dueDate.day}';
      byDay.putIfAbsent(key, () => []).add(t);
    }
    for (final entry in byDay.entries) {
      if (entry.value.length >= _deadlineClusterThreshold) {
        final date = entry.value.first.dueDate;
        final isToday = _isSameDay(date, DateTime.now());
        final isTomorrow = _isSameDay(
          date,
          DateTime.now().add(const Duration(days: 1)),
        );
        final dayLabel = isToday
            ? 'today'
            : isTomorrow
            ? 'tomorrow'
            : '${date.month}/${date.day}';

        alerts.add(
          RiskAlert(
            level: isToday ? RiskLevel.critical : RiskLevel.warning,
            title: '${entry.value.length} Tasks Due $dayLabel',
            message:
                'Heavy deadline cluster — ${entry.value.length} tasks all due on the same day.',
            suggestion:
                'Consider starting earlier or splitting work across days.',
            relatedTasks: entry.value,
            iconType: IconType.overload,
          ),
        );
      }
    }

    // 3. Daily overload (total estimated time exceeds threshold)
    final todayTasks = active.where((t) {
      return _isSameDay(t.dueDate, DateTime.now());
    }).toList();
    final todayMinutes = todayTasks.fold<int>(
      0,
      (sum, t) => sum + t.estimatedMinutes,
    );
    if (todayMinutes > _maxDailyMinutes) {
      alerts.add(
        RiskAlert(
          level: RiskLevel.warning,
          title: 'Today is Overloaded',
          message:
              '${(todayMinutes / 60).toStringAsFixed(1)}h of work planned, but only ${(_maxDailyMinutes / 60).round()}h recommended.',
          suggestion:
              'Move ${((todayMinutes - _maxDailyMinutes) / 60).toStringAsFixed(1)}h of tasks to tomorrow.',
          relatedTasks: todayTasks,
          iconType: IconType.overload,
        ),
      );
    }

    // 4. No-time warning (tasks with 0 estimated time)
    final noEstimate = active.where((t) => t.estimatedMinutes <= 0).toList();
    if (noEstimate.isNotEmpty) {
      alerts.add(
        RiskAlert(
          level: RiskLevel.info,
          title: 'Missing Time Estimates',
          message:
              '${noEstimate.length} task${noEstimate.length > 1 ? 's' : ''} have no time estimate.',
          suggestion: 'Add estimates for more accurate planning.',
          relatedTasks: noEstimate,
          iconType: IconType.tip,
        ),
      );
    }

    // 5. Upcoming week heavy load
    final weekTasks = active.where((t) {
      final diff = t.dueDate.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();
    if (weekTasks.length > 15) {
      alerts.add(
        RiskAlert(
          level: RiskLevel.warning,
          title: 'Heavy Week Ahead',
          message: '${weekTasks.length} tasks due this week.',
          suggestion:
              'Prioritize and consider delegating or postponing lower priority items.',
          relatedTasks: weekTasks,
          iconType: IconType.warning,
        ),
      );
    }

    // Sort by severity
    alerts.sort((a, b) => a.level.index.compareTo(b.level.index));
    return alerts;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WORKLOAD BALANCE DETECTOR
  // ═══════════════════════════════════════════════════════════════════

  /// Generate workload summary for the next 7 days
  static List<WorkloadSummary> getWeeklyWorkload(List<TaskModel> tasks) {
    final active = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();
    final now = DateTime.now();
    final summaries = <WorkloadSummary>[];

    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final dayTasks = active
          .where((t) => _isSameDay(t.dueDate, date))
          .toList();
      final totalMin = dayTasks.fold<int>(
        0,
        (sum, t) => sum + t.estimatedMinutes,
      );

      summaries.add(
        WorkloadSummary(
          date: date,
          taskCount: dayTasks.length,
          totalMinutes: totalMin,
          loadPercentage: (totalMin / _maxDailyMinutes).clamp(0.0, 1.5),
          tasks: dayTasks,
        ),
      );
    }

    return summaries;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ANALYTICS ENGINE
  // ═══════════════════════════════════════════════════════════════════

  /// Compute weekly stats from all tasks
  static WeeklyStats computeWeeklyStats(List<TaskModel> allTasks) {
    final now = DateTime.now();

    final completed = allTasks
        .where((t) => t.status == TaskStatus.completed)
        .toList();
    final missed = allTasks
        .where(
          (t) => t.status != TaskStatus.completed && t.dueDate.isBefore(now),
        )
        .length;

    // Tasks by day of week
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final tasksByDay = <String, int>{};
    final completedByDay = <String, int>{};
    for (final name in dayNames) {
      tasksByDay[name] = 0;
      completedByDay[name] = 0;
    }

    for (final t in allTasks) {
      final dayIndex = (t.dueDate.weekday - 1) % 7;
      tasksByDay[dayNames[dayIndex]] =
          (tasksByDay[dayNames[dayIndex]] ?? 0) + 1;
    }

    for (final t in completed) {
      if (t.completedAt != null) {
        final dayIndex = (t.completedAt!.weekday - 1) % 7;
        completedByDay[dayNames[dayIndex]] =
            (completedByDay[dayNames[dayIndex]] ?? 0) + 1;
      }
    }

    // Most productive day
    var bestDay = 'Mon';
    var bestDayCount = 0;
    completedByDay.forEach((day, count) {
      if (count > bestDayCount) {
        bestDay = day;
        bestDayCount = count;
      }
    });

    // Most productive hour
    final hourCounts = <int, int>{};
    for (final t in completed) {
      if (t.completedAt != null) {
        final hour = t.completedAt!.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }
    var bestHour = 10;
    var bestHourCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > bestHourCount) {
        bestHour = hour;
        bestHourCount = count;
      }
    });
    final hourLabel = bestHour < 12
        ? '${bestHour == 0 ? 12 : bestHour} AM'
        : '${bestHour == 12 ? 12 : bestHour - 12} PM';

    // Subject mastery
    final subjectMastery = <String, double>{};
    final subjectTotal = <String, int>{};
    final subjectCompleted = <String, int>{};
    for (final t in allTasks) {
      if (t.subject.isNotEmpty) {
        subjectTotal[t.subject] = (subjectTotal[t.subject] ?? 0) + 1;
        if (t.status == TaskStatus.completed) {
          subjectCompleted[t.subject] = (subjectCompleted[t.subject] ?? 0) + 1;
        }
      }
    }
    subjectTotal.forEach((subject, total) {
      final done = subjectCompleted[subject] ?? 0;
      subjectMastery[subject] = total > 0 ? (done / total * 100) : 0;
    });

    // Streak calculation
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    // Check each day going backwards
    for (int i = 0; i < 90; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final hadCompletion = completed.any(
        (t) => t.completedAt != null && _isSameDay(t.completedAt!, day),
      );

      if (hadCompletion) {
        tempStreak++;
        if (i == currentStreak) currentStreak = tempStreak;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        if (i > 0 && i == currentStreak) break; // Streak broken
        tempStreak = 0;
      }
    }

    final completionRate = allTasks.isEmpty
        ? 0.0
        : completed.length / allTasks.length;

    return WeeklyStats(
      totalTasks: allTasks.length,
      completedTasks: completed.length,
      missedDeadlines: missed,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      avgCompletionRate: completionRate,
      tasksByDay: tasksByDay,
      completedByDay: completedByDay,
      mostProductiveDay: bestDay,
      mostProductiveHour: hourLabel,
      subjectMastery: subjectMastery,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
