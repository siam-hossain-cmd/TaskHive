import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/task_providers.dart';
import '../../domain/models/task_model.dart';

// ─── AI Suggestion Model ─────────────────────────────────────────────────────

class AISuggestion {
  final String type;
  final String title;
  final String message;
  final String? taskId;
  final String? action;

  AISuggestion({
    required this.type,
    required this.title,
    required this.message,
    this.taskId,
    this.action,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      taskId: json['taskId'],
      action: json['action'],
    );
  }
}

class AIWeeklyReview {
  final String greeting;
  final String summary;
  final List<String> highlights;
  final List<String> improvements;
  final List<String> nextWeekTips;
  final int productivityScore;
  final String emoji;

  AIWeeklyReview({
    required this.greeting,
    required this.summary,
    required this.highlights,
    required this.improvements,
    required this.nextWeekTips,
    required this.productivityScore,
    required this.emoji,
  });

  factory AIWeeklyReview.fromJson(Map<String, dynamic> json) {
    return AIWeeklyReview(
      greeting: json['greeting'] ?? '',
      summary: json['summary'] ?? '',
      highlights: List<String>.from(json['highlights'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      nextWeekTips: List<String>.from(json['nextWeekTips'] ?? []),
      productivityScore: json['productivityScore'] ?? 0,
      emoji: json['emoji'] ?? '📊',
    );
  }
}

class AIPriorityAdjustment {
  final String taskId;
  final String taskTitle;
  final String currentPriority;
  final String suggestedPriority;
  final String reason;

  AIPriorityAdjustment({
    required this.taskId,
    required this.taskTitle,
    required this.currentPriority,
    required this.suggestedPriority,
    required this.reason,
  });

  factory AIPriorityAdjustment.fromJson(Map<String, dynamic> json) {
    return AIPriorityAdjustment(
      taskId: json['taskId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      currentPriority: json['currentPriority'] ?? 'medium',
      suggestedPriority: json['suggestedPriority'] ?? 'medium',
      reason: json['reason'] ?? '',
    );
  }
}

// ─── AI State ────────────────────────────────────────────────────────────────

class AIEnhancementState {
  final List<AISuggestion> suggestions;
  final String? dailyTip;
  final AIWeeklyReview? weeklyReview;
  final List<AIPriorityAdjustment> priorityAdjustments;
  final String? priorityAdvice;
  final bool isLoadingSuggestions;
  final bool isLoadingReview;
  final bool isLoadingPriority;
  final bool isParsingTask;
  final String? error;

  const AIEnhancementState({
    this.suggestions = const [],
    this.dailyTip,
    this.weeklyReview,
    this.priorityAdjustments = const [],
    this.priorityAdvice,
    this.isLoadingSuggestions = false,
    this.isLoadingReview = false,
    this.isLoadingPriority = false,
    this.isParsingTask = false,
    this.error,
  });

  AIEnhancementState copyWith({
    List<AISuggestion>? suggestions,
    String? dailyTip,
    AIWeeklyReview? weeklyReview,
    List<AIPriorityAdjustment>? priorityAdjustments,
    String? priorityAdvice,
    bool? isLoadingSuggestions,
    bool? isLoadingReview,
    bool? isLoadingPriority,
    bool? isParsingTask,
    String? error,
  }) {
    return AIEnhancementState(
      suggestions: suggestions ?? this.suggestions,
      dailyTip: dailyTip ?? this.dailyTip,
      weeklyReview: weeklyReview ?? this.weeklyReview,
      priorityAdjustments: priorityAdjustments ?? this.priorityAdjustments,
      priorityAdvice: priorityAdvice ?? this.priorityAdvice,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      isLoadingReview: isLoadingReview ?? this.isLoadingReview,
      isLoadingPriority: isLoadingPriority ?? this.isLoadingPriority,
      isParsingTask: isParsingTask ?? this.isParsingTask,
      error: error,
    );
  }
}

// ─── AI Enhancement Notifier ─────────────────────────────────────────────────

class AIEnhancementNotifier extends StateNotifier<AIEnhancementState> {
  final ApiService _apiService;
  final Ref _ref;

  AIEnhancementNotifier(this._apiService, this._ref)
    : super(const AIEnhancementState());

  /// Parse natural language into a task
  Future<Map<String, dynamic>?> parseTask(String text) async {
    state = state.copyWith(isParsingTask: true, error: null);
    try {
      final result = await _apiService.parseTaskFromText(text);
      state = state.copyWith(isParsingTask: false);
      return result;
    } catch (e) {
      state = state.copyWith(isParsingTask: false, error: e.toString());
      return null;
    }
  }

  /// Fetch AI suggestions based on current tasks
  Future<void> fetchSuggestions() async {
    state = state.copyWith(isLoadingSuggestions: true, error: null);
    try {
      final tasksAsync = _ref.read(userTasksProvider);
      final tasks = tasksAsync.valueOrNull ?? [];

      final activeTasks = tasks
          .where((t) => t.status != TaskStatus.completed)
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'subject': t.subject,
              'priority': t.priority.name,
              'dueDate': t.dueDate.toIso8601String(),
              'estimatedMinutes': t.estimatedMinutes,
              'status': t.status.name,
              'isOverdue': t.isOverdue,
              'subtaskProgress': t.subtaskProgress,
              'totalTimeSpent': t.totalTimeSpent,
            },
          )
          .toList();

      final completedTasks = tasks
          .where((t) => t.status == TaskStatus.completed)
          .take(10)
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'completedAt': t.completedAt?.toIso8601String(),
            },
          )
          .toList();

      final result = await _apiService.getAISuggestions(
        tasks: activeTasks,
        completedTasks: completedTasks,
      );

      if (result != null) {
        final suggestions = (result['suggestions'] as List<dynamic>? ?? [])
            .map((s) => AISuggestion.fromJson(s as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          suggestions: suggestions,
          dailyTip: result['dailyTip'] as String?,
          isLoadingSuggestions: false,
        );
      } else {
        state = state.copyWith(isLoadingSuggestions: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingSuggestions: false, error: e.toString());
    }
  }

  /// Generate weekly review
  Future<void> fetchWeeklyReview() async {
    state = state.copyWith(isLoadingReview: true, error: null);
    try {
      final tasksAsync = _ref.read(userTasksProvider);
      final tasks = tasksAsync.valueOrNull ?? [];
      final profile = _ref.read(userProfileProvider).valueOrNull;

      final taskData = tasks
          .map(
            (t) => {
              'title': t.title,
              'subject': t.subject,
              'priority': t.priority.name,
              'status': t.status.name,
              'dueDate': t.dueDate.toIso8601String(),
              'completedAt': t.completedAt?.toIso8601String(),
              'estimatedMinutes': t.estimatedMinutes,
              'totalTimeSpent': t.totalTimeSpent,
            },
          )
          .toList();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekTasks = tasks.where(
        (t) => t.createdAt.isAfter(weekStart) || t.dueDate.isAfter(weekStart),
      );
      final completedThisWeek = thisWeekTasks
          .where((t) => t.status == TaskStatus.completed)
          .length;

      final weeklyStats = {
        'totalTasks': thisWeekTasks.length,
        'completedTasks': completedThisWeek,
        'completionRate': thisWeekTasks.isNotEmpty
            ? (completedThisWeek / thisWeekTasks.length * 100).round()
            : 0,
        'overdueTasks': tasks.where((t) => t.isOverdue).length,
      };

      final result = await _apiService.getWeeklyReview(
        weeklyStats: weeklyStats,
        tasks: taskData,
        userName: profile?.displayName,
      );

      if (result != null) {
        state = state.copyWith(
          weeklyReview: AIWeeklyReview.fromJson(result),
          isLoadingReview: false,
        );
      } else {
        state = state.copyWith(isLoadingReview: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingReview: false, error: e.toString());
    }
  }

  /// Get smart priority suggestions
  Future<void> fetchPrioritySuggestions() async {
    state = state.copyWith(isLoadingPriority: true, error: null);
    try {
      final tasksAsync = _ref.read(userTasksProvider);
      final tasks = tasksAsync.valueOrNull ?? [];

      final activeTasks = tasks
          .where((t) => t.status != TaskStatus.completed)
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'subject': t.subject,
              'priority': t.priority.name,
              'dueDate': t.dueDate.toIso8601String(),
              'estimatedMinutes': t.estimatedMinutes,
              'status': t.status.name,
              'isOverdue': t.isOverdue,
              'dependsOn': t.dependsOn,
              'isBlocked': t.isBlocked,
            },
          )
          .toList();

      final result = await _apiService.getSmartPrioritySuggestions(
        tasks: activeTasks,
      );

      if (result != null) {
        final adjustments = (result['adjustments'] as List<dynamic>? ?? [])
            .map(
              (a) => AIPriorityAdjustment.fromJson(a as Map<String, dynamic>),
            )
            .toList();
        state = state.copyWith(
          priorityAdjustments: adjustments,
          priorityAdvice: result['overallAdvice'] as String?,
          isLoadingPriority: false,
        );
      } else {
        state = state.copyWith(isLoadingPriority: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingPriority: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final aiEnhancementProvider =
    StateNotifierProvider<AIEnhancementNotifier, AIEnhancementState>((ref) {
      return AIEnhancementNotifier(ref.read(apiServiceProvider), ref);
    });
