import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/teacher_doubt_model.dart';

class TeacherDoubtService {
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';

  /// Get all doubts assigned to this teacher
  Future<List<TeacherDoubtModel>> getMyDoubts(String token) async {
    try {
      print('📥 [TeacherDoubtService] Fetching teacher doubts...');
      print('🔐 Bearer Token: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/teachers/doubts/getMyDoubts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ Doubts fetched successfully, count: ${jsonData.length}');

        return jsonData
            .map((json) => TeacherDoubtModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        print('⚠️ No doubts found (404)');
        return [];
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load doubts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getMyDoubts: $e');
      rethrow;
    }
  }

  /// Get chat messages for a specific doubt
  Future<DoubtChatResponse> getChat(String token, int doubtId) async {
    try {
      print('💬 [TeacherDoubtService] Fetching chat for doubt ID: $doubtId');
      print('🔐 Bearer Token: Bearer ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/teachers/doubts/getChat/$doubtId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Chat fetched successfully');

        return DoubtChatResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Doubt not found.');
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load chat: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getChat: $e');
      rethrow;
    }
  }

  /// Send a message (text, image, or voice note)
  Future<bool> sendMessage(
      String token,
      int doubtId, {
        String? text,
        String? imageUrl,
        String? voiceNoteUrl,
      }) async {
    try {
      print('\n╔════════════════════════════════════════════════════════════╗');
      print('║            SEND MESSAGE DEBUG INFO                         ║');
      print('╚════════════════════════════════════════════════════════════╝');
      print('📤 [SEND_MESSAGE] Starting...');
      print('   ├─ Doubt ID: $doubtId');
      print('   ├─ Text: ${text ?? "null"} (length: ${text?.length ?? 0})');
      print('   ├─ Image URL: ${imageUrl ?? "null"}');
      print('   ├─ Voice URL: ${voiceNoteUrl ?? "null"}');
      print('   └─ Token length: ${token.length} chars');

      // Construct URL
      final url = Uri.parse('$baseUrl/teacher/doubts/sendMessage/$doubtId');
      print('\n🌐 [URL INFO]');
      print('   ├─ Base URL: $baseUrl');
      print('   ├─ Full URL: $url');
      print('   └─ Scheme: ${url.scheme}');

      // Construct request body
      final body = <String, dynamic>{};

      if (text != null && text.isNotEmpty) {
        body['text'] = text;
        print('\n📝 [BODY] Added text: "$text"');
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['image_url'] = imageUrl;
        print('🖼️ [BODY] Added image_url: "$imageUrl"');
      }

      if (voiceNoteUrl != null && voiceNoteUrl.isNotEmpty) {
        body['voice_note_url'] = voiceNoteUrl;
        print('🎤 [BODY] Added voice_note_url: "$voiceNoteUrl"');
      }

      if (body.isEmpty) {
        print('\n⚠️ [WARNING] Body is empty! Nothing to send.');
        throw Exception('No content to send (text, image, or voice required)');
      }

      final jsonBody = jsonEncode(body);
      print('\n📦 [REQUEST BODY]');
      print('   └─ JSON: $jsonBody');

      print('\n🔐 [HEADERS]');
      print('   ├─ Content-Type: application/json');
      print('   └─ Authorization: Bearer ${token.substring(0, 20)}...');

      print('\n⏳ [HTTP] Sending POST request...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      );

      print('\n📥 [RESPONSE]');
      print('   ├─ Status Code: ${response.statusCode}');
      print('   ├─ Status Message: ${response.reasonPhrase}');
      print('   └─ Body Length: ${response.body.length} chars');

      print('\n📨 [RESPONSE BODY]');
      print(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('\n✅ [SUCCESS] Message sent successfully!');
        print('╚════════════════════════════════════════════════════════════╝\n');
        return true;
      } else if (response.statusCode == 401) {
        print('\n❌ [ERROR] Unauthorized - Token may be expired');
        print('╚════════════════════════════════════════════════════════════╝\n');
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        print('\n❌ [ERROR] Not Found - Check URL path');
        print('╚════════════════════════════════════════════════════════════╝\n');
        throw Exception('Endpoint not found. URL may be incorrect.');
      } else {
        print('\n❌ [ERROR] HTTP ${response.statusCode}');
        print('╚════════════════════════════════════════════════════════════╝\n');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('\n💥 [EXCEPTION] Caught error in sendMessage');
      print('   ├─ Error Type: ${e.runtimeType}');
      print('   └─ Error Message: $e');
      print('\n📚 [STACK TRACE]');
      print(stackTrace.toString());
      print('╚════════════════════════════════════════════════════════════╝\n');
      rethrow;
    }
  }

  /// Mark doubt as resolved/closed
  Future<bool> resolveDoubt(String token, int doubtId) async {
    try {
      print('✅ [TeacherDoubtService] Resolving doubt ID: $doubtId');

      final response = await http.put(
        Uri.parse('$baseUrl/teachers/doubts/resolve/$doubtId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📩 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Doubt resolved successfully');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
      git  print('❌ Error: ${response.body}');
        throw Exception('Failed to resolve doubt: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in resolveDoubt: $e');
      rethrow;
    }
  }
}