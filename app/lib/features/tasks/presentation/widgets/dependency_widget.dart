import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/task_model.dart';
import '../providers/dependency_providers.dart';
import '../providers/task_providers.dart';

class DependencyWidget extends ConsumerWidget {
  final String taskId;

  const DependencyWidget({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocking = ref.watch(blockingTasksProvider(taskId));
    final dependents = ref.watch(dependentTasksProvider(taskId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Dependencies',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddDependencySheet(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Blocked By (tasks this task depends on)
          if (blocking.isNotEmpty) ...[
            _sectionLabel('BLOCKED BY'),
            const SizedBox(height: 8),
            ...blocking.map(
              (task) => _DependencyTile(
                task: task,
                taskId: taskId,
                type: _DepType.blockedBy,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Blocking (tasks that depend on this task)
          if (dependents.isNotEmpty) ...[
            _sectionLabel('BLOCKING'),
            const SizedBox(height: 8),
            ...dependents.map(
              (task) => _DependencyTile(
                task: task,
                taskId: taskId,
                type: _DepType.blocking,
              ),
            ),
          ],

          // Empty state
          if (blocking.isEmpty && dependents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No dependencies set',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  void _showAddDependencySheet(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.read(userTasksProvider);
    final allTasks = tasksAsync.valueOrNull ?? [];
    // Exclude current task
    final available = allTasks.where((t) => t.id != taskId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) =>
          _AddDependencySheet(taskId: taskId, availableTasks: available),
    );
  }
}

enum _DepType { blockedBy, blocking }

class _DependencyTile extends ConsumerWidget {
  final TaskModel task;
  final String taskId;
  final _DepType type;

  const _DependencyTile({
    required this.task,
    required this.taskId,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.status == TaskStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: type == _DepType.blockedBy
            ? AppColors.error.withValues(alpha: 0.05)
            : AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: type == _DepType.blockedBy
              ? AppColors.error.withValues(alpha: 0.15)
              : AppColors.warning.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (type == _DepType.blockedBy
                            ? AppColors.error
                            : AppColors.warning)
                        .withValues(alpha: 0.1),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : (type == _DepType.blockedBy
                        ? Icons.block_rounded
                        : Icons.arrow_forward_rounded),
              size: 16,
              color: isCompleted
                  ? AppColors.success
                  : (type == _DepType.blockedBy
                        ? AppColors.error
                        : AppColors.warning),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (type == _DepType.blockedBy)
            GestureDetector(
              onTap: () {
                ref
                    .read(dependencyNotifierProvider.notifier)
                    .removeDependency(taskId, task.id);
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddDependencySheet extends ConsumerStatefulWidget {
  final String taskId;
  final List<TaskModel> availableTasks;

  const _AddDependencySheet({
    required this.taskId,
    required this.availableTasks,
  });

  @override
  ConsumerState<_AddDependencySheet> createState() =>
      _AddDependencySheetState();
}

class _AddDependencySheetState extends ConsumerState<_AddDependencySheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.availableTasks.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Dependency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a task that must be completed first',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              // Search
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.bgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final task = filtered[index];
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await ref
                              .read(dependencyNotifierProvider.notifier)
                              .addDependency(widget.taskId, task.id);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                task.status == TaskStatus.completed
                                    ? Icons.check_circle_rounded
                                    : Icons.task_alt_rounded,
                                size: 18,
                                color: task.status == TaskStatus.completed
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    task.subject.isNotEmpty
                                        ? task.subject
                                        : task.status.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
