import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

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
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<TaskModel> _getTasksForDay(DateTime day, List<TaskModel> allTasks) {
    return allTasks.where((t) =>
      t.dueDate.year == day.year &&
      t.dueDate.month == day.month &&
      t.dueDate.day == day.day
    ).toList();
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
              loading: () => Center(child: CircularProgressIndicator(color: AppColors.textPrimary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<TaskModel> tasks) {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!, tasks) : <TaskModel>[];
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Calendar', style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            )),
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
                  _togglePill('Month', _isMonthView, () => setState(() => _isMonthView = true)),
                  _togglePill('Week', !_isMonthView, () => setState(() => _isMonthView = false)),
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
            calendarFormat: _isMonthView ? CalendarFormat.month : CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
              weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              defaultTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              weekendTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              todayTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
              selectedTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              selectedDecoration: BoxDecoration(
                gradient: AppColors.gradientPurpleBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              defaultDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
              weekendDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final dayTasks = _getTasksForDay(day, tasks);
                if (dayTasks.isEmpty) return null;
                return Positioned(
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: dayTasks.take(3).map((t) {
                      final color = t.priority == TaskPriority.high
                          ? AppColors.priorityHighText
                          : AppColors.accent;
                      return Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            onDaySelected: (selected, focused) {
              setState(() { _selectedDay = selected; _focusedDay = focused; });
            },
            onPageChanged: (focused) => _focusedDay = focused,
          ),
        ),
        SizedBox(height: 36),

        // Agenda Section
        Text('Upcoming Schedule', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        )),
        SizedBox(height: 20),

        if (pendingTasks.isEmpty)
          Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No upcoming events', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
            )),
          ))
        else
          ...pendingTasks.take(5).map((task) => _buildAgendaItem(task)),

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
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: active ? AppColors.textPrimary : AppColors.textSecondary,
        )),
      ),
    );
  }

  Widget _buildAgendaItem(TaskModel task) {
    final isHigh = task.priority == TaskPriority.high;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final timeStr = '${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}';
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
                Text(timeStr, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
                Text(dateStr, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                )),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Timeline dot
          Column(
            children: [
              SizedBox(height: 6),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: isHigh ? AppColors.priorityHighText : AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgColor, width: 2),
                ),
              ),
              Container(
                width: 2, height: 60,
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
                  Text(task.title, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
                  if (task.subject.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(task.subject, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
