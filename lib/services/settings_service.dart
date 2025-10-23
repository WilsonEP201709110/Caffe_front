import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<int> getMinImagesRequired() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/api/setting/get?clave=limit_images'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return int.parse(responseData['data']['valor']);
      } else {
        throw Exception('Error al obtener configuración');
      }
    } else {
      throw Exception('Error al obtener configuración: ${response.statusCode}');
    }
  }
}
