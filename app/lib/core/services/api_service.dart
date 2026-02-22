import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

// Update with your actual computer's IP or localhost
// For Android Emulator, use 10.0.2.2. For iOS Sim, use localhost or 127.0.0.1
const String _baseUrl = 'http://localhost:3001/api';

class ApiService {
  final Ref _ref;
  ApiService(this._ref);

  Future<Map<String, String>> _getHeaders() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return {'Content-Type': 'application/json'};
    
    // We send the Firebase Auth ID Token to the Node.js backend
    // to authenticate the user securely
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Register device FCM token to backend
  Future<void> registerFcmToken(String uid, String fcmToken) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/notifications/register-token');
    
    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'uid': uid,
          'fcmToken': fcmToken,
        }),
      );
      if (res.statusCode != 200) {
        print('Backend API Error: Failed to register token ${res.body}');
      }
    } catch (e) {
      print('Backend API Error: $e');
    }
  }

  Future<void> sendUserNotification({
    required String targetUid,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/notifications/user-to-user');
    
    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'targetUid': targetUid,
          'title': title,
          'body': body,
          if (payload != null) 'payload': payload,
        }),
      );
      if (res.statusCode != 200) {
        print('Backend API Error: Failed to send user notification ${res.body}');
      }
    } catch (e) {
      print('Backend API Error: $e');
    }
  }

  // You can route other functions here later (like sending push notifications to friends)
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});
