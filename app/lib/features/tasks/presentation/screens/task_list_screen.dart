import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../groups/domain/models/group_model.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';

// ─── Unified task wrapper ─────────────────────────────────────────────────────
enum _UnifiedType { personal, team }

class _UnifiedTask {
  final _UnifiedType type;
  final String id;
  final String title;
  final String subtitle;
  final String priority;
  final DateTime dueDate;
  final bool isOverdue;
  final bool isCompleted;
  final String statusLabel;
  final String? groupId;
  final String? assignmentId;
  final TaskModel? personalTask;
  final GroupTaskModel? groupTask;

  _UnifiedTask({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.dueDate,
    required this.isOverdue,
    required this.isCompleted,
    required this.statusLabel,
    this.groupId,
    this.assignmentId,
    this.personalTask,
    this.groupTask,
  });
}

enum _FilterType { all, personal, team }

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _FilterType _filter = _FilterType.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            _buildStatusTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UnifiedTaskList(filter: _filter, statusFilter: null),
                  _UnifiedTaskList(filter: _filter, statusFilter: 'pending'),
                  _UnifiedTaskList(
                    filter: _filter,
                    statusFilter: 'inProgress',
                  ),
                  _UnifiedTaskList(
                    filter: _filter,
                    statusFilter: 'completed',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Personal & Team tasks in one place',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Spacer(),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final personalTasks = ref.watch(filteredTasksProvider(null));
    final groups = ref.watch(userGroupsProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final uid = user?.uid ?? '';

    int totalTeamTasks = 0;
    if (groups.hasValue) {
      for (final g in groups.value!) {
        final tasks = ref.watch(groupTasksProvider(g.id));
        if (tasks.hasValue) {
          totalTeamTasks +=
              tasks.value!.where((t) => t.assignedTo == uid).length;
        }
      }
    }

    final totalCount = personalTasks.length + totalTeamTasks;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 6),
          Text(
            '$totalCount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 4),
          Text(
            'total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _chip('All', _FilterType.all, Icons.dashboard_rounded),
          SizedBox(width: 8),
          _chip('Personal', _FilterType.personal, Icons.person_rounded),
          SizedBox(width: 8),
          _chip('Team', _FilterType.team, Icons.groups_rounded),
        ],
      ),
    );
  }

  Widget _chip(String label, _FilterType type, IconData icon) {
    final isActive = _filter == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = type);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.15),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status tabs ────────────────────────────────────────────────────────────
  Widget _buildStatusTabs() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Active'),
          Tab(text: 'Done'),
        ],
      ),
    );
  }
}

// ─── Unified task list widget ─────────────────────────────────────────────────
class _UnifiedTaskList extends ConsumerWidget {
  final _FilterType filter;
  final String? statusFilter;

