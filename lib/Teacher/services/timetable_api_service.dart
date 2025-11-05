import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/timetable_model.dart';

class TeacherTimetableService {
  final String baseUrl = 'https://vraz-backend-api.onrender.com/api/teachers'; // ✅ Use HTTPS
  final String token;

  TeacherTimetableService({required this.token});

  /// Fetch teacher timetable between startDate and endDate
  Future<List<TeacherTimetableEntry>> fetchTimetable({
    required String startDate,
    required String endDate,
  }) async {
    final url =
        Uri.parse('$baseUrl/my/schedule?startDate=$startDate&endDate=$endDate');

    // ✅ Super clean token - remove ALL unwanted characters
    final cleanToken = token
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .trim();

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 [TeacherTimetableService] API Request');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 URL: $url');
    print('🔐 Token: $cleanToken');
    print('📏 Token Length: ${cleanToken.length}');
    print('📅 Date Range: $startDate to $endDate');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final headers = {
      'Authorization': 'Bearer $cleanToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Timetable fetched successfully: ${data.length} entries.');
        return data.map((e) => TeacherTimetableEntry.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized');
        print('💡 Token might be expired or invalid');
        print('🔑 Token used: Bearer $cleanToken');
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        print('⚠️ 404 Not Found - No timetable data');
        return [];
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to fetch timetable (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }
}