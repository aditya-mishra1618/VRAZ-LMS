import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Teacher/models/teacher_model.dart';

class TeacherSessionManager {
  static const String _teacherKey = 'teacher_session';

  // Save teacher session (token + user)
  Future<void> saveSession(TeacherModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanToken = token.replaceAll(RegExp(r'\s+'), '');
    final sessionData = {
      'token': cleanToken,
      'user': user.toJson(),
    };
    await prefs.setString(_teacherKey, json.encode(sessionData));

    print('[DEBUG] Teacher session saved. Token length: ${cleanToken.length}');
  }

  // Get teacher session
  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_teacherKey);
    if (jsonString == null) return null;

    final data = json.decode(jsonString);

    String token = data['token'].toString();
    token = token.replaceAll(RegExp(r'^"|"$'), '').replaceAll(RegExp(r'\s+'), '');

    final user = TeacherModel.fromJson(data['user']);

    print('[DEBUG] Teacher session retrieved. Token length: ${token.length}');

    return {
      'token': token,
      'user': user,
    };
  }

  // ✅ Load token (for API calls)
  Future<String?> loadToken() async {
    final session = await getSession();
    return session?['token'] as String?;
  }

  // Clear teacher session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teacherKey);
    print('[DEBUG] Teacher session cleared.');
  }
}