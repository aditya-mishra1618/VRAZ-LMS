import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/result_model.dart';

class ResultService {
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';

  String? _authToken;

  void setAuthToken(String token) {
    print('🔐 DEBUG: Setting auth token in ResultService');
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

  Future<List<ResultResponse>> getMyResults() async {
    print('🚀 DEBUG: Starting getMyResults API call');
    print('⏰ DEBUG: Request time: ${DateTime.now().toUtc().toIso8601String()}');

    if (!_hasValidToken()) {
      print('❌ DEBUG: Cannot fetch results - No authentication token');
      throw Exception('Authentication token not found. Please login again.');
    }

    print('🔐 DEBUG: Using token: ${_authToken!.substring(0, 20)}...');

    final url = Uri.parse('$baseUrl/students/my/results');
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
        print('📊 DEBUG: Number of results received: ${jsonData.length}');

        if (jsonData.isEmpty) {
          print('ℹ️ DEBUG: No results found for this student');
          return [];
        }

        final results = jsonData
            .map((json) {
          try {
            return ResultResponse.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('❌ DEBUG: Error parsing result: $e');
            print('❌ DEBUG: Problematic JSON: $json');
            rethrow;
          }
        })
            .toList();

        print('✅ DEBUG: Successfully parsed ${results.length} results');

        // Debug first result
        if (results.isNotEmpty) {
          print('📝 DEBUG: First result:');
          print('   - ID: ${results.first.id}');
          print('   - Test Name: ${results.first.test.name}');
          print('   - Percentage: ${results.first.percentage}%');
          print('   - Total Marks: ${results.first.totalMarksObtained}/${results.first.totalMaxMarks}');
          print('   - Rank: ${results.first.rank ?? "N/A"}');
          print('   - Batch: ${results.first.batch.name}');
          print('   - Test Date: ${results.first.test.date}');
          print('   - Subjects: ${results.first.test.testStructure.length}');
        }

        return results;
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
        print('❌ DEBUG: Response Body: ${response.body}');
        throw Exception('Failed to load results. Status: ${response.statusCode}');
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
}