import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/parent_profile_model.dart';

class ParentProfileApi {
  static Future<ParentProfile?> fetchParentProfile(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/parentMobile/my/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ParentProfile.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}