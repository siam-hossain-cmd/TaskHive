import 'package:cloud_firestore/cloud_firestore.dart';

enum PermissionMode { democratic, leader }

enum GroupTaskStatus {
  pending,
  inProgress,
  submitted,
  pendingApproval,
  changesRequested,
  approved,
  rejected,
}

class GroupModel {
  final String id;
  final String name;
  final String leaderId;
  final List<String> memberIds;
  final PermissionMode permissionMode;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.memberIds,
    this.permissionMode = PermissionMode.leader,
    required this.createdAt,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      leaderId: data['leaderId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      permissionMode: PermissionMode.values.firstWhere(
        (e) => e.name == data['permissionMode'],
        orElse: () => PermissionMode.leader,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'permissionMode': permissionMode.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? leaderId,
    List<String>? memberIds,
    PermissionMode? permissionMode,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      leaderId: leaderId ?? this.leaderId,
      memberIds: memberIds ?? this.memberIds,
      permissionMode: permissionMode ?? this.permissionMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupTaskModel {
  final String id;
  final String groupId;
  final String? assignmentId;
  final String assignedTo;
  final String assignedBy;
  final String title;
  final String description;
  final GroupTaskStatus status;
  final String? rejectionFeedback;
  final List<String> attachments;
  final String? submissionUrl;
  final String? submissionFileName;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime dueDate;
  final String priority;
  final DateTime createdAt;

  GroupTaskModel({
    required this.id,
    required this.groupId,
    this.assignmentId,
    required this.assignedTo,
    required this.assignedBy,
    required this.title,
    this.description = '',
    this.status = GroupTaskStatus.pending,
    this.rejectionFeedback,
    this.attachments = const [],
    this.submissionUrl,
    this.submissionFileName,
    this.submittedAt,
    this.approvedAt,
    required this.dueDate,
    this.priority = 'medium',
    required this.createdAt,
  });

  bool get isOverdue =>
      status != GroupTaskStatus.approved && DateTime.now().isAfter(dueDate);

  factory GroupTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupTaskModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      assignmentId: data['assignmentId'],
      assignedTo: data['assignedTo'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: GroupTaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GroupTaskStatus.pending,
      ),
      rejectionFeedback: data['rejectionFeedback'],
      attachments: List<String>.from(data['attachments'] ?? []),
      submissionUrl: data['submissionUrl'],
      submissionFileName: data['submissionFileName'],
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] is Timestamp
                ? (data['submittedAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['submittedAt'].toString()))
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] is Timestamp
                ? (data['approvedAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['approvedAt'].toString()))
          : null,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: data['priority'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'assignmentId': assignmentId,
      'assignedTo': assignedTo,
      'assignedBy': assignedBy,
      'title': title,
      'description': description,
      'status': status.name,
      'rejectionFeedback': rejectionFeedback,
      'attachments': attachments,
      'submissionUrl': submissionUrl,
      'submissionFileName': submissionFileName,
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupTaskModel copyWith({
    String? id,
    String? groupId,
    String? assignmentId,
    String? assignedTo,
    String? assignedBy,
    String? title,
    String? description,
    GroupTaskStatus? status,
    String? rejectionFeedback,
    List<String>? attachments,
    String? submissionUrl,
    String? submissionFileName,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? dueDate,
    String? priority,
    DateTime? createdAt,
  }) {
    return GroupTaskModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      assignmentId: assignmentId ?? this.assignmentId,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      rejectionFeedback: rejectionFeedback ?? this.rejectionFeedback,
      attachments: attachments ?? this.attachments,
      submissionUrl: submissionUrl ?? this.submissionUrl,
      submissionFileName: submissionFileName ?? this.submissionFileName,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ActivityLogModel {
  final String id;
  final String groupId;
  final String userId;
  final String action;
  final String? targetUserId;
  final String? taskId;
  final DateTime timestamp;
  final String details;

  ActivityLogModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.action,
    this.targetUserId,
    this.taskId,
    required this.timestamp,
    required this.details,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      targetUserId: data['targetUserId'],
      taskId: data['taskId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'action': action,
      'targetUserId': targetUserId,
      'taskId': taskId,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}

class MessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
