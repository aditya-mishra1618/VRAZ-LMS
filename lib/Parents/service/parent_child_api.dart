import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../models/parent_child_model.dart';

class ParentChildrenApi {
  static Future<List<ParentChild>> fetchParentChildren(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/parentMobile/my/children');
    print('[ParentChildrenApi] GET $url');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('[ParentChildrenApi] Response status: ${response.statusCode}');
      print('[ParentChildrenApi] Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          print('[ParentChildrenApi] Parsed children: ${data.length}');
          return data.map<ParentChild>((child) => ParentChild.fromJson(child)).toList();
        } else {
          print('[ParentChildrenApi] Unexpected response structure: $data');
        }
      } else {
        print('[ParentChildrenApi] Failed - status: ${response.statusCode}');
      }
    } catch (e) {
      print('[ParentChildrenApi] ERROR: $e');
    }
    return [];
  }
}