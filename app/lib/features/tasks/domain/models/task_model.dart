import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed }

enum RecurrenceRule { daily, weekly, monthly, none }

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String subject;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final bool isRecurring;
  final RecurrenceRule recurrenceRule;
  final List<String> attachments;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? groupId;
  final int estimatedMinutes;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.subject = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.isRecurring = false,
    this.recurrenceRule = RecurrenceRule.none,
    this.attachments = const [],
    this.completedAt,
    required this.createdAt,
    this.groupId,
    this.estimatedMinutes = 60,
  });

  bool get isOverdue =>
      status != TaskStatus.completed && DateTime.now().isAfter(dueDate);

  bool get isPersonal => groupId == null;

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      isRecurring: data['isRecurring'] ?? false,
      recurrenceRule: RecurrenceRule.values.firstWhere(
        (e) => e.name == data['recurrenceRule'],
        orElse: () => RecurrenceRule.none,
      ),
      attachments: List<String>.from(data['attachments'] ?? []),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      groupId: data['groupId'],
      estimatedMinutes: data['estimatedMinutes'] ?? 60,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.name,
      'status': status.name,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule.name,
      'attachments': attachments,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupId': groupId,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? subject,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    bool? isRecurring,
    RecurrenceRule? recurrenceRule,
    List<String>? attachments,
    DateTime? completedAt,
    DateTime? createdAt,
    String? groupId,
    int? estimatedMinutes,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      attachments: attachments ?? this.attachments,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
