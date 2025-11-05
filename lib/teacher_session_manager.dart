import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'Teacher/models/teacher_model.dart';

class TeacherSessionManager {
  static const String _teacherKey = 'teacher_session';
  static const String _tokenKey = 'teacher_auth_token';      // ✅ NEW
  static const String _emailKey = 'teacher_email';           // ✅ NEW

  // In-memory session state
  TeacherModel? _currentTeacher;
  String? _authToken;
  bool _isInitialized = false;

  // Public getters
  TeacherModel? get currentTeacher => _currentTeacher;
  String? get authToken => _authToken;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _authToken != null && _currentTeacher != null;

  /// Initialize by loading saved session (if any) from SharedPreferences.
  Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_teacherKey);
    if (jsonString != null) {
      try {
        final data = json.decode(jsonString);
        String token = data['token'].toString();
        token = token.replaceAll(RegExp(r'^"|"$'), '').replaceAll(RegExp(r'\s+'), '');
        final user = TeacherModel.fromJson(data['user']);

        _authToken = token;
        _currentTeacher = user;

        print('[DEBUG] TeacherSessionManager initialized. Teacher: ${user.fullName ?? "unknown"}, token length: ${_authToken?.length ?? 0}');
      } catch (e) {
        print('[ERROR] Failed to initialize TeacherSessionManager: $e');
        // If corrupted, clear stored session to avoid repeated errors
        await clearSession();
      }
    } else {
      print('[DEBUG] No saved teacher session found.');
    }
    _isInitialized = true;
  }

  // Save teacher session (token + user)
  Future<void> saveSession(TeacherModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanToken = token.replaceAll(RegExp(r'\s+'), '');
    final sessionData = {
      'token': cleanToken,
      'user': user.toJson(),
    };
    await prefs.setString(_teacherKey, json.encode(sessionData));

    // ✅ ALSO SAVE TOKEN AND EMAIL SEPARATELY (for notifications)
    await prefs.setString(_tokenKey, cleanToken);
    await prefs.setString(_emailKey, user.email);

    // Update in-memory state
    _authToken = cleanToken;
    _currentTeacher = user;
    _isInitialized = true;

    print('[DEBUG] Teacher session saved. Token length: ${cleanToken.length}');
    print('[DEBUG] Teacher auth token saved separately for notifications');
  }

  // Get teacher session (returns raw stored data)
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
    if (!_isInitialized) {
      await initialize();
    }
    return _authToken ?? (await getSession())?['token'] as String?;
  }

  // Clear teacher session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teacherKey);
    await prefs.remove(_tokenKey);    // ✅ NEW
    await prefs.remove(_emailKey);    // ✅ NEW

    _currentTeacher = null;
    _authToken = null;
    _isInitialized = true;
    print('[DEBUG] Teacher session cleared.');
  }
}