import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/friend_model.dart';
import '../providers/friend_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/domain/models/task_model.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  final String friendUid;
  final FriendModel? friend;

  const FriendChatScreen({
    super.key,
    required this.friendUid,
    this.friend,
  });

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showTasks = false;

  String get _chatId => FriendMessageModel.buildChatId(
      FirebaseAuth.instance.currentUser?.uid ?? '', widget.friendUid);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markRead() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.read(friendRepositoryProvider).markMessagesRead(_chatId, uid);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _msgCtrl.clear();

    final msg = FriendMessageModel(
      id: '',
      chatId: _chatId,
      senderId: user.uid,
      senderName: user.displayName ?? user.email ?? 'Me',
      text: text,
      timestamp: DateTime.now(),
    );

    await ref.read(friendChatNotifierProvider.notifier).sendMessage(msg);

    // Local push notification simulation (to show the feature)
    _triggerLocalNotification(
      title: 'New message from ${user.displayName ?? "You"}',
      body: text,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _triggerLocalNotification({required String title, required String body}) {
    const androidDetails = AndroidNotificationDetails(
      'friend_chat', 'Friend Messages',
      importance: Importance.high, priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    FlutterLocalNotificationsPlugin().show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body, details,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final messagesAsync = ref.watch(friendMessagesProvider(_chatId));
    final friend = widget.friend;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(friend),
            if (_showTasks) _SharedTasksPanel(
              myUid: me?.uid ?? '',
              friendUid: widget.friendUid,
            ),
            Expanded(
              child: messagesAsync.when(
                data: (msgs) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                  if (msgs.isEmpty) return _buildEmptyChat();
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) {
                      final msg = msgs[i];
                      final isMe = msg.senderId == me?.uid;
                      final showDate = i == 0 ||
                          !_isSameDay(msgs[i - 1].timestamp, msg.timestamp);
                      return Column(
                        children: [
                          if (showDate) _DateDivider(date: msg.timestamp),
                          _MessageBubble(msg: msg, isMe: isMe),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildHeader(FriendModel? friend) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgColor, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          if (friend != null)
            _ChatAvatar(name: friend.friendName, photoUrl: friend.friendPhotoUrl, size: 42)
          else
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                  gradient: AppColors.gradientPurpleBlue, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: AppColors.primary, size: 22),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend?.friendName ?? widget.friendUid.substring(0, 8),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.priorityLowText, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('Active now', style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          // Toggle shared tasks panel
          GestureDetector(
            onTap: () => setState(() => _showTasks = !_showTasks),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _showTasks ? AppColors.primary.withValues(alpha: 0.12) : AppColors.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.task_alt_rounded,
                  size: 20,
                  color: _showTasks ? AppColors.primary : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: _invertedShadows(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                gradient: AppColors.gradientPurpleBlue, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Start a conversation!', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Say hello to your friend 👋', style: TextStyle(
              fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<BoxShadow> _invertedShadows() => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, -8)),
  ];
}

// ═════════════════════ Message Bubble ══════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final FriendMessageModel msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _ChatAvatar(name: msg.senderName, photoUrl: null, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF7C7DFF)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : AppColors.surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: isMe ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ] : AppTheme.softShadows,
                  ),
                  child: Text(msg.text, style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    height: 1.4,
                  )),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(msg.timestamp),
                      style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 12, color: AppColors.primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ═════════════════════ Date Divider ═══════════════════════════════════════════
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String get _label {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Today';
    final diff = now.difference(date).inDays;
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.bgColor, thickness: 1.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
              ),
              child: Text(_label, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary,
              )),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.bgColor, thickness: 1.5)),
        ],
      ),
    );
  }
}

// ═════════════════════ Shared Tasks Panel ════════════════════════════════════
class _SharedTasksPanel extends ConsumerWidget {
  final String myUid;
  final String friendUid;
  const _SharedTasksPanel({required this.myUid, required this.friendUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(userTasksProvider);
    return tasksAsync.when(
      data: (allTasks) {
        // Show tasks where assignedTo == friendUid OR tasks by myUid assigned to friend
        // For simplicity: show MY pending/inProgress tasks (shared context)
        final undone = allTasks.where((t) =>
            t.status != TaskStatus.completed).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.task_alt_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Undone Tasks', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
                    )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.priorityHighBg, borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${undone.length}', style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.priorityHighText,
                      )),
                    ),
                  ],
                ),
              ),
              if (undone.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text('All caught up! 🎉', style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
                  )),
                )
              else
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    itemCount: undone.take(10).length,
                    itemBuilder: (ctx, i) => _TaskChip(task: undone[i]),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TaskChip extends StatelessWidget {
  final TaskModel task;
  const _TaskChip({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high: return AppColors.priorityHighText;
      case TaskPriority.medium: return AppColors.priorityMediumText;
      case TaskPriority.low: return AppColors.priorityLowText;
    }
  }

  Color get _priorityBg {
    switch (task.priority) {
      case TaskPriority.high: return AppColors.priorityHighBg;
      case TaskPriority.medium: return AppColors.priorityMediumBg;
      case TaskPriority.low: return AppColors.priorityLowBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _priorityBg, borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(task.title,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _priorityColor)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: _priorityColor),
              const SizedBox(width: 4),
              Text(task.priority.name.toUpperCase(), style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, color: _priorityColor,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────
class _ChatAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  const _ChatAvatar({required this.name, this.photoUrl, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(photoUrl!));
    }
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
          gradient: AppColors.gradientPurpleBlue, shape: BoxShape.circle),
      child: Center(child: Text(_initials, style: TextStyle(
        fontSize: size * 0.35, fontWeight: FontWeight.w900, color: AppColors.primary,
      ))),
    );
  }
}
