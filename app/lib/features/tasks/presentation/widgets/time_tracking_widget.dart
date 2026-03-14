import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/time_entry_model.dart';
import '../providers/time_tracking_providers.dart';

class TimeTrackingWidget extends ConsumerStatefulWidget {
  final String taskId;

  const TimeTrackingWidget({super.key, required this.taskId});

  @override
  ConsumerState<TimeTrackingWidget> createState() => _TimeTrackingWidgetState();
}

class _TimeTrackingWidgetState extends ConsumerState<TimeTrackingWidget> {
  bool _showManualEntry = false;
  final _manualMinController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _manualMinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.timer_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Time Tracking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Total time badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timerState.formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timer Display
          Center(
            child: Column(
              children: [
                // Large Timer
                Text(
                  timerState.isRunning
                      ? timerState.formattedTime
                      : timerState.formattedTime,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: timerState.isRunning
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                if (timerState.isRunning) ...[
                  const SizedBox(height: 4),
                  Text(
                    timerState.isBreak ? '☕ Break Time' : '🎯 Focus Session',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: timerState.isBreak
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Timer Controls
          Row(
            children: [
              // Start/Stop Timer
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (timerState.isRunning) {
                      ref.read(timerNotifierProvider.notifier).stopTimer();
                    } else {
                      ref
                          .read(timerNotifierProvider.notifier)
                          .startTimer(widget.taskId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: timerState.isRunning
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          timerState.isRunning
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                          color: timerState.isRunning
                              ? AppColors.error
                              : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timerState.isRunning ? 'Stop' : 'Start Timer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: timerState.isRunning
                                ? AppColors.error
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Pomodoro
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (!timerState.isRunning) {
                      ref
                          .read(timerNotifierProvider.notifier)
                          .startPomodoro(widget.taskId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: timerState.isRunning
                          ? AppColors.bgColor
                          : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: timerState.isRunning
                            ? AppColors.bgColor
                            : const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🍅', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Pomodoro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: timerState.isRunning
                                ? AppColors.textSecondary
                                : const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Pomodoro Progress
          if (timerState.pomodoroCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text('🍅', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pomodoro Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(timerState.pomodoroTarget, (
                            i,
                          ) {
                            final isComplete = i < timerState.pomodoroCount;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isComplete
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(
                                          0xFFFF6B6B,
                                        ).withValues(alpha: 0.15),
                                ),
                                child: isComplete
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${timerState.pomodoroCount}/${timerState.pomodoroTarget}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Manual Entry Toggle
          GestureDetector(
            onTap: () => setState(() => _showManualEntry = !_showManualEntry),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add Time Manually',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showManualEntry) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _manualMinController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Minutes',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _noteController,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Note (optional)',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final mins = int.tryParse(_manualMinController.text) ?? 0;
                    if (mins <= 0) return;
                    ref
                        .read(timerNotifierProvider.notifier)
                        .addManualTime(
                          widget.taskId,
                          mins,
                          note: _noteController.text.trim(),
                        );
                    _manualMinController.clear();
                    _noteController.clear();
                    setState(() => _showManualEntry = false);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Time Entries
          const SizedBox(height: 12),
          _TimeEntriesList(taskId: widget.taskId),
        ],
      ),
    );
  }
}

class _TimeEntriesList extends ConsumerWidget {
  final String taskId;
  const _TimeEntriesList({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(taskTimeEntriesProvider(taskId));

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        final recent = entries.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT SESSIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...recent.map((entry) {
              final totalSecs = entry.actualDuration;
              final mins = totalSecs ~/ 60;
              final secs = totalSecs % 60;
              final isPomo = entry.sessionType == TimerSessionType.pomodoro;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isPomo
                            ? const Color(0xFFFF6B6B).withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: isPomo
                            ? const Text('🍅', style: TextStyle(fontSize: 12))
                            : Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPomo ? 'Pomodoro Session' : 'Timer Session',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (entry.note != null && entry.note!.isNotEmpty)
                            Text(
                              entry.note!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${mins}m ${secs}s',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
