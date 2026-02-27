import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCommentModel {
  final String id;
  final String taskId;
  final String groupId;
  final String userId;
  final String userName;
  final String text;
  final String type; // "review" | "suggestion" | "general"
  final DateTime createdAt;

  TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.text,
    this.type = 'general',
    required this.createdAt,
  });

  factory TaskCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCommentModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'general',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['createdAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
    );
  }

  factory TaskCommentModel.fromJson(Map<String, dynamic> data) {
    return TaskCommentModel(
      id: data['id'] ?? '',
      taskId: data['taskId'] ?? '',
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      text: data['text'] ?? '',
      type: data['type'] ?? 'general',
      createdAt: data['createdAt'] != null
          ? (DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskCommentModel copyWith({
    String? id,
    String? taskId,
    String? groupId,
    String? userId,
    String? userName,
    String? text,
    String? type,
    DateTime? createdAt,
  }) {
    return TaskCommentModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
