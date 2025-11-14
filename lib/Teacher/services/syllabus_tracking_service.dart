import 'dart:convert';

import 'package:http/http.dart' as http;

// Import the new topic models (adjust path if needed)
// Example: Assuming models are in 'lib/Teacher/models/'
import '../models/topic_models.dart';

class SyllabusTrackingService {
  final String _baseApiUrl =
      "https://vraz-backend-api.onrender.com/api"; // Base API URL
  final String _teacherBaseUrl =
      "https://vraz-backend-api.onrender.com/api/teachers"; // Teacher specific base

  // --- Get Topics for a Subject ---
  Future<List<Topic>> getTopicsForSubject(
      int subjectId, String authToken) async {
    // Correct endpoint based on API structure provided
    final Uri url = Uri.parse('$_teacherBaseUrl/topics/subject/$subjectId');
    print('GET: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      print('Response Status (getTopicsForSubject): ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final topics = jsonData.map((json) => Topic.fromJson(json)).toList();
        // Sort topics by name or order if available in API
        topics.sort((a, b) => a.name.compareTo(b.name));
        return topics;
      } else {
        throw Exception(
            'Failed to load topics for subject $subjectId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching topics for subject $subjectId: $e');
      rethrow;
    }
  }

  Future<String> submitSyllabusRemark({
    required int sessionId,
    required int
        topicId, // This should be the ID of the selected Topic or SubTopic
    required String remark, // This will be the description + manual subtopic
    required String authToken,
  }) async {
    // Endpoint provided by user
    final Uri url =
        Uri.parse('$_teacherBaseUrl/remarks/submitRemark/$sessionId');
    print('POST: $url');

    // API expects a specific structure for remarks
    final Map<String, dynamic> body = {
      "remarks": [
        {
          "topicId": topicId,
          "remark": remark
        } // Send the determined topicId and combined remark
      ]
    };

    print('Request Body (submitSyllabusRemark): ${jsonEncode(body)}');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      print('Response Status (submitSyllabusRemark): ${response.statusCode}');
      print('Response Body (submitSyllabusRemark): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        return jsonData['message'] ?? 'Remarks submitted successfully!';
      } else {
        String serverMessage = 'Unknown server error';
        try {
          final errorBody = jsonDecode(response.body);
          serverMessage = errorBody['message'] ?? serverMessage;
        } catch (_) {
          serverMessage =
              response.body.isNotEmpty ? response.body : serverMessage;
        }
        throw Exception(
            'Failed to submit remarks. Status: ${response.statusCode}, Message: $serverMessage');
      }
    } catch (e) {
      print('Error submitting syllabus remarks: $e');
      rethrow;
    }
  }

  // --- Get Subject Name By ID ---
  // Replace with your actual Subject API endpoint if available
  Future<String> getSubjectNameById(int subjectId, String authToken) async {
    // *** Using a Placeholder Mapping - Replace with API Call ***
    // This avoids an extra API call if you know the mapping, but an API is better
    Map<int, String> subjectMap = {
      1: 'Chemistry',
      2: 'Physics',
      3: 'Mathematics',
      4: 'Biology',
      // Add other subject IDs and names as needed
    };
    if (subjectMap.containsKey(subjectId)) {
      return subjectMap[subjectId]!;
    } else {
      print(
          'Warning: Subject ID $subjectId not found in local map. Fetching from placeholder API...');
      // Fallback to a (placeholder) API call if map doesn't contain the ID
      final Uri url =
          Uri.parse('$_baseApiUrl/subjects/$subjectId'); // Placeholder URL
      print('GET (Placeholder): $url');
      try {
        final response = await http
            .get(url, headers: {'Authorization': 'Bearer $authToken'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['name'] ?? 'Subject ($subjectId)';
        } else {
          print(
              'Failed to get subject name for ID $subjectId: ${response.statusCode}');
          return 'Subject ($subjectId)'; // Fallback
        }
      } catch (e) {
        print('Error fetching subject name for ID $subjectId: $e');
        return 'Subject ($subjectId)'; // Fallback
      }
    }
  }
}
