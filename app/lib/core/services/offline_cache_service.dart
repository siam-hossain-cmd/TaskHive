import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/tasks/domain/models/task_model.dart';

/// Offline cache service using SharedPreferences for lightweight caching.
/// Stores tasks locally so they're available without network.
class OfflineCacheService {
  static const String _tasksKey = 'cached_tasks';
  static const String _pendingOpsKey = 'pending_operations';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Cache tasks locally
  static Future<void> cacheTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks
        .map((t) => jsonEncode(t.toFirestore()..['id'] = t.id))
        .toList();
    await prefs.setStringList(_tasksKey, jsonList);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get cached tasks
  static Future<List<TaskModel>> getCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_tasksKey) ?? [];
    return jsonList.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final id = data.remove('id') as String? ?? '';
      return _taskFromCacheMap(data, id);
    }).toList();
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastSyncKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  // ─── Pending Operations Queue ──────────────────────────────────────────────

  /// Queue a create operation for when we're back online
  static Future<void> queueCreateTask(TaskModel task) async {
    await _addPendingOp({
      'type': 'create',
      'data': task.toFirestore()..['id'] = task.id,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Queue an update operation
  static Future<void> queueUpdateTask(TaskModel task) async {
    await _addPendingOp({
      'type': 'update',
      'taskId': task.id,
      'data': task.toFirestore(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Queue a delete operation
  static Future<void> queueDeleteTask(String taskId) async {
    await _addPendingOp({
      'type': 'delete',
      'taskId': taskId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Queue a complete/toggle operation
  static Future<void> queueToggleComplete(String taskId) async {
    await _addPendingOp({
      'type': 'toggleComplete',
      'taskId': taskId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get all pending operations
  static Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_pendingOpsKey) ?? [];
    return jsonList
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  /// Clear pending operations after successful sync
  static Future<void> clearPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOpsKey);
  }

  /// Sync pending operations to Firestore
  static Future<SyncResult> syncPendingOperations() async {
    final ops = await getPendingOperations();
    if (ops.isEmpty) return SyncResult(synced: 0, failed: 0, conflicts: []);

    final firestore = FirebaseFirestore.instance;
    int synced = 0;
    int failed = 0;
    final conflicts = <String>[];

    for (final op in ops) {
      try {
        switch (op['type']) {
          case 'create':
            final data = Map<String, dynamic>.from(op['data']);
            final id = data.remove('id') as String?;
            if (id != null && id.isNotEmpty) {
              // Check if already exists (avoid duplicates)
              final doc = await firestore.collection('tasks').doc(id).get();
              if (!doc.exists) {
                await firestore
                    .collection('tasks')
                    .doc(id)
                    .set(_convertDates(data));
              } else {
                conflicts.add('Task already exists: ${data['title']}');
              }
            } else {
              await firestore.collection('tasks').add(_convertDates(data));
            }
            synced++;
            break;

          case 'update':
            final taskId = op['taskId'] as String;
            final data = Map<String, dynamic>.from(op['data']);
            await firestore
                .collection('tasks')
                .doc(taskId)
                .update(_convertDates(data));
            synced++;
            break;

          case 'delete':
            final taskId = op['taskId'] as String;
            await firestore.collection('tasks').doc(taskId).delete();
            synced++;
            break;

          case 'toggleComplete':
            final taskId = op['taskId'] as String;
            final doc = await firestore.collection('tasks').doc(taskId).get();
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final currentStatus = data['status'] as String? ?? 'pending';
              if (currentStatus == 'completed') {
                await firestore.collection('tasks').doc(taskId).update({
                  'status': 'pending',
                  'completedAt': null,
                });
              } else {
                await firestore.collection('tasks').doc(taskId).update({
                  'status': 'completed',
                  'completedAt': Timestamp.now(),
                });
              }
            }
            synced++;
            break;
        }
      } catch (e) {
        failed++;
        conflicts.add('Failed to sync ${op['type']}: $e');
      }
    }

    await clearPendingOperations();
    return SyncResult(synced: synced, failed: failed, conflicts: conflicts);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Future<void> _addPendingOp(Map<String, dynamic> op) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingOpsKey) ?? [];
    existing.add(jsonEncode(op));
    await prefs.setStringList(_pendingOpsKey, existing);
  }

  static Map<String, dynamic> _convertDates(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    // Convert ISO date strings back to Firestore Timestamps
    for (final key in ['dueDate', 'createdAt', 'completedAt']) {
      if (result[key] is String) {
        final dt = DateTime.tryParse(result[key]);
        if (dt != null) {
          result[key] = Timestamp.fromDate(dt);
        }
      }
    }
    return result;
  }

  static TaskModel _taskFromCacheMap(Map<String, dynamic> data, String id) {
    return TaskModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      subject: data['subject'] ?? '',
      dueDate: _parseDate(data['dueDate']),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      isRecurring: data['isRecurring'] ?? false,
      recurrenceRule: RecurrenceRule.values.firstWhere(
        (e) => e.name == data['recurrenceRule'],
        orElse: () => RecurrenceRule.none,
      ),
      attachments: List<String>.from(data['attachments'] ?? []),
      completedAt: data['completedAt'] != null
          ? _parseDate(data['completedAt'])
          : null,
      createdAt: _parseDate(data['createdAt']),
      groupId: data['groupId'],
      estimatedMinutes: data['estimatedMinutes'] ?? 60,
      subtaskCount: data['subtaskCount'] ?? 0,
      subtaskCompleted: data['subtaskCompleted'] ?? 0,
      totalTimeSpent: data['totalTimeSpent'] ?? 0,
      isTimerRunning: data['isTimerRunning'] ?? false,
      dependsOn: List<String>.from(data['dependsOn'] ?? []),
      blockedBy: List<String>.from(data['blockedBy'] ?? []),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is Map) {
      // Firestore Timestamp serialized as map
      final seconds = value['_seconds'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }

  /// Clear all cached data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_pendingOpsKey);
    await prefs.remove(_lastSyncKey);
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final List<String> conflicts;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.conflicts,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isFullySuccessful => failed == 0 && conflicts.isEmpty;
}
