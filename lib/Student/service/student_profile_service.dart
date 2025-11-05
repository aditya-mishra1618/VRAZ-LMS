// File: lib/Student/service/student_profile_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vraz_application/api_config.dart';
import '../models/student_profile_model.dart';

class StudentProfileService {
  /// Fetch student profile data
  Future<StudentProfileModel> getStudentProfile(String authToken) async {
    // Update this endpoint based on your actual API
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/profile');
    print('📘 [StudentProfileService] Fetching profile from $url');

    try {
      print('🔐 Bearer Token: Bearer ${authToken.substring(0, 20)}...');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📩 Profile Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('✅ Profile fetched successfully');
        return StudentProfileModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        throw Exception('Student profile not found');
      } else {
        print('❌ Profile fetch failed: ${response.body}');
        throw Exception(
            'Failed to load profile. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error in getStudentProfile(): $e');
      throw Exception('An error occurred while fetching profile: $e');
    }
  }
}