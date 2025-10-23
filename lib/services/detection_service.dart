import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DetectionService {
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000';

  Future<void> submitDetection({
    required int productId,
    required int modelId,
    required int quantity,
    required String imagePath,
    required double confidence,
    required String location,
    required String device,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.post(
      Uri.parse('$baseUrl/api/detections'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'model_id': modelId,
        'quantity': quantity,
        'image_path': imagePath,
        'confidence': confidence,
        'location': location,
        'device': device,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }
}
