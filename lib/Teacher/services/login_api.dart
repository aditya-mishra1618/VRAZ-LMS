import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../api_config.dart';


class LoginApiService {
  // Teacher/Admin login (email + password)
  static Future<Map<String, dynamic>?> credentialLogin(
      String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }
}
