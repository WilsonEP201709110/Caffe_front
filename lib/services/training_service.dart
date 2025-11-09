import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class TrainingService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<Map<String, dynamic>> detectAndSaveImage({
    required Uint8List imageBytes,
    required int productoId,
    required String dispositivo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/training/detect-and-save'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Agregar la imagen como archivo
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    // Otros campos del form-data
    request.fields['producto_id'] = productoId.toString();
    request.fields['dispositivo'] = dispositivo;
    request.fields['return_image'] = 'true';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body)['data'];
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Error desconocido (${response.statusCode})',
      );
    }
  }

  Future<Map<String, dynamic>> getModelDatasetsSimple(int modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/training/model-datasets-simple?modelo_base_id=$modelId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Error al cargar detalles del modelo');
    }
  }

  Future<Map<String, dynamic>> advanceStep2(
    int trainingId,
    String currentStep,
    String observations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final response = await http.put(
      Uri.parse('$baseUrl/api/training/$trainingId/advance-step2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_step': currentStep,
        'observations': observations,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Error al avanzar paso');
    }
  }

  Future<Map<String, dynamic>> getLogFile(int trainingId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/training/$trainingId/log-file'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Error al obtener el log. Código: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> advanceStep(
    int modelId,
    Map<String, dynamic> payload,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/training/$modelId/advance-step2');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> fetchTrainingStatus(int trainingId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No estás autenticado');

    final url = Uri.parse('$baseUrl/api/training/$trainingId/advance-step2');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"current_step": "look_entrenar"}),
    );

    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  Future<Map<String, dynamic>> updateTrainingStatus({
    required int trainingId,
    required String estado,
    String? observaciones,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse('$baseUrl/api/training/$trainingId/update-status');

    final body = {
      'estado': estado,
      if (observaciones != null && observaciones.isNotEmpty)
        'observaciones': observaciones,
    };

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(
        data['message'] ?? 'Error al actualizar el estado del entrenamiento',
      );
    }
  }
}
