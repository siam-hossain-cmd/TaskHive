import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../groups/domain/models/group_model.dart';
import '../../domain/models/assignment_model.dart';

import '../providers/assignment_providers.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final String groupId;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.groupId,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final assignmentAsync = ref.watch(assignmentProvider(widget.assignmentId));
    final tasksAsync = ref.watch(assignmentTasksProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: assignmentAsync.when(
          data: (assignment) {
            if (assignment == null) {
              return Center(
                child: Text(
                  'Assignment not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                _buildHeader(assignment),
                Expanded(
                  child: tasksAsync.when(
                    data: (tasks) => _buildContent(context, assignment, tasks),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildHeader(AssignmentModel assignment) {
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
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (assignment.subject.isNotEmpty)
                      Text(
                        assignment.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(assignment.status),
            ],
          ),
          if (assignment.summary.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              assignment.summary,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (assignment.dueDate != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'Due ${DateFormat('MMM dd, yyyy').format(assignment.dueDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AssignmentStatus status) {
    final colors = {
      AssignmentStatus.active: (
        AppColors.priorityMediumBg,
        AppColors.priorityMediumText,
      ),
      AssignmentStatus.compilationPhase: (
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
      AssignmentStatus.completed: (
        AppColors.priorityLowBg,
        AppColors.priorityLowText,
      ),
    };
    final (bg, text) = colors[status]!;
    final labels = {
      AssignmentStatus.active: 'ACTIVE',
      AssignmentStatus.compilationPhase: 'COMPILING',
      AssignmentStatus.completed: 'DONE',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[status]!,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: text,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AssignmentModel assignment,
    List<GroupTaskModel> tasks,
  ) {
    final user = ref.read(authStateProvider).valueOrNull;
    final currentUid = user?.uid ?? '';

    // Calculate progress
    final approvedCount = tasks
        .where((t) => t.status == GroupTaskStatus.approved)
        .length;
    final totalTasks = tasks.length;
    final progress = totalTasks > 0 ? approvedCount / totalTasks : 0.0;
    final allApproved = approvedCount == totalTasks && totalTasks > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View File Button
          if (assignment.originalPdfUrl != null)
            _buildViewFileButton(
              label: 'View Original File',
              url: assignment.originalPdfUrl!,
              icon: Icons.description_rounded,
            ),
          if (assignment.originalPdfUrl != null)
            const SizedBox(height: 12),

          // Progress Card
          _ProgressCard(
            progress: progress,
            approvedCount: approvedCount,
            totalTasks: totalTasks,
          ),
          SizedBox(height: 20),

          // Subtask List
          Text(
            'SUBTASKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...tasks.asMap().entries.map((entry) {
            final task = entry.value;
            final isMyTask = task.assignedTo == currentUid;
            return _SubtaskTile(
              task: task,
              isMyTask: isMyTask,
              onTap: () {
                context.push(
                  '/assignment/${widget.assignmentId}/task/${task.id}',
                  extra: {'task': task, 'groupId': widget.groupId},
                );
              },
            );
          }),

          // Compilation section
          if (allApproved &&
              assignment.status != AssignmentStatus.completed) ...[
            const SizedBox(height: 24),
            _CompilationSection(
              assignment: assignment,
              currentUid: currentUid,
              onAssignCompiler: () => _showCompilerPicker(tasks),
              onComplete: () => _completeAssignment(),
            ),
          ],

          // Final document
          if (assignment.finalDocUrl != null) ...[
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.priorityLowBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.priorityLowText.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: AppColors.priorityLowText,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Final Compiled Document',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.priorityLowText,
                          ),
                        ),
                        if (assignment.finalDocName != null)
                          Text(
                            assignment.finalDocName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.priorityLowText.withValues(
                                alpha: 0.7,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompilerPicker(List<GroupTaskModel> tasks) async {
    final memberIds = tasks.map((t) => t.assignedTo).toSet().toList();

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign Compiler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Choose who will compile all submissions into the final document.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            ...memberIds.map(
              (uid) => GestureDetector(
                onTap: () => Navigator.pop(ctx, uid),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            uid.isNotEmpty ? uid[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          uid.length > 20 ? '${uid.substring(0, 20)}...' : uid,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      final api = ref.read(apiServiceProvider);
      final success = await api.assignCompiler(
        assignmentId: widget.assignmentId,
        compilerId: selected,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compiler assigned successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _completeAssignment() async {
    final api = ref.read(apiServiceProvider);
    final success = await api.completeAssignment(widget.assignmentId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment completed!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
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
    if (lower.contains('.doc') || lower.contains('.docx')) return 'Word Document';
    if (lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg')) return 'Image';
    if (lower.contains('.xls') || lower.contains('.xlsx')) return 'Spreadsheet';
    if (lower.contains('.ppt') || lower.contains('.pptx')) return 'Presentation';
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

// ─── Progress Card ────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final double progress;
  final int approvedCount;
  final int totalTasks;

  const _ProgressCard({
    required this.progress,
    required this.approvedCount,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$approvedCount of $totalTasks subtasks approved',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subtask Tile ─────────────────────────────────────────────────────────────
class _SubtaskTile extends StatelessWidget {
  final GroupTaskModel task;
  final bool isMyTask;
  final VoidCallback onTap;

  const _SubtaskTile({
    required this.task,
    required this.isMyTask,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      GroupTaskStatus.pending: (AppColors.bgColor, AppColors.textSecondary),
      GroupTaskStatus.inProgress: (
        const Color(0xFFE3F2FD),
        const Color(0xFF1565C0),
      ),
      GroupTaskStatus.pendingApproval: (
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
      GroupTaskStatus.changesRequested: (
        AppColors.priorityHighBg,
        AppColors.priorityHighText,
      ),
      GroupTaskStatus.approved: (
        AppColors.priorityLowBg,
        AppColors.priorityLowText,
      ),
    };
    final (bg, textColor) =
        statusColors[task.status] ??
        (AppColors.bgColor, AppColors.textSecondary);

    final statusLabels = {
      GroupTaskStatus.pending: 'Pending',
      GroupTaskStatus.inProgress: 'In Progress',
      GroupTaskStatus.pendingApproval: 'Awaiting Review',
      GroupTaskStatus.changesRequested: 'Changes Needed',
      GroupTaskStatus.approved: 'Approved',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadows,
          border: isMyTask
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                task.status == GroupTaskStatus.approved
                    ? Icons.check_circle_rounded
                    : Icons.assignment_rounded,
                color: textColor,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabels[task.status] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isMyTask) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'YOUR TASK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compilation Section ──────────────────────────────────────────────────────
class _CompilationSection extends StatelessWidget {
  final AssignmentModel assignment;
  final String currentUid;
  final VoidCallback onAssignCompiler;
  final VoidCallback onComplete;

  const _CompilationSection({
    required this.assignment,
    required this.currentUid,
    required this.onAssignCompiler,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF3E0), const Color(0xFFFFF8E1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE65100).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.merge_type_rounded,
                  color: Color(0xFFE65100),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compilation Phase',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      'All subtasks approved! Time to compile.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (assignment.compilerId == null)
            GestureDetector(
              onTap: onAssignCompiler,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Assign Compiler',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            Text(
              'Compiler: ${assignment.compilerId}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (assignment.compilerId == currentUid) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Mark as Complete',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
