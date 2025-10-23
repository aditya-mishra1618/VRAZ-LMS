import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/timetable_model.dart';

class TeacherTimetableService {
  // --- THIS IS THE FIX ---
  // The baseUrl must use the secure 'https://'
  final String baseUrl = 'https://vraz-backend-api.onrender.com/api/teachers';
  final String token;

  TeacherTimetableService({required this.token});

  /// Fetch teacher timetable between startDate and endDate
  Future<List<TeacherTimetableEntry>> fetchTimetable({
    required String startDate,
    required String endDate,
  }) async {
    final url =
        Uri.parse('$baseUrl/my/schedule?startDate=$startDate&endDate=$endDate');

    // Clean token: remove quotes and trim spaces
    final cleanToken = token.replaceAll('"', '').trim();

    // Debug: show URL and cleaned token
    print('[DEBUG] Fetching timetable from URL: $url');
    print(
        '[DEBUG] Cleaned token: [$cleanToken] (length: ${cleanToken.length})');

    final headers = {
      'Authorization': 'Bearer $cleanToken',
      'Content-Type': 'application/json',
    };

    // Debug: show headers
    print('---DEBUG HEADERS---');
    headers.forEach((k, v) => print('$k: $v'));
    print('------------------');

    try {
      final response = await http.get(url, headers: headers);

      // Debug: show response status and body
      print('[DEBUG] Response status: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(
            '[DEBUG] Timetable fetched successfully: ${data.length} entries.');
        return data.map((e) => TeacherTimetableEntry.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        print('[ERROR] Unauthorized. Token may be expired or invalid.');
        throw Exception('Unauthorized. Token may be expired or invalid.');
      } else {
        print(
            '[ERROR] Failed to fetch timetable. Status code: ${response.statusCode}');
        throw Exception(
            'Failed to fetch timetable. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('[ERROR] Exception during API call: $e');
      rethrow;
    }
  }
}
