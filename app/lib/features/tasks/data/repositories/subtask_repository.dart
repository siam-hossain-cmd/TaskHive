import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/subtask_model.dart';

class SubtaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _subtasksRef => _firestore.collection('subtasks');
  CollectionReference get _tasksRef => _firestore.collection('tasks');

  /// Get all subtasks for a task (real-time stream)
  Stream<List<SubtaskModel>> getSubtasks(String taskId) {
    return _subtasksRef
        .where('taskId', isEqualTo: taskId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SubtaskModel.fromFirestore(d)).toList(),
        );
  }

  /// Add a new subtask
  Future<SubtaskModel> addSubtask(SubtaskModel subtask) async {
    final docRef = await _subtasksRef.add(subtask.toFirestore());

    // Update parent task subtask count
    await _tasksRef.doc(subtask.taskId).update({
      'subtaskCount': FieldValue.increment(1),
    });

    return subtask.copyWith(id: docRef.id);
  }

  /// Add multiple subtasks at once (batch)
  Future<void> addSubtasksBatch(List<SubtaskModel> subtasks) async {
    if (subtasks.isEmpty) return;
    final batch = _firestore.batch();
    for (final subtask in subtasks) {
      final docRef = _subtasksRef.doc();
      batch.set(docRef, subtask.toFirestore());
    }
    // Update parent count
    final taskId = subtasks.first.taskId;
    batch.update(_tasksRef.doc(taskId), {
      'subtaskCount': FieldValue.increment(subtasks.length),
    });
    await batch.commit();
  }

  /// Toggle subtask completion
  Future<void> toggleSubtask(
    String subtaskId,
    String taskId,
    bool isCompleted,
  ) async {
    final batch = _firestore.batch();

    batch.update(_subtasksRef.doc(subtaskId), {
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? Timestamp.now() : null,
    });

    // Update parent task completed count
    batch.update(_tasksRef.doc(taskId), {
      'subtaskCompleted': FieldValue.increment(isCompleted ? 1 : -1),
    });

    await batch.commit();
  }

  /// Update subtask title
  Future<void> updateSubtask(SubtaskModel subtask) async {
    await _subtasksRef.doc(subtask.id).update(subtask.toFirestore());
  }

  /// Delete a subtask
  Future<void> deleteSubtask(
    String subtaskId,
    String taskId,
    bool wasCompleted,
  ) async {
    final batch = _firestore.batch();
    batch.delete(_subtasksRef.doc(subtaskId));
    batch.update(_tasksRef.doc(taskId), {
      'subtaskCount': FieldValue.increment(-1),
      if (wasCompleted) 'subtaskCompleted': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  /// Reorder subtasks
  Future<void> reorderSubtasks(List<SubtaskModel> reordered) async {
    final batch = _firestore.batch();
    for (int i = 0; i < reordered.length; i++) {
      batch.update(_subtasksRef.doc(reordered[i].id), {'sortOrder': i});
    }
    await batch.commit();
  }

  /// Delete all subtasks for a task (cleanup)
  Future<void> deleteAllSubtasks(String taskId) async {
    final snap = await _subtasksRef.where('taskId', isEqualTo: taskId).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    if (snap.docs.isNotEmpty) {
      batch.update(_tasksRef.doc(taskId), {
        'subtaskCount': 0,
        'subtaskCompleted': 0,
      });
    }
    await batch.commit();
  }
}
