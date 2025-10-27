import 'dart:convert';

import 'package:http/http.dart' as http;

// Adjust path as needed
import '../models/assignment_api_models.dart';

class AssignmentApiService {
  final String _baseUrl = "https://vraz-backend-api.onrender.com/api/teachers";
  final String _baseApiUrl =
      "https://vraz-backend-api.onrender.com/api"; // For non-teacher specific

  // --- 1. Get Assignment Templates ---
  Future<List<ApiAssignmentTemplate>> getTemplates(String authToken) async {
    final Uri url = Uri.parse('$_baseUrl/assignments/getTemplates');
    print('GET: $url');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $authToken'});
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData
            .map((json) => ApiAssignmentTemplate.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTemplates: $e');
      rethrow;
    }
  }

  // --- 2. Get Teacher's Batches ---
  Future<List<ApiBatch>> getMyAssignedBatches(String authToken) async {
    final Uri url = Uri.parse('$_baseUrl/batches/myAssigned');
    print('GET: $url');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $authToken'});
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => ApiBatch.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load batches: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMyAssignedBatches: $e');
      rethrow;
    }
  }

  // --- 3. Assign Template to Batch ---
  Future<ApiAssignedAssignment> assignToBatch({
    required int templateId,
    required int batchId,
    required DateTime dueDate, // This includes date and time
    required int maxMarks,
    required String authToken,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/assignments/assignToBatch'); // Correct
    print('POST: $url');
    final String dueDateStr = dueDate.toUtc().toIso8601String();
    final Map<String, dynamic> body = {
      'assignmentTemplateId': templateId,
      'batchId': batchId,
      'dueDate': dueDateStr,
      'maxMarks': maxMarks
    };
    print('Assign Body: ${jsonEncode(body)}');
    try {
      final response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiAssignedAssignment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to assign batch: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in assignToBatch: $e');
      rethrow;
    }
  }

  // --- 4. Get Assignments for a Batch (GUESSED ENDPOINT) ---
  // This fetches the list of *assigned* assignments for the "Select Assignment" screen
  Future<List<ApiAssignedAssignment>> getAssignmentsForBatch(
      int batchId, String authToken) async {
    // *** THIS IS A GUESSED ENDPOINT. PLEASE VERIFY. ***
    final Uri url = Uri.parse('$_baseUrl/assignments/batch/$batchId');
    print('GET (Guessed): $url');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $authToken'});
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData
            .map((json) => ApiAssignedAssignment.fromJson(json))
            .toList();
      } else {
        if (response.statusCode == 404) return []; // No assignments found
        throw Exception(
            'Failed to load assignments for batch: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAssignmentsForBatch: $e');
      rethrow;
    }
  }

  // --- 5. Get Submissions for an Assignment ---
  Future<List<ApiSubmissionSummary>> getSubmissionsForAssignment(
      int assignedAssignmentId, String authToken) async {
    // --- UPDATED ENDPOINT ---
    // Using query parameter as assumed
    final Uri url = Uri.parse(
        '$_baseUrl/assignments/getSubmissions?batchAssignmentId=$assignedAssignmentId');
    print('GET: $url');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $authToken'});
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData
            .map((json) => ApiSubmissionSummary.fromJson(json))
            .toList();
      } else {
        if (response.statusCode == 404) return []; // No submissions found
        throw Exception('Failed to load submissions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getSubmissionsForAssignment: $e');
      rethrow;
    }
  }

  // --- 6. Get Submission Detail ---
  Future<ApiSubmissionDetail> getSubmissionDetail(
      int submissionId, String authToken) async {
    // --- UPDATED ENDPOINT ---
    final Uri url =
        Uri.parse('$_baseUrl/submissions/getSubmissionDetails/$submissionId');
    print('GET: $url');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $authToken'});
      if (response.statusCode == 200) {
        return ApiSubmissionDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load submission detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getSubmissionDetail: $e');
      rethrow;
    }
  }

  // --- 7. Grade Submission ---
  Future<ApiSubmissionDetail> gradeSubmission({
    required int submissionId,
    required int marks,
    required String feedback,
    required String authToken,
  }) async {
    // --- UPDATED ENDPOINT ---
    final Uri url =
        Uri.parse('$_baseUrl/submissions/gradeSubmission/$submissionId');
    print('POST: $url');
    final Map<String, dynamic> body = {'marks': marks, 'feedback': feedback};

    try {
      final response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming grading returns the updated submission detail
        return ApiSubmissionDetail.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to grade submission: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in gradeSubmission: $e');
      rethrow;
    }
  }

  // --- 8. Create Template (GUESSED ENDPOINT) ---
  Future<ApiAssignmentTemplate> createTemplate({
    required String title,
    required int subjectId, // You must provide this
    required String topic,
    required String subTopic,
    required String type,
    required String instructions,
    required List<Map<String, dynamic>> mcqQuestions,
    required String authToken,
  }) async {
    // *** THIS IS A GUESSED ENDPOINT. PLEASE VERIFY. ***
    final Uri url = Uri.parse('$_baseUrl/assignments/createTemplate');
    print('POST (Guessed): $url');
    final Map<String, dynamic> body = {
      'title': title,
      'description': instructions,
      'subjectId': subjectId,
      'type': type,
      'topic': topic,
      'subTopic': subTopic,
      'mcqQuestions': mcqQuestions,
      'attachments': [],
    };
    print('Create Template Body: ${jsonEncode(body)}');

    try {
      final response = await http.post(url,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(body));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiAssignmentTemplate.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to create template: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createTemplate: $e');
      rethrow;
    }
  }

  // --- 9. Get Subjects Map (GUESSED ENDPOINT) ---
  Future<Map<String, int>> getSubjectsMap(String authToken) async {
    // *** THIS IS A GUESSED ENDPOINT. PLEASE VERIFY. ***
    final Uri url =
        Uri.parse('$_baseApiUrl/subjects'); // Example: /api/subjects
    print('GET (Guessed): $url');
    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $authToken'});
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Convert list of {"id": 1, "name": "Physics"} to {"Physics": 1}
        return {
          for (var subject in jsonData)
            (subject['name'] as String): (subject['id'] as int)
        };
      }
    } catch (e) {
      print('Error in getSubjectsMap: $e');
    }
    // Fallback dummy map
    print("Warning: Using fallback subject map.");
    return {'Physics': 2, 'Chemistry': 1, 'Mathematics': 3, 'Biology': 4};
  }
}
