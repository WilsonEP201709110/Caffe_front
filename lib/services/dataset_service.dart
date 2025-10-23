import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class DatasetService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<Map<String, dynamic>> getDatasetImages(int datasetId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/api/training/datasets/$datasetId/images'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'images': responseData['data']['images'] ?? [],
        'total_images': responseData['data']['total_images'],
        'dataset_name': responseData['data']['dataset_name'],
      };
    } else {
      throw Exception(responseData['message'] ?? 'Error al cargar imágenes');
    }
  }

  Future<bool> uploadDatasetImage({
    required int datasetId,
    required Uint8List bytes,
    required String fileName,
    bool labeled = true,
    bool approved = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    var uri = Uri.parse(
      '$baseUrl/api/training/datasets/$datasetId/images/upload',
    );

    var request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['filename'] = fileName
          ..fields['labeled'] = labeled.toString()
          ..fields['approved'] = approved.toString()
          ..files.add(
            http.MultipartFile.fromBytes('image', bytes, filename: fileName),
          );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Error del servidor: ${response.body}');
    }
  }

  Future<bool> uploadImageFromBytes({
    required int datasetId,
    required Uint8List bytes,
    required String fileName,
    bool labeled = true,
    bool approved = true,
  }) async {
    return uploadDatasetImage(
      datasetId: datasetId,
      bytes: bytes,
      fileName: fileName,
      labeled: labeled,
      approved: approved,
    );
  }

  Future<bool> uploadImageFromFile({
    required int datasetId,
    required File file,
    bool labeled = true,
    bool approved = true,
  }) async {
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    return uploadDatasetImage(
      datasetId: datasetId,
      bytes: bytes,
      fileName: fileName,
      labeled: labeled,
      approved: approved,
    );
  }

  Future<bool> eliminarImagen(int idImagen) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final url = '$baseUrl/api/training/eliminar_imagen/$idImagen';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error eliminando imagen: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error en la petición: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> labelImage({
    XFile? imageFile,
    int? imageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/training/label_image_proxy'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    // Si hay imagen en file, agregar como MultipartFile
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    // Si hay imageId, agregarlo como field
    if (imageId != null) {
      request.fields['image_id'] = imageId.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final imageBytes = response.bodyBytes;
      final coordenadas = response.headers['x-coordinates'] ?? '';
      return {'imageBytes': imageBytes, 'coordenadas': coordenadas};
    } else {
      throw Exception('Error al obtener etiqueta: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchDatasets(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/training/datasets?product_id=$productId&limit=True',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception(responseData['message'] ?? 'Error al cargar datasets');
    }
  }

  Future<void> createDataset({
    required int productId,
    required String name,
    required String path,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.post(
      Uri.parse('$baseUrl/api/training/datasets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'name': name,
        'path': path,
        'description': description,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201 || responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Error al crear dataset');
    }
  }

  Future<Map<String, dynamic>> fetchAllDatasets(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.get(
      Uri.parse('$baseUrl/api/training/datasets?product_id=$productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception(responseData['message'] ?? 'Error al cargar datasets');
    }
  }

  Future<void> startTraining({
    required int productId,
    required int datasetId,
    required int baseModelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.post(
      Uri.parse('$baseUrl/api/training/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        'dataset_id': datasetId,
        'base_model_id': baseModelId,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201 || responseData['success'] != true) {
      throw Exception(
        responseData['message'] ?? 'Error al iniciar entrenamiento',
      );
    }
  }

  Future<void> advanceTrainingStep({
    required int trainingId,
    required String currentStep,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No estás autenticado');

    final response = await http.put(
      Uri.parse('$baseUrl/api/training/$trainingId/advance-step2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_step': currentStep,
        'observations': 'Iniciando fase de entrenamiento',
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200 || responseData['success'] != true) {
      throw Exception(responseData['message'] ?? 'Error al avanzar paso');
    }
  }
}
