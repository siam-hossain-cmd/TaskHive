import 'package:cloud_firestore/cloud_firestore.dart';

class SubtaskModel {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? completedAt;

  SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory SubtaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubtaskModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory SubtaskModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return SubtaskModel(
      id: id,
      taskId: data['taskId'] ?? '',
      title: data['title'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['completedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  SubtaskModel copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
