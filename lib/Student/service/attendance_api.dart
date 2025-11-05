import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/attendance_model.dart';

class AttendanceApi {
  static Future<List<AttendanceRecord>> fetchAttendance({
    required String authToken,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/attendance');

    print('[AttendanceApi] 📅 Fetching attendance...');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[AttendanceApi] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> attendanceData = data is List ? data : [];

        final records = attendanceData
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        records.sort((a, b) => a.session.startTime.compareTo(b.session.startTime));

        print('[AttendanceApi] ✅ Parsed ${records.length} attendance records');
        return records;
      }
      return [];
    } catch (e) {
      print('[AttendanceApi] ❌ ERROR: $e');
      return [];
    }
  }
}