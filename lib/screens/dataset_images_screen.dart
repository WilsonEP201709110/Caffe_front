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
  List<Map<String, dynamic>> _pendingImages = [];
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

  // Tomar foto
  Future<void> _takePhotoPending() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _pendingImages.add({'bytes': bytes, 'filename': pickedFile.name});
    });
  }

  // Selección múltiple de carpeta
  Future<void> _pickMultiplePending() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.bytes != null) {
            _pendingImages.add({'bytes': file.bytes!, 'filename': file.name});
          }
        }
      });
    }
  }

  Future<bool> eliminarImagenEnNube(int idImagen) async {
    final String url =
        "http://127.0.0.1:5000/api/training/eliminar_imagen/$idImagen";
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Si usas autenticación JWT
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error eliminando imagen: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error en la petición: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
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
              : (_images.isEmpty && _pendingImages.isEmpty)
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
              : Builder(
                builder: (context) {
                  final allImages = [
                    ..._pendingImages.map(
                      (e) => <String, dynamic>{
                        'filename': e['filename'],
                        'bytes': e['bytes'],
                        'pending': true,
                      },
                    ),
                    ..._images.map(
                      (e) => Map<String, dynamic>.from(e)..['pending'] = false,
                    ),
                  ];

                  return GridView.builder(
                    padding: EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: allImages.length,
                    itemBuilder: (context, index) {
                      final image = allImages[index];
                      return GestureDetector(
                        onTap: () => _showDeletePopup(image),
                        child: _buildImageCard(image),
                      );
                    },
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
            onPressed: _takePhotoPending,
            tooltip: 'Tomar Foto',
            child: Icon(Icons.camera_alt, color: AppColors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'folderBtn',
            backgroundColor: AppColors.brownMedium,
            onPressed: _pickMultiplePending,
            tooltip: 'Cargar desde carpeta',
            child: Icon(Icons.folder_open, color: AppColors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'uploadBtn',
            backgroundColor: Colors.blue.shade400,
            onPressed: _uploadPendingImages,
            tooltip: 'Subir imágenes pendientes',
            child: Icon(Icons.cloud_upload, color: Colors.white),
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
                onPressed: () async {
                  Navigator.pop(context);

                  if (image['pending'] == true) {
                    // Imagen en memoria (sin subir)
                    setState(() {
                      _pendingImages.removeWhere(
                        (e) => e['filename'] == image['filename'],
                      );
                    });
                  } else {
                    // Imagen ya subida → eliminar desde la nube
                    final int? idImagen =
                        image['id']; // Asegúrate que venga incluido
                    final String token =
                        "AQUÍ_TU_TOKEN"; // O recupéralo desde storage

                    if (idImagen == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ID de imagen no disponible')),
                      );
                      return;
                    }

                    final ok = await eliminarImagenEnNube(idImagen);

                    if (ok) {
                      setState(() {
                        _images.removeWhere((e) => e['id'] == idImagen);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Imagen eliminada correctamente'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al eliminar la imagen')),
                      );
                    }
                  }
                },
                child: Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image) {
    final bool pending = image['pending'] == true;

    return Container(
      decoration:
          pending
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              )
              : null,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              pending
                  ? BorderSide(color: AppColors.mintGreen, width: 4)
                  : BorderSide(color: AppColors.brownMedium, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: pending ? 0 : 4,
        child: Stack(
          children: [
            // Imagen
            pending
                ? Image.memory(
                  image['bytes'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
                : Image.network(
                  image['path'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

            // Botón de etiquetado
            Positioned(
              top: 8,
              left: 8,
              child: InkWell(
                onTap: () => _onLabelButtonPressed(image),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Ver etiqueta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botón de eliminar (opcional)
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _showDeletePopup(image),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete, color: Colors.white, size: 18),
                ),
              ),
            ),

            // Barra inferior con nombre
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.white,
                child: Text(
                  image['filename'] ?? 'sin_nombre.jpg',
                  style: TextStyle(color: AppColors.brownDark, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPendingImages() async {
    if (_pendingImages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    for (var img in _pendingImages) {
      String img64 = base64Encode(img['bytes']);
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
          "filename": img['filename'],
          "labeled": true,
          "approved": true,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo ${img['filename']}')),
        );
      }
    }

    setState(() {
      _pendingImages.clear();
      _fetchImages();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Imágenes subidas con éxito')));
  }

  Future<void> _onLabelButtonPressed(Map<String, dynamic> image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Preparar payload según si es base64 o id
      Map<String, dynamic> payload = {};
      if (image['pending'] == true) {
        // Imagen en memoria
        payload['image_base64'] = base64Encode(image['bytes']);
      } else {
        // Imagen en la web
        payload['image_id'] = image['id'];
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/training/label_image_proxy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Solo abrir el modal, NO llamar a setState()
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Etiqueta de la Imagen'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (responseData['image'] != null)
                        Image.memory(base64Decode(responseData['image'])),
                      SizedBox(height: 8),
                      if (responseData['coordenadas'] != null)
                        Text(responseData['coordenadas']),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // solo cierra el modal
                    },
                    child: Text('Cerrar'),
                  ),
                ],
              ),
        );
      } else {
        throw Exception('Error al obtener etiqueta: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLabelModal(Map<String, dynamic> data) {
    // data debe contener: image (base64) y coordenadas
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Imagen Etiquetada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['image'] != null)
                  Image.memory(base64Decode(data['image'])),
                SizedBox(height: 12),
                if (data['coordenadas'] != null)
                  Text('Coordenadas: ${data['coordenadas']}'),
              ],
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
}
