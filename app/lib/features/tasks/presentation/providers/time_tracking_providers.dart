import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/time_tracking_repository.dart';
import '../../domain/models/time_entry_model.dart';

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>((ref) {
  return TimeTrackingRepository();
});

/// Stream of time entries for a specific task
final taskTimeEntriesProvider =
    StreamProvider.family<List<TimeEntryModel>, String>((ref, taskId) {
      return ref.read(timeTrackingRepositoryProvider).getTimeEntries(taskId);
    });

/// Time tracking state for active timer
class TimerState {
  final TimeEntryModel? activeEntry;
  final String? activeTaskId;
  final int elapsedSeconds;
  final bool isRunning;
  final int pomodoroCount;
  final int pomodoroTarget; // default 4 pomodoros
  final int pomodoroMinutes; // default 25 min
  final int breakMinutes; // default 5 min
  final bool isBreak;
  final TimerSessionType sessionType;

  const TimerState({
    this.activeEntry,
    this.activeTaskId,
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.pomodoroCount = 0,
    this.pomodoroTarget = 4,
    this.pomodoroMinutes = 25,
    this.breakMinutes = 5,
    this.isBreak = false,
    this.sessionType = TimerSessionType.manual,
  });

  TimerState copyWith({
    TimeEntryModel? activeEntry,
    String? activeTaskId,
    int? elapsedSeconds,
    bool? isRunning,
    int? pomodoroCount,
    int? pomodoroTarget,
    int? pomodoroMinutes,
    int? breakMinutes,
    bool? isBreak,
    TimerSessionType? sessionType,
  }) {
    return TimerState(
      activeEntry: activeEntry ?? this.activeEntry,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      pomodoroTarget: pomodoroTarget ?? this.pomodoroTarget,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      isBreak: isBreak ?? this.isBreak,
      sessionType: sessionType ?? this.sessionType,
    );
  }

  String get formattedTime {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get pomodoroTotalSeconds =>
      isBreak ? breakMinutes * 60 : pomodoroMinutes * 60;
  int get pomodoroRemaining => pomodoroTotalSeconds - elapsedSeconds;

  String get pomodoroFormattedRemaining {
    final remaining = pomodoroRemaining.clamp(0, pomodoroTotalSeconds);
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  final TimeTrackingRepository _repository;
  final String? _userId;
  Timer? _timer;

  TimerNotifier(this._repository, this._userId) : super(const TimerState());

  /// Start a manual timer
  Future<void> startTimer(String taskId) async {
    if (_userId == null) return;
    if (state.isRunning) await stopTimer();

    final entry = await _repository.startTimer(
      taskId: taskId,
      userId: _userId,
      sessionType: TimerSessionType.manual,
    );

    state = TimerState(
      activeEntry: entry,
      activeTaskId: taskId,
      elapsedSeconds: 0,
      isRunning: true,
      sessionType: TimerSessionType.manual,
    );

    _startTicking();
  }

  /// Start a Pomodoro session
  Future<void> startPomodoro(
    String taskId, {
    int minutes = 25,
    int breakMin = 5,
    int target = 4,
  }) async {
    if (_userId == null) return;
    if (state.isRunning) await stopTimer();

    final entry = await _repository.startTimer(
      taskId: taskId,
      userId: _userId,
      sessionType: TimerSessionType.pomodoro,
    );

    state = TimerState(
      activeEntry: entry,
      activeTaskId: taskId,
      elapsedSeconds: 0,
      isRunning: true,
      pomodoroMinutes: minutes,
      breakMinutes: breakMin,
      pomodoroTarget: target,
      pomodoroCount: 0,
      isBreak: false,
      sessionType: TimerSessionType.pomodoro,
    );

    _startTicking();
  }

  /// Stop the timer
  Future<void> stopTimer() async {
    _timer?.cancel();
    if (state.activeEntry != null && state.activeTaskId != null) {
      if (state.sessionType == TimerSessionType.pomodoro) {
        await _repository.completePomodoroSession(
          entryId: state.activeEntry!.id,
          taskId: state.activeTaskId!,
          pomodoroCount: state.pomodoroCount,
        );
      } else {
        await _repository.stopTimer(state.activeEntry!.id, state.activeTaskId!);
      }
    }
    state = const TimerState();
  }

  /// Pause (just stops the tick but doesn't save)
  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resume
  void resumeTimer() {
    state = state.copyWith(isRunning: true);
    _startTicking();
  }

  /// Add manual time
  Future<void> addManualTime(String taskId, int minutes, {String? note}) async {
    if (_userId == null) return;
    await _repository.addManualEntry(
      taskId: taskId,
      userId: _userId,
      durationSeconds: minutes * 60,
      note: note,
    );
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isRunning) return;

      final newElapsed = state.elapsedSeconds + 1;

      // Pomodoro mode: check if session/break is complete
      if (state.sessionType == TimerSessionType.pomodoro) {
        if (newElapsed >= state.pomodoroTotalSeconds) {
          if (state.isBreak) {
            // Break done, start new pomodoro
            state = state.copyWith(elapsedSeconds: 0, isBreak: false);
          } else {
            // Pomodoro done
            final newCount = state.pomodoroCount + 1;
            if (newCount >= state.pomodoroTarget) {
              // All pomodoros done
              stopTimer();
              return;
            }
            // Start break
            state = state.copyWith(
              elapsedSeconds: 0,
              isBreak: true,
              pomodoroCount: newCount,
            );
          }
          return;
        }
      }

      state = state.copyWith(elapsedSeconds: newElapsed);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerNotifierProvider = StateNotifierProvider<TimerNotifier, TimerState>((
  ref,
) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return TimerNotifier(ref.read(timeTrackingRepositoryProvider), user?.uid);
});

/// Today's focus time
final todayFocusTimeProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;
  return ref
      .read(timeTrackingRepositoryProvider)
      .getTodayTotalSeconds(user.uid);
});
