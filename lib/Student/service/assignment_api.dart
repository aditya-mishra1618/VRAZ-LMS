// assignment_api_service.dart
// This file handles all API calls for assignments

import 'dart:convert';
import 'dart:io';
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

  /// Fetches detailed assignment information by ID
  /// Returns a single AssignmentResponse object with full MCQ questions
  Future<AssignmentResponse> getAssignmentDetails(int assignmentId) async {
    print('🚀 DEBUG: Starting getAssignmentDetails for ID: $assignmentId');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot fetch assignment details - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    print('🔐 DEBUG: Using Bearer Token: ${_bearerToken!.substring(0, 20)}...');

    final url = Uri.parse('$baseUrl/students/my/getAssignmentDetails/$assignmentId');
    print('📡 DEBUG: API URL: $url');

    try {
      print('⏳ DEBUG: Sending GET request for assignment details...');
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
      print('⏰ DEBUG: Response received at: ${DateTime.now().toUtc().toIso8601String()}');

      if (response.statusCode == 200) {
        print('✅ DEBUG: Assignment details fetched successfully!');
        print('📦 DEBUG: Response Body Length: ${response.body.length} characters');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        final assignment = AssignmentResponse.fromJson(jsonData);

        print('✅ DEBUG: Successfully parsed assignment details');
        print('📝 DEBUG: Assignment ID: ${assignment.id}');
        print('📝 DEBUG: Title: ${assignment.assignmentTemplate.title}');
        print('📝 DEBUG: Type: ${assignment.assignmentTemplate.type}');
        print('📝 DEBUG: Description: ${assignment.assignmentTemplate.description}');

        if (assignment.assignmentTemplate.mcqQuestions != null) {
          print('📝 DEBUG: MCQ Questions Count: ${assignment.assignmentTemplate.mcqQuestions!.length}');
          for (var i = 0; i < assignment.assignmentTemplate.mcqQuestions!.length; i++) {
            final q = assignment.assignmentTemplate.mcqQuestions![i];
            print('   Q${i + 1}: ${q.questionText}');
            print('   Options: ${q.options.length}');
          }
        }

        return assignment;
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized - Invalid or expired token');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ DEBUG: Assignment not found');
        throw Exception('Assignment not found.');
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('Failed to load assignment details. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ DEBUG: Network error occurred');
      print('❌ DEBUG: Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ DEBUG: Exception in getAssignmentDetails: $e');
      rethrow;
    }
  }

  /// ✅ NEW: Upload file and get URL
  /// Uploads a file to the server and returns the URL
  Future<String> uploadFile(File file) async {
    print('🚀 DEBUG: Starting file upload');
    print('📁 DEBUG: File path: ${file.path}');
    print('📁 DEBUG: File size: ${file.lengthSync()} bytes');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot upload file - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/doubts/uploadMedia');
    print('📡 DEBUG: Upload URL: $url');

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $_bearerToken';

      // Add file to request
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      print('⏳ DEBUG: Sending file upload request...');
      print('📅 DEBUG: Upload started at: ${DateTime.now().toUtc().toIso8601String()}');

      // Send request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏰ DEBUG: Upload timeout after 60 seconds');
          throw Exception('Upload timeout. Please check your internet connection.');
        },
      );

      // Get response
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 DEBUG: Upload Response Status Code: ${response.statusCode}');
      print('📥 DEBUG: Upload Response Body: ${response.body}');
      print('⏰ DEBUG: Upload completed at: ${DateTime.now().toUtc().toIso8601String()}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ DEBUG: File uploaded successfully!');

        final responseData = json.decode(response.body);

        // Extract URL from response
        // Adjust this based on your actual API response structure
        String fileUrl;
        if (responseData is Map && responseData.containsKey('url')) {
          fileUrl = responseData['url'];
        } else if (responseData is Map && responseData.containsKey('fileUrl')) {
          fileUrl = responseData['fileUrl'];
        } else if (responseData is String) {
          fileUrl = responseData;
        } else {
          print('⚠️ DEBUG: Unexpected response format: $responseData');
          throw Exception('Unexpected response format from upload API');
        }

        print('✅ DEBUG: File URL: $fileUrl');
        return fileUrl;
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized - Invalid or expired token');
        throw Exception('Session expired. Please login again.');
      } else {
        print('❌ DEBUG: Upload failed - Status: ${response.statusCode}');
        throw Exception('Failed to upload file. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ DEBUG: Network error during upload');
      print('❌ DEBUG: Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ DEBUG: Exception in uploadFile: $e');
      rethrow;
    }
  }

  /// Submit MCQ Assignment
  /// Submits MCQ answers for an assignment
  Future<void> submitMcqAssignment({
    required int assignmentId,
    required Map<String, String> mcqAnswers,
  }) async {
    print('🚀 DEBUG: Starting MCQ assignment submission');
    print('📝 DEBUG: Assignment ID: $assignmentId');
    print('📝 DEBUG: MCQ Answers: $mcqAnswers');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot submit - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/assignmentSubmit/$assignmentId');
    print('📡 DEBUG: API URL: $url');

    final requestBody = {
      'mcqAnswers': mcqAnswers,
    };

    print('📤 DEBUG: Request Body: ${json.encode(requestBody)}');

    try {
      print('⏳ DEBUG: Sending POST request...');
      print('📅 DEBUG: Request timestamp: ${DateTime.now().toUtc().toIso8601String()}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ DEBUG: Request timeout after 30 seconds');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');
      print('📥 DEBUG: Response Body: ${response.body}');
      print('⏰ DEBUG: Response received at: ${DateTime.now().toUtc().toIso8601String()}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ DEBUG: MCQ assignment submitted successfully!');
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized - Invalid or expired token');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        print('❌ DEBUG: Bad request');
        throw Exception('Invalid submission data. Please check your answers.');
      } else {
        print('❌ DEBUG: Submission failed - Status: ${response.statusCode}');
        throw Exception('Failed to submit assignment. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ DEBUG: Network error occurred');
      print('❌ DEBUG: Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ DEBUG: Exception in submitMcqAssignment: $e');
      rethrow;
    }
  }

  /// Submit Theory Assignment
  /// Submits theory assignment with text and optional file attachments
  Future<void> submitTheoryAssignment({
    required int assignmentId,
    required String solutionText,
    List<String>? solutionAttachments,
  }) async {
    print('🚀 DEBUG: Starting Theory assignment submission');
    print('📝 DEBUG: Assignment ID: $assignmentId');
    print('📝 DEBUG: Solution Text: $solutionText');
    print('📝 DEBUG: Attachments: ${solutionAttachments ?? []}');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot submit - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/assignmentSubmit/$assignmentId');
    print('📡 DEBUG: API URL: $url');

    final requestBody = {
      'solutionText': solutionText,
      'solutionAttachments': solutionAttachments ?? [],
    };

    print('📤 DEBUG: Request Body: ${json.encode(requestBody)}');

    try {
      print('⏳ DEBUG: Sending POST request...');
      print('📅 DEBUG: Request timestamp: ${DateTime.now().toUtc().toIso8601String()}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_bearerToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ DEBUG: Request timeout after 30 seconds');
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');
      print('📥 DEBUG: Response Body: ${response.body}');
      print('⏰ DEBUG: Response received at: ${DateTime.now().toUtc().toIso8601String()}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ DEBUG: Theory assignment submitted successfully!');
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized - Invalid or expired token');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        print('❌ DEBUG: Bad request');
        throw Exception('Invalid submission data. Please check your input.');
      } else {
        print('❌ DEBUG: Submission failed - Status: ${response.statusCode}');
        throw Exception('Failed to submit assignment. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ DEBUG: Network error occurred');
      print('❌ DEBUG: Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ DEBUG: Exception in submitTheoryAssignment: $e');
      rethrow;
    }
  }

  /// Get current bearer token (for debugging)
  String? getCurrentToken() {
    return _bearerToken;
  }
}