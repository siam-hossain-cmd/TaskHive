import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../smart_planner/presentation/providers/smart_planner_providers.dart';
import '../../../smart_planner/domain/models/planner_models.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0, 0.5, curve: Curves.easeOut),
          ),
        );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: tasksAsync.when(
              data: (tasks) => _buildContent(context, tasks),
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<TaskModel> tasks) {
    final completed = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final progress = tasks.isEmpty
        ? 0
        : ((completed / tasks.length) * 100).round();
    final stats = ref.watch(weeklyStatsProvider);
    final workload = ref.watch(weeklyWorkloadProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Insights',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 36),

        // Circular Progress Ring Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppTheme.softShadows,
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, child) {
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: progress * _progressAnim.value / 100,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress * _progressAnim.value).round()}%',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -2,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'COMPLETE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 40),
              // Stats Row - Real Data
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        'STREAK',
                        '${stats?.currentStreak ?? 0}d',
                        AppColors.textPrimary,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.bgColor),
                    Expanded(
                      child: _statItem(
                        'COMPLETED',
                        '${stats?.completedTasks ?? completed}',
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // ── Weekly Activity Chart ──────────────────────────────────────
        if (stats != null) ...[
          _buildWeeklyActivityChart(stats),
          SizedBox(height: 24),
        ],

        // ── Productivity Insights ──────────────────────────────────────
        if (stats != null) ...[
          _buildInsightsCard(stats, tasks),
          SizedBox(height: 24),
        ],

        // ── Workload Forecast ──────────────────────────────────────────
        if (workload.isNotEmpty) ...[
          _buildWorkloadForecast(workload),
          SizedBox(height: 24),
        ],

        // ── Subject Mastery (Real Data) ────────────────────────────────
        if (stats != null && stats.subjectMastery.isNotEmpty) ...[
          Text(
            'SUBJECT MASTERY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          ...stats.subjectMastery.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final subject = entry.value.key;
            final value = entry.value.value.round();
            final gradients = [
              AppColors.gradientPurpleBlue,
              AppColors.gradientPinkOrange,
              AppColors.gradientTealBlue,
              AppColors.gradientIndigo,
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _masteryCard(
                subject,
                value,
                gradients[i % gradients.length],
              ),
            );
          }),
        ],

        // ── Empty mastery state ─────────────────────────────────────
        if (stats == null || stats.subjectMastery.isEmpty) ...[
          Text(
            'SUBJECT MASTERY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadows,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                SizedBox(height: 12),
                Text(
                  'No subjects yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add subjects to your tasks to track mastery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WEEKLY ACTIVITY CHART
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWeeklyActivityChart(WeeklyStats stats) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxTasks = stats.tasksByDay.values.fold<int>(
      1,
      (m, v) => v > m ? v : m,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weekly Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: dayNames.map((day) {
                    final total = stats.tasksByDay[day] ?? 0;
                    final done = stats.completedByDay[day] ?? 0;
                    final barHeight = maxTasks > 0
                        ? (total / maxTasks * 80 * _progressAnim.value)
                        : 4.0;
                    final doneHeight = maxTasks > 0
                        ? (done / maxTasks * 80 * _progressAnim.value)
                        : 0.0;
                    final isToday =
                        day == dayNames[(DateTime.now().weekday - 1) % 7];

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$total',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: barHeight.clamp(4.0, 80.0),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: doneHeight.clamp(
                                  0.0,
                                  barHeight.clamp(4.0, 80.0),
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradientPurpleBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: isToday
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend(AppColors.primary.withValues(alpha: 0.15), 'Total'),
              const SizedBox(width: 16),
              _chartLegend(AppColors.primary, 'Completed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PRODUCTIVITY INSIGHTS CARD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildInsightsCard(WeeklyStats stats, List<TaskModel> tasks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Productivity Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _insightTile(
                  Icons.local_fire_department_rounded,
                  '${stats.currentStreak}',
                  'Day Streak',
                  const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _insightTile(
                  Icons.emoji_events_rounded,
                  '${stats.bestStreak}',
                  'Best Streak',
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _insightTile(
                  Icons.schedule_rounded,
                  stats.mostProductiveHour,
                  'Peak Hour',
                  const Color(0xFF667EEA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _insightTile(
                  Icons.calendar_today_rounded,
                  stats.mostProductiveDay,
                  'Best Day',
                  const Color(0xFF11998E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _insightTile(
                  Icons.close_rounded,
                  '${stats.missedDeadlines}',
                  'Missed',
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _insightTile(
                  Icons.speed_rounded,
                  '${(stats.avgCompletionRate * 100).round()}%',
                  'Rate',
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WORKLOAD FORECAST
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWorkloadForecast(List<WorkloadSummary> workload) {
    final dayLabels = ['Today', 'Tomorrow'];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '7-Day Forecast',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...workload.asMap().entries.map((entry) {
            final i = entry.key;
            final w = entry.value;
            final dayIndex = (w.date.weekday - 1) % 7;
            final label = i < 2 ? dayLabels[i] : dayNames[dayIndex];

            Color statusColor;
            String statusLabel;
            if (w.isOverloaded) {
              statusColor = AppColors.error;
              statusLabel = 'Overloaded';
            } else if (w.isHeavy) {
              statusColor = AppColors.warning;
              statusLabel = 'Heavy';
            } else if (w.taskCount > 0) {
              statusColor = AppColors.success;
              statusLabel = 'Balanced';
            } else {
              statusColor = AppColors.textSecondary;
              statusLabel = 'Free';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == 0 ? FontWeight.w900 : FontWeight.w600,
                        color: i == 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 8,
                            color: AppColors.bgColor,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor:
                                  (w.loadPercentage * _progressAnim.value)
                                      .clamp(0.02, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${w.taskCount}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: valueColor,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _masteryCard(String subject, int value, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                final fill = value * _progressAnim.value / 100;
                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 18.0;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with gradient shader
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = AppColors.gradientPurpleBlue.createShader(rect);

    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}
