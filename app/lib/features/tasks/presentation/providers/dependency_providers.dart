import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_dependency_repository.dart';
import '../../domain/models/task_dependency_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/task_providers.dart';
import '../../domain/models/task_model.dart';

final taskDependencyRepositoryProvider = Provider<TaskDependencyRepository>((
  ref,
) {
  return TaskDependencyRepository();
});

/// Dependencies for a specific task
final taskDependenciesProvider =
    StreamProvider.family<List<TaskDependencyModel>, String>((ref, taskId) {
      return ref.read(taskDependencyRepositoryProvider).getDependencies(taskId);
    });

/// Tasks that depend on this task
final taskDependentsProvider =
    StreamProvider.family<List<TaskDependencyModel>, String>((ref, taskId) {
      return ref.read(taskDependencyRepositoryProvider).getDependents(taskId);
    });

/// Get blocking tasks for a task (resolved with TaskModel)
final blockingTasksProvider = Provider.family<List<TaskModel>, String>((
  ref,
  taskId,
) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) {
      final task = tasks.cast<TaskModel?>().firstWhere(
        (t) => t!.id == taskId,
        orElse: () => null,
      );
      if (task == null) return [];
      return tasks.where((t) => task.blockedBy.contains(t.id)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Get dependent tasks (tasks that this task blocks)
final dependentTasksProvider = Provider.family<List<TaskModel>, String>((
  ref,
  taskId,
) {
  final tasksAsync = ref.watch(userTasksProvider);
  return tasksAsync.when(
    data: (tasks) {
      return tasks.where((t) => t.dependsOn.contains(taskId)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Dependency notifier for add/remove operations
class DependencyNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskDependencyRepository _repository;

  DependencyNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addDependency(String taskId, String dependsOnTaskId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addDependency(taskId, dependsOnTaskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeDependency(String taskId, String dependsOnTaskId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeDependency(taskId, dependsOnTaskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> onTaskCompleted(String taskId) async {
    try {
      await _repository.onTaskCompleted(taskId);
    } catch (e) {
      // Silent failure - dependency unblocking is not critical
    }
  }
}

final dependencyNotifierProvider =
    StateNotifierProvider<DependencyNotifier, AsyncValue<void>>((ref) {
      return DependencyNotifier(ref.read(taskDependencyRepositoryProvider));
    });
