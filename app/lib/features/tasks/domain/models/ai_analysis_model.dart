/// AI Analysis models used for PDF document analysis and task breakdown.

class AISubTask {
  final String title;
  final String description;
  final String priority; // "high" | "medium" | "low"
  final double estimatedHours;
  final String? suggestedAssigneeId;
  String? assignedToId;
  String? assignedToName;

  AISubTask({
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.estimatedHours = 1.0,
    this.suggestedAssigneeId,
    this.assignedToId,
    this.assignedToName,
  });

  factory AISubTask.fromJson(Map<String, dynamic> json) {
    return AISubTask(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      estimatedHours: (json['estimatedHours'] ?? 1.0).toDouble(),
      suggestedAssigneeId: json['suggestedAssignee'],
      assignedToId: json['assignedToId'],
      assignedToName: json['assignedToName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'estimatedHours': estimatedHours,
      'suggestedAssignee': suggestedAssigneeId,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
    };
  }

  AISubTask copyWith({
    String? title,
    String? description,
    String? priority,
    double? estimatedHours,
    String? suggestedAssigneeId,
    String? assignedToId,
    String? assignedToName,
  }) {
    return AISubTask(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      suggestedAssigneeId: suggestedAssigneeId ?? this.suggestedAssigneeId,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
    );
  }
}

class AIAnalysisResult {
  final String title;
  final String subject;
  final String summary;
  final List<AISubTask> subtasks;
  final String? conversationId;

  AIAnalysisResult({
    required this.title,
    this.subject = '',
    this.summary = '',
    required this.subtasks,
    this.conversationId,
  });

  factory AIAnalysisResult.fromJson(
    Map<String, dynamic> json, {
    String? conversationId,
  }) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? json;
    return AIAnalysisResult(
      title: analysis['title'] ?? '',
      subject: analysis['subject'] ?? '',
      summary: analysis['summary'] ?? '',
      subtasks: (analysis['subtasks'] as List<dynamic>? ?? [])
          .map((s) => AISubTask.fromJson(s as Map<String, dynamic>))
          .toList(),
      conversationId: conversationId ?? json['conversationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject': subject,
      'summary': summary,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'conversationId': conversationId,
    };
  }

  AIAnalysisResult copyWith({
    String? title,
    String? subject,
    String? summary,
    List<AISubTask>? subtasks,
    String? conversationId,
  }) {
    return AIAnalysisResult(
      title: title ?? this.title,
      subject: subject ?? this.subject,
      summary: summary ?? this.summary,
      subtasks: subtasks ?? this.subtasks,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
