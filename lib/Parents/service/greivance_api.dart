import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../api_config.dart';
import '../models/grivance_model.dart';

class GrievanceApi {
  /// Fetch all grievances for the parent
  static Future<List<Grievance>> fetchGrievances({
    required String authToken,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/getGrievances',
    );

    print('[GrievanceApi] 📢 Fetching grievances...');
    print('[GrievanceApi] GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[GrievanceApi] Response status: ${response.statusCode}');
      print('[GrievanceApi] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> grievancesData;

        if (data is List) {
          grievancesData = data;
        } else if (data is Map<String, dynamic>) {
          grievancesData = data['grievances'] ??
              data['data'] ??
              data['tickets'] ??
              [];
        } else {
          print('[GrievanceApi] ⚠️ Unexpected response format');
          return [];
        }

        if (grievancesData.isEmpty) {
          print('[GrievanceApi] ℹ️ No grievances found');
          return [];
        }

        final grievances = grievancesData
            .map((e) => Grievance.fromJson(e as Map<String, dynamic>))
            .toList();

        grievances.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('[GrievanceApi] ✅ Parsed ${grievances.length} grievances');
        print('[GrievanceApi] Open: ${grievances.where((g) => g.isOpen).length}');
        print('[GrievanceApi] Resolved: ${grievances.where((g) => g.isResolved).length}');

        return grievances;
      } else if (response.statusCode == 401) {
        print('[GrievanceApi] ❌ Unauthorized - token may be expired');
        return [];
      } else if (response.statusCode == 404) {
        print('[GrievanceApi] ℹ️ No grievances found');
        return [];
      } else {
        print('[GrievanceApi] ❌ Failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('[GrievanceApi] ❌ ERROR: $e');
      print('[GrievanceApi] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Create new grievance (UPDATED ENDPOINT)
  static Future<bool> createGrievance({
    required String authToken,
    required String title,
    required String description,
    String? category,
    List<String>? attachments,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/grievances/create', // ✅ UPDATED ENDPOINT
    );

    print('[GrievanceApi] 📝 Creating new grievance...');
    print('[GrievanceApi] POST $url');

    try {
      final body = {
        'title': title,
        'description': description,
        if (category != null) 'category': category,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments,
      };

      print('[GrievanceApi] Request body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('[GrievanceApi] Response status: ${response.statusCode}');
      print('[GrievanceApi] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[GrievanceApi] ✅ Grievance created successfully');
        return true;
      } else {
        print('[GrievanceApi] ❌ Failed to create grievance: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[GrievanceApi] ❌ ERROR: $e');
      print('[GrievanceApi] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get single grievance details (for chat)
  static Future<Grievance?> getGrievanceDetails({
    required String authToken,
    required int grievanceId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/my/grievances/$grievanceId',
    );

    print('[GrievanceApi] 🔍 Fetching grievance details for ID: $grievanceId');
    print('[GrievanceApi] GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      print('[GrievanceApi] Response status: ${response.statusCode}');
      print('[GrievanceApi] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final grievanceData = data is Map<String, dynamic>
            ? (data['grievance'] ?? data['data'] ?? data)
            : data;

        final grievance = Grievance.fromJson(grievanceData as Map<String, dynamic>);
        print('[GrievanceApi] ✅ Grievance details loaded: ${grievance.title}');
        return grievance;
      } else {
        print('[GrievanceApi] ❌ Failed to fetch grievance details: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('[GrievanceApi] ❌ ERROR: $e');
      print('[GrievanceApi] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Calculate grievance summary
  static GrievanceSummary calculateSummary(List<Grievance> grievances) {
    return GrievanceSummary.fromGrievances(grievances);
  }

  /// Filter grievances by status
  static List<Grievance> filterByStatus(
      List<Grievance> grievances, String status) {
    if (status == 'ALL') return grievances;
    return grievances.where((g) => g.status == status.toUpperCase()).toList();
  }
  static Future<String?> uploadMedia({
    required String authToken,
    required File file,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/parentMobile/supportTickets/uploadMedia',
    );

    print('[GrievanceApi] 📤 Uploading media...');
    print('[GrievanceApi] POST $url');
    print('[GrievanceApi] File path: ${file.path}');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $authToken';

      // Add file
      final fileExtension = file.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';

      if (fileExtension == 'png') {
        mimeType = 'image/png';
      } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        mimeType = 'image/jpeg';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('[GrievanceApi] Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[GrievanceApi] Response status: ${response.statusCode}');
      print('[GrievanceApi] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Extract URL from response
        String? fileUrl;
        if (data is Map<String, dynamic>) {
          fileUrl = data['url'] ??
              data['fileUrl'] ??
              data['data']?['url'] ??
              data['attachment'];
        }

        if (fileUrl != null) {
          print('[GrievanceApi] ✅ Media uploaded successfully: $fileUrl');
          return fileUrl;
        } else {
          print('[GrievanceApi] ⚠️ Upload successful but no URL in response');
          return null;
        }
      } else {
        print('[GrievanceApi] ❌ Failed to upload media: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('[GrievanceApi] ❌ ERROR uploading media: $e');
      print('[GrievanceApi] Stack trace: $stackTrace');
      return null;
    }
  }
}