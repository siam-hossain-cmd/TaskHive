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
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
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
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<TaskModel> tasks, UserModel? user) {
    // Sort: active first by due date, completed at bottom
    tasks.sort((a, b) {
      if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) return 1;
      if (a.status != TaskStatus.completed && b.status == TaskStatus.completed) return -1;
      return a.dueDate.compareTo(b.dueDate);
    });

    final total = tasks.length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final active = tasks.where((t) => t.status != TaskStatus.completed).toList();
    final progress = total == 0 ? 0.0 : completed / total;

    // Upcoming = due within next 3 days (active only)
    final now = DateTime.now();
    final upcoming = active
        .where((t) => t.dueDate.difference(now).inDays <= 3)
        .take(4)
        .toList();
    final restActive = active.where((t) => t.dueDate.difference(now).inDays > 3).toList();

    final firstName = user?.displayName.split(' ').first ?? 'there';
    final todayStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        _buildHeader(context, ref, user, firstName, todayStr),

        // ── Progress + Stats ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _buildProgressCard(total, completed, active.length, progress, user),
        ),

        // ── Quick Actions ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _buildQuickActions(context),
        ),

        // ── Upcoming Tasks ──────────────────────────────────────────────────
        if (upcoming.isNotEmpty) ...[
          _sectionHeader('Due Soon 🔥', upcoming.length),
          ...upcoming.map((t) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TaskCard(
              task: t,
              onToggle: () => ref.read(taskNotifierProvider.notifier).markComplete(t.id),
              onTap: () => context.push('/create-task'),
            ),
          )),
        ],

        // ── All Active ──────────────────────────────────────────────────────
        if (restActive.isNotEmpty) ...[
          _sectionHeader('All Tasks', restActive.length),
          ...restActive.map((t) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TaskCard(
              task: t,
              onToggle: () => ref.read(taskNotifierProvider.notifier).markComplete(t.id),
              onTap: () => context.push('/create-task'),
            ),
          )),
        ],

        // ── Empty State ─────────────────────────────────────────────────────
        if (tasks.isEmpty) _buildEmptyState(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserModel? user, String firstName, String todayStr) {
    final initial = user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : '?';
    final unreadCount = ref.watch(unreadNotificationCountProvider).value ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
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
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Center(child: Text(initial, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(todayStr, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Text('${_greeting()}, $firstName ${_greetingEmoji()}', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                ]),
              ),
              // Notifications quick-access bell
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bgColor, borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.softShadows,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
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

  Widget _buildProgressCard(int total, int completed, int active, double progress, UserModel? user) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          // Progress Ring
          SizedBox(
            width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$pct%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('done', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 16),
                Row(children: [
                  _miniStat('$total', 'Total', Icons.list_alt_rounded),
                  const SizedBox(width: 16),
                  _miniStat('$completed', 'Done', Icons.check_circle_rounded),
                  const SizedBox(width: 16),
                  _miniStat('$active', 'Left', Icons.pending_rounded),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70)),
    ]);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.calendar_month_rounded, 'Calendar', const Color(0xFF667EEA), '/calendar'),
      (Icons.groups_rounded, 'Teams', const Color(0xFF11998E), '/groups'),
      (Icons.insert_chart_rounded, 'Analytics', const Color(0xFFFF6B6B), '/analytics'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
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
                    child: Column(children: [
                      Icon(icon, color: color, size: 26),
                      const SizedBox(height: 6),
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                    ]),
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
      child: Row(children: [
        Expanded(child: Text(title, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: Icon(Icons.check_circle_rounded, size: 44, color: Colors.white),
        ),
        SizedBox(height: 24),
        Text('All clear! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        SizedBox(height: 8),
        Text('You have no tasks yet.\nTap + to create your first task.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.5)),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => context.push('/create-task'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Create Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ),
      ]),
    );
  }
}
