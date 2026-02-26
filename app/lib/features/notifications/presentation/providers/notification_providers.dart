import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final userNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUserNotifications(user.uid);
});

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(0);
  }
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount(user.uid);
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;
  final String _userId;

  NotificationNotifier(this._repository, this._userId) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(_userId, notificationId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      state = const AsyncValue.loading();
      await _repository.markAllAsRead(_userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationNotifierProvider = StateNotifierProvider.autoDispose<NotificationNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repo, user?.uid ?? '');
});
