import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/task_model.dart';
import '../providers/task_providers.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: tasksAsync.when(
          data: (tasks) {
            final task = tasks.cast<TaskModel?>().firstWhere(
              (t) => t!.id == widget.taskId,
              orElse: () => null,
            );
            if (task == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Task not found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _buildBody(task);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(TaskModel task) {
    return Column(
      children: [
        // ── Header ──
        _buildHeader(task),

        // ── Content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── View Files ──
                if (task.attachments.isNotEmpty) ...[
                  _buildViewFilesSection(task),
                  const SizedBox(height: 16),
                ],

                // ── Status & Priority Card ──
                _buildStatusCard(task),
                const SizedBox(height: 16),

                // ── Description ──
                if (task.description.isNotEmpty) ...[
                  _sectionLabel('DESCRIPTION'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Details Grid ──
                _sectionLabel('DETAILS'),
                const SizedBox(height: 8),
                _buildDetailsGrid(task),
                const SizedBox(height: 16),

                // ── Attachments ──
                if (task.attachments.isNotEmpty) ...[
                  _sectionLabel('ATTACHMENTS'),
                  const SizedBox(height: 8),
                  ...task.attachments.map((url) => _buildAttachmentTile(url)),
                  const SizedBox(height: 16),
                ],

                // ── Actions ──
                const SizedBox(height: 8),
                _buildActions(task),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(TaskModel task) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.subject.isNotEmpty)
                      Text(
                        task.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(task.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    final Color bg;
    final Color text;
    final String label;

    switch (status) {
      case TaskStatus.pending:
        bg = AppColors.priorityMediumBg;
        text = AppColors.priorityMediumText;
        label = 'PENDING';
        break;
      case TaskStatus.inProgress:
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0284C7);
        label = 'IN PROGRESS';
        break;
      case TaskStatus.completed:
        bg = AppColors.priorityLowBg;
        text = AppColors.priorityLowText;
        label = 'DONE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: text,
        ),
      ),
    );
  }

  Widget _buildStatusCard(TaskModel task) {
    final priorityColor = _priorityColor(task.priority);
    final priorityBg = _priorityBgColor(task.priority);
    final priorityLabel = _priorityLabel(task.priority);
    final isOverdue = task.isOverdue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          // Priority
          Expanded(
            child: _infoChip(
              icon: Icons.flag_rounded,
              label: priorityLabel,
              color: priorityColor,
              bgColor: priorityBg,
            ),
          ),
          const SizedBox(width: 10),
          // Due Date
          Expanded(
            child: _infoChip(
              icon: Icons.calendar_today_rounded,
              label: DateFormat('MMM dd, yyyy').format(task.dueDate),
              color: isOverdue ? AppColors.error : AppColors.textSecondary,
              bgColor: isOverdue
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.bgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          _detailRow(
            Icons.access_time_rounded,
            'Created',
            DateFormat('MMM dd, yyyy • hh:mm a').format(task.createdAt),
          ),
          if (task.completedAt != null) ...[
            const Divider(height: 20),
            _detailRow(
              Icons.check_circle_outline_rounded,
              'Completed',
              DateFormat('MMM dd, yyyy • hh:mm a').format(task.completedAt!),
            ),
          ],
          if (task.isRecurring) ...[
            const Divider(height: 20),
            _detailRow(
              Icons.repeat_rounded,
              'Recurrence',
              task.recurrenceRule.name[0].toUpperCase() +
                  task.recurrenceRule.name.substring(1),
            ),
          ],
          if (task.groupId != null) ...[
            const Divider(height: 20),
            _detailRow(Icons.group_rounded, 'Group Task', 'Yes'),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentTile(String url) {
    final fileName = Uri.parse(url).pathSegments.lastOrNull ?? 'Attachment';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.attach_file_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Uri.decodeFull(fileName),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(TaskModel task) {
    final isCompleted = task.status == TaskStatus.completed;

    return Column(
      children: [
        // Mark complete / uncomplete
        GestureDetector(
          onTap: () {
            ref.read(taskNotifierProvider.notifier).markComplete(task.id);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.priorityMediumBg
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isCompleted ? null : AppTheme.softShadows,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                  color: isCompleted
                      ? AppColors.priorityMediumText
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? AppColors.priorityMediumText
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete
        GestureDetector(
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: AppColors.surfaceColor,
                title: Text(
                  'Delete Task',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete "${task.title}"?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true && mounted) {
              await ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
              if (mounted) context.pop();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                SizedBox(width: 8),
                Text(
                  'Delete Task',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHighText;
      case TaskPriority.medium:
        return AppColors.priorityMediumText;
      case TaskPriority.low:
        return AppColors.priorityLowText;
    }
  }

  Color _priorityBgColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppColors.priorityHighBg;
      case TaskPriority.medium:
        return AppColors.priorityMediumBg;
      case TaskPriority.low:
        return AppColors.priorityLowBg;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Widget _buildViewFilesSection(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...task.attachments.asMap().entries.map((entry) {
          final url = entry.value;
          final idx = entry.key + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildViewFileButton(
              label: task.attachments.length == 1
                  ? 'View File'
                  : 'View File $idx',
              url: url,
              icon: Icons.attach_file_rounded,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildViewFileButton({
    required String label,
    required String url,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => _openFile(url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _getFileType(url),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.pdf')) return 'PDF Document';
    if (lower.contains('.doc') || lower.contains('.docx'))
      return 'Word Document';
    if (lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg'))
      return 'Image';
    if (lower.contains('.xls') || lower.contains('.xlsx')) return 'Spreadsheet';
    if (lower.contains('.ppt') || lower.contains('.pptx'))
      return 'Presentation';
    return 'File';
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the file'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
