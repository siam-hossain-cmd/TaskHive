import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../smart_planner/presentation/providers/smart_planner_providers.dart';
import '../../../smart_planner/domain/models/planner_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 17) return '🌤️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: tasksAsync.when(
          data: (tasks) => _buildContent(context, tasks, userAsync.valueOrNull),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<TaskModel> tasks,
    UserModel? user,
  ) {
    // Sort: active first by due date, completed at bottom
    tasks.sort((a, b) {
      if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) {
        return 1;
      }
      if (a.status != TaskStatus.completed && b.status == TaskStatus.completed) {
        return -1;
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    final total = tasks.length;
    final completed = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final active = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();

    // Upcoming = due within next 3 days (active only)
    final now = DateTime.now();
    final upcoming = active
        .where((t) => t.dueDate.difference(now).inDays <= 3)
        .take(4)
        .toList();
    final restActive = active
        .where((t) => t.dueDate.difference(now).inDays > 3)
        .toList();

    final firstName = user?.displayName.split(' ').first ?? 'there';
    final todayStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    // Smart Planner data
    final bestTask = ref.watch(bestTaskNowProvider);
    final schedule = ref.watch(todayScheduleProvider);
    final alerts = ref.watch(riskAlertsProvider);
    final workload = ref.watch(weeklyWorkloadProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // ── Header
        _buildHeader(context, ref, user, firstName, todayStr),

        // ── Quick Stats Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildQuickStats(
            total,
            completed,
            active.length,
            alerts.length,
          ),
        ),

        // ── Best Task Now (Hero Card)
        if (bestTask != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildBestTaskCard(context, bestTask),
          ),

        // ── Risk Alerts
        if (alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildRiskAlerts(alerts),
          ),

        // ── Today's Schedule
        if (schedule.isNotEmpty) ...[
          _sectionHeader('Today\'s Schedule 📅', schedule.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _buildScheduleTimeline(context, schedule),
          ),
        ],

        // ── Workload Balance
        if (workload.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildWorkloadBar(workload),
          ),

        // ── Quick Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _buildQuickActions(context),
        ),

        // ── Upcoming Tasks
        if (upcoming.isNotEmpty) ...[
          _sectionHeader('Due Soon 🔥', upcoming.length),
          ...upcoming.map(
            (t) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TaskCard(
                task: t,
                onToggle: () =>
                    ref.read(taskNotifierProvider.notifier).markComplete(t.id),
                onTap: () => context.push('/task/${t.id}'),
              ),
            ),
          ),
        ],

        // ── All Active
        if (restActive.isNotEmpty) ...[
          _sectionHeader('All Tasks', restActive.length),
          ...restActive.map(
            (t) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TaskCard(
                task: t,
                onToggle: () =>
                    ref.read(taskNotifierProvider.notifier).markComplete(t.id),
                onTap: () => context.push('/task/${t.id}'),
              ),
            ),
          ),
        ],

        // ── Empty State
        if (tasks.isEmpty) _buildEmptyState(context),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    String firstName,
    String todayStr,
  ) {
    final initial = user?.displayName.isNotEmpty == true
        ? user!.displayName[0].toUpperCase()
        : '?';
    final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar → goes to profile
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_greeting()}, $firstName ${_greetingEmoji()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Notifications quick-access bell
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.softShadows,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  QUICK STATS BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildQuickStats(int total, int completed, int active, int alerts) {
    return Row(
      children: [
        _statChip(
          Icons.check_circle_rounded,
          '$completed',
          'Done',
          AppColors.success,
        ),
        const SizedBox(width: 8),
        _statChip(
          Icons.pending_rounded,
          '$active',
          'Active',
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _statChip(
          Icons.list_alt_rounded,
          '$total',
          'Total',
          AppColors.textSecondary,
        ),
        if (alerts > 0) ...[
          const SizedBox(width: 8),
          _statChip(
            Icons.warning_rounded,
            '$alerts',
            'Alerts',
            AppColors.warning,
          ),
        ],
      ],
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BEST TASK NOW (Hero Card)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildBestTaskCard(BuildContext context, ScoredTask scored) {
    final task = scored.task;
    final hoursLeft = task.dueDate.difference(DateTime.now()).inHours;
    final dueLabel = hoursLeft < 0
        ? 'Overdue'
        : hoursLeft < 24
        ? '${hoursLeft}h left'
        : '${(hoursLeft / 24).ceil()}d left';

    return GestureDetector(
      onTap: () => context.push('/task/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Best Task Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hoursLeft < 0
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dueLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.subject.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.subject,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              scored.reason,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _heroChip(Icons.timer_outlined, '${task.estimatedMinutes} min'),
                const SizedBox(width: 8),
                _heroChip(
                  Icons.flag_rounded,
                  task.priority.name[0].toUpperCase() +
                      task.priority.name.substring(1),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Start →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF667EEA),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  RISK ALERTS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildRiskAlerts(List<RiskAlert> alerts) {
    final shown = alerts.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shown.map((alert) {
        final color = alert.level == RiskLevel.critical
            ? AppColors.error
            : alert.level == RiskLevel.warning
            ? AppColors.warning
            : AppColors.info;
        final icon = alert.level == RiskLevel.critical
            ? Icons.error_rounded
            : alert.level == RiskLevel.warning
            ? Icons.warning_rounded
            : Icons.info_rounded;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
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
                        alert.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.suggestion,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TODAY'S SCHEDULE TIMELINE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildScheduleTimeline(
    BuildContext context,
    List<ScheduleSlot> slots,
  ) {
    final shown = slots.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: shown.asMap().entries.map((entry) {
          final i = entry.key;
          final slot = entry.value;
          final timeStr = DateFormat('h:mm a').format(slot.startTime);
          final endStr = DateFormat('h:mm a').format(slot.endTime);
          final isLast = i == shown.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                SizedBox(
                  width: 55,
                  child: Column(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dot + line
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Task card
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/task/${slot.task.id}'),
                    child: Container(
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  slot.task.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${slot.durationMinutes}m',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$timeStr – $endStr  •  ${slot.label}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  WORKLOAD BALANCE BAR (7-day heatmap)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildWorkloadBar(List<WorkloadSummary> workload) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.balance_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Workload Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: workload.asMap().entries.map((entry) {
              final i = entry.key;
              final w = entry.value;
              final dayIndex = (w.date.weekday - 1) % 7;
              final isToday = i == 0;

              Color barColor;
              if (w.isOverloaded) {
                barColor = AppColors.error;
              } else if (w.isHeavy) {
                barColor = AppColors.warning;
              } else if (w.taskCount > 0) {
                barColor = AppColors.success;
              } else {
                barColor = AppColors.textSecondary.withValues(alpha: 0.2);
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  child: Column(
                    children: [
                      Container(
                        height: 48,
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: (w.loadPercentage.clamp(0.05, 1.0) * 48),
                          decoration: BoxDecoration(
                            color: barColor.withValues(
                              alpha: isToday ? 1.0 : 0.6,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayNames[dayIndex],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: isToday
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${w.taskCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.success, 'Light'),
              const SizedBox(width: 12),
              _legendDot(AppColors.warning, 'Heavy'),
              const SizedBox(width: 12),
              _legendDot(AppColors.error, 'Overloaded'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        Icons.calendar_month_rounded,
        'Calendar',
        const Color(0xFF667EEA),
        '/calendar',
      ),
      (Icons.groups_rounded, 'Teams', const Color(0xFF11998E), '/groups'),
      (
        Icons.insert_chart_rounded,
        'Analytics',
        const Color(0xFFFF6B6B),
        '/analytics',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) {
            final (icon, label, color, route) = a;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: route != '/analytics' ? 10 : 0),
                child: GestureDetector(
                  onTap: () => context.push(route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(icon, color: color, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'All clear! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You have no tasks yet.\nTap + to create your first task.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => context.push('/create-task'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create Task',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
