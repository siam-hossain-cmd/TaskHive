import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/reminder_model.dart';
import '../providers/reminder_providers.dart';
import '../widgets/reminder_card.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(userRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: remindersAsync.when(
            data: (reminders) => _buildContent(reminders),
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-reminder'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(List<ReminderModel> reminders) {
    final now = DateTime.now();
    final upcoming = reminders
        .where((r) => !r.isCompleted && r.date.isAfter(now))
        .toList();
    final overdue = reminders
        .where((r) => !r.isCompleted && r.date.isBefore(now))
        .toList();
    final completed = reminders.where((r) => r.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Header
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Reminders',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${upcoming.length + overdue.length} active',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Overdue section
        if (overdue.isNotEmpty) ...[
          _sectionLabel('Overdue', AppColors.error, overdue.length),
          const SizedBox(height: 12),
          ...overdue.map(
            (r) => ReminderCard(
              reminder: r,
              onTap: () => context.push('/create-reminder', extra: r),
              onDismiss: () => _completeReminder(r.id),
              onDelete: () => _deleteReminder(r.id),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Upcoming section
        if (upcoming.isNotEmpty) ...[
          _sectionLabel('Upcoming', AppColors.primary, upcoming.length),
          const SizedBox(height: 12),
          ...upcoming.map(
            (r) => ReminderCard(
              reminder: r,
              onTap: () => context.push('/create-reminder', extra: r),
              onDismiss: () => _completeReminder(r.id),
              onDelete: () => _deleteReminder(r.id),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Empty state
        if (upcoming.isEmpty && overdue.isEmpty && completed.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first reminder',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Completed toggle
        if (completed.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _showCompleted = !_showCompleted),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadows,
              ),
              child: Row(
                children: [
                  Icon(
                    _showCompleted
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completed (${completed.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCompleted) ...[
            const SizedBox(height: 12),
            ...completed.map(
              (r) => ReminderCard(
                reminder: r,
                onDelete: () => _deleteReminder(r.id),
              ),
            ),
          ],
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _sectionLabel(String text, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
    );
  }

  void _completeReminder(String id) {
    ref.read(reminderNotifierProvider.notifier).completeReminder(id);
  }

  void _deleteReminder(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Reminder',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this reminder?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(reminderNotifierProvider.notifier).deleteReminder(id);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
