import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/task_dependency_model.dart';

class TaskDependencyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _depsRef =>
      _firestore.collection('task_dependencies');
  CollectionReference get _tasksRef => _firestore.collection('tasks');

  /// Get dependencies for a task
  Stream<List<TaskDependencyModel>> getDependencies(String taskId) {
    return _depsRef
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TaskDependencyModel.fromFirestore(d))
              .toList(),
        );
  }

  /// Get tasks that depend on this task (reverse lookup)
  Stream<List<TaskDependencyModel>> getDependents(String taskId) {
    return _depsRef
        .where('dependsOnTaskId', isEqualTo: taskId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TaskDependencyModel.fromFirestore(d))
              .toList(),
        );
  }

  /// Add a dependency: taskId depends on dependsOnTaskId
  Future<void> addDependency(String taskId, String dependsOnTaskId) async {
    // Prevent self-dependency
    if (taskId == dependsOnTaskId) return;

    // Check for circular dependencies
    if (await _wouldCreateCycle(taskId, dependsOnTaskId)) {
      throw Exception(
        'Cannot add dependency: would create a circular reference',
      );
    }

    // Check if this dependency already exists
    final existing = await _depsRef
        .where('taskId', isEqualTo: taskId)
        .where('dependsOnTaskId', isEqualTo: dependsOnTaskId)
        .get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    // Create dependency record
    final depRef = _depsRef.doc();
    batch.set(
      depRef,
      TaskDependencyModel(
        id: depRef.id,
        taskId: taskId,
        dependsOnTaskId: dependsOnTaskId,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );

    // Update task's dependsOn array
    batch.update(_tasksRef.doc(taskId), {
      'dependsOn': FieldValue.arrayUnion([dependsOnTaskId]),
    });

    // Update the other task's blockedBy array (it blocks taskId)
    // Note: Only update blockedBy if the dependency task is not yet completed
    final depTask = await _tasksRef.doc(dependsOnTaskId).get();
    if (depTask.exists) {
      final depData = depTask.data() as Map<String, dynamic>;
      if (depData['status'] != 'completed') {
        batch.update(_tasksRef.doc(taskId), {
          'blockedBy': FieldValue.arrayUnion([dependsOnTaskId]),
        });
      }
    }

    await batch.commit();
  }

  /// Remove a dependency
  Future<void> removeDependency(String taskId, String dependsOnTaskId) async {
    final snap = await _depsRef
        .where('taskId', isEqualTo: taskId)
        .where('dependsOnTaskId', isEqualTo: dependsOnTaskId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }

    batch.update(_tasksRef.doc(taskId), {
      'dependsOn': FieldValue.arrayRemove([dependsOnTaskId]),
      'blockedBy': FieldValue.arrayRemove([dependsOnTaskId]),
    });

    await batch.commit();
  }

  /// When a task is completed, unblock all tasks that depend on it
  Future<void> onTaskCompleted(String completedTaskId) async {
    final dependents = await _depsRef
        .where('dependsOnTaskId', isEqualTo: completedTaskId)
        .get();

    if (dependents.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in dependents.docs) {
      final dep = TaskDependencyModel.fromFirestore(doc);
      batch.update(_tasksRef.doc(dep.taskId), {
        'blockedBy': FieldValue.arrayRemove([completedTaskId]),
      });
    }
    await batch.commit();
  }

  /// Check if adding a dependency would create a cycle
  Future<bool> _wouldCreateCycle(String taskId, String dependsOnTaskId) async {
    // BFS: Check if dependsOnTaskId already depends on taskId (directly or transitively)
    final visited = <String>{};
    final queue = [dependsOnTaskId];

    // Walk backwards through the dependency chain, but we need to check if
    // dependsOnTaskId transitively depends on taskId
    // Actually, we need to check: does taskId appear in the transitive deps of dependsOnTaskId?
    // i.e., we check: from taskId, can we reach dependsOnTaskId by following dependsOn links?
    // If yes -> cycle
    final forwardQueue = [taskId];
    final forwardVisited = <String>{};

    // Actually simpler: we need to check if dependsOnTaskId could reach taskId
    // by following ITS dependsOn links (the tasks IT depends on).
    // But since we're adding "taskId depends on dependsOnTaskId",
    // a cycle would mean dependsOnTaskId already (transitively) depends on taskId.
    // So check: starting from dependsOnTaskId, follow dependsOn links, do we reach taskId?
    final checkQueue = [dependsOnTaskId];
    final checkVisited = <String>{};

    while (checkQueue.isNotEmpty) {
      final current = checkQueue.removeAt(0);
      if (current == taskId) return true; // Cycle detected
      if (checkVisited.contains(current)) continue;
      checkVisited.add(current);

      final deps = await _depsRef.where('taskId', isEqualTo: current).get();
      for (final doc in deps.docs) {
        final dep = TaskDependencyModel.fromFirestore(doc);
        checkQueue.add(dep.dependsOnTaskId);
      }
    }

    return false;
  }
}
