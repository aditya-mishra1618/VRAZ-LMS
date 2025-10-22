import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Teacher/models/teacher_model.dart'; // Model for Teacher (User)

class TeacherSessionManager {
  static const String _teacherKey = 'teacher_session';

  // Save teacher session (token + user)
  Future<void> saveSession(TeacherModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();

    // Clean token before saving (remove whitespace/newlines)
    final cleanToken = token.replaceAll(RegExp(r'\s+'), '');
    final sessionData = {
      'token': cleanToken,
      'user': user.toJson(),
    };
    await prefs.setString(_teacherKey, json.encode(sessionData));

    print('[DEBUG] Session saved. Token length: ${cleanToken.length}');
  }

  // Get teacher session
  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_teacherKey);
    if (jsonString == null) return null;

    final data = json.decode(jsonString);

    // Ensure token is clean: remove any extra quotes or whitespace
    String token = data['token'].toString();
    token = token.replaceAll(RegExp(r'^"|"$'), '').replaceAll(RegExp(r'\s+'), '');

    final user = TeacherModel.fromJson(data['user']);

    print('[DEBUG] Session retrieved. Token length: ${token.length}');

    return {
      'token': token,
      'user': user,
    };
  }

  // Clear teacher session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teacherKey);
    print('[DEBUG] Teacher session cleared.');
  }
}
