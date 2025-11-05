import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Student/models/student_profile_model.dart';
import 'Student/service/student_profile_service.dart';

class StudentProfileProvider extends ChangeNotifier {
  // --- Storage Keys ---
  static const _studentProfileKey = 'student_profile_data';
  static const _profileLastFetchKey = 'profile_last_fetch_time';

  // --- Services ---
  final StudentProfileService _profileService = StudentProfileService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
  bool get hasData => _studentProfile != null; // ✅ ADDED

  // Quick access getters
  String get studentName => _studentProfile?.studentUser.fullName ?? 'Student';
  String get studentEmail => _studentProfile?.studentUser.email ?? 'N/A';
  String get studentPhone => _studentProfile?.studentUser.phoneNumber ?? 'N/A';
  String get photoUrl => _studentProfile?.studentUser.photoUrl ?? '';
  String get studentPhotoUrl => _studentProfile?.studentUser.photoUrl ?? '';
  String get courseName => _studentProfile?.course.name ?? 'N/A';
  String get branchName => _studentProfile?.branch.name ?? 'N/A';
  String get currentClass => _studentProfile?.currentClass ?? 'N/A';
  String get studentId => _studentProfile?.formNumber ?? 'N/A';
  String get formNumber => _studentProfile?.formNumber ?? 'N/A';

  // Additional getters
  String get address => _studentProfile?.studentUser.address ?? 'N/A';
  String get gender => _studentProfile?.studentUser.gender ?? 'N/A';
  String get sessionYear => _studentProfile?.sessionYear ?? 'N/A';
  String get status => _studentProfile?.status ?? 'N/A';
  String get admissionDate => _studentProfile?.getFormattedAdmissionDate() ?? 'N/A';
  String get dateOfBirth => _studentProfile?.studentUser.getFormattedDOB() ?? 'N/A';
  int? get age => _studentProfile?.studentUser.getAge();

  // Parent information
  ParentModel? get father => _studentProfile?.getFather();
  ParentModel? get mother => _studentProfile?.getMother();

  // Fee information
  String get courseFee => _studentProfile?.courseFee ?? 'N/A';
  String get totalPayable => _studentProfile?.totalPayable ?? 'N/A';
  String get totalDiscount => _studentProfile?.getTotalDiscount() ?? '0';
  bool get isActive => _studentProfile?.isActive() ?? false;

  // Emergency contact
  String get emergencyContactName => _studentProfile?.emergencyContactName ?? 'N/A';
  String get emergencyContactNumber => _studentProfile?.emergencyContactNumber ?? 'N/A';
  String get emergencyContactRelation => _studentProfile?.emergencyContactRelation ?? 'N/A';

  StudentProfileProvider() {
    _initializeProfile();
  }

  /// ✅ FIXED: Get auth token from secure storage (matches SessionManager key)
  Future<String?> _getAuthToken() async {
    try {
      // ✅ This matches SessionManager's '_activeTokenKey'
      String? token = await _secureStorage.read(key: 'authToken');

      if (token != null) {
        print('✅ [Provider] Auth token found: ${token.substring(0, 20)}...');
      } else {
        print('⚠️ [Provider] No auth token found in secure storage');
      }

      return token;
    } catch (e) {
      print('❌ [Provider] Error reading auth token: $e');
      return null;
    }
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
          print('👤 Cached student: ${_studentProfile?.studentUser.fullName}');
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

  /// ✅ ADDED: Load student profile (auto-fetches token)
  Future<void> loadStudentProfile() async {
    if (_isLoading) {
      print('⚠️ [Provider] Profile already loading, skipping...');
      return;
    }

    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      await fetchStudentProfile(token, forceRefresh: false);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('❌ [Provider] Error in loadStudentProfile: $_errorMessage');
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
      print('👤 Student: ${_studentProfile?.studentUser.fullName}');
      print('🆔 Form Number: ${_studentProfile?.formNumber}');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('❌ Error fetching student profile: $_errorMessage');
      notifyListeners();
      rethrow;
    }
  }

  /// ✅ ADDED: Refresh profile (auto-fetches token and forces refresh)
  Future<void> refreshProfile() async {
    print('🔄 [Provider] Refreshing student profile...');

    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      await fetchStudentProfile(token, forceRefresh: true);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('❌ [Provider] Error refreshing profile: $_errorMessage');
      notifyListeners();
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
  Future<void> refreshIfStale({int maxAgeMinutes = 30}) async {
    if (isProfileStale(maxAgeMinutes: maxAgeMinutes)) {
      await refreshProfile();
    }
  }

  /// Check if profile needs to be loaded
  bool needsLoading() {
    return _studentProfile == null && !_isLoading && _errorMessage == null;
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

  /// Get formatted display information
  String get displayInfo {
    if (_studentProfile == null) return 'No profile data';
    return '${studentName} - ${courseName} (${currentClass})';
  }
}