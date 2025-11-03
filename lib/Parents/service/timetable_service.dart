import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/timetable_model.dart';

class TimetableApi {
  /// Fetch weekly timetable for a specific child
  static Future<WeeklyTimetable?> fetchChildTimetable({
    required String authToken,
    required int childId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Format dates as YYYY-MM-DD
    final startDateStr = _formatDate(startDate);
    final endDateStr = _formatDate(endDate);

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/children/timetable/$childId?startDate=$startDateStr&endDate=$endDateStr',
    );

    print('[TimetableApi] 📅 Fetching timetable for child: $childId');
    print('[TimetableApi] GET $url');
    print('[TimetableApi] Date range: $startDateStr to $endDateStr');
    print('[TimetableApi] Auth token: ${authToken.substring(0, 30)}...');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[TimetableApi] Response status: ${response.statusCode}');
      print('[TimetableApi] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response structures
        List<dynamic> timetableData;

        if (data is List) {
          timetableData = data;
        } else if (data is Map<String, dynamic>) {
          timetableData = data['timetable'] ??
              data['data'] ??
              data['entries'] ??
              data['schedule'] ??
              [];
        } else {
          print('[TimetableApi] ⚠️ Unexpected response format');
          return null;
        }

        if (timetableData.isEmpty) {
          print('[TimetableApi] ℹ️ No timetable entries for this week');
          return WeeklyTimetable(
            weekStart: startDate,
            weekEnd: endDate,
            entries: [],
          );
        }

        final entries = timetableData
            .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        print('[TimetableApi] ✅ Parsed ${entries.length} timetable entries');

        return WeeklyTimetable(
          weekStart: startDate,
          weekEnd: endDate,
          entries: entries,
        );
      } else if (response.statusCode == 401) {
        print('[TimetableApi] ❌ Unauthorized - token may be expired');
        return null;
      } else if (response.statusCode == 404) {
        print('[TimetableApi] ℹ️ No timetable found for this child/week');
        return WeeklyTimetable(
          weekStart: startDate,
          weekEnd: endDate,
          entries: [],
        );
      } else {
        print('[TimetableApi] ❌ Failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('[TimetableApi] ❌ ERROR: $e');
      print('[TimetableApi] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Format DateTime to YYYY-MM-DD string
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get current week's start (Monday) and end (Sunday) dates
  static Map<String, DateTime> getCurrentWeekDates() {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday

    // Calculate Monday of current week
    final weekStart = now.subtract(Duration(days: currentWeekday - 1));
    // Calculate Sunday of current week
    final weekEnd = weekStart.add(const Duration(days: 6));

    return {
      'start': DateTime(weekStart.year, weekStart.month, weekStart.day),
      'end': DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    };
  }

  /// Get week dates for a specific date (returns Monday-Sunday of that week)
  static Map<String, DateTime> getWeekDatesForDate(DateTime date) {
    final currentWeekday = date.weekday; // 1 = Monday, 7 = Sunday

    // Calculate Monday of the week containing 'date'
    final weekStart = date.subtract(Duration(days: currentWeekday - 1));
    // Calculate Sunday of the week
    final weekEnd = weekStart.add(const Duration(days: 6));

    return {
      'start': DateTime(weekStart.year, weekStart.month, weekStart.day),
      'end': DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    };
  }

  /// Get next week's start and end dates
  static Map<String, DateTime> getNextWeekDates(DateTime currentWeekStart) {
    final nextWeekStart = currentWeekStart.add(const Duration(days: 7));
    return getWeekDatesForDate(nextWeekStart);
  }

  /// Get previous week's start and end dates
  static Map<String, DateTime> getPreviousWeekDates(DateTime currentWeekStart) {
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    return getWeekDatesForDate(previousWeekStart);
  }

  /// Check if a date is in the current week
  static bool isInCurrentWeek(DateTime date) {
    final currentWeek = getCurrentWeekDates();
    return date.isAfter(currentWeek['start']!.subtract(const Duration(seconds: 1))) &&
        date.isBefore(currentWeek['end']!.add(const Duration(seconds: 1)));
  }

  /// Get date range string for display
  static String getDateRangeString(DateTime start, DateTime end) {
    return '${_formatDate(start)} to ${_formatDate(end)}';
  }
}