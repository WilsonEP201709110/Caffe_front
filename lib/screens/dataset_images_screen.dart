import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class DatasetImagesScreen extends StatefulWidget {
  static const routeName = '/datasets/images';

  @override
  _DatasetImagesScreenState createState() => _DatasetImagesScreenState();
}

class _DatasetImagesScreenState extends State<DatasetImagesScreen> {
  List<dynamic> _images = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _datasetInfo;
  late int _datasetId;
  late String _datasetName;

  final ImagePicker _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _datasetId = args['datasetId'];
    _datasetName = args['datasetName'];
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:5000/api/training/datasets/$_datasetId/images',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _images = responseData['data']['images'] ?? [];
          _datasetInfo = {
            'total_images': responseData['data']['total_images'],
            'dataset_name': responseData['data']['dataset_name'],
          };
          _isLoading = false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Error al cargar imágenes');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _takeAndUploadPhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String img64 = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:5000/api/training/datasets/$_datasetId/images/base64',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "image": img64,
          "filename": fileName,
          "labeled": true,
          "approved": true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imagen subida con éxito')));
        _fetchImages();
      } else {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen')));
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (kIsWeb && file.bytes != null) {
            await _uploadImageBytes(file.bytes!, file.name);
          } else if (file.path != null) {
            await _uploadImageFile(File(file.path!));
          }
        }
        _fetchImages();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando imágenes')));
    }
  }

  Future<void> _uploadImageBytes(Uint8List bytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    String img64 = base64Encode(bytes);

    await http.post(
      Uri.parse(
        'http://127.0.0.1:5000/api/training/datasets/$_datasetId/images/base64',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "image": img64,
        "filename": fileName,
        "labeled": true,
        "approved": true,
      }),
    );
  }

  Future<void> _uploadImageFile(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final bytes = await file.readAsBytes();
    String img64 = base64Encode(bytes);
    String fileName = file.path.split('/').last;

    await http.post(
      Uri.parse(
        'http://127.0.0.1:5000/api/training/datasets/$_datasetId/images/base64',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "image": img64,
        "filename": fileName,
        "labeled": true,
        "approved": true,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_datasetName),
            if (_datasetInfo != null)
              Text(
                '${_datasetInfo!['total_images']} imágenes',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.brownDark),
              )
              : _error != null
              ? Center(
                child: Text(_error!, style: TextStyle(color: Colors.redAccent)),
              )
              : _images.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, size: 50, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay imágenes en este dataset'),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _fetchImages,
                      child: Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final image = _images[index];
                  return GestureDetector(
                    onTap: () => _showDeletePopup(image),
                    child: _buildImageCard(image),
                  );
                },
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refreshBtn',
            backgroundColor: AppColors.brownMedium,
            onPressed: _fetchImages,
            tooltip: 'Actualizar',
            child: Icon(Icons.refresh, color: AppColors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'cameraBtn',
            backgroundColor: AppColors.brownMedium,
            onPressed: _takeAndUploadPhoto,
            tooltip: 'Tomar Foto',
            child: Icon(Icons.camera_alt, color: AppColors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'folderBtn',
            backgroundColor: AppColors.brownMedium,
            onPressed: _pickMultipleImages,
            tooltip: 'Cargar desde carpeta',
            child: Icon(Icons.folder_open, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Stack(
        children: [
          Image.network(
            image['path'] ?? '',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder:
                (context, child, progress) =>
                    progress == null
                        ? child
                        : Center(child: CircularProgressIndicator()),
            errorBuilder:
                (_, __, ___) =>
                    Center(child: Icon(Icons.broken_image, size: 50)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      image['filename'] ?? 'sin_nombre.jpg',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (image['labeled'] == true)
                    Icon(
                      image['approved'] == true
                          ? Icons.verified
                          : Icons.pending,
                      color:
                          image['approved'] == true
                              ? Colors.green
                              : Colors.orange,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletePopup(Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar imagen'),
            content: Text('¿Deseas eliminar "${image['filename']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Funcionalidad de eliminar aún no implementada',
                      ),
                    ),
                  );
                },
                child: Text('Eliminar'),
              ),
            ],
          ),
    );
  }
}
