import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/friend_repository.dart';
import '../../domain/models/friend_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

// ── Current UID helper ─────────────────────────────────────────────────────────
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid;
});

// ── Friends list ──────────────────────────────────────────────────────────────
final friendsProvider = StreamProvider<List<FriendModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.read(friendRepositoryProvider).getFriends(uid);
});

// ── Incoming requests ─────────────────────────────────────────────────────────
final incomingRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.read(friendRepositoryProvider).getIncomingRequests(uid);
});

// ── Outgoing requests ─────────────────────────────────────────────────────────
final outgoingRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.read(friendRepositoryProvider).getOutgoingRequests(uid);
});

// ── Messages for a chat ───────────────────────────────────────────────────────
final friendMessagesProvider =
    StreamProvider.family<List<FriendMessageModel>, String>((ref, chatId) {
  return ref.read(friendRepositoryProvider).getMessages(chatId);
});

// ── Search users ──────────────────────────────────────────────────────────────
final userSearchQueryProvider = StateProvider<String>((ref) => '');

final userSearchResultsProvider = FutureProvider<List<UserProfile>>((ref) async {
  final q = ref.watch(userSearchQueryProvider);
  if (q.trim().isEmpty) return [];
  return ref.read(friendRepositoryProvider).searchUsers(q);
});

// ── Send message notifier ─────────────────────────────────────────────────────
class FriendChatNotifier extends StateNotifier<AsyncValue<void>> {
  final FriendRepository _repo;
  FriendChatNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> sendMessage(FriendMessageModel msg) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendMessage(msg);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final friendChatNotifierProvider =
    StateNotifierProvider<FriendChatNotifier, AsyncValue<void>>((ref) {
  return FriendChatNotifier(ref.read(friendRepositoryProvider));
});

// ── Accept / Decline requests ─────────────────────────────────────────────────
class FriendRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final FriendRepository _repo;
  FriendRequestNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> accept(FriendRequestModel req) async {
    state = const AsyncValue.loading();
    try {
      await _repo.acceptRequest(req);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> decline(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.declineRequest(requestId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendRequest({
    required String fromUid,
    required String toUid,
    required String fromName,
    required String fromEmail,
    String? fromPhotoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendFriendRequest(
        fromUid: fromUid,
        toUid: toUid,
        fromName: fromName,
        fromEmail: fromEmail,
        fromPhotoUrl: fromPhotoUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final friendRequestNotifierProvider =
    StateNotifierProvider<FriendRequestNotifier, AsyncValue<void>>((ref) {
  return FriendRequestNotifier(ref.read(friendRepositoryProvider));
});
