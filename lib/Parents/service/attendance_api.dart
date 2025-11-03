import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/attendance_model.dart';

class AttendanceApi {
  /// Fetch attendance records for a specific child
  static Future<List<AttendanceRecord>> fetchChildAttendance({
    required String authToken,
    required int childId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/children/attendance/$childId',
    );

    print('[AttendanceApi] 📅 Fetching attendance for child ID: $childId');
    print('[AttendanceApi] GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[AttendanceApi] Response status: ${response.statusCode}');
      print('[AttendanceApi] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response structures
        List<dynamic> attendanceData;

        if (data is List) {
          attendanceData = data;
        } else if (data is Map<String, dynamic>) {
          attendanceData = data['attendance'] ??
              data['data'] ??
              data['records'] ??
              [];
        } else {
          print('[AttendanceApi] ⚠️ Unexpected response format');
          return [];
        }

        if (attendanceData.isEmpty) {
          print('[AttendanceApi] ℹ️ No attendance records found');
          return [];
        }

        final records = attendanceData
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        // Sort by date (newest first)
        records.sort((a, b) => b.sessionStartTime.compareTo(a.sessionStartTime));

        print('[AttendanceApi] ✅ Parsed ${records.length} attendance records');

        // Debug: Print first few records
        if (records.isNotEmpty) {
          print('[AttendanceApi] Sample records:');
          for (var i = 0; i < (records.length > 3 ? 3 : records.length); i++) {
            print('[AttendanceApi]   - ${records[i].formattedDate}: ${records[i].status} (${records[i].subjectName})');
          }
        }

        return records;
      } else if (response.statusCode == 401) {
        print('[AttendanceApi] ❌ Unauthorized - token may be expired');
        return [];
      } else if (response.statusCode == 404) {
        print('[AttendanceApi] ℹ️ No attendance data found for this child');
        return [];
      } else {
        print('[AttendanceApi] ❌ Failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('[AttendanceApi] ❌ ERROR: $e');
      print('[AttendanceApi] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Calculate attendance summary
  static AttendanceSummary calculateSummary(List<AttendanceRecord> records) {
    return AttendanceSummary.fromRecords(records);
  }

  /// Get attendance for specific date range
  static List<AttendanceRecord> getRecordsInDateRange({
    required List<AttendanceRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return records.where((record) {
      return record.sessionStartTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
          record.sessionStartTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get records for current month
  static List<AttendanceRecord> getCurrentMonthRecords(List<AttendanceRecord> records) {
    final now = DateTime.now();
    return records.where((record) {
      return record.sessionStartTime.year == now.year &&
          record.sessionStartTime.month == now.month;
    }).toList();
  }

  /// Get records for current week
  static List<AttendanceRecord> getCurrentWeekRecords(List<AttendanceRecord> records) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return getRecordsInDateRange(
      records: records,
      startDate: weekStart,
      endDate: weekEnd,
    );
  }
}