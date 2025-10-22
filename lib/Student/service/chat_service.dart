import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vraz_application/api_config.dart';
import '../models/chat_model.dart';


class ChatService {
  /// 💬 Fetch chat messages for a specific doubt
  Future<DoubtChatModel> getChat(String authToken, int doubtId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/doubts/getChat/$doubtId');
    print('📥 [ChatService] Fetching chat for doubt ID: $doubtId');

    try {
      print('🔐 Bearer Token: Bearer ${authToken.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📩 Get Chat Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('✅ Chat fetched successfully, messages count: ${jsonResponse['messages']?.length ?? 0}');
        return DoubtChatModel.fromJson(jsonResponse);
      } else {
        print('❌ Failed to fetch chat: ${response.body}');
        throw Exception(
            'Failed to load chat. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error in getChat(): $e');
      throw Exception('An error occurred while fetching chat: $e');
    }
  }

  /// 📤 Send a message (text, image, or voice note)
  Future<bool> sendMessage(
      String authToken, int doubtId, SendMessageRequest message) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/doubts/sendMessage/$doubtId');
    print('📤 [ChatService] Sending message to doubt ID: $doubtId');
    print('📋 Message Data: ${message.toJson()}');

    // Validate message before sending
    if (!message.isValid()) {
      print('❌ Invalid message: At least one field (text, imageUrl, voiceNoteUrl) must be provided');
      throw Exception('Message must contain text, image, or voice note');
    }

    try {
      print('🔐 Bearer Token: Bearer ${authToken.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(message.toJson()),
      );

      print('📩 Send Message Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Message sent successfully!');
        return true;
      } else {
        print('❌ Failed to send message: ${response.body}');
        throw Exception(
            'Failed to send message. Status Code: ${response.statusCode}, Message: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error in sendMessage(): $e');
      throw Exception('An error occurred while sending message: $e');
    }
  }

  /// 📤 Send text message (convenience method)
  Future<bool> sendTextMessage(
      String authToken, int doubtId, String text) async {
    return sendMessage(
      authToken,
      doubtId,
      SendMessageRequest(text: text),
    );
  }

  /// 📤 Send image message (convenience method)
  Future<bool> sendImageMessage(
      String authToken, int doubtId, String imageUrl) async {
    return sendMessage(
      authToken,
      doubtId,
      SendMessageRequest(imageUrl: imageUrl),
    );
  }

  /// 📤 Send voice note message (convenience method)
  Future<bool> sendVoiceMessage(
      String authToken, int doubtId, String voiceNoteUrl) async {
    return sendMessage(
      authToken,
      doubtId,
      SendMessageRequest(voiceNoteUrl: voiceNoteUrl),
    );
  }
}