import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/manage_attendance_model.dart';

class AttendanceService {
  final String _baseUrl = "https://vraz-backend-api.onrender.com";

  Future<List<StudentAttendanceModel>> getAttendanceSheet(
      String sessionId, String authToken) async {
    final Uri url =
        Uri.parse('$_baseUrl/api/teachers/attendance/getSessions/$sessionId');

    final headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((json) => StudentAttendanceModel.fromJson(json))
            .toList();
      } else {
        if (response.statusCode == 401) {
          throw Exception(
              'Authorization failed (401). Token may be invalid or expired.');
        }
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
    required String authToken,
  }) async {
    final Uri url = Uri.parse(
        '$_baseUrl/api/teachers/attendance/submitAttendance/$sessionId');

    // --- THIS IS THE FIX ---
    // We are trying a new key: "attendanceData"
    final Map<String, dynamic> requestBody = {
      'attendanceData': students.map((student) => student.toJson()).toList()
    };
    // --- END OF FIX ---

    final headers = {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody), // Send the Map
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['message'] ?? 'Attendance saved successfully!';
      } else {
        if (response.statusCode == 401) {
          throw Exception(
              'Authorization failed (401). Token may be invalid or expired.');
        }
        // This will print the 400 status code
        throw Exception(
            'Failed to submit attendance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit attendance: $e');
    }
  }
}
