import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { active, compilationPhase, completed }

class AssignmentModel {
  final String id;
  final String groupId;
  final String createdBy;
  final String title;
  final String subject;
  final String summary;
  final String? originalPdfUrl;
  final String? finalDocUrl;
  final String? finalDocName;
  final String? compilerId;
  final AssignmentStatus status;
  final List<String> subtaskIds;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  AssignmentModel({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    this.subject = '',
    this.summary = '',
    this.originalPdfUrl,
    this.finalDocUrl,
    this.finalDocName,
    this.compilerId,
    this.status = AssignmentStatus.active,
    this.subtaskIds = const [],
    this.dueDate,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == AssignmentStatus.completed;
  bool get isCompilationPhase => status == AssignmentStatus.compilationPhase;

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      summary: data['summary'] ?? '',
      originalPdfUrl: data['originalPdfUrl'],
      finalDocUrl: data['finalDocUrl'],
      finalDocName: data['finalDocName'],
      compilerId: data['compilerId'],
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AssignmentStatus.active,
      ),
      subtaskIds: List<String>.from(data['subtaskIds'] ?? []),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] is Timestamp
                ? (data['dueDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['dueDate'].toString()))
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['createdAt'].toString()) ??
                      DateTime.now())
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] is Timestamp
                ? (data['completedAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['completedAt'].toString()))
          : null,
    );
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> data) {
    return AssignmentModel(
      id: data['id'] ?? '',
      groupId: data['groupId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      summary: data['summary'] ?? '',
      originalPdfUrl: data['originalPdfUrl'],
      finalDocUrl: data['finalDocUrl'],
      finalDocName: data['finalDocName'],
      compilerId: data['compilerId'],
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AssignmentStatus.active,
      ),
      subtaskIds: List<String>.from(data['subtaskIds'] ?? []),
      dueDate: data['dueDate'] != null
          ? DateTime.tryParse(data['dueDate'].toString())
          : null,
      createdAt: data['createdAt'] != null
          ? (DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? DateTime.tryParse(data['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'createdBy': createdBy,
      'title': title,
      'subject': subject,
      'summary': summary,
      'originalPdfUrl': originalPdfUrl,
      'finalDocUrl': finalDocUrl,
      'finalDocName': finalDocName,
      'compilerId': compilerId,
      'status': status.name,
      'subtaskIds': subtaskIds,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? groupId,
    String? createdBy,
    String? title,
    String? subject,
    String? summary,
    String? originalPdfUrl,
    String? finalDocUrl,
    String? finalDocName,
    String? compilerId,
    AssignmentStatus? status,
    List<String>? subtaskIds,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      summary: summary ?? this.summary,
      originalPdfUrl: originalPdfUrl ?? this.originalPdfUrl,
      finalDocUrl: finalDocUrl ?? this.finalDocUrl,
      finalDocName: finalDocName ?? this.finalDocName,
      compilerId: compilerId ?? this.compilerId,
      status: status ?? this.status,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
