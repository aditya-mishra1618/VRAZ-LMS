import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/support_chat_model.dart';
import '../models/support_ticket_model.dart';

class SupportChatService {
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // API 1: Get Chat Messages
  // ============================================
  Future<ApiResponse<ChatTicketDetails>> getChatMessages({
    required String token,
    required int ticketId,
  }) async {
    try {
      print('\n🔷 [CHAT_SERVICE] getChatMessages called');
      print('   └─ Ticket ID: $ticketId');

      final url = Uri.parse('$baseUrl/parentMobile/supportTickets/getChat/$ticketId');
      print('🌐 [URL] $url');

      final response = await http
          .get(
        url,
        headers: _getHeaders(token),
      )
          .timeout(timeoutDuration);

      print('📥 Get Chat Response - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final chatDetails = ChatTicketDetails.fromJson(jsonResponse);

        print('✅ Chat loaded: ${chatDetails.messages.length} messages');
        return ApiResponse.success(chatDetails);
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse.error(
          'Chat not found.',
          statusCode: 404,
        );
      } else {
        return ApiResponse.error(
          'Failed to load chat. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on http.ClientException {
      return ApiResponse.error('Network error. Please try again.');
    } on FormatException {
      return ApiResponse.error('Invalid response format from server.');
    } catch (e) {
      print('❌ Error getting chat messages: $e');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // ============================================
  // API 2: Send Message
  // ============================================
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String token,
    required int ticketId,
    required SendMessageRequest request,
  }) async {
    try {
      print('\n🔷 [CHAT_SERVICE] sendMessage called');
      print('   ├─ Ticket ID: $ticketId');
      print('   ├─ Has text: ${request.text != null}');
      print('   └─ Has image: ${request.imageUrl != null}');

      final url = Uri.parse('$baseUrl/parentMobile/supportTickets/sendMessage/$ticketId');
      print('🌐 [URL] $url');

      final response = await http
          .post(
        url,
        headers: _getHeaders(token),
        body: json.encode(request.toJson()),
      )
          .timeout(timeoutDuration);

      print('📥 Send Message Response - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final message = ChatMessage.fromJson(jsonResponse);

        print('✅ Message sent successfully');
        return ApiResponse.success(message);
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 400) {
        return ApiResponse.error(
          'Invalid message data.',
          statusCode: 400,
        );
      } else {
        return ApiResponse.error(
          'Failed to send message. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on http.ClientException {
      return ApiResponse.error('Network error. Please try again.');
    } on FormatException {
      return ApiResponse.error('Invalid response format from server.');
    } catch (e) {
      print('❌ Error sending message: $e');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // ============================================
  // API 3: Upload Media (Image/Voice)
  // ============================================
  Future<ApiResponse<String>> uploadMedia({
    required String token,
    required File file,
  }) async {
    try {
      print('\n🔷 [CHAT_SERVICE] uploadMedia called');
      print('   ├─ File path: ${file.path}');
      print('   └─ File size: ${await file.length()} bytes');

      final url = Uri.parse('$baseUrl/parentMobile/supportTickets/uploadMedia');
      print('🌐 [URL] $url');

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      print('📤 Uploading file...');
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload Response - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final String mediaUrl = jsonResponse['url'] as String;

        print('✅ Media uploaded successfully: $mediaUrl');
        return ApiResponse.success(mediaUrl);
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 400) {
        return ApiResponse.error(
          'Invalid file format.',
          statusCode: 400,
        );
      } else {
        return ApiResponse.error(
          'Failed to upload media. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on http.ClientException {
      return ApiResponse.error('Network error. Please try again.');
    } catch (e) {
      print('❌ Error uploading media: $e');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }
}