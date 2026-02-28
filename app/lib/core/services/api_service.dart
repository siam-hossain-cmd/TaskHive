import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/tasks/domain/models/ai_analysis_model.dart';

// Update with your actual computer's IP or localhost
// For Android Emulator, use 10.0.2.2. For iOS Sim, use localhost or 127.0.0.1
// For real device on Wi-Fi, use your Mac's local IP address
const String _baseUrl = 'http://192.168.0.9:3001/api';

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
        body: jsonEncode({'uid': uid, 'fcmToken': fcmToken}),
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
        print(
          'Backend API Error: Failed to send user notification ${res.body}',
        );
      }
    } catch (e) {
      print('Backend API Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  AI ANALYSIS ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze a PDF and break it into sub-tasks using AI
  Future<AIAnalysisResult?> analyzeAssignment({
    required String pdfUrl,
    String? title,
    String? subject,
    List<Map<String, String>>? teamMembers,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/ai/analyze');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'pdfUrl': pdfUrl,
          if (title != null) 'title': title,
          if (subject != null) 'subject': subject,
          if (teamMembers != null) 'teamMembers': teamMembers,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AIAnalysisResult.fromJson(
          data,
          conversationId: data['conversationId'],
        );
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? 'Failed to analyze assignment');
      }
    } catch (e) {
      print('AI Analysis Error: $e');
      rethrow;
    }
  }

  /// Refine AI analysis with a chat message
  Future<List<AISubTask>?> refineAnalysis({
    required String conversationId,
    required String message,
    required List<AISubTask> currentSubtasks,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/ai/refine');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'conversationId': conversationId,
          'message': message,
          'currentSubtasks': currentSubtasks.map((s) => s.toJson()).toList(),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final subtasks = (data['updatedSubtasks'] as List<dynamic>? ?? [])
            .map((s) => AISubTask.fromJson(s as Map<String, dynamic>))
            .toList();
        return subtasks;
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? 'Failed to refine analysis');
      }
    } catch (e) {
      print('AI Refine Error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ASSIGNMENT ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create an assignment with subtasks (batch creation on backend)
  Future<Map<String, dynamic>?> createAssignment({
    required String groupId,
    required String title,
    String? subject,
    String? summary,
    String? originalPdfUrl,
    String? dueDate,
    required List<Map<String, dynamic>> subtasks,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/assignments');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'groupId': groupId,
          'title': title,
          if (subject != null) 'subject': subject,
          if (summary != null) 'summary': summary,
          if (originalPdfUrl != null) 'originalPdfUrl': originalPdfUrl,
          if (dueDate != null) 'dueDate': dueDate,
          'subtasks': subtasks,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['error'] ?? 'Failed to create assignment');
      }
    } catch (e) {
      print('Create Assignment Error: $e');
      rethrow;
    }
  }

  /// Submit work for a task
  Future<bool> submitTaskWork({
    required String taskId,
    required String submissionUrl,
    required String submissionFileName,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/tasks/$taskId/submit');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'submissionUrl': submissionUrl,
          'submissionFileName': submissionFileName,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Submit Task Error: $e');
      return false;
    }
  }

  /// Approve a task submission
  Future<bool> approveTask(String taskId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/tasks/$taskId/approve');

    try {
      final res = await http.post(url, headers: headers);
      return res.statusCode == 200;
    } catch (e) {
      print('Approve Task Error: $e');
      return false;
    }
  }

  /// Request changes on a task submission
  Future<bool> requestTaskChanges({
    required String taskId,
    required String feedback,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/tasks/$taskId/request-changes');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'feedback': feedback}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Request Changes Error: $e');
      return false;
    }
  }

  /// Add a comment on a task
  Future<Map<String, dynamic>?> addTaskComment({
    required String taskId,
    required String text,
    String type = 'general',
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/tasks/$taskId/comments');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'text': text, 'type': type}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('Add Comment Error: $e');
      return null;
    }
  }

  /// Assign a compiler to an assignment
  Future<bool> assignCompiler({
    required String assignmentId,
    required String compilerId,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '$_baseUrl/assignments/$assignmentId/assign-compiler',
    );

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'compilerId': compilerId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Assign Compiler Error: $e');
      return false;
    }
  }

  /// Upload final compiled document
  Future<bool> uploadFinalDoc({
    required String assignmentId,
    required String finalDocUrl,
    String? finalDocName,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/assignments/$assignmentId/upload-final');

    try {
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'finalDocUrl': finalDocUrl,
          'finalDocName': finalDocName,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Upload Final Doc Error: $e');
      return false;
    }
  }

  /// Mark assignment as completed
  Future<bool> completeAssignment(String assignmentId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/assignments/$assignmentId/complete');

    try {
      final res = await http.post(url, headers: headers);
      return res.statusCode == 200;
    } catch (e) {
      print('Complete Assignment Error: $e');
      return false;
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref);
});
