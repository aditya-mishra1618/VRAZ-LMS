import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/teacher_doubt_model.dart';

class TeacherDoubtService {
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';

  /// Get all doubts assigned to this teacher
  Future<List<TeacherDoubtModel>> getMyDoubts(String token) async {
    try {
      print('📥 [TeacherDoubtService] Fetching teacher doubts...');
      print('🔐 Bearer Token: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/teachers/doubts/getMyDoubts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ Doubts fetched successfully, count: ${jsonData.length}');

        return jsonData
            .map((json) => TeacherDoubtModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        print('⚠️ No doubts found (404)');
        return [];
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load doubts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getMyDoubts: $e');
      rethrow;
    }
  }

  /// Get chat messages for a specific doubt
  Future<DoubtChatResponse> getChat(String token, int doubtId) async {
    try {
      print('💬 [TeacherDoubtService] Fetching chat for doubt ID: $doubtId');
      print('🔐 Bearer Token: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/teachers/doubts/getChat/$doubtId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');
      print(
          '📨 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Chat fetched successfully');

        return DoubtChatResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Doubt not found.');
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load chat: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getChat: $e');
      rethrow;
    }
  }

  /// Send a text message in a doubt discussion
  Future<bool> sendMessage(
    String token,
    int doubtId, {
    String? text,
    String? imageUrl,
    String? voiceNoteUrl,
  }) async {
    try {
      print('📤 [TeacherDoubtService] Sending message to doubt ID: $doubtId');

      // ========== FINAL FIX: Using 'teachers' (plural) ==========
      // This path now matches the other working endpoints in this file
      // (like getMyDoubts, getChat, resolveDoubt).
      //
      // This will call:
      // https://vraz-backend-api.onrender.com/api/teachers/doubts/7/messages
      //
      final response = await http.post(
        Uri.parse(
            '$baseUrl/teachers/doubts/$doubtId/messages'), // <-- CORRECTED PATH
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Keys here (e.g., 'text') must match what the backend API expects
          if (text != null) 'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
        }),
      );
      // ======================================================

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Message sent successfully');
        return true;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in sendMessage: $e');
      rethrow;
    }
  }

  /// Mark doubt as resolved/closed
  Future<bool> resolveDoubt(String token, int doubtId) async {
    try {
      print('✅ [TeacherDoubtService] Resolving doubt ID: $doubtId');

      final response = await http.put(
        Uri.parse('$baseUrl/teachers/doubts/resolve/$doubtId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Doubt resolved successfully');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        print('❌ Error: ${response.body}');
        throw Exception('Failed to resolve doubt: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in resolveDoubt: $e');
      rethrow;
    }
  }
}
