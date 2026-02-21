import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/models/group_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

// Stream of user's groups
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.read(groupRepositoryProvider).getUserGroups(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Group tasks
final groupTasksProvider =
    StreamProvider.family<List<GroupTaskModel>, String>((ref, groupId) {
  return ref.read(groupRepositoryProvider).getGroupTasks(groupId);
});

// Activity log
final activityLogProvider =
    StreamProvider.family<List<ActivityLogModel>, String>((ref, groupId) {
  return ref.read(groupRepositoryProvider).getActivityLog(groupId);
});

// Chat messages
final chatMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, groupId) {
  return ref.read(groupRepositoryProvider).getMessages(groupId);
});
