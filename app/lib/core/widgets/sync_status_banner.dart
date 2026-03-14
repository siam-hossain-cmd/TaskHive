import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/sync_providers.dart';

/// A small banner widget that shows connectivity status & pending sync operations.
/// Add this to the top of your home screen or as a persistent widget.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncProvider);

    // Don't show anything when online and no pending
    if (isOnline && syncState.pendingOperations == 0 && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOnline
            ? (syncState.isSyncing
                  ? AppColors.info.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1))
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? (syncState.isSyncing
                    ? AppColors.info.withValues(alpha: 0.2)
                    : AppColors.warning.withValues(alpha: 0.2))
              : AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isOnline
                  ? (syncState.isSyncing
                        ? AppColors.info.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15))
                  : AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: syncState.isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.info,
                      ),
                    ),
                  )
                : Icon(
                    isOnline ? Icons.sync_rounded : Icons.cloud_off_rounded,
                    size: 16,
                    color: isOnline ? AppColors.warning : AppColors.error,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnline
                      ? (syncState.isSyncing
                            ? 'Syncing changes...'
                            : '${syncState.pendingOperations} pending changes')
                      : 'You\'re offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOnline
                        ? (syncState.isSyncing
                              ? AppColors.info
                              : AppColors.warning)
                        : AppColors.error,
                  ),
                ),
                if (!isOnline)
                  Text(
                    'Changes will sync when connected',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Sync now button
          if (isOnline &&
              syncState.pendingOperations > 0 &&
              !syncState.isSyncing)
            GestureDetector(
              onTap: () => ref.read(syncProvider.notifier).syncNow(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Sync',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
