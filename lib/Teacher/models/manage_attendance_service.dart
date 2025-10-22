import 'dart:convert';

import 'package:http/http.dart' as http;

// --- UPDATED IMPORT ---
// Imports the model from the same directory
import 'manage_attendance_model.dart';

class AttendanceService {
  // The class name remains AttendanceService
  final String _baseUrl = "https://vraz-backend-api.onrender.com";

  Future<List<StudentAttendanceModel>> getAttendanceSheet(
      String sessionId) async {
    final Uri url =
        Uri.parse('$_baseUrl/api/teachers/attendance/getSessions/$sessionId');

    try {
      final response = await http.get(url, headers: {
        // TODO: Add your auth token here if required
        // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
      });

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((json) => StudentAttendanceModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load attendance sheet. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  Future<String> markAttendance({
    required String sessionId,
    required List<StudentAttendanceModel> students,
  }) async {
    final Uri url = Uri.parse(
        '$_baseUrl/api/teachers/attendance/submitAttendance/$sessionId');

    final List<Map<String, dynamic>> requestBody =
        students.map((student) => student.toJson()).toList();

    try {
      final response = await http.post(
        url,
        headers: {
          // TODO: Add your auth token here if required
          // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['message'] ?? 'Attendance saved successfully!';
      } else {
        throw Exception(
            'Failed to submit attendance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit attendance: $e');
    }
  }
}
