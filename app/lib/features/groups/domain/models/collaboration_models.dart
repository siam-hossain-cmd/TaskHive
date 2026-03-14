import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced group message with @mentions, file sharing, and message types
enum GroupMessageType { text, image, file, system, poll }

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final GroupMessageType messageType;
  final DateTime timestamp;
  final List<String> mentions; // UIDs of mentioned users
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToId; // Reply threading
  final String? replyToText;
  final String? replyToSender;

  GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    this.messageType = GroupMessageType.text,
    required this.timestamp,
    this.mentions = const [],
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
  });

  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessageModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      text: data['text'] ?? '',
      messageType: GroupMessageType.values.firstWhere(
        (e) => e.name == data['messageType'],
        orElse: () => GroupMessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mentions: List<String>.from(data['mentions'] ?? []),
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToSender: data['replyToSender'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'messageType': messageType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'mentions': mentions,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
    };
  }
}

/// Shared note in a group
class SharedNoteModel {
  final String id;
  final String groupId;
  final String createdBy;
  final String creatorName;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastEditedBy;
  final bool isPinned;

  SharedNoteModel({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.creatorName,
    required this.title,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
    this.lastEditedBy,
    this.isPinned = false,
  });

  factory SharedNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedNoteModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastEditedBy: data['lastEditedBy'],
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastEditedBy': lastEditedBy,
      'isPinned': isPinned,
    };
  }

  SharedNoteModel copyWith({
    String? id,
    String? groupId,
    String? createdBy,
    String? creatorName,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastEditedBy,
    bool? isPinned,
  }) {
    return SharedNoteModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

/// Poll model for group voting
class PollModel {
  final String id;
  final String groupId;
  final String createdBy;
  final String creatorName;
  final String question;
  final List<PollOption> options;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool allowMultipleVotes;

  PollModel({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.creatorName,
    required this.question,
    required this.options,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.allowMultipleVotes = false,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes.length);

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final optionsList = (data['options'] as List<dynamic>? ?? [])
        .map((o) => PollOption.fromMap(o as Map<String, dynamic>))
        .toList();
    return PollModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      question: data['question'] ?? '',
      options: optionsList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      allowMultipleVotes: data['allowMultipleVotes'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'question': question,
      'options': options.map((o) => o.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'allowMultipleVotes': allowMultipleVotes,
    };
  }

  PollModel copyWith({String? id, List<PollOption>? options, bool? isActive}) {
    return PollModel(
      id: id ?? this.id,
      groupId: groupId,
      createdBy: createdBy,
      creatorName: creatorName,
      question: question,
      options: options ?? this.options,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: isActive ?? this.isActive,
      allowMultipleVotes: allowMultipleVotes,
    );
  }
}

class PollOption {
  final String text;
  final List<String> votes; // UIDs

  PollOption({required this.text, this.votes = const []});

  factory PollOption.fromMap(Map<String, dynamic> data) {
    return PollOption(
      text: data['text'] ?? '',
      votes: List<String>.from(data['votes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'votes': votes};
  }
}
