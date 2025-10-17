import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Student/auth_models.dart'; // Assuming your UserModel is here

class SessionManager extends ChangeNotifier {
  // Using SharedPreferences for simplicity. For production, consider secure storage for tokens.
  static const _sessionPrefix = 'session_';

  UserModel? _currentUser;
  String? _authToken;
  bool _isInitialized = false;

  // --- Public Getters for UI ---
  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoading => !_isInitialized;
  String? get userRole => _currentUser?.role;

  SessionManager() {
    // We don't load a default session on startup anymore,
    // as login is now tied to a specific phone number.
    _isInitialized = true;
  }

  /// Saves the user's session data, keyed by their phone number.
  Future<void> createSession(
      UserModel user, String token, String phoneNumber) async {
    _currentUser = user;
    _authToken = token;

    final prefs = await SharedPreferences.getInstance();
    final sessionData = json.encode({
      'token': token,
      'user': user.toJson(),
    });

    // Save the session against the phone number
    await prefs.setString('$_sessionPrefix$phoneNumber', sessionData);

    notifyListeners();
  }

  /// Retrieves a saved session for a specific phone number.
  /// Returns null if no session is found.
  Future<Map<String, dynamic>?> getSavedSession(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionDataString = prefs.getString('$_sessionPrefix$phoneNumber');

    if (sessionDataString != null) {
      try {
        final sessionData = json.decode(sessionDataString);
        return {
          'token': sessionData['token'],
          'user': UserModel.fromJson(sessionData['user']),
        };
      } catch (e) {
        // If data is corrupt, remove it.
        await prefs.remove('$_sessionPrefix$phoneNumber');
        return null;
      }
    }
    return null;
  }

  /// Clears the current in-memory session.
  /// Note: This doesn't clear the saved session from storage.
  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    // You might want to add logic here to clear all saved sessions if needed.
    notifyListeners();
  }
}
