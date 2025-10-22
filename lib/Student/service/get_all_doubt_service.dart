import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vraz_application/Student/models/get_all_model.dart';
class GetAllDoubtService {
  final String baseUrl = 'https://vraz-backend-api.onrender.com/api/students/my/doubts';

  Future<List<GetAllDoubtModel>> getAllDoubt(String token) async {
    print('Fetching doubts from API...'); // Debug
    final response = await http.get(
      Uri.parse('$baseUrl/getDoubts'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      print('Doubts fetched successfully!'); // Debug
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => GetAllDoubtModel.fromJson(e)).toList();
    } else {
      print('Failed to fetch doubts. Status code: ${response.statusCode}'); // Debug
      throw Exception('Failed to fetch doubts');
    }
  }
}
