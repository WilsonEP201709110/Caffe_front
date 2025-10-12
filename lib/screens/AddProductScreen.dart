import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _selectedCategory;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchCategories() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/category/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        setState(() {
          _categories = data.map((e) => e as Map<String, dynamic>).toList();
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories.first;
          }
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'No estás autenticado';
          _isLoading = false;
        });
        return;
      }

      String? imageBase64;
      if (_selectedImage != null) {
        if (kIsWeb) {
          // Para Web
          final bytes = await _selectedImage!.readAsBytes();
          imageBase64 = base64Encode(bytes);
        } else {
          // Para Mobile
          final bytes = await File(_selectedImage!.path).readAsBytes();
          imageBase64 = base64Encode(bytes);
        }
      }

      final body = jsonEncode({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category_id': _selectedCategory?['id'],
        'barcode': _barcodeController.text,
        'image': imageBase64,
        'filename': _selectedImage != null ? _selectedImage!.name : null,
      });

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/api/products'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Producto agregado exitosamente!')),
          );
          Navigator.pop(context);
        } else {
          print('Respuesta: ${response.body}');
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Selecciona la imagen'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                child: Text('Cámara'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                child: Text('Galería'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agregar Producto',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Imagen
              GestureDetector(
                onTap: _showImagePickerDialog,
                child:
                    _selectedImage == null
                        ? Container(
                          height: 150,
                          width: double.infinity,
                          color: AppColors.beigeLight,
                          child: Icon(
                            Icons.coffee,
                            size: 50,
                            color: AppColors.brownDark,
                          ),
                        )
                        : kIsWeb
                        ? Image.network(
                          _selectedImage!.path,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                        : Image.file(
                          File(_selectedImage!.path),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
              ),
              SizedBox(height: 20),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  prefixIcon: Icon(
                    Icons.drive_file_rename_outline,
                    color: AppColors.brownDark,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
              ),
              SizedBox(height: 15),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(
                    Icons.description,
                    color: AppColors.brownDark,
                  ),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 15),

              // Categoría
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedCategory,
                items:
                    _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c['nombre']),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category, color: AppColors.brownDark),
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null ? 'Selecciona una categoría' : null,
              ),
              SizedBox(height: 15),

              // Código de barras
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Código de barra',
                  prefixIcon: Icon(Icons.qr_code, color: AppColors.brownDark),
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Ingresa un código de barra' : null,
              ),
              SizedBox(height: 20),

              // Botón guardar
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brownDark,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Guardar',
                      style: TextStyle(fontSize: 18, color: AppColors.white),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
