import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../reminders/domain/models/reminder_model.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';
import '../../../reminders/presentation/widgets/reminder_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<TaskModel> _getTasksForDay(DateTime day, List<TaskModel> allTasks) {
    return allTasks
        .where(
          (t) =>
              t.dueDate.year == day.year &&
              t.dueDate.month == day.month &&
              t.dueDate.day == day.day,
        )
        .toList();
  }

  List<ReminderModel> _getRemindersForDay(
    DateTime day,
    List<ReminderModel> allReminders,
  ) {
    return allReminders
        .where(
          (r) =>
              r.date.year == day.year &&
              r.date.month == day.month &&
              r.date.day == day.day,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final remindersAsync = ref.watch(userRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: tasksAsync.when(
              data: (tasks) {
                final reminders = remindersAsync.asData?.value ?? [];
                return _buildContent(context, tasks, reminders);
              },
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

  Widget _buildContent(
    BuildContext context,
    List<TaskModel> tasks,
    List<ReminderModel> reminders,
  ) {
    final selectedTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!, tasks)
        : <TaskModel>[];
    final selectedReminders = _selectedDay != null
        ? _getRemindersForDay(_selectedDay!, reminders)
        : <ReminderModel>[];
    final pendingTasks = tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();
    final upcomingReminders = reminders
        .where((r) => !r.isCompleted && r.date.isAfter(DateTime.now()))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Calendar',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            // Month/Week toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadows,
              ),
              child: Row(
                children: [
                  _togglePill(
                    'Month',
                    _isMonthView,
                    () => setState(() => _isMonthView = true),
                  ),
                  _togglePill(
                    'Week',
                    !_isMonthView,
                    () => setState(() => _isMonthView = false),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 32),

        // Calendar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.softShadows,
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _isMonthView
                ? CalendarFormat.month
                : CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textSecondary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              defaultTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              todayTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              selectedTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              selectedDecoration: BoxDecoration(
                gradient: AppColors.gradientPurpleBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              defaultDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              weekendDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final dayTasks = _getTasksForDay(day, tasks);
                final dayReminders = _getRemindersForDay(day, reminders);
                if (dayTasks.isEmpty && dayReminders.isEmpty) return null;
                final dots = <Widget>[];
                // Task dots
                for (final t in dayTasks.take(2)) {
                  final color = t.priority == TaskPriority.high
                      ? AppColors.priorityHighText
                      : AppColors.accent;
                  dots.add(
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                // Reminder dots
                for (final r in dayReminders.take(2)) {
                  dots.add(
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: r.type.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return Positioned(
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: dots.take(4).toList(),
                  ),
                );
              },
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
          ),
        ),
        SizedBox(height: 36),

        // Selected Day Details
        if (_selectedDay != null &&
            (selectedTasks.isNotEmpty || selectedReminders.isNotEmpty)) ...[
          Text(
            '${DateFormat('EEEE, MMM d').format(_selectedDay!)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 16),
          // Show reminders for selected day
          if (selectedReminders.isNotEmpty) ...[
            _reminderSectionLabel(),
            const SizedBox(height: 8),
            ...selectedReminders.map(
              (r) => ReminderCard(
                reminder: r,
                onDismiss: () {
                  ref
                      .read(reminderNotifierProvider.notifier)
                      .completeReminder(r.id);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Show tasks for selected day
          if (selectedTasks.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...selectedTasks.map((task) => _buildAgendaItem(task)),
          ],
          SizedBox(height: 24),
        ],

        // Agenda Section
        Text(
          'Upcoming Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 20),

        if (pendingTasks.isEmpty && upcomingReminders.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No upcoming events',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else ...[
          // Upcoming reminders in agenda
          ...upcomingReminders.take(3).map((r) => _buildReminderAgendaItem(r)),
          // Tasks in agenda
          ...pendingTasks.take(5).map((task) => _buildAgendaItem(task)),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _togglePill(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.bgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaItem(TaskModel task) {
    final isHigh = task.priority == TaskPriority.high;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final timeStr =
        '${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}';
    final dateStr = '${task.dueDate.day} ${months[task.dueDate.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time left side
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Timeline dot
          Column(
            children: [
              SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isHigh ? AppColors.priorityHighText : AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgColor, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (task.subject.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      task.subject,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderSectionLabel() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFFF512F),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Reminders',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderAgendaItem(ReminderModel reminder) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final timeStr =
        '${reminder.date.hour}:${reminder.date.minute.toString().padLeft(2, '0')}';
    final dateStr = '${reminder.date.day} ${months[reminder.date.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time left side
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Timeline dot with reminder type color
          Column(
            children: [
              SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: reminder.type.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgColor, width: 2),
                ),
              ),
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
                border: Border.all(
                  color: reminder.type.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: reminder.type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      reminder.type.icon,
                      color: reminder.type.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (reminder.remark.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            reminder.remark,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
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
