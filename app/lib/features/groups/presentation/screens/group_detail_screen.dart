import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/domain/models/assignment_model.dart';
import '../../../tasks/presentation/providers/assignment_providers.dart';
import '../../domain/models/group_model.dart';
import '../providers/group_providers.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(groupAssignmentsProvider(groupId));
    final groupTasksAsync = ref.watch(groupTasksProvider(groupId));
    final user = ref.read(authStateProvider).valueOrNull;
    final currentUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: assignmentsAsync.when(
                data: (assignments) => groupTasksAsync.when(
                  data: (allTasks) => _buildBody(
                    context,
                    ref,
                    assignments,
                    allTasks,
                    currentUid,
                  ),
                  loading: () => Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
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
                  groupName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Assignments & Tasks',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _headerAction(
            Icons.chat_bubble_rounded,
            const Color(0xFF667EEA),
            () => context.push(
              '/group/$groupId/chat',
              extra: {'groupName': groupName},
            ),
          ),
          SizedBox(width: 8),
          _headerAction(
            Icons.sticky_note_2_rounded,
            const Color(0xFF11998E),
            () => context.push(
              '/group/$groupId/notes',
              extra: {'groupName': groupName},
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ─── Body ───────────────────────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<AssignmentModel> assignments,
    List<GroupTaskModel> allTasks,
    String currentUid,
  ) {
    final myTasks =
        allTasks.where((t) => t.assignedTo == currentUid).toList();

    final approvedCount =
        allTasks.where((t) => t.status == GroupTaskStatus.approved).length;
    final totalCount = allTasks.length;
    final progress = totalCount > 0 ? approvedCount / totalCount : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallProgress(progress, approvedCount, totalCount),
          SizedBox(height: 24),

          // ── My Tasks ──
          if (myTasks.isNotEmpty) ...[
            _sectionHeader(
              Icons.person_rounded,
              'My Tasks',
              AppColors.primary,
              '${myTasks.where((t) => t.status == GroupTaskStatus.approved).length}/${myTasks.length} done',
            ),
            SizedBox(height: 10),
            ...myTasks.map((task) => _buildMyTaskTile(context, task)),
            SizedBox(height: 24),
          ],

          // ── Assignments ──
          if (assignments.isNotEmpty) ...[
            _sectionHeader(
              Icons.assignment_rounded,
              'Assignments',
              const Color(0xFFE65100),
              '${assignments.length}',
            ),
            SizedBox(height: 10),
            ...assignments.map(
              (a) => _buildAssignmentCard(context, a, allTasks),
            ),
            SizedBox(height: 24),
          ],

          // ── Member Tasks Table ──
          if (allTasks.isNotEmpty) ...[
            _sectionHeader(
              Icons.groups_rounded,
              'Member Tasks',
              const Color(0xFF667EEA),
              '${allTasks.length} tasks',
            ),
            SizedBox(height: 10),
            _buildMemberTasksTable(context, allTasks, currentUid),
          ],

          if (allTasks.isEmpty && assignments.isEmpty)
            _buildEmptyState(context),
        ],
      ),
    );
  }

  // ─── Overall Progress ───────────────────────────────────────────
  Widget _buildOverallProgress(
    double progress,
    int approvedCount,
    int totalCount,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
                      'Team Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$approvedCount of $totalCount tasks completed',
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── My Task Tile ───────────────────────────────────────────────
  Widget _buildMyTaskTile(BuildContext context, GroupTaskModel task) {
    final sc = _getStatusConfig(task.status);
    final isCompleted = task.status == GroupTaskStatus.approved;
    final hasSubmission = task.submissionUrl != null;

    return GestureDetector(
      onTap: () {
        if (task.assignmentId != null && task.assignmentId!.isNotEmpty) {
          context.push(
            '/assignment/${task.assignmentId}/task/${task.id}',
            extra: {'groupId': groupId},
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadows,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sc.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(sc.icon, color: sc.color, size: 20),
            ),
            SizedBox(width: 14),
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
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sc.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sc.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: sc.color,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'YOUR TASK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isCompleted || hasSubmission)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF11998E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded,
                        size: 16, color: Color(0xFF11998E)),
                    SizedBox(width: 4),
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11998E),
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Member Tasks Table ─────────────────────────────────────────
  Widget _buildMemberTasksTable(
    BuildContext context,
    List<GroupTaskModel> allTasks,
    String currentUid,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          // ── Table Header ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'MEMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ASSIGNED TASK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'SUBMISSION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.bgColor),
          // ── Table Rows ──
          ...allTasks.asMap().entries.map((entry) {
            final idx = entry.key;
            final task = entry.value;
            final isMe = task.assignedTo == currentUid;
            final isLast = idx == allTasks.length - 1;
            return _buildTableRow(context, task, isMe, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    GroupTaskModel task,
    bool isMe,
    bool isLast,
  ) {
    final sc = _getStatusConfig(task.status);
    final isCompleted = task.status == GroupTaskStatus.approved;
    final hasSubmission = task.submissionUrl != null;
    final initial = isMe
        ? 'Me'
        : (task.assignedTo.isNotEmpty
            ? task.assignedTo[0].toUpperCase()
            : '?');

    return GestureDetector(
      onTap: () {
        if (task.assignmentId != null && task.assignmentId!.isNotEmpty) {
          context.push(
            '/assignment/${task.assignmentId}/task/${task.id}',
            extra: {'groupId': groupId},
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.03)
              : Colors.transparent,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: AppColors.bgColor, width: 1),
                ),
          borderRadius: isLast
              ? BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                )
              : null,
        ),
        child: Row(
          children: [
            // ── MEMBER ──
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isMe
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.bgColor,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMe ? 10 : 14,
                          color: isMe
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMe ? 'You' : _shortenId(task.assignedTo),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.description.isNotEmpty)
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── ASSIGNED TASK ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // ── STATUS ──
            SizedBox(
              width: 82,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: sc.bg,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: sc.color.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    sc.shortLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: sc.color,
                    ),
                  ),
                ),
              ),
            ),
            // ── SUBMISSION ──
            SizedBox(
              width: 90,
              child: isCompleted || hasSubmission
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded,
                            size: 15, color: const Color(0xFF11998E)),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'View Done Task',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF11998E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'In progress...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────
  Widget _sectionHeader(
      IconData icon, String title, Color color, String badge) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Assignment Card ────────────────────────────────────────────
  Widget _buildAssignmentCard(
    BuildContext context,
    AssignmentModel assignment,
    List<GroupTaskModel> allTasks,
  ) {
    final assignmentTasks =
        allTasks.where((t) => t.assignmentId == assignment.id).toList();
    final approved = assignmentTasks
        .where((t) => t.status == GroupTaskStatus.approved)
        .length;
    final total = assignmentTasks.length;
    final progress = total > 0 ? approved / total : 0.0;

    final statusColor = assignment.isCompleted
        ? AppColors.priorityLowText
        : assignment.isCompilationPhase
            ? const Color(0xFFE65100)
            : AppColors.primary;
    final statusLabel = assignment.isCompleted
        ? 'DONE'
        : assignment.isCompilationPhase
            ? 'COMPILING'
            : 'ACTIVE';

    return GestureDetector(
      onTap: () => context.push(
        '/assignment/${assignment.id}',
        extra: {'groupId': groupId},
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_rounded,
                      color: statusColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (assignment.subject.isNotEmpty)
                        Text(
                          assignment.subject,
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.bgColor,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  '$approved/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (assignment.dueDate != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Due ${DateFormat('MMM dd').format(assignment.dueDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (assignment.originalPdfUrl != null) ...[
                    const Spacer(),
                    Icon(Icons.picture_as_pdf_rounded,
                        size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'PDF attached',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadows,
            ),
            child: Icon(Icons.assignment_outlined,
                size: 36, color: AppColors.textSecondary),
          ),
          SizedBox(height: 20),
          Text(
            'No assignments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a task to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────
  String _shortenId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  _StatusConfig _getStatusConfig(GroupTaskStatus status) {
    switch (status) {
      case GroupTaskStatus.pending:
        return _StatusConfig('Pending', 'Pending', AppColors.bgColor,
            AppColors.textSecondary, Icons.schedule_rounded);
      case GroupTaskStatus.inProgress:
        return _StatusConfig('In Progress', 'In Progress',
            const Color(0xFFE3F2FD), const Color(0xFF1565C0),
            Icons.play_circle_rounded);
      case GroupTaskStatus.pendingApproval:
        return _StatusConfig('Awaiting Review', 'In Review',
            const Color(0xFFFFF3E0), const Color(0xFFE65100),
            Icons.hourglass_top_rounded);
      case GroupTaskStatus.changesRequested:
        return _StatusConfig('Changes Needed', 'Changes',
            AppColors.priorityHighBg, AppColors.priorityHighText,
            Icons.edit_rounded);
      case GroupTaskStatus.approved:
        return _StatusConfig('Completed', 'Completed',
            AppColors.priorityLowBg, AppColors.priorityLowText,
            Icons.check_circle_rounded);
      default:
        return _StatusConfig('Unknown', 'Unknown', AppColors.bgColor,
            AppColors.textSecondary, Icons.help_rounded);
    }
  }
}

class _StatusConfig {
  final String label;
  final String shortLabel;
  final Color bg;
  final Color color;
  final IconData icon;
  _StatusConfig(this.label, this.shortLabel, this.bg, this.color, this.icon);
}
