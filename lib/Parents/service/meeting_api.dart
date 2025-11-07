import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vraz_application/Parents/models/teacher_model.dart';
import '../../api_config.dart';
import '../models/meeting_model.dart';

class MeetingApi {

  static Future<List<Teacher>> fetchTeachers({
    required String authToken,
    required int childId,
  }) async {
    try {
      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[MeetingApi] 📚 Fetching teachers for child ID: $childId');

      final url = Uri.parse('${ApiConfig.baseUrl}/api/parentMobile/my/children/faculty/$childId');

      print('[MeetingApi] 🌐 Full URL: $url');
      print('[MeetingApi] 🔑 Token length: ${authToken.length} chars');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('[MeetingApi] 📥 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('[MeetingApi] ❌ Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final teachers = jsonList
            .map((json) => Teacher.fromJson(json as Map<String, dynamic>))
            .toList();

        print('[MeetingApi] ✅ Loaded ${teachers.length} teachers');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        return teachers;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      print('[MeetingApi] ❌ Error fetching teachers: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      rethrow;
    }
  }

  /// Fetch all meetings for parent
  static Future<List<Meeting>> fetchMeetings({required String authToken}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/parentMobile/my/ptm/get');

    print('[MeetingApi] 📅 GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[MeetingApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> meetingsData;
        if (data is List) {
          meetingsData = data;
        } else if (data is Map<String, dynamic>) {
          meetingsData = data['meetings'] ?? data['data'] ?? data['ptms'] ?? [];
        } else {
          return [];
        }

        final meetings = meetingsData
            .map((e) {
          try {
            return Meeting.fromJson(e as Map<String, dynamic>);
          } catch (error) {
            print('[MeetingApi] ⚠️ Parse error: $error');
            return null;
          }
        })
            .whereType<Meeting>()
            .toList();

        print('[MeetingApi] ✅ Loaded ${meetings.length} meetings');

        // Debug: Print meetings with AWAITING_PARENT status
        final awaitingMeetings = meetings.where((m) => m.status == 'AWAITING_PARENT').toList();
        if (awaitingMeetings.isNotEmpty) {
          print('[MeetingApi] 🔔 ${awaitingMeetings.length} meetings awaiting parent response');
          for (var m in awaitingMeetings) {
            print('[MeetingApi]   - ID: ${m.id}, Status: ${m.status}, Initiated: ${m.initiatedBy}');
          }
        }

        return meetings;
      } else {
        print('[MeetingApi] ❌ Failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('[MeetingApi] ❌ Error: $e');
      print('[MeetingApi] Stack: $stackTrace');
      return [];
    }
  }

  /// Create new meeting request
  static Future<bool> createMeetingRequest({
    required String authToken,
    required int admissionId,
    required String teacherId,
    required String reason,
    required List<DateTime> requestedTimeSlots,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/parentMobile/my/ptm/request');

    final body = {
      'admissionId': admissionId,
      'teacherId': teacherId,
      'reason': reason,
      'requestedTimeSlots': requestedTimeSlots.map((dt) => dt.toIso8601String()).toList(),
    };

    print('[MeetingApi] 📝 POST $url');
    print('[MeetingApi] Body: ${json.encode(body)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('[MeetingApi] Status: ${response.statusCode}');
      print('[MeetingApi] Response: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[MeetingApi] ❌ Error: $e');
      return false;
    }
  }

  /// Update meeting status (Accept/Decline)
  static Future<bool> updateMeetingStatus({
    required String authToken,
    required int meetingId,
    required String newStatus,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/parentMobile/my/ptm/update/$meetingId');

    final body = {'status': newStatus};

    print('[MeetingApi] 🔄 PUT $url');
    print('[MeetingApi] Body: ${json.encode(body)}');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('[MeetingApi] Status: ${response.statusCode}');
      print('[MeetingApi] Response: ${response.body}');

      if (response.statusCode == 200) {
        print('[MeetingApi] ✅ Status updated to $newStatus');
        return true;
      } else {
        print('[MeetingApi] ❌ Failed to update');
        return false;
      }
    } catch (e) {
      print('[MeetingApi] ❌ Error: $e');
      return false;
    }
  }
}