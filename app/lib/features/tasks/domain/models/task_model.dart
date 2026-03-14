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

  // Subtask tracking
  final int subtaskCount;
  final int subtaskCompleted;

  // Time tracking
  final int totalTimeSpent; // seconds
  final bool isTimerRunning;

  // Dependencies
  final List<String> dependsOn; // task IDs this task depends on
  final List<String> blockedBy; // task IDs blocking this task

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
    this.subtaskCount = 0,
    this.subtaskCompleted = 0,
    this.totalTimeSpent = 0,
    this.isTimerRunning = false,
    this.dependsOn = const [],
    this.blockedBy = const [],
  });

  bool get isOverdue =>
      status != TaskStatus.completed && DateTime.now().isAfter(dueDate);

  bool get isPersonal => groupId == null;

  bool get isBlocked => blockedBy.isNotEmpty;

  double get subtaskProgress =>
      subtaskCount > 0 ? subtaskCompleted / subtaskCount : 0.0;

  String get formattedTimeSpent {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

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
      subtaskCount: data['subtaskCount'] ?? 0,
      subtaskCompleted: data['subtaskCompleted'] ?? 0,
      totalTimeSpent: data['totalTimeSpent'] ?? 0,
      isTimerRunning: data['isTimerRunning'] ?? false,
      dependsOn: List<String>.from(data['dependsOn'] ?? []),
      blockedBy: List<String>.from(data['blockedBy'] ?? []),
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
      'subtaskCount': subtaskCount,
      'subtaskCompleted': subtaskCompleted,
      'totalTimeSpent': totalTimeSpent,
      'isTimerRunning': isTimerRunning,
      'dependsOn': dependsOn,
      'blockedBy': blockedBy,
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
    int? subtaskCount,
    int? subtaskCompleted,
    int? totalTimeSpent,
    bool? isTimerRunning,
    List<String>? dependsOn,
    List<String>? blockedBy,
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
      subtaskCount: subtaskCount ?? this.subtaskCount,
      subtaskCompleted: subtaskCompleted ?? this.subtaskCompleted,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      dependsOn: dependsOn ?? this.dependsOn,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }
}
