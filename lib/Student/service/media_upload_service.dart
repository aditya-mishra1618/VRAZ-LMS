import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vraz_application/api_config.dart';

class MediaUploadService {
  /// 📤 Upload media file (image or audio) to server
  Future<String> uploadMedia(String authToken, File file) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/students/my/doubts/uploadMedia');
    print('📤 [MediaUploadService] Uploading file: ${file.path}');

    try {
      print('🔐 Bearer Token: Bearer ${authToken.substring(0, 20)}...');

      var request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $authToken';

      // Add file to request
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      print('📦 Sending file: ${file.path.split('/').last}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📩 Upload Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final String uploadedUrl = jsonResponse['url'] ?? '';

        if (uploadedUrl.isEmpty) {
          throw Exception('No URL returned from server');
        }

        print('✅ File uploaded successfully: $uploadedUrl');
        return uploadedUrl;
      } else {
        print('❌ Failed to upload file: ${response.body}');
        throw Exception(
            'Failed to upload file. Status Code: ${response.statusCode}, Message: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error in uploadMedia(): $e');
      throw Exception('An error occurred while uploading file: $e');
    }
  }

  /// 📸 Upload image file
  Future<String> uploadImage(String authToken, File imageFile) async {
    print('📸 Uploading image...');
    return await uploadMedia(authToken, imageFile);
  }

  /// 🎤 Upload audio file
  Future<String> uploadAudio(String authToken, File audioFile) async {
    print('🎤 Uploading audio...');
    return await uploadMedia(authToken, audioFile);
  }
}