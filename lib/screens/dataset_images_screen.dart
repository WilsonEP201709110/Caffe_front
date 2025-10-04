import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

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

      if (pickedFile == null) {
        print("📸 No se seleccionó ninguna imagen");
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Convertir a Base64
      String img64 = base64Encode(bytes);

      print("🚀 Enviando imagen: $fileName");

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

      print("✅ Status: ${response.statusCode}");
      print("✅ Respuesta del servidor: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imagen subida con éxito')));
        _fetchImages();
      } else {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e, stacktrace) {
      print("❌ Error al subir imagen: $e");
      print("🧵 Stacktrace: $stacktrace");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir imagen')));
    }
  }

  Future<void> _uploadImageBytes(Uint8List bytes, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final img64 = base64Encode(bytes);

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

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
      print("❌ Error al subir desde Web: $e");
    }
  }

  Future<void> _uploadImageFile(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final bytes = await file.readAsBytes();
      final img64 = base64Encode(bytes);
      final fileName = file.path.split('/').last;

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

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
      print("❌ Error al subir archivo: $e");
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true, // ✅ Necesario para Web
      );

      if (result != null) {
        for (var file in result.files) {
          if (kIsWeb) {
            if (file.bytes != null) {
              await _uploadImageBytes(file.bytes!, file.name);
            }
          } else {
            if (file.path != null) {
              await _uploadImageFile(File(file.path!));
            }
          }
        }

        _fetchImages();
      }
    } catch (e) {
      print('Error seleccionando imágenes: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando imágenes')));
    }
  }

  // ... el resto del código se mantiene igual hasta el build ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_datasetName),
            if (_datasetInfo != null)
              Text(
                '${_datasetInfo!['total_images']} imágenes',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
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
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final image = _images[index];
                  return GestureDetector(
                    onTap: () => _showImageDetails(image),
                    child: _buildImageCard(image),
                  );
                },
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refreshBtn',
            onPressed: _fetchImages,
            tooltip: 'Actualizar',
            child: Icon(Icons.refresh),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'cameraBtn',
            onPressed: _takeAndUploadPhoto,
            tooltip: 'Tomar Foto',
            child: Icon(Icons.camera_alt),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'folderBtn',
            onPressed: _pickMultipleImages,
            tooltip: 'Cargar desde carpeta',
            child: Icon(
              Icons.folder_open,
            ), // ✅ Icono de carpeta o cambia si quieres
          ),
        ],
      ),
    );
  }

  void _showImageDetails(Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detalles de la imagen'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Nombre'),
                    subtitle: Text(image['filename'] ?? 'N/A'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.storage),
                    title: Text('Tamaño'),
                    subtitle: Text(
                      '${image['size_kb']?.toStringAsFixed(2) ?? 'N/A'} KB',
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.aspect_ratio),
                    title: Text('Resolución'),
                    subtitle: Text(image['resolution'] ?? 'N/A'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.label),
                    title: Text('Estado'),
                    subtitle: Text(
                      image['labeled'] == true
                          ? (image['approved'] == true
                              ? 'Aprobado'
                              : 'Pendiente de aprobación')
                          : 'Sin etiquetar',
                    ),
                  ),
                  if (image['labeled'] == true) ...[
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Etiquetador'),
                      subtitle: Text(image['labeler_id']?.toString() ?? 'N/A'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.date_range),
                      title: Text('Fecha etiquetado'),
                      subtitle: Text(image['labeling_date'] ?? 'N/A'),
                    ),
                  ],
                  if (image['annotations'] != null) ...[
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.note),
                      title: Text('Anotaciones'),
                      subtitle: Text(image['annotations'].toString()),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: 300, // ✅ Tamaño fijo del contenedor
              child: Image.network(
                image['path'] ?? '',
                fit: BoxFit.cover, // ✅ Se adapta sin deformarse
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder:
                    (_, __, ___) =>
                        Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
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
}
