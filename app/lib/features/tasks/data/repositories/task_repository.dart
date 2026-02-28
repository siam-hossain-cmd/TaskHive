import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../domain/models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _tasksRef => _firestore.collection('tasks');

  // Get all tasks for a user
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _tasksRef
        .where('userId', isEqualTo: userId)
        .where('groupId', isNull: true)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Get tasks by status
  Stream<List<TaskModel>> getTasksByStatus(String userId, TaskStatus status) {
    return _tasksRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .where('groupId', isNull: true)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Get tasks for a specific date
  Stream<List<TaskModel>> getTasksForDate(String userId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _tasksRef
        .where('userId', isEqualTo: userId)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dueDate', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList(),
        );
  }

  // Create task
  Future<TaskModel> createTask(TaskModel task) async {
    final docRef = await _tasksRef.add(task.toFirestore());
    return task.copyWith(id: docRef.id);
  }

  // Update task
  Future<void> updateTask(TaskModel task) async {
    await _tasksRef.doc(task.id).update(task.toFirestore());
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  // Toggle complete / incomplete
  Future<void> markComplete(String taskId) async {
    final doc = await _tasksRef.doc(taskId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final currentStatus = data['status'] as String? ?? 'pending';

    if (currentStatus == TaskStatus.completed.name) {
      // Mark incomplete
      await _tasksRef.doc(taskId).update({
        'status': TaskStatus.pending.name,
        'completedAt': null,
      });
    } else {
      // Mark complete
      await _tasksRef.doc(taskId).update({
        'status': TaskStatus.completed.name,
        'completedAt': Timestamp.now(),
      });
    }
  }

  // Upload file attachment
  Future<String> uploadAttachment(
    String userId,
    String taskId,
    File file,
  ) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref('tasks/$userId/$taskId/$fileName');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    // Save URL to the task's attachments array
    await _tasksRef.doc(taskId).update({
      'attachments': FieldValue.arrayUnion([url]),
    });

    return url;
  }

  // Get completed task count for analytics
  Future<int> getCompletedTaskCount(String userId, {DateTime? since}) async {
    Query query = _tasksRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TaskStatus.completed.name);

    if (since != null) {
      query = query.where(
        'completedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(since),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.length;
  }

  // Get overdue task count
  Future<int> getOverdueTaskCount(String userId) async {
    final snapshot = await _tasksRef
        .where('userId', isEqualTo: userId)
        .where(
          'status',
          whereIn: [TaskStatus.pending.name, TaskStatus.inProgress.name],
        )
        .where('dueDate', isLessThan: Timestamp.now())
        .get();
    return snapshot.docs.length;
  }
}
