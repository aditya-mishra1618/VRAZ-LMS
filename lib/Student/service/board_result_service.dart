import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/board_result_model.dart';

class BoardResultService {
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
    print('🔐 BoardResultService: Auth token set');
  }

  Map<String, String> _getHeaders() {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('Authentication token is not set');
    }

    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  /// API 1: Get all board results for the logged-in student
  Future<List<BoardResultResponse>> getMyResults() async {
    print('📡 Fetching my board results...');

    try {
      final url = Uri.parse('$baseUrl/students/my/results');
      print('🌐 Request URL: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Truncate long responses for logging
        final bodyPreview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        print('📊 Response Body: $bodyPreview');

        final List<dynamic> jsonData = json.decode(response.body);

        // Parse with error handling for each result
        List<BoardResultResponse> results = [];
        for (var i = 0; i < jsonData.length; i++) {
          try {
            results.add(BoardResultResponse.fromJson(jsonData[i]));
          } catch (e) {
            print('⚠️ Warning: Skipping result at index $i due to parsing error: $e');
            print('⚠️ Problematic data: ${jsonData[i]}');
            // Continue parsing other results
          }
        }

        print('✅ Successfully fetched ${results.length} board results (out of ${jsonData.length} total)');
        return results;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ 404 Error - Endpoint not found');
        print('❌ Response Body: ${response.body}');
        throw Exception('Results endpoint not found. Please contact support.');
      } else {
        print('❌ Error Response Body: ${response.body}');
        throw Exception('Failed to load results: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching board results: $e');
      rethrow;
    }
  }

  /// API 2: Get detailed information about a specific test
  Future<TestDetailResponse> getTestDetail(int testId) async {
    print('📡 Fetching test detail for testId: $testId');

    try {
      final url = Uri.parse('$baseUrl/students/my/tests/$testId');
      print('🌐 Request URL: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📊 Response Body: ${response.body}');
        final jsonData = json.decode(response.body);
        final testDetail = TestDetailResponse.fromJson(jsonData);

        print('✅ Successfully fetched test detail: ${testDetail.name}');
        return testDetail;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ 404 Error - Test not found');
        throw Exception('Test details not found.');
      } else {
        print('❌ Error Response Body: ${response.body}');
        throw Exception('Failed to load test details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching test detail: $e');
      rethrow;
    }
  }

  /// API 3: Get overall performance analytics
  Future<PerformanceResponse> getOverallPerformance() async {
    print('📡 Fetching overall performance...');

    try {
      final url = Uri.parse('$baseUrl/students/my/performance/overall');
      print('🌐 Request URL: $url');

      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📊 Response Body: ${response.body}');
        final jsonData = json.decode(response.body);
        final performance = PerformanceResponse.fromJson(jsonData);

        print('✅ Successfully fetched overall performance');
        return performance;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        print('❌ 404 Error - Performance endpoint not found');
        throw Exception('Performance data not found.');
      } else {
        print('❌ Error Response Body: ${response.body}');
        throw Exception('Failed to load performance: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching overall performance: $e');
      rethrow;
    }
  }

  /// Helper: Get subject-wise performance summary
  Map<String, SubjectPerformance> getSubjectWisePerformance(
      List<BoardResultResponse> results) {
    print('📊 Calculating subject-wise performance...');

    Map<String, SubjectPerformance> subjectMap = {};

    for (var result in results) {
      for (var structure in result.test.testStructure) {
        // Use displayName helper to handle both data structures
        final subjectName = structure.displayName;

        if (!subjectMap.containsKey(subjectName)) {
          subjectMap[subjectName] = SubjectPerformance(
            subjectName: subjectName,
            totalTests: 0,
            totalMarksObtained: 0,
            totalMaxMarks: 0,
            tests: [],
          );
        }

        // Get marks for this specific subject from the marks map
        final marksObtained = int.parse(result.marks[structure.id] ?? '0');

        subjectMap[subjectName]!.totalTests++;
        subjectMap[subjectName]!.totalMarksObtained += marksObtained;
        subjectMap[subjectName]!.totalMaxMarks += structure.maxMarks;

        // Only add to tests list if not already added
        if (!subjectMap[subjectName]!.tests.contains(result)) {
          subjectMap[subjectName]!.tests.add(result);
        }
      }
    }

    print('✅ Subject-wise performance calculated for ${subjectMap.length} subjects');
    return subjectMap;
  }

  /// Helper: Get exam type wise results (INTERNAL, EXTERNAL, etc.)
  Map<String, List<BoardResultResponse>> groupByExamType(
      List<BoardResultResponse> results,
      Map<int, TestDetailResponse> testDetails) {
    print('📊 Grouping results by exam type...');

    Map<String, List<BoardResultResponse>> examTypeMap = {};

    for (var result in results) {
      final testDetail = testDetails[result.testId];
      if (testDetail != null) {
        final examType = testDetail.testTemplate.examType;

        if (!examTypeMap.containsKey(examType)) {
          examTypeMap[examType] = [];
        }
        examTypeMap[examType]!.add(result);
      }
    }

    print('✅ Results grouped into ${examTypeMap.length} exam types');
    return examTypeMap;
  }
}

/// Helper class for subject-wise performance
class SubjectPerformance {
  final String subjectName;
  int totalTests;
  int totalMarksObtained;
  int totalMaxMarks;
  List<BoardResultResponse> tests;

  SubjectPerformance({
    required this.subjectName,
    required this.totalTests,
    required this.totalMarksObtained,
    required this.totalMaxMarks,
    required this.tests,
  });

  double get averagePercentage =>
      totalMaxMarks > 0 ? (totalMarksObtained / totalMaxMarks) * 100 : 0;

  String get grade {
    if (averagePercentage >= 90) return 'A+';
    if (averagePercentage >= 80) return 'A';
    if (averagePercentage >= 70) return 'B+';
    if (averagePercentage >= 60) return 'B';
    if (averagePercentage >= 50) return 'C';
    if (averagePercentage >= 40) return 'D';
    return 'F';
  }
}