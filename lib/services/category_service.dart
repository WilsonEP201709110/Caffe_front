import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CategoryService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  // ✅ Obtener token guardado
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No hay token disponible');
    return token;
  }

  // ✅ Listar categorías por usuario
  Future<List<Map<String, dynamic>>> getCategories() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/category/list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al obtener categorías');
    }
  }

  // ✅ Crear una categoría
  Future<void> createCategory(String nombre, String descripcion) async {
    final token = await _getToken();

    final body = jsonEncode({'nombre': nombre, 'descripcion': descripcion});

    final response = await http.post(
      Uri.parse('$baseUrl/api/category/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(responseData['message'] ?? 'Error al crear categoría');
    }
  }

  // ✅ Actualizar una categoría
  Future<void> updateCategory(int id, String nombre, String descripcion) async {
    final token = await _getToken();

    final body = jsonEncode({'nombre': nombre, 'descripcion': descripcion});

    final response = await http.put(
      Uri.parse('$baseUrl/api/category/update/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        responseData['message'] ?? 'Error al actualizar categoría',
      );
    }
  }

  // ✅ Eliminar una categoría (si no tiene productos asociados)
  Future<void> deleteCategory(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/category/delete/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(responseData['message'] ?? 'Error al eliminar categoría');
    }
  }
}
