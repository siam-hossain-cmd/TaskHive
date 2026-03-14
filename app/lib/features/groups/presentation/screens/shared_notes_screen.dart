import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/collaboration_models.dart';
import '../providers/collaboration_providers.dart';

class SharedNotesScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const SharedNotesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<SharedNotesScreen> createState() => _SharedNotesScreenState();
}

class _SharedNotesScreenState extends ConsumerState<SharedNotesScreen> {
  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(sharedNotesProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) return _buildEmpty();
                  // Pinned first, then by updatedAt
                  final sorted = [...notes];
                  sorted.sort((a, b) {
                    if (a.isPinned && !b.isPinned) return -1;
                    if (!a.isPinned && b.isPinned) return 1;
                    return b.updatedAt.compareTo(a.updatedAt);
                  });
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: sorted.length,
                    itemBuilder: (_, index) =>
                        _NoteTile(note: sorted[index], groupId: widget.groupId),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateNoteDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shared Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.groupName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.note_alt_rounded, size: 22, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No shared notes yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a note for your team',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'New Note',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Note title',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.bgColor,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Write your note...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.bgColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text.trim();
              if (title.isEmpty) return;
              final user = ref.read(authStateProvider).valueOrNull;
              if (user == null) return;

              ref
                  .read(collaborationNotifierProvider.notifier)
                  .createNote(
                    groupId: widget.groupId,
                    createdBy: user.uid,
                    creatorName: user.displayName ?? 'Unknown',
                    title: title,
                    content: content,
                  );
              Navigator.pop(ctx);
            },
            child: const Text(
              'Create',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends ConsumerWidget {
  final SharedNoteModel note;
  final String groupId;

  const _NoteTile({required this.note, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('MMM d, h:mm a').format(note.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
        border: note.isPinned
            ? Border.all(color: AppColors.warning.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned) ...[
                Icon(
                  Icons.push_pin_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Pin toggle
              GestureDetector(
                onTap: () {
                  ref
                      .read(collaborationNotifierProvider.notifier)
                      .togglePin(note.id, !note.isPinned);
                },
                child: Icon(
                  note.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 18,
                  color: note.isPinned
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              // Delete
              GestureDetector(
                onTap: () {
                  ref
                      .read(collaborationNotifierProvider.notifier)
                      .deleteNote(note.id);
                },
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.content,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Updated $time',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
