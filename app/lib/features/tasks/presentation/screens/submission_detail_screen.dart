import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../groups/domain/models/group_model.dart';
import '../../domain/models/task_comment_model.dart';

import '../providers/assignment_providers.dart';

class SubmissionDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final String taskId;
  final String groupId;

  const SubmissionDetailScreen({
    super.key,
    required this.assignmentId,
    required this.taskId,
    required this.groupId,
  });

  @override
  ConsumerState<SubmissionDetailScreen> createState() =>
      _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState
    extends ConsumerState<SubmissionDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskStream = ref.watch(assignmentTasksProvider(widget.assignmentId));
    final commentsStream = ref.watch(taskCommentsProvider(widget.taskId));
    final user = ref.read(authStateProvider).valueOrNull;
    final currentUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: taskStream.when(
          data: (tasks) {
            final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
            if (task == null) {
              return Center(
                child: Text(
                  'Task not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            final isMyTask = task.assignedTo == currentUid;

            return Column(
              children: [
                _buildHeader(task),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // View Files
                        if (task.submissionUrl != null || task.attachments.isNotEmpty)
                          _buildViewFilesSection(task),
                        if (task.submissionUrl != null || task.attachments.isNotEmpty)
                          const SizedBox(height: 16),

                        // Task Info Card
                        _TaskInfoCard(task: task),
                        const SizedBox(height: 16),

                        // Submission section
                        if (task.submissionUrl != null) ...[
                          _SubmissionCard(task: task),
                          const SizedBox(height: 16),
                        ],

                        // Action buttons
                        if (isMyTask &&
                            (task.status == GroupTaskStatus.pending ||
                                task.status == GroupTaskStatus.inProgress ||
                                task.status ==
                                    GroupTaskStatus.changesRequested))
                          _UploadSubmissionButton(
                            isUploading: _isUploading,
                            onUpload: () => _uploadSubmission(task),
                          ),

                        if (!isMyTask &&
                            task.status == GroupTaskStatus.pendingApproval) ...[
                          const SizedBox(height: 12),
                          _ReviewActions(
                            onApprove: () => _approveTask(task),
                            onRequestChanges: () =>
                                _showRequestChangesDialog(task),
                            isSubmitting: _isSubmitting,
                          ),
                        ],

                        SizedBox(height: 20),

                        // Comments Section
                        Text(
                          'COMMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 10),
                        commentsStream.when(
                          data: (comments) => comments.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No comments yet',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: comments
                                      .map(
                                        (c) => _CommentTile(
                                          comment: c,
                                          isMe: c.userId == currentUid,
                                        ),
                                      )
                                      .toList(),
                                ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment input
                _buildCommentInput(),
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

  Widget _buildHeader(GroupTaskModel task) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
        borderRadius: const BorderRadius.only(
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
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
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

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _commentCtrl,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addComment,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final api = ref.read(apiServiceProvider);
    final result = await api.addTaskComment(taskId: widget.taskId, text: text);

    if (result != null) {
      _commentCtrl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add comment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildViewFilesSection(GroupTaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.submissionUrl != null)
          _buildViewFileButton(
            label: 'View Submission',
            url: task.submissionUrl!,
            icon: Icons.assignment_turned_in_rounded,
          ),
        if (task.submissionUrl != null && task.attachments.isNotEmpty)
          const SizedBox(height: 8),
        ...task.attachments.asMap().entries.map((entry) {
          final url = entry.value;
          final idx = entry.key + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildViewFileButton(
              label: 'Attachment $idx',
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

  Future<void> _uploadSubmission(GroupTaskModel task) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'zip'],
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref(
        'submissions/${widget.groupId}/${widget.taskId}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Submit via API
      final api = ref.read(apiServiceProvider);
      final success = await api.submitTaskWork(
        taskId: widget.taskId,
        submissionUrl: downloadUrl,
        submissionFileName: fileName,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work submitted successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit work'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _approveTask(GroupTaskModel task) async {
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiServiceProvider);
      final success = await api.approveTask(widget.taskId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task approved!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showRequestChangesDialog(GroupTaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Changes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Provide feedback on what needs to be changed.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _feedbackCtrl,
                maxLines: 4,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe what needs to be changed...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final feedback = _feedbackCtrl.text.trim();
                if (feedback.isEmpty) return;
                Navigator.pop(ctx);
                setState(() => _isSubmitting = true);
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.requestTaskChanges(
                    taskId: widget.taskId,
                    feedback: feedback,
                  );
                  _feedbackCtrl.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Changes requested'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  setState(() => _isSubmitting = false);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Request Changes',
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
        ),
      ),
    );
  }
}

// ─── Task Info Card ───────────────────────────────────────────────────────────
class _TaskInfoCard extends StatelessWidget {
  final GroupTaskModel task;
  const _TaskInfoCard({required this.task});

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

    return Container(
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  task.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
              const Spacer(),
              ...[
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd').format(task.dueDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          if (task.description.isNotEmpty) ...[
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 4),
              Text(
                'Assigned to: ${task.assignedTo.length > 18 ? '${task.assignedTo.substring(0, 18)}...' : task.assignedTo}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Submission Card ──────────────────────────────────────────────────────────
class _SubmissionCard extends StatelessWidget {
  final GroupTaskModel task;
  const _SubmissionCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.file_present_rounded,
              color: Color(0xFF1565C0),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submitted Work',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                  ),
                ),
                if (task.submissionFileName != null)
                  Text(
                    task.submissionFileName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1565C0).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (task.submittedAt != null)
                  Text(
                    'Submitted ${DateFormat('MMM dd, h:mm a').format(task.submittedAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF1565C0).withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upload Submission Button ─────────────────────────────────────────────────
class _UploadSubmissionButton extends StatelessWidget {
  final bool isUploading;
  final VoidCallback onUpload;

  const _UploadSubmissionButton({
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onUpload,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isUploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Upload & Submit Work',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Review Actions ───────────────────────────────────────────────────────────
class _ReviewActions extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onRequestChanges;
  final bool isSubmitting;

  const _ReviewActions({
    required this.onApprove,
    required this.onRequestChanges,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: isSubmitting ? null : onRequestChanges,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Text(
                  'Request Changes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: isSubmitting ? null : onApprove,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Approve',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Comment Tile ─────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final TaskCommentModel comment;
  final bool isMe;

  const _CommentTile({required this.comment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isMe ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.userName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatTime(comment.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              comment.text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          if (comment.type != 'general') ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: comment.type == 'review'
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  comment.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: comment.type == 'review'
                        ? const Color(0xFFE65100)
                        : const Color(0xFF1565C0),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(dt);
  }
}
