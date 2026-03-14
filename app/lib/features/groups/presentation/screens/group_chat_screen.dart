import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/collaboration_models.dart';
import '../providers/collaboration_providers.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    ref
        .read(collaborationNotifierProvider.notifier)
        .sendTextMessage(
          groupId: widget.groupId,
          senderId: user.uid,
          senderName: user.displayName ?? 'Unknown',
          text: text,
        );
    _msgController.clear();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    ref
        .read(collaborationNotifierProvider.notifier)
        .sendImage(
          groupId: widget.groupId,
          senderId: user.uid,
          senderName: user.displayName ?? 'Unknown',
          imageFile: File(img.path),
        );
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    ref
        .read(collaborationNotifierProvider.notifier)
        .sendFile(
          groupId: widget.groupId,
          senderId: user.uid,
          senderName: user.displayName ?? 'Unknown',
          file: File(file.path!),
          fileName: file.name,
          fileSize: file.size,
        );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupChatMessagesProvider(widget.groupId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUser?.uid;
                      final showSender =
                          !isMe &&
                          (index == messages.length - 1 ||
                              messages[index + 1].senderId != msg.senderId);
                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showSender: showSender,
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
                  widget.groupName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Group Chat',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Notes Button
          GestureDetector(
            onTap: () => context.push(
              '/group/${widget.groupId}/notes',
              extra: widget.groupName,
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.note_alt_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Polls Button
          GestureDetector(
            onTap: () => context.push(
              '/group/${widget.groupId}/polls',
              extra: widget.groupName,
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.poll_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: AppTheme.softShadows,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachments
            GestureDetector(
              onTap: () => _showAttachOptions(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_file_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text Input
            Expanded(
              child: TextField(
                controller: _msgController,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.bgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                'Send Image',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _sendImage();
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.file_present_rounded,
                  color: AppColors.warning,
                ),
              ),
              title: Text(
                'Send File',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _sendFile();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessageModel message;
  final bool isMe;
  final bool showSender;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.timestamp);

    if (message.messageType == GroupMessageType.system) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showSender && !isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isMe ? null : AppTheme.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply
                  if (message.replyToText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.15)
                            : AppColors.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.replyToSender ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isMe ? Colors.white70 : AppColors.primary,
                            ),
                          ),
                          Text(
                            message.replyToText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isMe
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Image
                  if (message.messageType == GroupMessageType.image &&
                      message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 200,
                          height: 100,
                          color: AppColors.bgColor,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // File
                  if (message.messageType == GroupMessageType.file &&
                      message.fileName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_present_rounded,
                            size: 20,
                            color: isMe ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.fileName!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isMe
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Text
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
