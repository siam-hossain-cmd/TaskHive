import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../tasks/domain/models/assignment_model.dart';
import '../../../tasks/domain/models/task_comment_model.dart';
import '../../../groups/domain/models/group_model.dart';

class AssignmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Assignments ──

  Stream<List<AssignmentModel>> getGroupAssignments(String groupId) {
    return _firestore
        .collection('assignments')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AssignmentModel.fromFirestore(d)).toList(),
        );
  }

  Stream<AssignmentModel?> getAssignment(String assignmentId) {
    return _firestore
        .collection('assignments')
        .doc(assignmentId)
        .snapshots()
        .map((doc) => doc.exists ? AssignmentModel.fromFirestore(doc) : null);
  }

  Future<AssignmentModel> createAssignment(AssignmentModel assignment) async {
    final docRef = await _firestore
        .collection('assignments')
        .add(assignment.toFirestore());
    return assignment.copyWith(id: docRef.id);
  }

  Future<void> updateAssignment(AssignmentModel assignment) async {
    await _firestore
        .collection('assignments')
        .doc(assignment.id)
        .update(assignment.toFirestore());
  }

  Future<void> assignCompiler(String assignmentId, String compilerId) async {
    await _firestore.collection('assignments').doc(assignmentId).update({
      'compilerId': compilerId,
      'status': AssignmentStatus.compilationPhase.name,
    });
  }

  Future<void> uploadFinalDoc(
    String assignmentId,
    String finalDocUrl,
    String finalDocName,
  ) async {
    await _firestore.collection('assignments').doc(assignmentId).update({
      'finalDocUrl': finalDocUrl,
      'finalDocName': finalDocName,
    });
  }

  Future<void> completeAssignment(String assignmentId) async {
    await _firestore.collection('assignments').doc(assignmentId).update({
      'status': AssignmentStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Assignment Sub-Tasks (GroupTaskModels with assignmentId) ──

  Stream<List<GroupTaskModel>> getAssignmentTasks(String assignmentId) {
    return _firestore
        .collection('group_tasks')
        .where('assignmentId', isEqualTo: assignmentId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => GroupTaskModel.fromFirestore(d)).toList(),
        );
  }

  // ── Task Comments ──

  Stream<List<TaskCommentModel>> getTaskComments(String taskId) {
    return _firestore
        .collection('task_comments')
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskCommentModel.fromFirestore(d)).toList(),
        );
  }

  Future<TaskCommentModel> addTaskComment(TaskCommentModel comment) async {
    final docRef = await _firestore
        .collection('task_comments')
        .add(comment.toFirestore());
    return comment.copyWith(id: docRef.id);
  }

  // ── Task Submission ──

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

  Future<void> approveTask(String taskId) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'status': GroupTaskStatus.approved.name,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectionFeedback': null,
    });
  }

  Future<void> requestChanges(String taskId, String feedback) async {
    await _firestore.collection('group_tasks').doc(taskId).update({
      'status': GroupTaskStatus.changesRequested.name,
      'rejectionFeedback': feedback,
    });
  }
}
