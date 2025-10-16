import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'course_models.dart';

class ApiService {
  // This method now requires the auth token to be passed in.
  Future<List<SubjectModel>> fetchCurriculum(String authToken) async {
    // Construct the full URL from the base URL and the specific endpoint.
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/curriculum');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Use the provided token for authorization.
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => SubjectModel.fromJson(data)).toList();
      } else {
        // Provide more specific error information.
        throw Exception(
            'Failed to load curriculum. Status Code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Catch network or parsing errors.
      throw Exception('An error occurred while fetching curriculum: $e');
    }
  }
}
