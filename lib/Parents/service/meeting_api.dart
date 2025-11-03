import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/meeting_model.dart';

class MeetingApi {
  static Future<List<ParentTeacherMeeting>> fetchMeetings({
    required String authToken,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/ptm/get',
    );

    print('[MeetingApi] 👨‍🏫 Fetching meetings...');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[MeetingApi] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> meetingsData = data is List ? data : [];

        final meetings = meetingsData
            .map((e) => ParentTeacherMeeting.fromJson(e as Map<String, dynamic>))
            .toList();

        print('[MeetingApi] ✅ Parsed ${meetings.length} meetings');
        return meetings;
      }
      return [];
    } catch (e) {
      print('[MeetingApi] ❌ ERROR: $e');
      return [];
    }
  }

  // ✅ NEW: Create meeting request
  static Future<bool> createMeetingRequest({
    required String authToken,
    required int admissionId,
    required String teacherId,
    required String reason,
    required List<DateTime> requestedTimeSlots,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/ptm/create',
    );

    print('[MeetingApi] 📝 Creating meeting request...');
    print('[MeetingApi] POST $url');

    try {
      final body = {
        'admissionId': admissionId,
        'teacherId': teacherId,
        'reason': reason,
        'requestedTimeSlots': requestedTimeSlots
            .map((slot) => slot.toUtc().toIso8601String())
            .toList(),
      };

      print('[MeetingApi] Request body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('[MeetingApi] Response status: ${response.statusCode}');
      print('[MeetingApi] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[MeetingApi] ✅ Meeting request created successfully');
        return true;
      } else {
        print('[MeetingApi] ❌ Failed to create meeting: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[MeetingApi] ❌ ERROR: $e');
      print('[MeetingApi] Stack trace: $stackTrace');
      return false;
    }
  }
}