  const _UnifiedTaskList({required this.filter, this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final uid = user?.uid ?? '';
    final personalTasksAsync = ref.watch(userTasksProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return personalTasksAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (personalTasks) {
        final List<_UnifiedTask> unified = [];

        // Personal tasks
        if (filter != _FilterType.team) {
          for (final t in personalTasks) {
            if (_matchesStatus(t.status.name)) {
              unified.add(_UnifiedTask(
                type: _UnifiedType.personal,
                id: t.id,
                title: t.title,
                subtitle: t.subject.isNotEmpty ? t.subject : 'Personal Task',
                priority: t.priority.name,
                dueDate: t.dueDate,
                isOverdue: t.isOverdue,
                isCompleted: t.status == TaskStatus.completed,
                statusLabel: _personalStatusLabel(t.status),
                personalTask: t,
              ));
            }
          }
        }

        // Team tasks
        if (filter != _FilterType.personal && groupsAsync.hasValue) {
          for (final group in groupsAsync.value!) {
            final gta = ref.watch(groupTasksProvider(group.id));
            if (gta.hasValue) {
              for (final gt in gta.value!) {
                if (gt.assignedTo == uid &&
                    _matchesGroupStatus(gt.status.name)) {
                  unified.add(_UnifiedTask(
                    type: _UnifiedType.team,
                    id: gt.id,
                    title: gt.title,
                    subtitle: group.name,
                    priority: gt.priority,
                    dueDate: gt.dueDate,
                    isOverdue: gt.isOverdue,
                    isCompleted: gt.status == GroupTaskStatus.approved,
                    statusLabel: _groupStatusLabel(gt.status),
                    groupId: gt.groupId,
                    assignmentId: gt.assignmentId,
                    groupTask: gt,
                  ));
                }
              }
            }
          }
        }

        // Sort: overdue first, then by due date, completed last
        unified.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
          return a.dueDate.compareTo(b.dueDate);
        });

        if (unified.isEmpty) return _buildEmpty();

        return _buildGroupedList(context, ref, unified);
      },
    );
  }

  bool _matchesStatus(String status) {
    if (statusFilter == null) return true;
    if (statusFilter == 'completed') return status == 'completed';
    if (statusFilter == 'inProgress') return status == 'inProgress';
    if (statusFilter == 'pending') return status == 'pending';
    return true;
  }

  bool _matchesGroupStatus(String status) {
    if (statusFilter == null) return true;
    if (statusFilter == 'completed') return status == 'approved';
    if (statusFilter == 'inProgress') {
      return status == 'inProgress' ||
          status == 'pendingApproval' ||
          status == 'changesRequested' ||
          status == 'submitted';
    }
    if (statusFilter == 'pending') return status == 'pending';
    return true;
  }

  String _personalStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  String _groupStatusLabel(GroupTaskStatus status) {
    switch (status) {
      case GroupTaskStatus.pending:
        return 'Pending';
      case GroupTaskStatus.inProgress:
        return 'In Progress';
      case GroupTaskStatus.submitted:
        return 'Submitted';
      case GroupTaskStatus.pendingApproval:
        return 'Pending Approval';
      case GroupTaskStatus.changesRequested:
        return 'Changes Requested';
      case GroupTaskStatus.approved:
        return 'Approved';
      case GroupTaskStatus.rejected:
        return 'Rejected';
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No tasks here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap + to create your first task',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<_UnifiedTask> tasks,
  ) {
    final Map<String, List<_UnifiedTask>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7));

    for (final task in tasks) {
      final d = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      String section;
      if (task.isCompleted) {
        section = 'Completed';
      } else if (task.isOverdue) {
        section = 'Overdue';
      } else if (d == today) {
        section = 'Today';
      } else if (d == tomorrow) {
        section = 'Tomorrow';
      } else if (d.isBefore(weekEnd)) {
        section = 'This Week';
      } else {
        section = 'Upcoming';
      }
      groups.putIfAbsent(section, () => []);
      groups[section]!.add(task);
    }

    const order = [
      'Overdue',
      'Today',
      'Tomorrow',
      'This Week',
      'Upcoming',
      'Completed',
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        for (final s in order)
          if (groups.containsKey(s)) ...[
            _sectionHeader(s, groups[s]!.length),
            ...groups[s]!.map((t) => _UnifiedTaskCard(task: t)),
            SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    IconData icon;
    Color color;
    switch (title) {
      case 'Overdue':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case 'Today':
        icon = Icons.today_rounded;
        color = AppColors.primary;
        break;
      case 'Tomorrow':
        icon = Icons.event_rounded;
        color = AppColors.info;
        break;
      case 'This Week':
        icon = Icons.date_range_rounded;
        color = AppColors.warning;
        break;
      case 'Upcoming':
        icon = Icons.schedule_rounded;
        color = AppColors.accent;
        break;
      case 'Completed':
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      default:
        icon = Icons.list_rounded;
        color = AppColors.textSecondary;
    }

    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unified Task Card ────────────────────────────────────────────────────────
class _UnifiedTaskCard extends ConsumerStatefulWidget {
  final _UnifiedTask task;
  const _UnifiedTaskCard({required this.task});

  @override
  ConsumerState<_UnifiedTaskCard> createState() => _UnifiedTaskCardState();
}

class _UnifiedTaskCardState extends ConsumerState<_UnifiedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isTeam = task.type == _UnifiedType.team;
    final isCompleted = task.isCompleted;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _animCtrl.forward(),
        onTapUp: (_) {
          _animCtrl.reverse();
          _onTap(context);
        },
        onTapCancel: () => _animCtrl.reverse(),
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left accent bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(color: _accentColor(task)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: type + priority + status
                            Row(
                              children: [
                                _typeBadge(isTeam),
                                SizedBox(width: 6),
                                _priorityDot(task.priority),
                                SizedBox(width: 4),
                                Text(
                                  _priorityLabel(task.priority),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _priorityColor(task.priority),
                                  ),
                                ),
                                Spacer(),
                                _statusBadge(task),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Title
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            // Subtitle
                            Text(
                              task.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 10),
                            // Bottom row: due date + action
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: task.isOverdue && !isCompleted
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _formatDue(task),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: task.isOverdue && !isCompleted
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                Spacer(),
                                if (task.type == _UnifiedType.personal)
                                  _completeButton(task),
                                if (task.type == _UnifiedType.team)
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final task = widget.task;
    if (task.type == _UnifiedType.personal) {
      context.push('/task/${task.id}');
    } else if (task.assignmentId != null && task.assignmentId!.isNotEmpty) {
      context.push(
        '/assignment/${task.assignmentId}/task/${task.id}',
        extra: {'groupId': task.groupId},
      );
    } else if (task.groupId != null) {
      context.push(
        '/group/${task.groupId}',
        extra: {'groupName': task.subtitle},
      );
    }
  }

  Color _accentColor(_UnifiedTask task) {
    if (task.isCompleted) return AppColors.success;
    if (task.isOverdue) return AppColors.error;
    switch (task.priority) {
      case 'high':
        return AppColors.priorityHighText;
      case 'low':
        return AppColors.priorityLowText;
      default:
        return AppColors.primary;
    }
  }

  Widget _typeBadge(bool isTeam) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTeam
            ? Color(0xFF8B5CF6).withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTeam ? Icons.groups_rounded : Icons.person_rounded,
            size: 12,
            color: isTeam ? Color(0xFF8B5CF6) : AppColors.primary,
          ),
          SizedBox(width: 3),
          Text(
            isTeam ? 'Team' : 'Solo',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isTeam ? Color(0xFF8B5CF6) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityDot(String priority) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _priorityColor(priority),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.priorityHighText;
      case 'low':
        return AppColors.priorityLowText;
      default:
        return AppColors.priorityMediumText;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Med';
    }
  }

  Widget _statusBadge(_UnifiedTask task) {
    Color bg;
    Color fg;
    String label = task.statusLabel;

    if (task.isCompleted) {
      bg = AppColors.success.withValues(alpha: 0.1);
      fg = AppColors.success;
    } else if (task.isOverdue) {
      bg = AppColors.error.withValues(alpha: 0.1);
      fg = AppColors.error;
      label = 'Overdue';
    } else if (task.statusLabel == 'Pending') {
      bg = AppColors.warning.withValues(alpha: 0.1);
      fg = AppColors.warning;
    } else if (task.statusLabel == 'In Progress') {
      bg = AppColors.info.withValues(alpha: 0.1);
      fg = AppColors.info;
    } else if (task.statusLabel == 'Pending Approval') {
      bg = Color(0xFF8B5CF6).withValues(alpha: 0.1);
      fg = Color(0xFF8B5CF6);
    } else if (task.statusLabel == 'Changes Requested') {
      bg = AppColors.warning.withValues(alpha: 0.1);
      fg = AppColors.warning;
    } else {
      bg = AppColors.textSecondary.withValues(alpha: 0.1);
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  String _formatDue(_UnifiedTask task) {
    if (task.isCompleted) return 'Done';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate =
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final diff = taskDate.difference(today).inDays;

    if (diff < 0) {
      return '${-diff}d overdue';
    } else if (diff == 0) {
      return 'Today, ${DateFormat.jm().format(task.dueDate)}';
    } else if (diff == 1) {
      return 'Tomorrow, ${DateFormat.jm().format(task.dueDate)}';
    } else if (diff < 7) {
      return DateFormat('EEE, MMM d').format(task.dueDate);
    } else {
      return DateFormat('MMM d, y').format(task.dueDate);
    }
  }

  Widget _completeButton(_UnifiedTask task) {
    final isCompleted = task.isCompleted;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (task.personalTask != null) {
          ref
              .read(taskNotifierProvider.notifier)
              .markComplete(task.personalTask!.id);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? AppColors.success
              : AppColors.textSecondary.withValues(alpha: 0.08),
          border: isCompleted
              ? null
              : Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
        ),
        child: Icon(
          isCompleted ? Icons.undo_rounded : Icons.check_rounded,
          size: 16,
          color: isCompleted ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
