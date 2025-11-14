import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting dates for the API

// Import your LeaveApplication model (adjust the path if necessary)
// Example assumes models are in 'lib/Teacher/models/' relative to services
import '../models/leave_application_model.dart';

class LeaveApiService {
  final String _baseUrl =
      "https://vraz-backend-api.onrender.com/api/teachers/leaves";

  // --- GET My Leaves ---
  Future<List<LeaveApplication>> getMyLeaves(String authToken) async {
    final Uri url = Uri.parse('$_baseUrl/getMyLeaves');
    print('GET: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      print('Response Status (getMyLeaves): ${response.statusCode}');
      print('Response Body (getMyLeaves): ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Must be a Map containing quotas + history
        if (decoded is Map<String, dynamic>) {
          if (!decoded.containsKey('history')) {
            throw Exception("API response missing 'history' field");
          }

          final List<dynamic> historyList = decoded['history'];

          final leaves = historyList
              .map((json) => LeaveApplication.fromJson(json))
              .toList();

          // Sort newest first
          leaves.sort((a, b) => b.startDate.compareTo(a.startDate));

          return leaves;
        }

        throw Exception("Unexpected API format: $decoded");
      } else {
        throw Exception(
            'Failed to load leaves. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leaves: $e');
      rethrow;
    }
  }



  // --- POST Apply for Leave ---
  Future<LeaveApplication> applyLeave({
    required String leaveType, // Expect "SICK" or "CASUAL"
    required String reason,
    required DateTime startDate,
    required DateTime endDate,
    required String authToken,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/apply');
    print('POST: $url'); // Debug print

    // --- FIX: Ensure start of day UTC ---
    // Create new DateTime objects representing the start of the day in local time
    final startOfDayLocal =
        DateTime(startDate.year, startDate.month, startDate.day);
    // Use the *end* of the selected day for endDate to cover the full day range in UTC
    final endOfDayLocal =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Format dates to ISO 8601 string in UTC for the API
    final DateFormat apiFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    // Convert the start-of-day local time to UTC before formatting
    final String startDateStr = apiFormatter.format(startOfDayLocal.toUtc());
    final String endDateStr = apiFormatter.format(endOfDayLocal.toUtc());
    // --- END FIX ---

    final Map<String, dynamic> body = {
      'leaveType': leaveType, // Send "SICK" or "CASUAL"
      'reason': reason,
      'startDate': startDateStr,
      'endDate': endDateStr,
    };

    print('Request Body (applyLeave): ${jsonEncode(body)}'); // Debug print
    print('Start Date Sent (UTC): $startDateStr');
    print('End Date Sent (UTC): $endDateStr');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      print(
          'Response Status (applyLeave): ${response.statusCode}'); // Debug print
      print('Response Body (applyLeave): ${response.body}'); // Debug print

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 201 Created is also common
        final jsonData = jsonDecode(response.body);
        return LeaveApplication.fromJson(jsonData); // Return the created leave
      } else {
        // Try to parse the error message from the backend if possible
        String serverMessage = 'Unknown error';
        try {
          final errorBody = jsonDecode(response.body);
          serverMessage = errorBody['message'] ?? serverMessage;
        } catch (_) {
          // If body is not JSON or doesn't have 'message', use the raw body or default
          serverMessage =
              response.body.isNotEmpty ? response.body : serverMessage;
        }
        // Include the status code in the exception message
        throw Exception(
            'Failed to apply for leave. Status: ${response.statusCode}, Message: $serverMessage');
      }
    } catch (e) {
      print('Error applying for leave: $e');
      // Rethrowing the original exception might provide more specific info
      rethrow;
    }
  }

  // --- DELETE Leave Application ---
  Future<void> deleteLeave(int leaveId, String authToken) async {
    final Uri url = Uri.parse('$_baseUrl/delete/$leaveId');
    print('DELETE: $url'); // Debug print

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      print(
          'Response Status (deleteLeave): ${response.statusCode}'); // Debug print

      // API returns 204 No Content on success
      if (response.statusCode == 204) {
        return; // Success
      } else if (response.statusCode == 403) {
        // Forbidden if not PENDING
        throw Exception(
            'Cannot delete leave. It might already be approved or rejected.');
      } else {
        // Try to parse error message
        String serverMessage = 'Unknown error';
        try {
          final errorBody = jsonDecode(response.body);
          serverMessage = errorBody['message'] ?? serverMessage;
        } catch (_) {
          serverMessage =
              response.body.isNotEmpty ? response.body : serverMessage;
        }
        throw Exception(
            'Failed to delete leave. Status: ${response.statusCode}, Message: $serverMessage');
      }
    } catch (e) {
      print('Error deleting leave: $e');
      rethrow;
    }
  }
}
