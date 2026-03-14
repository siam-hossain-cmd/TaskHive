import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReminderType {
  birthday,
  anniversary,
  meeting,
  appointment,
  billPayment,
  medication,
  event,
  deadline,
  followUp,
  custom,
}

enum ReminderRecurrence { none, daily, weekly, monthly, yearly }

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.birthday:
        return 'Birthday';
      case ReminderType.anniversary:
        return 'Anniversary';
      case ReminderType.meeting:
        return 'Meeting';
      case ReminderType.appointment:
        return 'Appointment';
      case ReminderType.billPayment:
        return 'Bill Payment';
      case ReminderType.medication:
        return 'Medication';
      case ReminderType.event:
        return 'Event / Occasion';
      case ReminderType.deadline:
        return 'Deadline';
      case ReminderType.followUp:
        return 'Follow-up';
      case ReminderType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderType.birthday:
        return Icons.cake_rounded;
      case ReminderType.anniversary:
        return Icons.favorite_rounded;
      case ReminderType.meeting:
        return Icons.groups_rounded;
      case ReminderType.appointment:
        return Icons.calendar_month_rounded;
      case ReminderType.billPayment:
        return Icons.payment_rounded;
      case ReminderType.medication:
        return Icons.medication_rounded;
      case ReminderType.event:
        return Icons.celebration_rounded;
      case ReminderType.deadline:
        return Icons.timer_rounded;
      case ReminderType.followUp:
        return Icons.replay_rounded;
      case ReminderType.custom:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ReminderType.birthday:
        return const Color(0xFFE91E63);
      case ReminderType.anniversary:
        return const Color(0xFFFF5252);
      case ReminderType.meeting:
        return const Color(0xFF2196F3);
      case ReminderType.appointment:
        return const Color(0xFF00BCD4);
      case ReminderType.billPayment:
        return const Color(0xFFFF9800);
      case ReminderType.medication:
        return const Color(0xFF4CAF50);
      case ReminderType.event:
        return const Color(0xFF9C27B0);
      case ReminderType.deadline:
        return const Color(0xFFF44336);
      case ReminderType.followUp:
        return const Color(0xFF607D8B);
      case ReminderType.custom:
        return const Color(0xFF795548);
    }
  }
}

extension ReminderRecurrenceExtension on ReminderRecurrence {
  String get label {
    switch (this) {
      case ReminderRecurrence.none:
        return 'No Repeat';
      case ReminderRecurrence.daily:
        return 'Daily';
      case ReminderRecurrence.weekly:
        return 'Weekly';
      case ReminderRecurrence.monthly:
        return 'Monthly';
      case ReminderRecurrence.yearly:
        return 'Yearly';
    }
  }
}

class ReminderModel {
  final String id;
  final String userId;
  final ReminderType type;
  final String title;
  final String remark;
  final DateTime date;
  final ReminderRecurrence recurrence;
  final int notifyBeforeMinutes; // 0 = at time, 5, 15, 30, 60, 1440 (1 day)
  final bool isCompleted;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.remark = '',
    required this.date,
    this.recurrence = ReminderRecurrence.none,
    this.notifyBeforeMinutes = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReminderType.custom,
      ),
      title: data['title'] ?? '',
      remark: data['remark'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurrence: ReminderRecurrence.values.firstWhere(
        (e) => e.name == data['recurrence'],
        orElse: () => ReminderRecurrence.none,
      ),
      notifyBeforeMinutes: data['notifyBeforeMinutes'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'remark': remark,
      'date': Timestamp.fromDate(date),
      'recurrence': recurrence.name,
      'notifyBeforeMinutes': notifyBeforeMinutes,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? userId,
    ReminderType? type,
    String? title,
    String? remark,
    DateTime? date,
    ReminderRecurrence? recurrence,
    int? notifyBeforeMinutes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      remark: remark ?? this.remark,
      date: date ?? this.date,
      recurrence: recurrence ?? this.recurrence,
      notifyBeforeMinutes: notifyBeforeMinutes ?? this.notifyBeforeMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Human-readable label for the notify-before setting
  static String notifyBeforeLabel(int minutes) {
    switch (minutes) {
      case 0:
        return 'At time of reminder';
      case 5:
        return '5 minutes before';
      case 15:
        return '15 minutes before';
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 1440:
        return '1 day before';
      default:
        return '$minutes minutes before';
    }
  }

  /// All available notify-before options
  static const List<int> notifyBeforeOptions = [0, 5, 15, 30, 60, 1440];
}
