import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../notifications/domain/models/notification_model.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../core/services/api_service.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// Stream of user's personal tasks
final userTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.read(taskRepositoryProvider).getUserTasks(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Filtered tasks by status
final filteredTasksProvider =
    Provider.family<List<TaskModel>, TaskStatus?>((ref, status) {
  final tasks = ref.watch(userTasksProvider);
  return tasks.when(
    data: (taskList) {
      if (status == null) return taskList;
      return taskList.where((t) => t.status == status).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Today's tasks
final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(userTasksProvider);
  return tasks.when(
    data: (taskList) {
      final now = DateTime.now();
      return taskList.where((t) {
        return t.dueDate.year == now.year &&
            t.dueDate.month == now.month &&
            t.dueDate.day == now.day;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Overdue tasks
final overdueTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(userTasksProvider);
  return tasks.when(
    data: (taskList) => taskList.where((t) => t.isOverdue).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Task CRUD Notifier
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;
  final String? _userId;
  final NotificationRepository _notifRepo;
  final ApiService _apiService;

  TaskNotifier(this._repository, this._userId, this._notifRepo, this._apiService)
      : super(const AsyncValue.data(null));

  Future<TaskModel?> createTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createTask(task);
      
      // Notification Logic
      if (_userId != null) {
        final notif = NotificationModel(
          id: '',
          title: 'Task Created',
          body: 'You created a new task: "${task.title}"',
          type: 'task_created',
          createdAt: DateTime.now(),
          relatedId: created.id,
        );
        await _notifRepo.createNotification(_userId, notif);
        
        // Also send push
        await _apiService.sendUserNotification(
          targetUid: _userId,
          title: notif.title,
          body: notif.body,
          payload: {'type': 'task_created', 'taskId': created.id},
        );
      }

      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTask(task);
      
      // Basic assignment / update notification 
      if (_userId != null) {
        final notif = NotificationModel(
          id: '',
          title: 'Task Updated',
          body: 'Task "${task.title}" was updated.',
          type: 'task_assigned', // or 'general'
          createdAt: DateTime.now(),
          relatedId: task.id,
        );
        await _notifRepo.createNotification(_userId, notif);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTask(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markComplete(String taskId) async {
    try {
      await _repository.markComplete(taskId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> uploadAttachment(String taskId, File file) async {
    try {
      if (_userId == null) return null;
      return await _repository.uploadAttachment(_userId, taskId, file);
    } catch (e) {
      return null;
    }
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  final repo = ref.read(taskRepositoryProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final notifRepo = ref.watch(notificationRepositoryProvider);
  final apiService = ref.watch(apiServiceProvider);
  return TaskNotifier(repo, user?.uid, notifRepo, apiService);
});
