import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/offline_cache_service.dart';

// ─── Connectivity State ──────────────────────────────────────────────────────

enum ConnectivityStatus { online, offline }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  });
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // assume online initially
    error: (_, __) => true,
  );
});

// ─── Sync State ──────────────────────────────────────────────────────────────

class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingOperations;
  final SyncResult? lastResult;
  final String? error;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingOperations = 0,
    this.lastResult,
    this.error,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingOperations,
    SyncResult? lastResult,
    String? error,
    bool clearError = false,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastResult: lastResult ?? this.lastResult,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  Timer? _autoSyncTimer;

  SyncNotifier(this._ref) : super(const SyncState()) {
    _init();
  }

  Future<void> _init() async {
    await _updatePendingCount();
    final lastSync = await OfflineCacheService.getLastSyncTime();
    state = state.copyWith(lastSyncTime: lastSync);

    // Auto-sync every 5 minutes when online
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline && state.pendingOperations > 0) {
        syncNow();
      }
    });

    // Listen for connectivity changes to auto-sync when coming back online
    _ref.listen(connectivityProvider, (prev, next) {
      next.whenData((status) {
        if (status == ConnectivityStatus.online &&
            state.pendingOperations > 0) {
          syncNow();
        }
      });
    });
  }

  Future<void> _updatePendingCount() async {
    final ops = await OfflineCacheService.getPendingOperations();
    state = state.copyWith(pendingOperations: ops.length);
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;

    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) {
      state = state.copyWith(error: 'No internet connection');
      return;
    }

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final result = await OfflineCacheService.syncPendingOperations();
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastResult: result,
        pendingOperations: 0,
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: 'Sync failed: $e');
    }
  }

  /// Called when an offline operation is queued
  Future<void> operationQueued() async {
    await _updatePendingCount();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

// ─── Pending Operations Count ────────────────────────────────────────────────

final pendingOperationsCountProvider = FutureProvider<int>((ref) async {
  final ops = await OfflineCacheService.getPendingOperations();
  return ops.length;
});
