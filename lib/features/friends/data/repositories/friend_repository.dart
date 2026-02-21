import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/friend_model.dart';

class FriendRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Collection refs ─────────────────────────────────────────────────────────
  CollectionReference get _friendsRef => _firestore.collection('friends');
  CollectionReference get _requestsRef => _firestore.collection('friend_requests');
  CollectionReference get _messagesRef => _firestore.collection('friend_messages');
  CollectionReference get _usersRef => _firestore.collection('users');

  // ── User search ─────────────────────────────────────────────────────────────
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim();
    final results = <UserProfile>{}; // Set to deduplicate

    // 1️⃣ Try exact User-ID lookup (UID has no '@' and is typically ≥20 chars)
    if (!q.contains('@') && q.length >= 6) {
      try {
        final doc = await _usersRef.doc(q).get();
        if (doc.exists) {
          results.add(UserProfile.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'uid': doc.id,
          }));
        }
      } catch (_) {}
    }

    // 2️⃣ Email prefix search
    final lq = q.toLowerCase();
    final emailSnap = await _usersRef
        .where('email', isGreaterThanOrEqualTo: lq)
        .where('email', isLessThanOrEqualTo: '$lq\uf8ff')
        .limit(20)
        .get();
    for (final d in emailSnap.docs) {
      results.add(UserProfile.fromMap({
        ...d.data() as Map<String, dynamic>,
        'uid': d.id,
      }));
    }

    return results.toList();
  }

  // ── Friend Requests ─────────────────────────────────────────────────────────

  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
    required String fromName,
    required String fromEmail,
    String? fromPhotoUrl,
  }) async {
    // Check if request already exists
    final existing = await _requestsRef
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.docs.isNotEmpty) return;

    await _requestsRef.add(FriendRequestModel(
      id: '',
      fromUid: fromUid,
      toUid: toUid,
      fromName: fromName,
      fromEmail: fromEmail,
      fromPhotoUrl: fromPhotoUrl,
      createdAt: DateTime.now(),
    ).toFirestore());
  }

  Stream<List<FriendRequestModel>> getIncomingRequests(String uid) {
    return _requestsRef
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => FriendRequestModel.fromFirestore(d)).toList());
  }

  Stream<List<FriendRequestModel>> getOutgoingRequests(String uid) {
    return _requestsRef
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => FriendRequestModel.fromFirestore(d)).toList());
  }

  Future<void> acceptRequest(FriendRequestModel req) async {
    // Update request status
    await _requestsRef.doc(req.id).update({'status': 'accepted'});

    // Fetch toUser info
    final toUserDoc = await _usersRef.doc(req.toUid).get();
    final toData = toUserDoc.data() as Map<String, dynamic>? ?? {};
    final toName = toData['displayName'] ?? toData['email'] ?? req.toUid;
    final toEmail = toData['email'] ?? '';
    final toPhotoUrl = toData['photoUrl'];
    final toFcmToken = toData['fcmToken'];

    final fromUserDoc = await _usersRef.doc(req.fromUid).get();
    final fromData = fromUserDoc.data() as Map<String, dynamic>? ?? {};
    final fromFcmToken = fromData['fcmToken'];

    final now = DateTime.now();

    // Create friend entry for both users
    await _friendsRef.add(FriendModel(
      id: '',
      userId: req.toUid,
      friendUid: req.fromUid,
      friendName: req.fromName,
      friendEmail: req.fromEmail,
      friendPhotoUrl: req.fromPhotoUrl,
      fcmToken: fromFcmToken,
      connectedAt: now,
    ).toFirestore());

    await _friendsRef.add(FriendModel(
      id: '',
      userId: req.fromUid,
      friendUid: req.toUid,
      friendName: toName,
      friendEmail: toEmail,
      friendPhotoUrl: toPhotoUrl,
      fcmToken: toFcmToken,
      connectedAt: now,
    ).toFirestore());
  }

  Future<void> declineRequest(String requestId) async {
    await _requestsRef.doc(requestId).update({'status': 'declined'});
  }

  Future<void> removeFriend(String userId, String friendUid) async {
    final snap = await _friendsRef
        .where('userId', isEqualTo: userId)
        .where('friendUid', isEqualTo: friendUid)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    final snap2 = await _friendsRef
        .where('userId', isEqualTo: friendUid)
        .where('friendUid', isEqualTo: userId)
        .get();
    for (final doc in snap2.docs) {
      await doc.reference.delete();
    }
  }

  // ── Friends list ─────────────────────────────────────────────────────────────

  Stream<List<FriendModel>> getFriends(String uid) {
    return _friendsRef
        .where('userId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => FriendModel.fromFirestore(d)).toList());
  }

  // Return the FriendModel doc for a specific friendship
  Future<FriendModel?> getFriend(String myUid, String friendUid) async {
    final snap = await _friendsRef
        .where('userId', isEqualTo: myUid)
        .where('friendUid', isEqualTo: friendUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return FriendModel.fromFirestore(snap.docs.first);
  }

  // ── Messages ─────────────────────────────────────────────────────────────────

  Stream<List<FriendMessageModel>> getMessages(String chatId) {
    return _messagesRef
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => FriendMessageModel.fromFirestore(d)).toList());
  }

  Future<void> sendMessage(FriendMessageModel msg) async {
    await _messagesRef.add(msg.toFirestore());
    // Update last message on both friend entries
    final chatParts = msg.chatId.split('_');
    if (chatParts.length == 2) {
      final [uid1, uid2] = chatParts;
      final now = Timestamp.fromDate(msg.timestamp);
      final update = {
        'lastMessage': msg.text,
        'lastMessageAt': now,
      };
      // Update uid1's friend entry pointing to uid2
      final s1 = await _friendsRef
          .where('userId', isEqualTo: uid1)
          .where('friendUid', isEqualTo: uid2)
          .get();
      for (final d in s1.docs) {
        // Only increment unread for receiver
        final isReceiver = uid1 != msg.senderId;
        await d.reference.update({
          ...update,
          if (isReceiver) 'unreadCount': FieldValue.increment(1),
        });
      }
      final s2 = await _friendsRef
          .where('userId', isEqualTo: uid2)
          .where('friendUid', isEqualTo: uid1)
          .get();
      for (final d in s2.docs) {
        final isReceiver = uid2 != msg.senderId;
        await d.reference.update({
          ...update,
          if (isReceiver) 'unreadCount': FieldValue.increment(1),
        });
      }
    }
  }

  Future<void> markMessagesRead(String chatId, String uid) async {
    // Update unread count to 0 for this chat
    final chatSnap = await _friendsRef
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in chatSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fuid = data['friendUid'] ?? '';
      final expectedChatId = FriendMessageModel.buildChatId(uid, fuid);
      if (expectedChatId == chatId) {
        await doc.reference.update({'unreadCount': 0});
      }
    }
  }

  // ── User profile management ──────────────────────────────────────────────────
  Future<void> upsertUserProfile(User user) async {
    await _usersRef.doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
      'email': user.email ?? '',
      'photoUrl': user.photoURL,
    }, SetOptions(merge: true));
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _usersRef.doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }
}
