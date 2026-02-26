import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference for a specific user's notifications
  CollectionReference _notificationsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('notifications');
  }

  // Get stream of user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get stream of unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark a single notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsRef(userId).doc(notificationId).update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // Create a notification
  Future<void> createNotification(String userId, NotificationModel notification) async {
    await _notificationsRef(userId).add(notification.toFirestore());
  }
}
