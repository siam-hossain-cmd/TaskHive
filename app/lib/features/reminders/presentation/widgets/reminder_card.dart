import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/reminder_model.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onDismiss,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = reminder.type;
    final dateStr = DateFormat('EEE, MMM d').format(reminder.date);
    final timeStr = DateFormat('h:mm a').format(reminder.date);
    final isPast = reminder.date.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadows,
          border: Border.all(
            color: reminder.isCompleted
                ? Colors.transparent
                : type.color.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: type.color.withValues(
                  alpha: reminder.isCompleted ? 0.08 : 0.15,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                type.icon,
                color: reminder.isCompleted
                    ? AppColors.textSecondary
                    : type.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: reminder.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$dateStr  ·  $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPast && !reminder.isCompleted
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (reminder.remark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.remark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (reminder.recurrence != ReminderRecurrence.none) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 12,
                            color: type.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reminder.recurrence.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: type.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            if (!reminder.isCompleted && onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
                tooltip: 'Mark Done',
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error.withValues(alpha: 0.7),
                  size: 22,
                ),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }
}
