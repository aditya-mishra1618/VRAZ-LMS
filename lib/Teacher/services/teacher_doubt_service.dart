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

      // ✅ Correct endpoint from your CURL
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
        return []; // No doubts found
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load doubts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getMyDoubts: $e');
      rethrow;
    }
  }

  /// Mark doubt as resolved/closed (you can add this later)
  Future<bool> resolveDoubt(String token, int doubtId) async {
    try {
      print('✅ [TeacherDoubtService] Resolving doubt ID: $doubtId');

      final response = await http.patch(
        Uri.parse('$baseUrl/teachers/doubts/$doubtId/resolve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Doubt resolved successfully');
        return true;
      } else {
        print('❌ Error: ${response.body}');
        throw Exception('Failed to resolve doubt');
      }
    } catch (e) {
      print('❌ Error in resolveDoubt: $e');
      rethrow;
    }
  }
}