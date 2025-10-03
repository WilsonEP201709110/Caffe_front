import 'package:caffe/screens/product_model_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_datasets_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProductDetailScreen extends StatefulWidget {
  static const routeName = '/products/detail';

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Map<String, dynamic> _product;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productId = ModalRoute.of(context)!.settings.arguments as int;
    _fetchProduct(productId);
  }

  Future<void> _fetchProduct(int productId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _product = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar el producto (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // Puedes cambiar a ImageSource.camera
    );

    final prefs = await SharedPreferences.getInstance();
      //final token = prefs.getString('auth_token');
    final usuarioId = prefs.getInt('user_id') ?? 0;

    if (_product == null || _product['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No se pudo identificar el producto')),
      );
      return;
    }

    final productoId = _product['id'];

    if (pickedFile != null) {
      /*
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );*/
      
      //final imageFile = File(pickedFile.path);
      final imageBytes = await pickedFile.readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      String ubicacion = 'Desconocida';

      // Obtener información del dispositivo
      String dispositivo = 'App1';//'${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5001/analyze-image-mysql'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'image': imageBase64,
            'usuario_id': usuarioId,
            'producto_id': productoId,
            'ubicacion': ubicacion,
            'dispositivo': dispositivo,
          }),
        );

        //Navigator.of(context).pop();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imagen analizada exitosamente')),
          );
          
          // Opcional: Mostrar resultados de la detección
          final responseData = jsonDecode(response.body);
          print('Objetos detectados: ${responseData['detected_objects']}');
          print('Imagen anotada: ${responseData['anotated_image_path']}');
          
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorData['message'] ?? 'Error desconocido (${response.statusCode})'}')),
          );
        }
      } catch (e) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Cargando...' : _product['name']),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/products/edit',
              arguments: _product['id'],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del producto
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _product['image_path'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _product['image_path'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.shopping_basket, size: 50),
                      ),
                      SizedBox(height: 20),
                      // Información principal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${_product['price']}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Chip(
                            label: Text(_product['category'] ?? 'Sin categoría'),
                            backgroundColor: Colors.blue[50],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        _product['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Descripción
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _product['description'] ?? 'No hay descripción disponible',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 20),
                      // Código de barras
                      Text(
                        'Código de barras',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _product['barcode'] ?? 'N/A',
                        style: TextStyle(
                          fontFamily: 'Monospace',
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 30),
                      // Botones de acción
                      // Botones de acción
                      Row(
                        children: [
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.favorite_border),
                            onPressed: () {},
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(15),
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.dataset),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              ProductDatasetsScreen.routeName,
                              arguments: _product['id'], // Pasamos el product_id
                            ),
                            tooltip: 'Ver datasets',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(15),
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.model_training),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              ProductModelsScreen.routeName,
                              arguments: _product['id'], // Pasamos el product_id
                            ),
                            tooltip: 'Ver models',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(15),
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.add_alert),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/detections/new',
                              arguments: _product['id'], // Pasamos el product_id
                            ),
                            tooltip: 'Registrar detección',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(15),
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.camera_alt),
                            onPressed: _pickAndAnalyzeImage,
                            tooltip: 'Analizar imagen',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.all(15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}