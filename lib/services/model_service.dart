import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ModelService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<Map<String, dynamic>> fetchModels(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/api/models/product/$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception(responseData['message'] ?? 'Error al cargar modelos');
    }
  }

  Future<void> createModel({
    required int productId,
    required String name,
    required String version,
    required String framework,
    required String routeType,
    required String routePath,
    required String routeFormat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.post(
      Uri.parse('$baseUrl/api/models'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'name': name,
        'version': version,
        'framework': framework,
        'routes': [
          {'type': routeType, 'path': routePath, 'format': routeFormat},
        ],
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201 || responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Error al crear modelo');
    }
  }

  Future<void> addRouteToModel({
    required int modelId,
    required String type,
    required String path,
    required String format,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.post(
      Uri.parse('$baseUrl/api/models/$modelId/routes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'type': type, 'path': path, 'format': format}),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201 || responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Error al agregar ruta');
    }
  }

  Future<void> setModelActive(int modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.put(
      Uri.parse('$baseUrl/api/models/$modelId/set-active'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200 || responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Error al activar modelo');
    }
  }
}
