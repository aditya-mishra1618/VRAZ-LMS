import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/child_profile_model.dart';

class ChildProfileApi {
  /// Fetch complete profile details for a specific child
  static Future<ChildProfile?> fetchChildProfile({
    required String authToken,
    required int childId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/childrenProfile/$childId',
    );

    print('[ChildProfileApi] 👶 Fetching profile for child ID: $childId');
    print('[ChildProfileApi] GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[ChildProfileApi] Response status: ${response.statusCode}');
      print('[ChildProfileApi] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle both direct object and wrapped response
        final profileData = data is Map<String, dynamic>
            ? (data['data'] ?? data)
            : data;

        final profile = ChildProfile.fromJson(profileData as Map<String, dynamic>);

        print('[ChildProfileApi] ✅ Profile loaded: ${profile.fullName}');
        print('[ChildProfileApi] Class: ${profile.currentClass}, Course: ${profile.courseName}');

        return profile;
      } else if (response.statusCode == 401) {
        print('[ChildProfileApi] ❌ Unauthorized - token may be expired');
        return null;
      } else if (response.statusCode == 404) {
        print('[ChildProfileApi] ❌ Child profile not found');
        return null;
      } else {
        print('[ChildProfileApi] ❌ Failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('[ChildProfileApi] ❌ ERROR: $e');
      print('[ChildProfileApi] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch profiles for multiple children
  static Future<List<ChildProfile>> fetchMultipleChildProfiles({
    required String authToken,
    required List<int> childIds,
  }) async {
    final profiles = <ChildProfile>[];

    for (final childId in childIds) {
      final profile = await fetchChildProfile(
        authToken: authToken,
        childId: childId,
      );
      if (profile != null) {
        profiles.add(profile);
      }
    }

    print('[ChildProfileApi] ✅ Loaded ${profiles.length} profiles');
    return profiles;
  }
}