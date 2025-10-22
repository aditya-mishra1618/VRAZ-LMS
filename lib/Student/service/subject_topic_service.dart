// File: lib/Student/service/subject_topic_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/course_models.dart';

class SubjectTopicService {
  // TODO: Update this with your actual API base URL
  static const String baseUrl = 'YOUR_API_BASE_URL_HERE';
  static const String endpoint = '/api/subjects'; // Update with actual endpoint

  Future<List<SubjectModel>> getAllSubjectsWithTopics(String token) async {
    try {
      print('Fetching subjects and topics from API...');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, 200)}...'); // First 200 chars

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        List<SubjectModel> subjects = jsonData
            .map((json) => SubjectModel.fromJson(json))
            .toList();

        print('Successfully parsed ${subjects.length} subjects');
        return subjects;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found');
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in SubjectTopicService: $e');
      throw Exception('Failed to fetch subjects and topics: $e');
    }
  }
}