import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'api_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final service = PushNotificationService(apiService);
  ref.onDispose(() => service.dispose());
  return service;
});

final pushNotificationManagerProvider = Provider<void>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  final user = ref.watch(authStateProvider).value;
  
  if (user != null) {
    service.startListening(user.uid);
  } else {
    service.stopListening();
  }
});

class PushNotificationService {
  final ApiService _apiService;
  final _firestore = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();
  
  StreamSubscription? _incomingRequestsSub;
  StreamSubscription? _acceptedRequestsSub;
  String? _currentUid;
  
  PushNotificationService(this._apiService);
  
  bool _isInitIncoming = true;
  bool _isInitAccepted = true;

  void dispose() {
    stopListening();
  }

  void stopListening() {
    _incomingRequestsSub?.cancel();
    _acceptedRequestsSub?.cancel();
    _currentUid = null;
  }

  void startListening(String uid) async {
    if (_currentUid == uid) return;
    stopListening();
    
    _currentUid = uid;
    _isInitIncoming = true;
    _isInitAccepted = true;

    // Get FCM Token and send to backend
    try {
      await _fcm.requestPermission();
      String? fcmToken;
      
      if (kIsWeb) {
        fcmToken = await _fcm.getToken();
      } else if (Platform.isIOS) {
        // Wait for APNS token to be available (will remain null on Simulators)
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) {
          fcmToken = await _fcm.getToken();
        } else {
          print('APNS token is null. Running on simulator or APNS not configured.');
        }
      } else {
        fcmToken = await _fcm.getToken();
      }

      if (fcmToken != null) {
        await _apiService.registerFcmToken(uid, fcmToken);
      }
      
      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
         _apiService.registerFcmToken(uid, newToken);
      });
    } catch (e) {
      print('Failed to register FCM token: $e');
    }

    // Listen for new incoming requests
    _incomingRequestsSub = _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (_isInitIncoming) {
        _isInitIncoming = false;
        return; // Skip existing requests on startup
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final fromName = data['fromName'] ?? 'Someone';
            _showNotification(
              id: change.doc.id.hashCode,
              title: 'New Friend Request',
              body: '$fromName sent you a friend request to connect with.',
              payload: 'friend_request',
            );
          }
        }
      }
    });

    // Listen for accepted requests
    _acceptedRequestsSub = _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      if (_isInitAccepted) {
        _isInitAccepted = false;
        return; // Skip existing ones on startup
      }

      for (var change in snapshot.docChanges) {
        // We look for modified docs where status changed to accepted
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final toName = data['toName'] ?? 'User';
            _showNotification(
              id: change.doc.id.hashCode,
              title: 'Friend Request Accepted',
              body: '$toName accepted your friend request.',
              payload: 'friend_accepted',
            );
          }
        }
      }
    });
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'friend_requests_channel',
      'Friend Requests',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifs.show(id, title, body, details, payload: payload);
  }
}
