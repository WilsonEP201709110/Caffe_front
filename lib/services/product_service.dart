import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/image_utils.dart';

class ProductService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<bool> createProduct({
    required String name,
    required String description,
    required int? categoryId,
    required String barcode,
    dynamic selectedImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    // Construir la request multipart
    var uri = Uri.parse('$baseUrl/api/products');
    var request = http.MultipartRequest('POST', uri);

    // Campos de texto
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category_id'] = categoryId.toString();
    request.fields['barcode'] = barcode;

    if (selectedImage != null) {
      final compressedBytes = await ImageUtils.compressImage(
        selectedImage!,
        quality: 70,
        maxWidth: 1080,
      );

      // Ahora puedes enviarla con multipart
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          compressedBytes,
          filename: selectedImage!.name,
        ),
      );
    }

    // Headers
    request.headers['Authorization'] = 'Bearer $token';

    // Enviar request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(
        'Error del servidor (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<List<dynamic>> fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/api/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return data as List<dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión nuevamente');
    } else {
      throw Exception('Error al cargar objetos: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchProduct(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Error al cargar el objeto (${response.statusCode})');
    }
  }
}
