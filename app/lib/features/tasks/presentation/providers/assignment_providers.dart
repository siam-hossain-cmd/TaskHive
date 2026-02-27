import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/task_comment_model.dart';
import '../../../groups/domain/models/group_model.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository();
});

/// Stream a single assignment by ID
final assignmentProvider = StreamProvider.family<AssignmentModel?, String>((
  ref,
  assignmentId,
) {
  return ref.read(assignmentRepositoryProvider).getAssignment(assignmentId);
});

/// Stream all assignments for a group
final groupAssignmentsProvider =
    StreamProvider.family<List<AssignmentModel>, String>((ref, groupId) {
      return ref
          .read(assignmentRepositoryProvider)
          .getGroupAssignments(groupId);
    });

/// Stream all subtasks (group_tasks) for an assignment
final assignmentTasksProvider =
    StreamProvider.family<List<GroupTaskModel>, String>((ref, assignmentId) {
      return ref
          .read(assignmentRepositoryProvider)
          .getAssignmentTasks(assignmentId);
    });

/// Stream comments for a task
final taskCommentsProvider =
    StreamProvider.family<List<TaskCommentModel>, String>((ref, taskId) {
      return ref.read(assignmentRepositoryProvider).getTaskComments(taskId);
    });
