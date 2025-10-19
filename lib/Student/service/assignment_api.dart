// assignment_api_service.dart
// This file handles all API calls for assignments

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/assignment_model.dart';


class AssignmentApiService {
  // Base URL for the API
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';

  // Bearer token will be provided dynamically from SessionManager
  String? _bearerToken;

  AssignmentApiService({String? bearerToken}) : _bearerToken = bearerToken;

  /// Updates the bearer token dynamically
  void updateBearerToken(String newToken) {
    print('🔐 DEBUG: Updating Bearer Token in API Service');
    _bearerToken = newToken;
    print('✅ DEBUG: Bearer Token updated successfully');
  }

  /// Validates if bearer token is available
  bool _hasValidToken() {
    if (_bearerToken == null || _bearerToken!.isEmpty) {
      print('❌ DEBUG: No bearer token available');
      return false;
    }
    return true;
  }

  /// Fetches all assignments for the student
  /// Returns a list of AssignmentResponse objects
  Future<List<AssignmentResponse>> fetchMyAssignments() async {
    print('🚀 DEBUG: Starting fetchMyAssignments API call');

    // Check if token is available
    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot fetch assignments - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    print('🔐 DEBUG: Using Bearer Token: ${_bearerToken!.substring(0, 20)}...');

    final url = Uri.parse('$baseUrl/students/my/assignments');
    print('📡 DEBUG: API URL: $url');

    try {
      print('⏳ DEBUG: Sending GET request...');
      print('📅 DEBUG: Request timestamp: ${DateTime.now().toUtc().toIso8601String()}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ DEBUG: Request timeout after 30 seconds');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');
      print('📥 DEBUG: Response Headers: ${response.headers}');
      print('⏰ DEBUG: Response received at: ${DateTime.now().toUtc().toIso8601String()}');

      if (response.statusCode == 200) {
        print('✅ DEBUG: API call successful!');
        print('📦 DEBUG: Response Body Length: ${response.body.length} characters');

        // Parse the JSON response
        final List<dynamic> jsonData = json.decode(response.body);
        print('📊 DEBUG: Number of assignments received: ${jsonData.length}');

        // Convert JSON to List of AssignmentResponse objects
        final List<AssignmentResponse> assignments = jsonData
            .map((json) => AssignmentResponse.fromJson(json))
            .toList();

        print('✅ DEBUG: Successfully parsed ${assignments.length} assignments');

        // Debug: Print details of each assignment
        for (var i = 0; i < assignments.length; i++) {
          print('📝 DEBUG: Assignment ${i + 1}:');
          print('   - ID: ${assignments[i].id}');
          print('   - Title: ${assignments[i].assignmentTemplate.title}');
          print('   - Type: ${assignments[i].assignmentTemplate.type}');
          print('   - Due Date: ${assignments[i].dueDate}');
          print('   - Max Marks: ${assignments[i].maxMarks}');
          print('   - Submissions Count: ${assignments[i].submissions.length}');

          if (assignments[i].submissions.isNotEmpty) {
            final submission = assignments[i].submissions.first;
            print('   - Latest Submission Status: ${submission.status}');
            print('   - Marks: ${submission.marks ?? "Not graded"}');
          }
        }

        return assignments;
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized - Invalid or expired token');
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ DEBUG: Endpoint not found');
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('API endpoint not found. Please contact support.');
      } else if (response.statusCode == 500) {
        print('❌ DEBUG: Server error');
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('Server error. Please try again later.');
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        print('❌ DEBUG: Error Response Body: ${response.body}');
        throw Exception('Failed to load assignments. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ DEBUG: Network error occurred');
      print('❌ DEBUG: Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ DEBUG: Exception occurred during API call');
      print('❌ DEBUG: Exception type: ${e.runtimeType}');
      print('❌ DEBUG: Exception message: $e');
      rethrow;
    }
  }

  /// Fetches a specific assignment by ID
  /// Returns a single AssignmentResponse object
  Future<AssignmentResponse> fetchAssignmentById(int assignmentId) async {
    print('🚀 DEBUG: Fetching assignment with ID: $assignmentId');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot fetch assignment - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/assignments/$assignmentId');
    print('📡 DEBUG: API URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ DEBUG: Request timeout for assignment $assignmentId');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ DEBUG: Successfully fetched assignment $assignmentId');
        final jsonData = json.decode(response.body);
        return AssignmentResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized access for assignment $assignmentId');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ DEBUG: Assignment $assignmentId not found');
        throw Exception('Assignment not found.');
      } else {
        print('❌ DEBUG: Failed to fetch assignment $assignmentId');
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('Failed to load assignment. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception in fetchAssignmentById: $e');
      rethrow;
    }
  }

  /// Get current bearer token (for debugging)
  String? getCurrentToken() {
    return _bearerToken;
  }
}