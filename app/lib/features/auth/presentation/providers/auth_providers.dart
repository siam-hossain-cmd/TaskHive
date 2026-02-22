import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth State Stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Current User Profile
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return ref.read(authRepositoryProvider).getUserProfile();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth Loading State
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Sign Up Notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('DEBUG: Attempting sign up for $email');
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      print('DEBUG: Sign up successful: ${user.uid}');
      state = AsyncValue.data(user);
    } catch (e, st) {
      print('DEBUG: Sign up FAILED: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('DEBUG: Attempting sign in for $email');
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      print('DEBUG: Sign in successful: ${user?.uid}');
      state = AsyncValue.data(user);
    } catch (e, st) {
      print('DEBUG: Sign in FAILED: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      print('DEBUG: Attempting Google sign in');
      final user = await _repository.signInWithGoogle();
      print('DEBUG: Google sign in result: ${user?.uid}');
      state = AsyncValue.data(user);
    } catch (e, st) {
      print('DEBUG: Google sign in FAILED: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});
