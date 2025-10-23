import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Student/models/auth_models.dart';
import 'Student/service/firebase_notification_service.dart';

class SessionManager extends ChangeNotifier {
  // --- Storage Keys ---
  final _secureStorage = const FlutterSecureStorage();
  static const _activeTokenKey = 'authToken'; // For the currently active user
  static const _activeUserDataKey =
      'user_data'; // For the currently active user
  static const _savedUsersKey = 'saved_users_map'; // For all remembered users

  // --- State for Active Session ---
  UserModel? _currentUser;
  static String? _authToken;
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  // --- State for Remembered Users ---
  Map<String, dynamic> _savedUsers = {};

  // --- Public Getters ---
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get authToken => _authToken;

  SessionManager() {
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // 1. Load the map of all saved users from standard storage
    final prefs = await SharedPreferences.getInstance();
    final savedUsersString = prefs.getString(_savedUsersKey);
    if (savedUsersString != null) {
      _savedUsers = json.decode(savedUsersString);
    }

    // 2. Attempt to load the currently active session from secure storage
    _authToken = await _secureStorage.read(key: _activeTokenKey);
    final activeUserDataString = prefs.getString(_activeUserDataKey);

    if (_authToken != null && activeUserDataString != null) {
      try {
        _currentUser = UserModel.fromJson(json.decode(activeUserDataString));
        _isLoggedIn = true;
      } catch (e) {
        print("Error loading active session, logging out: $e");
        await logout(); // Clear corrupt active session
      }
    } else {
      _isLoggedIn = false;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Checks the saved users map for an existing session.
  Future<Map<String, dynamic>?> getSavedSession(String phoneNumber) async {
    if (_savedUsers.containsKey(phoneNumber)) {
      final sessionData = _savedUsers[phoneNumber];
      return {
        'user': UserModel.fromJson(sessionData['user']),
        'token': sessionData['token'],
      };
    }
    return null;
  }

  /// Creates and saves a new session, making it the active one.
  Future<void> createSession(
      UserModel user, String token, String phoneNumber) async {
    // Existing code
    _currentUser = user;
    _authToken = token;
    _isLoggedIn = true;

    await _secureStorage.write(key: _activeTokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeUserDataKey, json.encode(user.toJson()));

    _savedUsers[phoneNumber] = {
      'token': token,
      'user': user.toJson(),
    };
    await prefs.setString(_savedUsersKey, json.encode(_savedUsers));

    // ✅ ADD THIS: Register device token after login
    await FirebaseNotificationService().refreshToken(this);

    notifyListeners();
  }

  /// Logs out the active user but keeps their credentials saved for quick login.
  Future<void> logout() async {
    // Delete FCM token
    await FirebaseNotificationService().deleteToken();

    // Existing logout code
    _currentUser = null;
    _authToken = null;
    _isLoggedIn = false;

    await _secureStorage.delete(key: _activeTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserDataKey);

    notifyListeners();
  }
  Future<String?> loadToken() async {
    if (!_isInitialized) {
      await _initializeSession();
    }
    return _authToken;
  }
}
