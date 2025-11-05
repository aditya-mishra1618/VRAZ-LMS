import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feedback_model.dart';
import '../models/faculty_model.dart';

class FeedbackService {
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';

  String? _authToken;

  void setAuthToken(String token) {
    print('🔐 DEBUG: Setting auth token in FeedbackService');
    _authToken = token;
    print('✅ DEBUG: Token set successfully');
  }

  bool _hasValidToken() {
    if (_authToken == null || _authToken!.isEmpty) {
      print('❌ DEBUG: No bearer token available');
      return false;
    }
    return true;
  }

  // Get all available feedback forms
  Future<List<FeedbackFormAssignment>> getMyFeedbackForms() async {
    print('🚀 DEBUG: Starting getMyFeedbackForms API call');
    print('⏰ DEBUG: Request time: ${DateTime.now().toUtc().toIso8601String()}');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot fetch feedback forms - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    print('🔐 DEBUG: Using token: ${_authToken!.substring(0, 20)}...');

    final url = Uri.parse('$baseUrl/students/my/feedbackForms');
    print('📡 DEBUG: API URL: $url');

    try {
      print('⏳ DEBUG: Sending GET request...');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
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
      print('📥 DEBUG: Response Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        print('✅ DEBUG: API call successful!');

        final List<dynamic> jsonData = json.decode(response.body);
        print('📊 DEBUG: Number of forms received: ${jsonData.length}');

        final forms = jsonData
            .map((json) {
          try {
            return FeedbackFormAssignment.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('❌ DEBUG: Error parsing form: $e');
            print('❌ DEBUG: Problematic JSON: $json');
            rethrow;
          }
        })
            .toList();

        print('✅ DEBUG: Successfully parsed ${forms.length} feedback forms');

        if (forms.isNotEmpty) {
          print('📝 DEBUG: First form:');
          print('   - ID: ${forms.first.id}');
          print('   - Title: ${forms.first.form.title}');
          print('   - Type: ${forms.first.form.formType}');
          print('   - Has Submitted: ${forms.first.hasSubmitted}');
          print('   - Is Active: ${forms.first.isActive}');
        }

        return forms;
      } else if (response.statusCode == 401) {
        print('❌ DEBUG: Unauthorized - Invalid or expired token');
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ DEBUG: Endpoint not found');
        throw Exception('API endpoint not found. Please contact support.');
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('Failed to load feedback forms. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception occurred during API call');
      print('❌ DEBUG: Exception type: ${e.runtimeType}');
      print('❌ DEBUG: Exception message: $e');
      rethrow;
    }
  }

  // Get form details with questions
  Future<FeedbackFormDetails> getFormDetails(int formAssignmentId) async {
    print('🚀 DEBUG: Starting getFormDetails for ID: $formAssignmentId');
    print('⏰ DEBUG: Request time: ${DateTime.now().toUtc().toIso8601String()}');

    if (!_hasValidToken()) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/feedbackForms/$formAssignmentId');
    print('📡 DEBUG: API URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ DEBUG: Form details fetched successfully');

        final jsonData = json.decode(response.body);
        final formDetails = FeedbackFormDetails.fromJson(jsonData);

        print('📝 DEBUG: Form Title: ${formDetails.form.title}');
        print('📝 DEBUG: Form Type: ${formDetails.form.formType}');

        if (formDetails.form.questions != null) {
          print('📝 DEBUG: Number of questions: ${formDetails.form.questions!.length}');
        }

        return formDetails;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        throw Exception('Failed to load form details. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception: $e');
      rethrow;
    }
  }

  // Get batch faculty members
  Future<List<FacultyModel>> getBatchFaculty() async {
    print('🚀 DEBUG: Starting getBatchFaculty API call');
    print('⏰ DEBUG: Request time: ${DateTime.now().toUtc().toIso8601String()}');

    if (!_hasValidToken()) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/batchFaculty');
    print('📡 DEBUG: API URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ DEBUG: Faculty list fetched successfully');

        final List<dynamic> jsonData = json.decode(response.body);
        print('📊 DEBUG: Number of faculty members: ${jsonData.length}');

        final faculties = jsonData
            .map((json) => FacultyModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ DEBUG: Successfully parsed ${faculties.length} faculty members');

        if (faculties.isNotEmpty) {
          print('📝 DEBUG: First faculty: ${faculties.first.fullName}');
        }

        return faculties;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        throw Exception('Failed to load faculty list. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception: $e');
      rethrow;
    }
  }

  // Submit GENERAL feedback
  Future<void> submitGeneralFeedback({
    required int formAssignmentId,
    required Map<String, String> answers,
  }) async {
    print('🚀 DEBUG: Starting submitGeneralFeedback');
    print('📝 DEBUG: Form Assignment ID: $formAssignmentId');
    print('📝 DEBUG: Answers: $answers');
    print('⏰ DEBUG: Submission time: ${DateTime.now().toUtc().toIso8601String()}');

    if (!_hasValidToken()) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/feedbackForms/submit/$formAssignmentId');
    print('📡 DEBUG: API URL: $url');

    final body = json.encode({'answers': answers});
    print('📤 DEBUG: Request body: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');
      print('📥 DEBUG: Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ DEBUG: General feedback submitted successfully!');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid feedback data. Please check your answers.');
      } else {
        print('❌ DEBUG: Submission failed with status: ${response.statusCode}');
        throw Exception('Failed to submit feedback. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception during submission: $e');
      rethrow;
    }
  }

  // Submit FACULTY_REVIEW feedback
  Future<void> submitFacultyFeedback({
    required int formAssignmentId,
    required List<FacultyFeedbackSubmission> facultyFeedback,
  }) async {
    print('🚀 DEBUG: Starting submitFacultyFeedback');
    print('📝 DEBUG: Form Assignment ID: $formAssignmentId');
    print('📝 DEBUG: Number of faculty reviews: ${facultyFeedback.length}');
    print('⏰ DEBUG: Submission time: ${DateTime.now().toUtc().toIso8601String()}');

    if (!_hasValidToken()) {
      throw Exception('Authentication token not found. Please login again.');
    }

    final url = Uri.parse('$baseUrl/students/my/feedbackForms/submit/$formAssignmentId');
    print('📡 DEBUG: API URL: $url');

    final body = json.encode({
      'facultyFeedback': facultyFeedback.map((f) => f.toJson()).toList(),
    });
    print('📤 DEBUG: Request body: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('📥 DEBUG: Response Status Code: ${response.statusCode}');
      print('📥 DEBUG: Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ DEBUG: Faculty feedback submitted successfully!');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid feedback data. Please check your ratings.');
      } else {
        print('❌ DEBUG: Submission failed with status: ${response.statusCode}');
        throw Exception('Failed to submit feedback. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception during submission: $e');
      rethrow;
    }
  }
}