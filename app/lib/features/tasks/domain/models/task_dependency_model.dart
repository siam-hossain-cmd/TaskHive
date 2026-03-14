import 'package:cloud_firestore/cloud_firestore.dart';

enum DependencyType { blockedBy, blocks }

class TaskDependencyModel {
  final String id;
  final String taskId;
  final String dependsOnTaskId;
  final DateTime createdAt;

  TaskDependencyModel({
    required this.id,
    required this.taskId,
    required this.dependsOnTaskId,
    required this.createdAt,
  });

  factory TaskDependencyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskDependencyModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      dependsOnTaskId: data['dependsOnTaskId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'dependsOnTaskId': dependsOnTaskId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskDependencyModel copyWith({
    String? id,
    String? taskId,
    String? dependsOnTaskId,
    DateTime? createdAt,
  }) {
    return TaskDependencyModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
