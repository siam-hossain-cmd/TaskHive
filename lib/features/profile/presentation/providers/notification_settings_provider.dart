import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ────────────────────────────────────────────────────────────────────
const _kPushEnabled = 'notif_push_enabled';
const _kReminderEnabled = 'notif_reminder_enabled';
const _kReminderHours = 'notif_reminder_hours';

// ─── Prefs singleton ─────────────────────────────────────────────────────────
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// ─── Notification Settings State ─────────────────────────────────────────────
class NotificationSettings {
  final bool pushEnabled;
  final bool reminderEnabled;
  final int reminderHours; // hours before deadline

  const NotificationSettings({
    this.pushEnabled = true,
    this.reminderEnabled = true,
    this.reminderHours = 24,
  });

  NotificationSettings copyWith({bool? pushEnabled, bool? reminderEnabled, int? reminderHours}) =>
      NotificationSettings(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHours: reminderHours ?? this.reminderHours,
      );
}

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      pushEnabled: prefs.getBool(_kPushEnabled) ?? true,
      reminderEnabled: prefs.getBool(_kReminderEnabled) ?? true,
      reminderHours: prefs.getInt(_kReminderHours) ?? 24,
    );
  }

  Future<void> togglePush(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushEnabled, value);
    state = AsyncData((state.value ?? const NotificationSettings()).copyWith(pushEnabled: value));
  }

  Future<void> toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReminderEnabled, value);
    state = AsyncData((state.value ?? const NotificationSettings()).copyWith(reminderEnabled: value));
  }

  Future<void> setReminderHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHours, hours);
    state = AsyncData((state.value ?? const NotificationSettings()).copyWith(reminderHours: hours));
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        NotificationSettingsNotifier.new);
