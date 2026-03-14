import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/collaboration_repository.dart';
import '../../domain/models/collaboration_models.dart';

final collaborationRepositoryProvider = Provider<CollaborationRepository>((
  ref,
) {
  return CollaborationRepository();
});

// ─── Group Chat Providers ────────────────────────────────────────────────────

/// Enhanced group messages stream
final groupChatMessagesProvider =
    StreamProvider.family<List<GroupMessageModel>, String>((ref, groupId) {
      return ref
          .read(collaborationRepositoryProvider)
          .getGroupMessages(groupId);
    });

// ─── Shared Notes Providers ──────────────────────────────────────────────────

/// Shared notes for a group
final sharedNotesProvider =
    StreamProvider.family<List<SharedNoteModel>, String>((ref, groupId) {
      return ref.read(collaborationRepositoryProvider).getSharedNotes(groupId);
    });

// ─── Polls Providers ─────────────────────────────────────────────────────────

/// Polls for a group
final groupPollsProvider = StreamProvider.family<List<PollModel>, String>((
  ref,
  groupId,
) {
  return ref.read(collaborationRepositoryProvider).getPolls(groupId);
});

/// Active polls count
final activePollsCountProvider = Provider.family<int, String>((ref, groupId) {
  final polls = ref.watch(groupPollsProvider(groupId));
  return polls.when(
    data: (list) => list.where((p) => p.isActive && !p.isExpired).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ─── Collaboration Notifier ─────────────────────────────────────────────────

class CollaborationNotifier extends StateNotifier<AsyncValue<void>> {
  final CollaborationRepository _repository;

  CollaborationNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Send a text message with optional mentions
  Future<void> sendTextMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String text,
    List<String> mentions = const [],
    String? replyToId,
    String? replyToText,
    String? replyToSender,
  }) async {
    try {
      await _repository.sendMessage(
        GroupMessageModel(
          id: '',
          groupId: groupId,
          senderId: senderId,
          senderName: senderName,
          senderPhotoUrl: senderPhotoUrl,
          text: text,
          messageType: GroupMessageType.text,
          timestamp: DateTime.now(),
          mentions: mentions,
          replyToId: replyToId,
          replyToText: replyToText,
          replyToSender: replyToSender,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send an image message
  Future<void> sendImage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required File imageFile,
    String caption = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendImageMessage(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        imageFile: imageFile,
        caption: caption,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send a file message
  Future<void> sendFile({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required File file,
    required String fileName,
    required int fileSize,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendFileMessage(
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        file: file,
        fileName: fileName,
        fileSize: fileSize,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a shared note
  Future<SharedNoteModel?> createNote({
    required String groupId,
    required String createdBy,
    required String creatorName,
    required String title,
    String content = '',
  }) async {
    try {
      final now = DateTime.now();
      return await _repository.createNote(
        SharedNoteModel(
          id: '',
          groupId: groupId,
          createdBy: createdBy,
          creatorName: creatorName,
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update a shared note
  Future<void> updateNote(SharedNoteModel note) async {
    try {
      await _repository.updateNote(note.copyWith(updatedAt: DateTime.now()));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a shared note
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle note pin
  Future<void> togglePin(String noteId, bool isPinned) async {
    try {
      await _repository.togglePinNote(noteId, isPinned);
    } catch (e) {
      // silent
    }
  }

  /// Create a poll
  Future<PollModel?> createPoll({
    required String groupId,
    required String createdBy,
    required String creatorName,
    required String question,
    required List<String> optionTexts,
    DateTime? expiresAt,
    bool allowMultiple = false,
  }) async {
    try {
      final poll = PollModel(
        id: '',
        groupId: groupId,
        createdBy: createdBy,
        creatorName: creatorName,
        question: question,
        options: optionTexts.map((t) => PollOption(text: t)).toList(),
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        allowMultipleVotes: allowMultiple,
      );
      return await _repository.createPoll(poll);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Vote on a poll
  Future<void> vote(String pollId, int optionIndex, String userId) async {
    try {
      await _repository.vote(pollId, optionIndex, userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Close a poll
  Future<void> closePoll(String pollId) async {
    try {
      await _repository.closePoll(pollId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final collaborationNotifierProvider =
    StateNotifierProvider<CollaborationNotifier, AsyncValue<void>>((ref) {
      return CollaborationNotifier(ref.read(collaborationRepositoryProvider));
    });
