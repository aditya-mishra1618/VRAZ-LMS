import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/universal_notification_service.dart';

import 'Student/models/auth_models.dart';
import 'Student/service/firebase_notification_service.dart';
// Universal service (single-file)

class SessionManager extends ChangeNotifier {
  // --- Storage Keys ---
  final _secureStorage = const FlutterSecureStorage();
  static const _activeTokenKey = 'authToken';
  static const _activeUserDataKey = 'user_data';
  static const _savedUsersKey = 'saved_users_map';

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
    print('🔄 Initializing SessionManager...');

    final prefs = await SharedPreferences.getInstance();
    final savedUsersString = prefs.getString(_savedUsersKey);
    if (savedUsersString != null) {
      try {
        _savedUsers = json.decode(savedUsersString);
      } catch (e) {
        _savedUsers = {};
      }
      print('📦 Loaded ${_savedUsers.length} saved user(s)');
    }

    _authToken = await _secureStorage.read(key: _activeTokenKey);
    final activeUserDataString = prefs.getString(_activeUserDataKey);

    if (_authToken != null && activeUserDataString != null) {
      try {
        _currentUser = UserModel.fromJson(json.decode(activeUserDataString));
        _isLoggedIn = true;
        print('✅ Active session found: ${_currentUser!.fullName}');

        // Do not block initialization — schedule notification registration & sync
        Future(() async {
          try {
            // Keep existing FCM refresh for backward compatibility
            await FirebaseNotificationService().refreshToken(this);

            // Fetch notifications with Authorization header (authToken)
            await UniversalNotificationService.instance.fetchAndMergeFromServer(
              authToken: _authToken,
            );

            print('✅ Notification registration & sync attempted for restored student session');
          } catch (e) {
            print('⚠️ Notification registration/fetch failed during session init: $e');
          }
        });
      } catch (e) {
        print("❌ Error loading active session, logging out: $e");
        await logout();
      }
    } else {
      _isLoggedIn = false;
      print('ℹ️ No active session found');
    }

    _isInitialized = true;
    notifyListeners();
    print('✅ SessionManager initialized');
  }

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

  Future<void> createSession(
      UserModel user, String token, String phoneNumber) async {
    print('💾 Creating session for: ${user.fullName}');

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

    try {
      await FirebaseNotificationService().refreshToken(this);
      print('✅ FirebaseNotificationService.refreshToken() completed');
    } catch (e) {
      print('⚠️ FirebaseNotificationService.refreshToken() failed: $e');
    }

    // Only fetch & merge server notifications using Authorization header
    try {
      await UniversalNotificationService.instance.fetchAndMergeFromServer(
        authToken: _authToken,
      );
      print('✅ Fetched & merged server notifications for student (auth header)');
    } catch (e) {
      print('⚠️ Error fetching notifications with auth header: $e');
    }

    notifyListeners();
    print('✅ Session created and saved');
  }

  Future<void> logout() async {
    print('🚪 Logging out user: ${_currentUser?.fullName ?? "Unknown"}');

    try {
      await FirebaseNotificationService().deleteToken();
      print('✅ FCM token deleted');
    } catch (e) {
      print('⚠️ Error deleting FCM token: $e');
    }

    try {
      await UniversalNotificationService.instance.clearAll();
      print('✅ Cleared local notifications on logout');
    } catch (e) {
      print('⚠️ Failed to clear local notifications on logout: $e');
    }

    _currentUser = null;
    _authToken = null;
    _isLoggedIn = false;

    await _secureStorage.delete(key: _activeTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserDataKey);

    notifyListeners();
    print('✅ User logged out');
  }

  Future<String?> loadToken() async {
    if (!_isInitialized) {
      await _initializeSession();
    }
    return _authToken;
  }
}