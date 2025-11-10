import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../api_config.dart'; // Import API config
import '../models/board_result_model.dart';

class BoardResultService {
  // Use baseUrl from ApiConfig
  static const String baseUrl = ApiConfig.baseUrl;

  String? _authToken;

  void setAuthToken(String token) {
    print('🔐 DEBUG: Setting auth token in BoardResultService');
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

  // Helper for making authenticated GET requests
  Future<Map<String, dynamic>?> _get(String path) async {
    if (!_hasValidToken()) {
      throw Exception('Authentication token not found. Please login again.');
    }
    // --- FIX: Path now correctly includes /api ---
    final url = Uri.parse('$baseUrl/api$path');
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
        print('✅ DEBUG: API call successful!');
        // Handle cases where the response is a list (like getMyResults)
        // This helper is designed for Map responses, so we'll adjust getMyResults
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        throw Exception('Failed to load data. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception occurred during API call: $e');
      rethrow;
    }
  }

  Future<List<BoardResultResponse>> getMyResults() async {
    print('🚀 DEBUG: Starting getMyResults API call');
    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot fetch results - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }
    print('🔐 DEBUG: Using token: ${_authToken!.substring(0, 20)}...');

    // --- FIX: Added /api to the path ---
    final url = Uri.parse('$baseUrl/api/students/my/results');
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
        print('✅ DEBUG: API call successful!');
        // This API returns a List, not a Map
        final List<dynamic> jsonData = json.decode(response.body);
        print('📊 DEBUG: Number of results received: ${jsonData.length}');
        if (jsonData.isEmpty) return [];

        final results = jsonData
            .map((json) =>
                BoardResultResponse.fromJson(json as Map<String, dynamic>))
            .toList();
        print('✅ DEBUG: Successfully parsed ${results.length} results');
        return results;
      } else {
        print('❌ DEBUG: API Error - Status: ${response.statusCode}');
        throw Exception(
            'Failed to load results. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception occurred during API call: $e');
      rethrow;
    }
  }

  // --- NEW: Added getTestDetail API ---
  Future<TestDetailResponse> getTestDetail(int testId) async {
    // Uses the helper _get which already has /api
    final json = await _get('/students/my/tests/$testId');
    if (json != null) {
      return TestDetailResponse.fromJson(json);
    } else {
      throw Exception('Failed to get test details');
    }
  }

  // --- NEW: Added getTestPerformance API ---
  Future<PerformanceResponse> getTestPerformance(int testId) async {
    // Uses the helper _get which already has /api
    final json = await _get('/students/my/performance/test/$testId');
    if (json != null) {
      return PerformanceResponse.fromJson(json);
    } else {
      throw Exception('Failed to get test performance');
    }
  }

  // --- NEW: Added getOverallPerformance API ---
  Future<SubjectPerformanceResponse> getOverallPerformance() async {
    // Uses the helper _get which already has /api
    final json = await _get('/students/my/performance/overall');
    if (json != null) {
      return SubjectPerformanceResponse.fromJson(json);
    } else {
      throw Exception('Failed to get overall performance');
    }
  }

  // --- NEW: Added getSubjectPerformance API ---
  Future<SubjectPerformanceResponse> getSubjectPerformance(
      String subjectId) async {
    // Uses the helper _get which already has /api
    final json = await _get('/students/my/performance/subject/$subjectId');
    if (json != null) {
      return SubjectPerformanceResponse.fromJson(json);
    } else {
      throw Exception('Failed to get subject performance');
    }
  }

  // --- FIX: This function now requires the list of results ---
  Map<String, SubjectPerformance> calculateLocalSubjectPerformance(
      List<BoardResultResponse> results) {
    Map<String, SubjectPerformance> performanceMap = {};
    for (var result in results) {
      for (var structure in result.test.testStructure) {
        final subjectName = structure.displayName; // Use helper
        final marksObtained =
            int.tryParse(result.marks[structure.id] ?? '0') ?? 0;
        final maxMarks = structure.maxMarks;

        if (performanceMap.containsKey(subjectName)) {
          performanceMap[subjectName]!.addTest(marksObtained, maxMarks);
        } else {
          performanceMap[subjectName] =
              SubjectPerformance(subjectName: subjectName)
                ..addTest(marksObtained, maxMarks);
        }
      }
    }
    return performanceMap;
  }
}

// --- ALL MOCK MODELS REMOVED ---
// (They are correctly defined in board_result_model.dart)
