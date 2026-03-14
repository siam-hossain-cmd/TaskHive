import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/time_entry_model.dart';

class TimeTrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _timeEntriesRef =>
      _firestore.collection('time_entries');
  CollectionReference get _tasksRef => _firestore.collection('tasks');

  /// Get all time entries for a task
  Stream<List<TimeEntryModel>> getTimeEntries(String taskId) {
    return _timeEntriesRef
        .where('taskId', isEqualTo: taskId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TimeEntryModel.fromFirestore(d)).toList(),
        );
  }

  /// Get all time entries for a user (for analytics)
  Stream<List<TimeEntryModel>> getUserTimeEntries(
    String userId, {
    DateTime? since,
  }) {
    Query query = _timeEntriesRef
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true);

    if (since != null) {
      query = query.where(
        'startTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(since),
      );
    }

    return query.snapshots().map(
      (snap) => snap.docs.map((d) => TimeEntryModel.fromFirestore(d)).toList(),
    );
  }

  /// Start a timer session
  Future<TimeEntryModel> startTimer({
    required String taskId,
    required String userId,
    TimerSessionType sessionType = TimerSessionType.manual,
  }) async {
    final entry = TimeEntryModel(
      id: '',
      taskId: taskId,
      userId: userId,
      startTime: DateTime.now(),
      sessionType: sessionType,
    );

    final docRef = await _timeEntriesRef.add(entry.toFirestore());

    // Mark task timer as running
    await _tasksRef.doc(taskId).update({'isTimerRunning': true});

    return entry.copyWith(id: docRef.id);
  }

  /// Stop a timer session
  Future<void> stopTimer(String entryId, String taskId) async {
    final doc = await _timeEntriesRef.doc(entryId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(startTime).inSeconds;

    final batch = _firestore.batch();

    batch.update(_timeEntriesRef.doc(entryId), {
      'endTime': Timestamp.fromDate(endTime),
      'durationSeconds': durationSeconds,
    });

    // Update task total time and stop timer
    batch.update(_tasksRef.doc(taskId), {
      'totalTimeSpent': FieldValue.increment(durationSeconds),
      'isTimerRunning': false,
    });

    await batch.commit();
  }

  /// Add a manual time entry
  Future<TimeEntryModel> addManualEntry({
    required String taskId,
    required String userId,
    required int durationSeconds,
    String? note,
  }) async {
    final now = DateTime.now();
    final entry = TimeEntryModel(
      id: '',
      taskId: taskId,
      userId: userId,
      startTime: now.subtract(Duration(seconds: durationSeconds)),
      endTime: now,
      durationSeconds: durationSeconds,
      sessionType: TimerSessionType.manual,
      note: note,
    );

    final docRef = await _timeEntriesRef.add(entry.toFirestore());

    // Update task total time
    await _tasksRef.doc(taskId).update({
      'totalTimeSpent': FieldValue.increment(durationSeconds),
    });

    return entry.copyWith(id: docRef.id);
  }

  /// Complete a pomodoro session
  Future<void> completePomodoroSession({
    required String entryId,
    required String taskId,
    required int pomodoroCount,
  }) async {
    final doc = await _timeEntriesRef.doc(entryId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(startTime).inSeconds;

    final batch = _firestore.batch();

    batch.update(_timeEntriesRef.doc(entryId), {
      'endTime': Timestamp.fromDate(endTime),
      'durationSeconds': durationSeconds,
      'pomodoroCount': pomodoroCount,
    });

    batch.update(_tasksRef.doc(taskId), {
      'totalTimeSpent': FieldValue.increment(durationSeconds),
      'isTimerRunning': false,
    });

    await batch.commit();
  }

  /// Delete a time entry
  Future<void> deleteTimeEntry(
    String entryId,
    String taskId,
    int durationSeconds,
  ) async {
    final batch = _firestore.batch();
    batch.delete(_timeEntriesRef.doc(entryId));
    batch.update(_tasksRef.doc(taskId), {
      'totalTimeSpent': FieldValue.increment(-durationSeconds),
    });
    await batch.commit();
  }

  /// Get total time spent today (for analytics)
  Future<int> getTodayTotalSeconds(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snap = await _timeEntriesRef
        .where('userId', isEqualTo: userId)
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .get();

    int total = 0;
    for (final doc in snap.docs) {
      total +=
          (doc.data() as Map<String, dynamic>)['durationSeconds'] as int? ?? 0;
    }
    return total;
  }

  /// Get running timer entry (if any)
  Future<TimeEntryModel?> getRunningTimer(String userId) async {
    final snap = await _timeEntriesRef
        .where('userId', isEqualTo: userId)
        .where('endTime', isNull: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return TimeEntryModel.fromFirestore(snap.docs.first);
  }
}
