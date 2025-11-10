import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/support_ticket_model.dart';

class SupportTicketService {
  // Base URL - Change this based on your environment
  static const String baseUrl = 'https://vraz-backend-api.onrender.com/api';

  // Timeout duration
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Headers
  Map<String, String> _getHeaders(String token) {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    print('🔑 [HEADERS] Generated headers:');
    print('   ├─ Content-Type: ${headers['Content-Type']}');
    print('   └─ Authorization: Bearer ${token.substring(0, 30)}...');

    return headers;
  }

  // ============================================
  // API 1: Fetch All Support Tickets
  // ============================================
  Future<ApiResponse<List<SupportTicketModel>>> fetchSupportTickets(
      String token) async {
    try {
      print('\n🔷 [SERVICE] fetchSupportTickets called');
      print('   └─ Token length received: ${token.length}');

      final url = Uri.parse('$baseUrl/parentMobile/my/supportTickets/get');
      print('🌐 [URL] $url');

      final headers = _getHeaders(token);

      print('📤 [REQUEST] Making GET request...');
      final response = await http
          .get(
        url,
        headers: headers,
      )
          .timeout(timeoutDuration);

      print('📥 GET Support Tickets - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<SupportTicketModel> tickets =
        jsonList.map((json) => SupportTicketModel.fromJson(json)).toList();

        return ApiResponse.success(tickets);
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse.error(
          'No tickets found.',
          statusCode: 404,
        );
      } else {
        return ApiResponse.error(
          'Failed to fetch tickets. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error(
        'No internet connection. Please check your network.',
      );
    } on http.ClientException {
      return ApiResponse.error(
        'Network error. Please try again.',
      );
    } on FormatException {
      return ApiResponse.error(
        'Invalid response format from server.',
      );
    } catch (e) {
      print('❌ Error fetching support tickets: $e');
      return ApiResponse.error(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // ============================================
  // API 2: Create Support Ticket
  // ============================================
  Future<ApiResponse<SupportTicketModel>> createSupportTicket({
    required String token,
    required CreateSupportTicketRequest request,
  }) async {
    try {
      print('\n🔷 [SERVICE] createSupportTicket called');
      print('   └─ Token length received: ${token.length}');

      final url = Uri.parse('$baseUrl/parentMobile/supportTickets/create');
      print('🌐 [URL] $url');

      print('📤 Creating Support Ticket...');
      print('📤 Request Body: ${json.encode(request.toJson())}');

      final headers = _getHeaders(token);

      final response = await http
          .post(
        url,
        headers: headers,
        body: json.encode(request.toJson()),
      )
          .timeout(timeoutDuration);

      print('📥 Create Ticket Response - Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final SupportTicketModel ticket =
        SupportTicketModel.fromJson(jsonResponse);

        return ApiResponse.success(ticket);
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 400) {
        return ApiResponse.error(
          'Invalid ticket data. Please check all fields.',
          statusCode: 400,
        );
      } else {
        return ApiResponse.error(
          'Failed to create ticket. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error(
        'No internet connection. Please check your network.',
      );
    } on http.ClientException {
      return ApiResponse.error(
        'Network error. Please try again.',
      );
    } on FormatException {
      return ApiResponse.error(
        'Invalid response format from server.',
      );
    } catch (e) {
      print('❌ Error creating support ticket: $e');
      return ApiResponse.error(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // ============================================
  // Helper: Check Network Connectivity
  // ============================================
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}