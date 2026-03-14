import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../domain/models/reminder_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Repository singleton
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

/// Stream of ALL user reminders (for calendar)
final userRemindersProvider = StreamProvider<List<ReminderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.read(reminderRepositoryProvider).getUserReminders(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Stream of upcoming (not completed) reminders
final upcomingRemindersProvider = StreamProvider<List<ReminderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref
          .read(reminderRepositoryProvider)
          .getUpcomingReminders(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Today's reminders
final todayRemindersProvider = Provider<List<ReminderModel>>((ref) {
  final reminders = ref.watch(userRemindersProvider);
  return reminders.when(
    data: (list) {
      final now = DateTime.now();
      return list.where((r) {
        return r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// CRUD Notifier for reminders
class ReminderNotifier extends StateNotifier<AsyncValue<void>> {
  final ReminderRepository _repository;
  final String? _userId;

  ReminderNotifier(this._repository, this._userId)
    : super(const AsyncValue.data(null));

  Future<ReminderModel?> createReminder(ReminderModel reminder) async {
    if (_userId == null) return null;
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createReminder(
        reminder.copyWith(userId: _userId),
      );
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateReminder(reminder);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.completeReminder(reminderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReminder(reminderId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reminderNotifierProvider =
    StateNotifierProvider<ReminderNotifier, AsyncValue<void>>((ref) {
      final repo = ref.read(reminderRepositoryProvider);
      final user = ref.watch(authStateProvider).valueOrNull;
      return ReminderNotifier(repo, user?.uid);
    });
