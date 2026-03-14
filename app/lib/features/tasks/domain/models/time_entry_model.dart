import 'package:cloud_firestore/cloud_firestore.dart';

enum TimerSessionType { manual, pomodoro }

class TimeEntryModel {
  final String id;
  final String taskId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final TimerSessionType sessionType;
  final int pomodoroCount;
  final String? note;

  TimeEntryModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.sessionType = TimerSessionType.manual,
    this.pomodoroCount = 0,
    this.note,
  });

  bool get isRunning => endTime == null;

  int get actualDuration {
    if (endTime != null) return durationSeconds;
    return DateTime.now().difference(startTime).inSeconds;
  }

  factory TimeEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeEntryModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      durationSeconds: data['durationSeconds'] ?? 0,
      sessionType: TimerSessionType.values.firstWhere(
        (e) => e.name == data['sessionType'],
        orElse: () => TimerSessionType.manual,
      ),
      pomodoroCount: data['pomodoroCount'] ?? 0,
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationSeconds': durationSeconds,
      'sessionType': sessionType.name,
      'pomodoroCount': pomodoroCount,
      'note': note,
    };
  }

  TimeEntryModel copyWith({
    String? id,
    String? taskId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    TimerSessionType? sessionType,
    int? pomodoroCount,
    String? note,
  }) {
    return TimeEntryModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sessionType: sessionType ?? this.sessionType,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      note: note ?? this.note,
    );
  }
}
