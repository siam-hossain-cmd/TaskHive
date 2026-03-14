import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/collaboration_models.dart';

class CollaborationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  //  ENHANCED GROUP CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get group messages (real-time, with enhanced model)
  Stream<List<GroupMessageModel>> getGroupMessages(
    String groupId, {
    int limit = 100,
  }) {
    return _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => GroupMessageModel.fromFirestore(d)).toList(),
        );
  }

  /// Send a text message with optional @mentions and reply
  Future<GroupMessageModel> sendMessage(GroupMessageModel message) async {
    final docRef = await _firestore
        .collection('group_messages')
        .add(message.toFirestore());
    return GroupMessageModel(
      id: docRef.id,
      groupId: message.groupId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderPhotoUrl: message.senderPhotoUrl,
      text: message.text,
      messageType: message.messageType,
      timestamp: message.timestamp,
      mentions: message.mentions,
      replyToId: message.replyToId,
      replyToText: message.replyToText,
      replyToSender: message.replyToSender,
    );
  }

  /// Send image message
  Future<GroupMessageModel> sendImageMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required File imageFile,
    String caption = '',
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
    final ref = _storage.ref('group_chat/$groupId/$fileName');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    final message = GroupMessageModel(
      id: '',
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: caption,
      messageType: GroupMessageType.image,
      timestamp: DateTime.now(),
      imageUrl: url,
    );

    return sendMessage(message);
  }

  /// Send file message
  Future<GroupMessageModel> sendFileMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required File file,
    required String fileName,
    required int fileSize,
  }) async {
    final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref('group_files/$groupId/$storageName');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    final message = GroupMessageModel(
      id: '',
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: '',
      messageType: GroupMessageType.file,
      timestamp: DateTime.now(),
      fileUrl: url,
      fileName: fileName,
      fileSize: fileSize,
    );

    return sendMessage(message);
  }

  /// Parse @mentions from text (format: @UserName)
  List<String> parseMentions(String text, Map<String, String> memberNameToUid) {
    final mentions = <String>[];
    final pattern = RegExp(r'@(\w+(?:\s\w+)*)');
    for (final match in pattern.allMatches(text)) {
      final name = match.group(1);
      if (name != null) {
        // Find matching member
        for (final entry in memberNameToUid.entries) {
          if (entry.key.toLowerCase().contains(name.toLowerCase())) {
            mentions.add(entry.value);
            break;
          }
        }
      }
    }
    return mentions;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED NOTES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all shared notes for a group
  Stream<List<SharedNoteModel>> getSharedNotes(String groupId) {
    return _firestore
        .collection('shared_notes')
        .where('groupId', isEqualTo: groupId)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SharedNoteModel.fromFirestore(d)).toList(),
        );
  }

  /// Create a new shared note
  Future<SharedNoteModel> createNote(SharedNoteModel note) async {
    final docRef = await _firestore
        .collection('shared_notes')
        .add(note.toFirestore());
    return note.copyWith(id: docRef.id);
  }

  /// Update a shared note
  Future<void> updateNote(SharedNoteModel note) async {
    await _firestore
        .collection('shared_notes')
        .doc(note.id)
        .update(note.toFirestore());
  }

  /// Delete a shared note
  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('shared_notes').doc(noteId).delete();
  }

  /// Toggle pin on a note
  Future<void> togglePinNote(String noteId, bool isPinned) async {
    await _firestore.collection('shared_notes').doc(noteId).update({
      'isPinned': isPinned,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  POLLS / VOTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get polls for a group
  Stream<List<PollModel>> getPolls(String groupId) {
    return _firestore
        .collection('polls')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => PollModel.fromFirestore(d)).toList(),
        );
  }

  /// Create a poll
  Future<PollModel> createPoll(PollModel poll) async {
    final docRef = await _firestore.collection('polls').add(poll.toFirestore());
    return poll.copyWith(id: docRef.id);
  }

  /// Vote on a poll option
  Future<void> vote(String pollId, int optionIndex, String userId) async {
    final doc = await _firestore.collection('polls').doc(pollId).get();
    if (!doc.exists) return;

    final poll = PollModel.fromFirestore(doc);
    if (!poll.isActive || poll.isExpired) return;

    final updatedOptions = List<PollOption>.from(poll.options);

    if (!poll.allowMultipleVotes) {
      // Remove user's previous vote from all options
      for (int i = 0; i < updatedOptions.length; i++) {
        final votes = List<String>.from(updatedOptions[i].votes);
        votes.remove(userId);
        updatedOptions[i] = PollOption(
          text: updatedOptions[i].text,
          votes: votes,
        );
      }
    }

    // Add vote to selected option
    final votes = List<String>.from(updatedOptions[optionIndex].votes);
    if (!votes.contains(userId)) {
      votes.add(userId);
      updatedOptions[optionIndex] = PollOption(
        text: updatedOptions[optionIndex].text,
        votes: votes,
      );
    }

    await _firestore.collection('polls').doc(pollId).update({
      'options': updatedOptions.map((o) => o.toMap()).toList(),
    });
  }

  /// Close a poll
  Future<void> closePoll(String pollId) async {
    await _firestore.collection('polls').doc(pollId).update({
      'isActive': false,
    });
  }
}
