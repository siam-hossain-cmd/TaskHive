import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _priorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.high: return AppColors.priorityHighText;
      case TaskPriority.medium: return AppColors.priorityMediumText;
      case TaskPriority.low: return AppColors.priorityLowText;
    }
  }

  Color _priorityBgColor() {
    switch (widget.task.priority) {
      case TaskPriority.high: return AppColors.priorityHighBg;
      case TaskPriority.medium: return AppColors.priorityMediumBg;
      case TaskPriority.low: return AppColors.priorityLowBg;
    }
  }

  String _priorityLabel() {
    switch (widget.task.priority) {
      case TaskPriority.high: return 'High Priority';
      case TaskPriority.medium: return 'Medium Priority';
      case TaskPriority.low: return 'Low Priority';
    }
  }

  String _formatDue() {
    final now = DateTime.now();
    final diff = widget.task.dueDate.difference(now);
    if (widget.task.status == TaskStatus.completed) return 'Done';
    if (diff.isNegative) return 'Overdue';
    
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[widget.task.dueDate.month - 1]} ${widget.task.dueDate.day}, ${widget.task.dueDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.status == TaskStatus.completed;
    // Derive a unique gradient index based on the task ID
    final gradientIndex = widget.task.id.hashCode;
    
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _animController.reverse(),
        child: Container(
          // Soft outer shadow (Glassmorphism / Dribbble base)
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.softShadows,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            // The Vibrant Gradient Background with opacity
            decoration: BoxDecoration(
              gradient: isCompleted ? null : AppColors.getGradientTheme(gradientIndex),
              color: isCompleted ? AppColors.surfaceColor : null,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Container(
              // Inner white wash to create the glass effect over the gradient
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: isCompleted
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.65), // Magic glass wash
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title & Priority
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 22, // Large, bold typography
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textSecondary,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Priority Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.bgColor : _priorityBgColor().withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _priorityLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isCompleted ? AppColors.textSecondary : _priorityColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Subtitle / Subject
                  if (widget.task.subject.isNotEmpty)
                    Text(
                      widget.task.subject,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                  // Bottom Row: Date & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDue(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.more_horiz_rounded,
                            color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 16),
                          // Subtle complete action (doesn't have to be a checkbox if it breaks the clean look)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onToggle?.call();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? AppColors.textPrimary : Colors.white.withValues(alpha: 0.7),
                                boxShadow: isCompleted ? null : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10, offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Icon(
                                isCompleted ? Icons.undo_rounded : Icons.check_rounded,
                                size: 20,
                                color: isCompleted ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
