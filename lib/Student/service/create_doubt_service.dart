import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vraz_application/api_config.dart';
import '../models/create_doubt_model.dart';

class CreateDoubtService {
  /// 📤 Create/Submit a new doubt
  Future<bool> createDoubt(String authToken, CreateDoubtModel doubt) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/doubts/create');
    print('📤 [CreateDoubtService] Creating doubt at $url');
    print('📋 Doubt Data: ${doubt.toString()}');

    try {
      print('🔐 Bearer Token: Bearer ${authToken.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(doubt.toJson()),
      );

      print('📩 Create Doubt Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Doubt created successfully!');
        return true;
      } else {
        print('❌ Failed to create doubt: ${response.body}');
        throw Exception(
            'Failed to create doubt. Status Code: ${response.statusCode}, Message: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error in createDoubt(): $e');
      throw Exception('An error occurred while creating doubt: $e');
    }
  }
}