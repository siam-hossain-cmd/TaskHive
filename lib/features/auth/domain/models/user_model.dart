import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String uniqueId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final int xp;
  final int streak;
  final List<String> badges;
  final UserSettings settings;

  UserModel({
    required this.uid,
    required this.uniqueId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.xp = 0,
    this.streak = 0,
    this.badges = const [],
    required this.settings,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      uniqueId: data['uniqueId'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      xp: data['xp'] ?? 0,
      streak: data['streak'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      settings: UserSettings.fromMap(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uniqueId': uniqueId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'xp': xp,
      'streak': streak,
      'badges': badges,
      'settings': settings.toMap(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? uniqueId,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    int? xp,
    int? streak,
    List<String>? badges,
    UserSettings? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      uniqueId: uniqueId ?? this.uniqueId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      settings: settings ?? this.settings,
    );
  }
}

class UserSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final int reminderHoursBefore;

  UserSettings({
    this.darkMode = true,
    this.notificationsEnabled = true,
    this.reminderHoursBefore = 24,
  });

  factory UserSettings.fromMap(Map<String, dynamic> data) {
    return UserSettings(
      darkMode: data['darkMode'] ?? true,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      reminderHoursBefore: data['reminderHoursBefore'] ?? 24,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'reminderHoursBefore': reminderHoursBefore,
    };
  }

  UserSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    int? reminderHoursBefore,
  }) {
    return UserSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderHoursBefore: reminderHoursBefore ?? this.reminderHoursBefore,
    );
  }
}
