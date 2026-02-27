import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/group_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _groupsRef => _firestore.collection('groups');

  // Get user's groups
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _groupsRef
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => GroupModel.fromFirestore(d)).toList(),
        );
  }

  // Create group
  Future<GroupModel> createGroup(GroupModel group) async {
    final docRef = await _groupsRef.add(group.toFirestore());
    return group.copyWith(id: docRef.id);
  }

  // Create group and return just the ID (used by task wizard)
  Future<String> createGroupReturnId(GroupModel group) async {
    final docRef = await _groupsRef.add(group.toFirestore());
    return docRef.id;
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    await _groupsRef.doc(group.id).update(group.toFirestore());
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    await _groupsRef.doc(groupId).delete();
  }

  // Add member
  Future<void> addMember(String groupId, String userId) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Remove member
  Future<void> removeMember(String groupId, String userId) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Group Tasks ──

  Future<GroupTaskModel> createGroupTask(GroupTaskModel task) async {
    final docRef = await _firestore
        .collection('group_tasks')
        .add(task.toFirestore());
    return task.copyWith(id: docRef.id);
  }

  Stream<List<GroupTaskModel>> getGroupTasks(String groupId) {
    return _firestore
        .collection('group_tasks')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => GroupTaskModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> updateGroupTask(GroupTaskModel task) async {
    await _firestore
        .collection('group_tasks')
        .doc(task.id)
        .update(task.toFirestore());
  }

  Future<void> approveTask(String taskId) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'status': GroupTaskStatus.approved.name,
    });
  }

  Future<void> rejectTask(String taskId, String feedback) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'status': GroupTaskStatus.rejected.name,
      'rejectionFeedback': feedback,
    });
  }

  Future<void> submitTask(String taskId) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'status': GroupTaskStatus.pendingApproval.name,
    });
  }

  Future<void> submitTaskWork(
    String taskId,
    String submissionUrl,
    String fileName,
  ) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'submissionUrl': submissionUrl,
      'submissionFileName': fileName,
      'submittedAt': FieldValue.serverTimestamp(),
      'status': GroupTaskStatus.pendingApproval.name,
    });
  }

  Future<void> requestChanges(String taskId, String feedback) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'status': GroupTaskStatus.changesRequested.name,
      'rejectionFeedback': feedback,
    });
  }

  // ── Activity Log ──

  Future<void> addActivityLog(ActivityLogModel log) async {
    await _firestore.collection('activity_log').add(log.toFirestore());
  }

  Stream<List<ActivityLogModel>> getActivityLog(String groupId) {
    return _firestore
        .collection('activity_log')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ActivityLogModel.fromFirestore(d)).toList(),
        );
  }

  // ── Chat ──

  Future<void> sendMessage(MessageModel message) async {
    await _firestore.collection('messages').add(message.toFirestore());
  }

  Stream<List<MessageModel>> getMessages(String groupId) {
    return _firestore
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MessageModel.fromFirestore(d)).toList(),
        );
  }
}
