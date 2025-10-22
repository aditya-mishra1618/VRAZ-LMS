import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vraz_application/api_config.dart';
import '../models/course_models.dart';
import '../models/timetable_model.dart';


class ApiService {
  /// 🧠 Fetch student curriculum (already created)
  Future<List<SubjectModel>> fetchCurriculum(String authToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/curriculum');
    print('📘 [ApiService] Fetching curriculum from $url');

    try {
      print('🔐 Bearer Token: Bearer $authToken');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📩 Curriculum Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        print('✅ Curriculum fetched successfully, count: ${jsonResponse.length}');
        return jsonResponse.map((data) => SubjectModel.fromJson(data)).toList();
      } else {
        print('❌ Curriculum fetch failed: ${response.body}');
        throw Exception(
            'Failed to load curriculum. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error in fetchCurriculum(): $e');
      throw Exception('An error occurred while fetching curriculum: $e');
    }
  }

  /// 🕒 Fetch student timetable between given dates
  Future<List<TimetableModel>> fetchTimetable(
      String authToken, String startDate, String endDate) async {
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/students/my/timetable?startDate=$startDate&endDate=$endDate');
    print('📘 [ApiService] Fetching timetable from $url');

    try {
      print('🔐 Bearer Token: Bearer $authToken');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📩 Timetable Response Status: ${response.statusCode}');
      print('📨 Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        print('✅ Timetable fetched successfully, count: ${jsonResponse.length}');
        return jsonResponse.map((e) => TimetableModel.fromJson(e)).toList();
      } else {
        print('❌ Timetable fetch failed: ${response.body}');
        throw Exception(
            'Failed to load timetable: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error in fetchTimetable(): $e');
      throw Exception('Error fetching timetable: $e');
    }
  }
}
