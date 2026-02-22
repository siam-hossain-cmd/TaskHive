import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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

  TaskNotifier(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<TaskModel?> createTask(TaskModel task) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createTask(task);
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
  return TaskNotifier(repo, user?.uid);
});
