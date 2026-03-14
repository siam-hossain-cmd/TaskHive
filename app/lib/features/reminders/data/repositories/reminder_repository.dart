import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/reminder_model.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _remindersRef => _firestore.collection('reminders');

  /// Stream all reminders for a user, ordered by date ascending
  Stream<List<ReminderModel>> getUserReminders(String userId) {
    return _remindersRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream upcoming (not completed) reminders
  Stream<List<ReminderModel>> getUpcomingReminders(String userId) {
    return _remindersRef
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get reminders for a specific date range (for calendar view)
  Stream<List<ReminderModel>> getRemindersForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _remindersRef
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReminderModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a new reminder
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    final docRef = await _remindersRef.add(reminder.toFirestore());
    return reminder.copyWith(id: docRef.id);
  }

  /// Update an existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    await _remindersRef.doc(reminder.id).update(reminder.toFirestore());
  }

  /// Mark a reminder as completed / dismissed
  Future<void> completeReminder(String reminderId) async {
    await _remindersRef.doc(reminderId).update({'isCompleted': true});
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    await _remindersRef.doc(reminderId).delete();
  }

  /// Get a single reminder by ID
  Future<ReminderModel?> getReminder(String reminderId) async {
    final doc = await _remindersRef.doc(reminderId).get();
    if (!doc.exists) return null;
    return ReminderModel.fromFirestore(doc);
  }
}
