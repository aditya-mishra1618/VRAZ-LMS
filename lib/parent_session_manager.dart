import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'Parents/models/parent_child_model.dart';
import 'Parents/models/parent_model.dart';

class ParentSessionManager extends ChangeNotifier {
  static const String _keyToken = 'parent_auth_token';
  static const String _keyParentData = 'parent_data';
  static const String _keyPhoneNumber = 'parent_phone_number';
  static const String _keySessionTimestamp = 'parent_session_timestamp';
  List<ParentChild> _childrenDetails = [];
  List<ParentChild> get childrenDetails => _childrenDetails;
  ParentModel? _currentParent;
  String? _token;
  String? _phoneNumber;

  ParentModel? get currentParent => _currentParent;
  String? get token => _token;
  String? get phoneNumber => _phoneNumber;
  bool get isLoggedIn => _token != null && _currentParent != null;

  void setChildrenDetails(List<ParentChild> children) {
    _childrenDetails = children;
    notifyListeners();
  }
  /// Create new session after successful login
  Future<void> createSession(ParentModel parent, String token, String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _currentParent = parent;
      _token = token;
      _phoneNumber = phoneNumber;

      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyParentData, json.encode(parent.toJson()));
      await prefs.setString(_keyPhoneNumber, phoneNumber);
      await prefs.setString(_keySessionTimestamp, DateTime.now().toIso8601String());

      debugPrint('[ParentSession] ✅ Session created: ${parent.fullName}, Phone: $phoneNumber');
      debugPrint('[ParentSession] Token saved: $token');
      notifyListeners();
    } catch (e) {
      debugPrint('[ParentSession] ❌ Error creating session: $e');
      rethrow;
    }
  }

  /// Load saved session on app startup
  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_keyToken);
      final parentJson = prefs.getString(_keyParentData);
      final phone = prefs.getString(_keyPhoneNumber);
      final timestamp = prefs.getString(_keySessionTimestamp);

      if (token == null || parentJson == null) {
        debugPrint('[ParentSession] No saved session found');
        return false;
      }

      // Check if session is expired (30 days)
      if (timestamp != null) {
        final sessionDate = DateTime.parse(timestamp);
        final daysSinceLogin = DateTime.now().difference(sessionDate).inDays;

        if (daysSinceLogin > 30) {
          debugPrint('[ParentSession] ⏰ Session expired ($daysSinceLogin days old)');
          await clearSession();
          return false;
        }
      }

      _token = token;
      _currentParent = ParentModel.fromJson(json.decode(parentJson));
      _phoneNumber = phone;

      debugPrint('[ParentSession] ✅ Session loaded: ${_currentParent!.fullName}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ParentSession] ❌ Error loading session: $e');
      await clearSession();
      return false;
    }
  }

  /// Get saved session by phone number (for persistent login)
  Future<Map<String, dynamic>?> getSavedSession(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedPhone = prefs.getString(_keyPhoneNumber);
      if (savedPhone != phoneNumber) {
        debugPrint('[ParentSession] Phone number mismatch: saved=$savedPhone, provided=$phoneNumber');
        return null;
      }

      final token = prefs.getString(_keyToken);
      final parentJson = prefs.getString(_keyParentData);

      if (token == null || parentJson == null) {
        debugPrint('[ParentSession] Incomplete session data');
        return null;
      }

      final parent = ParentModel.fromJson(json.decode(parentJson));

      debugPrint('[ParentSession] ✅ Found saved session for $phoneNumber');
      return {
        'parent': parent,
        'token': token,
      };
    } catch (e) {
      debugPrint('[ParentSession] ❌ Error getting saved session: $e');
      return null;
    }
  }

  /// Update parent data (e.g., after profile update)
  Future<void> updateParent(ParentModel parent) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _currentParent = parent;
      await prefs.setString(_keyParentData, json.encode(parent.toJson()));

      debugPrint('[ParentSession] ✅ Parent data updated');
      notifyListeners();
    } catch (e) {
      debugPrint('[ParentSession] ❌ Error updating parent: $e');
      rethrow;
    }
  }

  /// Clear session on logout
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyToken);
      await prefs.remove(_keyParentData);
      await prefs.remove(_keyPhoneNumber);
      await prefs.remove(_keySessionTimestamp);

      _currentParent = null;
      _token = null;
      _phoneNumber = null;

      debugPrint('[ParentSession] 🗑️ Session cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('[ParentSession] ❌ Error clearing session: $e');
      rethrow;
    }
  }

  /// Update auth token
  Future<void> updateToken(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _token = newToken;
      await prefs.setString(_keyToken, newToken);

      debugPrint('[ParentSession] ✅ Token updated');
      notifyListeners();
    } catch (e) {
      debugPrint('[ParentSession] ❌ Error updating token: $e');
      rethrow;
    }
  }
}