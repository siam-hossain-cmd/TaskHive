import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/collaboration_models.dart';
import '../providers/collaboration_providers.dart';

class PollsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const PollsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  @override
  Widget build(BuildContext context) {
    final pollsAsync = ref.watch(groupPollsProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: pollsAsync.when(
                data: (polls) {
                  if (polls.isEmpty) return _buildEmpty();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: polls.length,
                    itemBuilder: (_, index) =>
                        _PollCard(poll: polls[index], groupId: widget.groupId),
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
        onPressed: () => _showCreatePollDialog(),
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
                  'Polls',
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
          Icon(Icons.poll_rounded, size: 22, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.poll_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No polls yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a poll for your team',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCreatePollDialog() {
    final questionCtrl = TextEditingController();
    final optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    bool allowMultiple = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Create Poll',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionCtrl,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Poll question',
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
                ...optionControllers.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entry.value,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Option ${entry.key + 1}',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.bgColor,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                optionControllers.removeAt(entry.key);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    if (optionControllers.length < 6) {
                      setDialogState(() {
                        optionControllers.add(TextEditingController());
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add Option',
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: allowMultiple,
                      onChanged: (v) => setDialogState(() => allowMultiple = v),
                      activeTrackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Allow multiple votes',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                final question = questionCtrl.text.trim();
                final options = optionControllers
                    .map((c) => c.text.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                if (question.isEmpty || options.length < 2) return;
                final user = ref.read(authStateProvider).valueOrNull;
                if (user == null) return;

                ref
                    .read(collaborationNotifierProvider.notifier)
                    .createPoll(
                      groupId: widget.groupId,
                      createdBy: user.uid,
                      creatorName: user.displayName ?? 'Unknown',
                      question: question,
                      optionTexts: options,
                      allowMultiple: allowMultiple,
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
      ),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final PollModel poll;
  final String groupId;

  const _PollCard({required this.poll, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final userId = currentUser?.uid ?? '';
    final totalVotes = poll.options.fold<int>(0, (s, o) => s + o.votes.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.poll_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  poll.question,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!poll.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Closed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Options
          ...poll.options.asMap().entries.map((entry) {
            final option = entry.value;
            final hasVoted = option.votes.contains(userId);
            final voteCount = option.votes.length;
            final pct = totalVotes > 0 ? voteCount / totalVotes : 0.0;

            return GestureDetector(
              onTap: poll.isActive
                  ? () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(collaborationNotifierProvider.notifier)
                          .vote(poll.id, entry.key, userId);
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: hasVoted
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasVoted
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: hasVoted ? 1.5 : 0,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Vote indicator
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasVoted
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: hasVoted
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.3,
                                    ),
                              width: 2,
                            ),
                          ),
                          child: hasVoted
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasVoted
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$voteCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: hasVoted
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: AppColors.textSecondary.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation(
                          hasVoted
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (poll.allowMultipleVotes) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Multi-vote',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                DateFormat('MMM d').format(poll.createdAt),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
