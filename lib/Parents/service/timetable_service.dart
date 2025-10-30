import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../Student/models/timetable_model.dart';
import '../../api_config.dart';
import '../models/timetable_model.dart' hide TimetableModel;

/// TimetableApiService - provides static methods used by the UI.
/// Keeps the same return map shape as your screen expects.
class TimetableApiService {
  static final Duration _defaultTimeout = const Duration(seconds: 15);

  /// Fetch weekly timetable for a child ID
  /// Returns a Map with:
  ///  - 'success': true on success
  ///  - 'timetable': List<TimetableModel>
  ///  - 'student': StudentInfoModel?
  ///  - 'startDate' and 'endDate' as DateTime
  /// On error returns a map with 'error': true and 'message'
  static Future<Map<String, dynamic>?> fetchTimetable({
    required int childId,
    required String token,
    DateTime? selectedDate,
  }) async {
    try {
      final date = selectedDate ?? DateTime.now();
      final monday = date.subtract(Duration(days: date.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      final startDate = DateFormat('yyyy-MM-dd').format(monday);
      final endDate = DateFormat('yyyy-MM-dd').format(sunday);

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/parentMobile/my/children/timetable/$childId?startDate=$startDate&endDate=$endDate',
      );

      debugPrint('[TimetableAPI] 📅 Fetching timetable for child: $childId');
      debugPrint('[TimetableAPI] 📅 Date range: $startDate to $endDate');
      debugPrint('[TimetableAPI] 📅 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        _defaultTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('[TimetableAPI] ✅ Response status: ${response.statusCode}');
      debugPrint('[TimetableAPI] 📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<TimetableModel> timetableList = [];

        List<dynamic>? timetableData;
        if (data is List) {
          timetableData = data;
        } else if (data is Map) {
          timetableData = data['timetable'] ??
              data['data'] ??
              data['schedule'] ??
              data['classes'] ??
              data['items'];
        }

        if (timetableData != null && timetableData is List) {
          for (var item in timetableData) {
            try {
              if (item is Map<String, dynamic>) {
                timetableList.add(TimetableModel.fromJson(item));
              } else if (item is Map) {
                timetableList.add(TimetableModel.fromJson(Map<String, dynamic>.from(item)));
              } else {
                debugPrint('[TimetableAPI] ⚠️ Skipping non-map timetable item: $item');
              }
            } catch (e) {
              debugPrint('[TimetableAPI] ⚠️ Error parsing timetable item: $e');
            }
          }
        }

        StudentInfoModel? studentInfo;
        if (data is Map && data['student'] != null) {
          try {
            final studentRaw = data['student'];
            if (studentRaw is Map) {
              studentInfo = StudentInfoModel.fromJson(Map<String, dynamic>.from(studentRaw));
            }
          } catch (e) {
            debugPrint('[TimetableAPI] ⚠️ Error parsing student info: $e');
          }
        }

        debugPrint('[TimetableAPI] ✅ Successfully parsed ${timetableList.length} classes');

        return {
          'success': true,
          'timetable': timetableList,
          'student': studentInfo,
          'startDate': monday,
          'endDate': sunday,
        };
      } else if (response.statusCode == 401) {
        debugPrint('[TimetableAPI] ❌ Unauthorized - Token may be expired');
        return {
          'error': true,
          'message': 'Session expired. Please login again.',
          'statusCode': 401,
        };
      } else if (response.statusCode == 404) {
        debugPrint('[TimetableAPI] ⚠️ No timetable found for this child');
        return {
          'error': true,
          'message': 'No timetable found for this student.',
          'statusCode': 404,
        };
      } else {
        dynamic errorData;
        try {
          errorData = json.decode(response.body);
        } catch (_) {
          errorData = {'message': response.body};
        }
        debugPrint('[TimetableAPI] ❌ Error: ${errorData['message']}');
        return {
          'error': true,
          'message': errorData['message'] ?? 'Failed to fetch timetable',
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('[TimetableAPI] ❌ Exception: $e');
      debugPrint('[TimetableAPI] 📚 Stack trace: $stackTrace');
      return {
        'error': true,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Download timetable PDF (returns bytes in 'data' if success)
  static Future<Map<String, dynamic>> downloadTimetable({
    required int childId,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/parentMobile/my/children/timetable/$childId/download',
      );

      debugPrint('[TimetableAPI] 📥 Downloading timetable for child: $childId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download timeout');
        },
      );

      if (response.statusCode == 200) {
        debugPrint('[TimetableAPI] ✅ Timetable downloaded successfully');
        return {
          'success': true,
          'message': 'Timetable downloaded successfully',
          'data': response.bodyBytes,
        };
      } else {
        debugPrint('[TimetableAPI] ❌ Download failed: ${response.statusCode}');
        return {
          'error': true,
          'message': 'Download failed. Please try again.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('[TimetableAPI] ❌ Download exception: $e');
      return {
        'error': true,
        'message': 'Failed to download timetable.',
      };
    }
  }
}