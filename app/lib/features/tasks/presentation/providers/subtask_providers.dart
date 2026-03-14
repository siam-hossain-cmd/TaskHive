import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/subtask_repository.dart';
import '../../domain/models/subtask_model.dart';

final subtaskRepositoryProvider = Provider<SubtaskRepository>((ref) {
  return SubtaskRepository();
});

/// Stream of subtasks for a specific task
final subtasksProvider = StreamProvider.family<List<SubtaskModel>, String>((
  ref,
  taskId,
) {
  return ref.read(subtaskRepositoryProvider).getSubtasks(taskId);
});

/// Subtask CRUD notifier
class SubtaskNotifier extends StateNotifier<AsyncValue<void>> {
  final SubtaskRepository _repository;

  SubtaskNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<SubtaskModel?> addSubtask({
    required String taskId,
    required String title,
    int sortOrder = 0,
  }) async {
    try {
      final subtask = SubtaskModel(
        id: '',
        taskId: taskId,
        title: title,
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
      );
      return await _repository.addSubtask(subtask);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> addMultipleSubtasks({
    required String taskId,
    required List<String> titles,
  }) async {
    try {
      final subtasks = titles
          .asMap()
          .entries
          .map(
            (e) => SubtaskModel(
              id: '',
              taskId: taskId,
              title: e.value,
              sortOrder: e.key,
              createdAt: DateTime.now(),
            ),
          )
          .toList();
      await _repository.addSubtasksBatch(subtasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSubtask(
    String subtaskId,
    String taskId,
    bool isCompleted,
  ) async {
    try {
      await _repository.toggleSubtask(subtaskId, taskId, isCompleted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSubtask(SubtaskModel subtask) async {
    try {
      await _repository.updateSubtask(subtask);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSubtask(
    String subtaskId,
    String taskId,
    bool wasCompleted,
  ) async {
    try {
      await _repository.deleteSubtask(subtaskId, taskId, wasCompleted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderSubtasks(List<SubtaskModel> reordered) async {
    try {
      await _repository.reorderSubtasks(reordered);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final subtaskNotifierProvider =
    StateNotifierProvider<SubtaskNotifier, AsyncValue<void>>((ref) {
      return SubtaskNotifier(ref.read(subtaskRepositoryProvider));
    });
