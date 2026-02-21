import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Friend Status ────────────────────────────────────────────────────────────
enum FriendRequestStatus { pending, accepted, declined }

// ─── User Profile (lightweight, stored on friend doc) ────────────────────────
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? 'Unknown',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
  };

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    return '?';
  }
}

// ─── Friend Request ────────────────────────────────────────────────────────────
class FriendRequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromName;
  final String fromEmail;
  final String? fromPhotoUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.fromEmail,
    this.fromPhotoUrl,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      fromName: data['fromName'] ?? '',
      fromEmail: data['fromEmail'] ?? '',
      fromPhotoUrl: data['fromPhotoUrl'],
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fromUid': fromUid,
    'toUid': toUid,
    'fromName': fromName,
    'fromEmail': fromEmail,
    'fromPhotoUrl': fromPhotoUrl,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─── Friend (accepted connection) ─────────────────────────────────────────────
class FriendModel {
  final String id; // Firestore doc ID
  final String userId; // owner
  final String friendUid;
  final String friendName;
  final String friendEmail;
  final String? friendPhotoUrl;
  final String? fcmToken; // for push notifications
  final DateTime connectedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  FriendModel({
    required this.id,
    required this.userId,
    required this.friendUid,
    required this.friendName,
    required this.friendEmail,
    this.friendPhotoUrl,
    this.fcmToken,
    required this.connectedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      friendUid: data['friendUid'] ?? '',
      friendName: data['friendName'] ?? '',
      friendEmail: data['friendEmail'] ?? '',
      friendPhotoUrl: data['friendPhotoUrl'],
      fcmToken: data['fcmToken'],
      connectedAt: (data['connectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: (data['unreadCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'friendUid': friendUid,
    'friendName': friendName,
    'friendEmail': friendEmail,
    'friendPhotoUrl': friendPhotoUrl,
    'fcmToken': fcmToken,
    'connectedAt': Timestamp.fromDate(connectedAt),
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    'unreadCount': unreadCount,
  };

  String get initials {
    final parts = friendName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (friendName.isNotEmpty) return friendName[0].toUpperCase();
    return '?';
  }
}

// ─── Direct Message ────────────────────────────────────────────────────────────
class FriendMessageModel {
  final String id;
  final String chatId; // sorted(uid1, uid2).join('_')
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  FriendMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory FriendMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendMessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
  };

  /// Build a stable chat ID from two UIDs (alphabetical sort)
  static String buildChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }
}
