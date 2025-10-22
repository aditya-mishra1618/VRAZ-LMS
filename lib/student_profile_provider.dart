// File: lib/Student/student_profile_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Student/models/student_profile_model.dart';
import 'Student/service/student_profile_service.dart';

class StudentProfileProvider extends ChangeNotifier {
  // --- Storage Keys ---
  static const _studentProfileKey = 'student_profile_data';
  static const _profileLastFetchKey = 'profile_last_fetch_time';

  // --- Service ---
  final StudentProfileService _profileService = StudentProfileService();

  // --- State ---
  StudentProfileModel? _studentProfile;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;

  // --- Public Getters ---
  StudentProfileModel? get studentProfile => _studentProfile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetchTime => _lastFetchTime;

  // Quick access getters
  String get studentName => _studentProfile?.studentUser.fullName ?? 'Student';
  String get studentEmail => _studentProfile?.studentUser.email ?? '';
  String get studentPhone => _studentProfile?.studentUser.phoneNumber ?? '';
  String get studentPhotoUrl => _studentProfile?.studentUser.photoUrl ?? '';
  String get courseName => _studentProfile?.course.name ?? '';
  String get branchName => _studentProfile?.branch.name ?? '';
  String get currentClass => _studentProfile?.currentClass ?? '';

  StudentProfileProvider() {
    _initializeProfile();
  }

  /// Initialize by loading cached profile from storage
  Future<void> _initializeProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached profile data
      final profileDataString = prefs.getString(_studentProfileKey);
      final lastFetchString = prefs.getString(_profileLastFetchKey);

      if (profileDataString != null) {
        try {
          _studentProfile = StudentProfileModel.fromJson(
            json.decode(profileDataString),
          );

          if (lastFetchString != null) {
            _lastFetchTime = DateTime.parse(lastFetchString);
          }

          print('✅ Student profile loaded from cache');
        } catch (e) {
          print('❌ Error parsing cached profile: $e');
          await clearProfile(); // Clear corrupt cache
        }
      }
    } catch (e) {
      print('❌ Error initializing profile: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Fetch student profile from API and cache it
  Future<void> fetchStudentProfile(String token, {bool forceRefresh = false}) async {
    // Don't fetch if already loading
    if (_isLoading) return;

    // Check if we need to refresh (only if not forcing and recently fetched)
    if (!forceRefresh && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inMinutes < 5) {
        print('⏭️ Skipping profile fetch, recently fetched ${difference.inMinutes} minutes ago');
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 Fetching student profile from API...');

      _studentProfile = await _profileService.getStudentProfile(token);
      _lastFetchTime = DateTime.now();

      // Cache the profile
      await _saveProfileToCache();

      _isLoading = false;
      _errorMessage = null;
      print('✅ Student profile fetched and cached successfully');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      print('❌ Error fetching student profile: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Save profile to local cache
  Future<void> _saveProfileToCache() async {
    if (_studentProfile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _studentProfileKey,
        json.encode(_studentProfile!.toJson()),
      );
      await prefs.setString(
        _profileLastFetchKey,
        _lastFetchTime!.toIso8601String(),
      );
      print('💾 Profile cached successfully');
    } catch (e) {
      print('❌ Error caching profile: $e');
    }
  }

  /// Clear profile data from memory and cache
  Future<void> clearProfile() async {
    _studentProfile = null;
    _lastFetchTime = null;
    _errorMessage = null;
    _isLoading = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_studentProfileKey);
      await prefs.remove(_profileLastFetchKey);
      print('🗑️ Profile cleared from cache');
    } catch (e) {
      print('❌ Error clearing profile cache: $e');
    }

    notifyListeners();
  }

  /// Update profile data locally (for optimistic updates)
  void updateProfileLocally(StudentProfileModel updatedProfile) {
    _studentProfile = updatedProfile;
    _saveProfileToCache();
    notifyListeners();
  }

  /// Check if profile data is stale (older than specified minutes)
  bool isProfileStale({int maxAgeMinutes = 30}) {
    if (_lastFetchTime == null) return true;
    final age = DateTime.now().difference(_lastFetchTime!);
    return age.inMinutes > maxAgeMinutes;
  }

  /// Refresh profile if stale
  Future<void> refreshIfStale(String token, {int maxAgeMinutes = 30}) async {
    if (isProfileStale(maxAgeMinutes: maxAgeMinutes)) {
      await fetchStudentProfile(token, forceRefresh: true);
    }
  }

  /// Get parent by relation
  ParentModel? getParentByRelation(String relation) {
    if (_studentProfile == null) return null;
    try {
      return _studentProfile!.parents.firstWhere(
            (parent) => parent.relation.toLowerCase() == relation.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if student has active status
  bool get isActive => _studentProfile?.isActive() ?? false;

  /// Get formatted display information
  String get displayInfo {
    if (_studentProfile == null) return 'No profile data';
    return '${studentName} - ${courseName} (${currentClass})';
  }
}