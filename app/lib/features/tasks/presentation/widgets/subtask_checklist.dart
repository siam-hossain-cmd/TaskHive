import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/subtask_model.dart';
import '../providers/subtask_providers.dart';

class SubtaskChecklist extends ConsumerStatefulWidget {
  final String taskId;

  const SubtaskChecklist({super.key, required this.taskId});

  @override
  ConsumerState<SubtaskChecklist> createState() => _SubtaskChecklistState();
}

class _SubtaskChecklistState extends ConsumerState<SubtaskChecklist> {
  final _controller = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref
        .read(subtaskNotifierProvider.notifier)
        .addSubtask(taskId: widget.taskId, title: text);
    _controller.clear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(subtasksProvider(widget.taskId));

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
              Icon(Icons.checklist_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Subtasks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              subtasksAsync.when(
                data: (subtasks) {
                  if (subtasks.isEmpty) return const SizedBox.shrink();
                  final done = subtasks.where((s) => s.isCompleted).length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: done == subtasks.length
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$done / ${subtasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: done == subtasks.length
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          subtasksAsync.when(
            data: (subtasks) {
              if (subtasks.isEmpty) return const SizedBox.shrink();
              final done = subtasks.where((s) => s.isCompleted).length;
              final progress = subtasks.isEmpty ? 0.0 : done / subtasks.length;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.bgColor,
                      valueColor: AlwaysStoppedAnimation(
                        progress == 1.0 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Subtask List
          subtasksAsync.when(
            data: (subtasks) {
              if (subtasks.isEmpty && !_isAdding) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'No subtasks yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subtasks.length,
                onReorder: (oldIdx, newIdx) {
                  if (newIdx > oldIdx) newIdx--;
                  final reordered = [...subtasks];
                  final item = reordered.removeAt(oldIdx);
                  reordered.insert(newIdx, item);
                  ref
                      .read(subtaskNotifierProvider.notifier)
                      .reorderSubtasks(reordered);
                },
                proxyDecorator: (child, _, __) =>
                    Material(color: Colors.transparent, child: child),
                itemBuilder: (_, index) {
                  final subtask = subtasks[index];
                  return _SubtaskTile(
                    key: ValueKey(subtask.id),
                    subtask: subtask,
                    taskId: widget.taskId,
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),

          const SizedBox(height: 8),

          // Add Subtask
          if (_isAdding)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a subtask...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addSubtask,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isAdding = false),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _isAdding = true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Add Subtask',
                      style: TextStyle(
                        fontSize: 13,
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
    );
  }
}

class _SubtaskTile extends ConsumerWidget {
  final SubtaskModel subtask;
  final String taskId;

  const _SubtaskTile({super.key, required this.subtask, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: subtask.isCompleted
              ? AppColors.success.withValues(alpha: 0.06)
              : AppColors.bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(subtaskNotifierProvider.notifier)
                    .toggleSubtask(subtask.id, taskId, !subtask.isCompleted);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: subtask.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  border: Border.all(
                    color: subtask.isCompleted
                        ? AppColors.success
                        : AppColors.textSecondary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: subtask.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subtask.isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: subtask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
            // Drag handle
            Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            // Delete
            GestureDetector(
              onTap: () {
                ref
                    .read(subtaskNotifierProvider.notifier)
                    .deleteSubtask(subtask.id, taskId, subtask.isCompleted);
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
