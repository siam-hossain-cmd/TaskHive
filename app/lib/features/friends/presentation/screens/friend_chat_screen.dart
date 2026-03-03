import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/friend_model.dart';
import '../providers/friend_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/domain/models/task_model.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  final String friendUid;
  final FriendModel? friend;

  const FriendChatScreen({super.key, required this.friendUid, this.friend});

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showTasks = false;
  bool _isUploadingImage = false;

  String get _chatId => FriendMessageModel.buildChatId(
    FirebaseAuth.instance.currentUser?.uid ?? '',
    widget.friendUid,
  );

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

    // Local push notification simulation
    _triggerLocalNotification(
      title: 'New message from ${user.displayName ?? "You"}',
      body: text,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _showAttachmentMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Send Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF05252).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file_rounded,
                    color: Color(0xFFF05252),
                  ),
                ),
                title: const Text(
                  'File (PDF, DOC, etc.)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;
    if (choice == 'camera') {
      await _sendImage(ImageSource.camera);
    } else if (choice == 'gallery') {
      await _sendImage(ImageSource.gallery);
    } else if (choice == 'file') {
      await _sendFile();
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final imageUrl = await ref
          .read(friendRepositoryProvider)
          .uploadChatImage(_chatId, File(picked.path));

      final msg = FriendMessageModel(
        id: '',
        chatId: _chatId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'Me',
        text: '📷 Photo',
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        messageType: 'image',
      );

      await ref.read(friendChatNotifierProvider.notifier).sendMessage(msg);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final originalName = picked.name;
    final fileSize = picked.size;

    setState(() => _isUploadingImage = true);
    try {
      final fileUrl = await ref
          .read(friendRepositoryProvider)
          .uploadChatFile(_chatId, File(picked.path!), originalName);

      final msg = FriendMessageModel(
        id: '',
        chatId: _chatId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'Me',
        text: '📎 $originalName',
        timestamp: DateTime.now(),
        messageType: 'file',
        fileUrl: fileUrl,
        fileName: originalName,
        fileSize: fileSize,
      );

      await ref.read(friendChatNotifierProvider.notifier).sendMessage(msg);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _triggerLocalNotification({
    required String title,
    required String body,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'friend_chat',
      'Friend Messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    FlutterLocalNotificationsPlugin().show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final messagesAsync = ref.watch(friendMessagesProvider(_chatId));
    final friend = widget.friend;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(friend),
              if (_showTasks)
                _SharedTasksPanel(
                  myUid: me?.uid ?? '',
                  friendUid: widget.friendUid,
                ),
              Expanded(
                child: messagesAsync.when(
                  data: (msgs) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom(),
                    );
                    if (msgs.isEmpty) return _buildEmptyChat();
                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: msgs.length,
                      itemBuilder: (context, i) {
                        final msg = msgs[i];
                        final isMe = msg.senderId == me?.uid;
                        final showDate =
                            i == 0 ||
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
              _buildInputBar(),
            ],
          ),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          if (friend != null)
            _ChatAvatar(
              name: friend.friendName,
              photoUrl: friend.friendPhotoUrl,
              size: 42,
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPurpleBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: AppColors.primary, size: 22),
            ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend?.friendName ?? widget.friendUid.substring(0, 8),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.priorityLowText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Active now',
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
          ),
          // Toggle shared tasks panel
          GestureDetector(
            onTap: () => setState(() => _showTasks = !_showTasks),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showTasks
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 20,
                color: _showTasks ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: _invertedShadows(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          GestureDetector(
            onTap: _isUploadingImage ? null : _showAttachmentMenu,
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                color: _isUploadingImage
                    ? AppColors.textSecondary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isUploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
            ),
          ),
          // Text input
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: 3,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
              cursorColor: AppColors.primary,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: AppColors.bgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPurpleBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Start a conversation!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Say hello to your friend 👋',
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

  List<BoxShadow> _invertedShadows() => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, -8),
    ),
  ];
}

// ═════════════════════ Message Bubble ══════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final FriendMessageModel msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isImage = msg.messageType == 'image' && msg.imageUrl != null;
    final isFile = msg.messageType == 'file' && msg.fileUrl != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _ChatAvatar(name: msg.senderName, photoUrl: null, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (isImage)
                  _ImageBubble(imageUrl: msg.imageUrl!, isMe: isMe)
                else if (isFile)
                  _FileBubble(msg: msg, isMe: isMe)
                else
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF7C7DFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : AppColors.surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : AppTheme.softShadows,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(msg.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
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

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  const _ImageBubble({required this.imageUrl, required this.isMe});

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (ctx, anim, anim2) {
          return FadeTransition(
            opacity: anim,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Hero(
                          tag: 'chat_img_$imageUrl',
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  // Top bar
                  Positioned(
                    top: MediaQuery.of(ctx).padding.top + 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(ctx),
                        ),
                        Row(
                          children: [
                            _CircleButton(
                              icon: Icons.open_in_new_rounded,
                              onTap: () async {
                                final uri = Uri.parse(imageUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.68,
        ),
        decoration: BoxDecoration(
          borderRadius: bubbleRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image
            Hero(
              tag: 'chat_img_$imageUrl',
              child: ClipRRect(
                borderRadius: bubbleRadius,
                child: Image.network(
                  imageUrl,
                  width: 260,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    final pct = progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null;
                    return Container(
                      width: 260,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        borderRadius: bubbleRadius,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: pct,
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                          if (pct != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${(pct * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 260,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: bubbleRadius,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Failed to load',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom gradient overlay with time
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
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

/// Small circular button used in fullscreen image viewer
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final FriendMessageModel msg;
  final bool isMe;
  const _FileBubble({required this.msg, required this.isMe});

  String get _ext {
    final name = msg.fileName ?? '';
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  String get _sizeLabel {
    final bytes = msg.fileSize ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get _fileIcon {
    switch (_ext) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'DOC':
      case 'DOCX':
        return Icons.description_rounded;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart_rounded;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_rounded;
      case 'ZIP':
      case 'RAR':
      case '7Z':
        return Icons.folder_zip_rounded;
      case 'MP3':
      case 'WAV':
      case 'AAC':
      case 'M4A':
        return Icons.audiotrack_rounded;
      case 'MP4':
      case 'MOV':
      case 'AVI':
      case 'MKV':
        return Icons.videocam_rounded;
      case 'TXT':
        return Icons.article_rounded;
      case 'CSV':
        return Icons.table_rows_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get _extColor {
    switch (_ext) {
      case 'PDF':
        return const Color(0xFFE53935);
      case 'DOC':
      case 'DOCX':
        return const Color(0xFF2196F3);
      case 'XLS':
      case 'XLSX':
        return const Color(0xFF4CAF50);
      case 'PPT':
      case 'PPTX':
        return const Color(0xFFFF9800);
      case 'ZIP':
      case 'RAR':
      case '7Z':
        return const Color(0xFF795548);
      case 'MP3':
      case 'WAV':
      case 'AAC':
      case 'M4A':
        return const Color(0xFF9C27B0);
      case 'MP4':
      case 'MOV':
      case 'AVI':
      case 'MKV':
        return const Color(0xFFE91E63);
      case 'TXT':
      case 'CSV':
        return const Color(0xFF607D8B);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return _FileBubbleTappable(
      msg: msg,
      isMe: isMe,
      ext: _ext,
      sizeLabel: _sizeLabel,
      fileIcon: _fileIcon,
      extColor: _extColor,
      bubbleRadius: bubbleRadius,
    );
  }
}

class _FileBubbleTappable extends StatefulWidget {
  final FriendMessageModel msg;
  final bool isMe;
  final String ext;
  final String sizeLabel;
  final IconData fileIcon;
  final Color extColor;
  final BorderRadius bubbleRadius;

  const _FileBubbleTappable({
    required this.msg,
    required this.isMe,
    required this.ext,
    required this.sizeLabel,
    required this.fileIcon,
    required this.extColor,
    required this.bubbleRadius,
  });

  @override
  State<_FileBubbleTappable> createState() => _FileBubbleTappableState();
}

class _FileBubbleTappableState extends State<_FileBubbleTappable> {
  bool _isDownloading = false;
  double _progress = 0;

  Future<void> _openFile() async {
    final url = widget.msg.fileUrl;
    if (url == null) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      // Get temp directory
      final dir = await getTemporaryDirectory();
      final fileName =
          widget.msg.fileName ??
          'file_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${dir.path}/$fileName';

      // Check if already downloaded
      final file = File(filePath);
      if (await file.exists()) {
        setState(() => _isDownloading = false);
        await OpenFilex.open(filePath);
        return;
      }

      // Download the file
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() => _progress = receivedBytes / totalBytes);
        }
      }

      await sink.close();

      if (mounted) setState(() => _isDownloading = false);

      // Open the downloaded file
      await OpenFilex.open(filePath);
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final ext = widget.ext;
    final extColor = widget.extColor;

    return GestureDetector(
      onTap: _isDownloading ? null : _openFile,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceColor,
          borderRadius: widget.bubbleRadius,
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.10)
                : extColor.withValues(alpha: 0.06),
            borderRadius: widget.bubbleRadius,
          ),
          child: Row(
            children: [
              // File type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.18)
                      : extColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.fileIcon,
                  size: 26,
                  color: isMe ? Colors.white : extColor,
                ),
              ),
              const SizedBox(width: 12),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.msg.fileName ?? 'File',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.15)
                                : extColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ext,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : extColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.sizeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.70)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action icon — open for sent, download for received
              _isDownloading
                  ? SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          strokeWidth: 2.5,
                          color: isMe ? Colors.white : extColor,
                        ),
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.15)
                            : extColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMe
                            ? Icons.open_in_new_rounded
                            : Icons.download_rounded,
                        size: 18,
                        color: isMe ? Colors.white : extColor,
                      ),
                    ),
            ],
          ),
        ),
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
    if (date.day == now.day && date.month == now.month && date.year == now.year)
      return 'Today';
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
          Expanded(child: Divider(color: AppColors.bgColor, thickness: 1.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
              ),
              child: Text(
                _label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.bgColor, thickness: 1.5)),
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
        final undone = allTasks
            .where((t) => t.status != TaskStatus.completed)
            .toList();

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
                    Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Undone Tasks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.priorityHighBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${undone.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.priorityHighText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (undone.isEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    'All caught up! 🎉',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _TaskChip extends StatelessWidget {
  final TaskModel task;
  const _TaskChip({required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.priorityHighText;
      case TaskPriority.medium:
        return AppColors.priorityMediumText;
      case TaskPriority.low:
        return AppColors.priorityLowText;
    }
  }

  Color get _priorityBg {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.priorityHighBg;
      case TaskPriority.medium:
        return AppColors.priorityMediumBg;
      case TaskPriority.low:
        return AppColors.priorityLowBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _priorityBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _priorityColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: _priorityColor),
              const SizedBox(width: 4),
              Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _priorityColor,
                ),
              ),
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
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPurpleBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
