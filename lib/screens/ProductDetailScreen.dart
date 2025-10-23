import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import 'DetectionResultScreen.dart';
import 'product_datasets_screen.dart';
import 'product_model_screen.dart';
import '../services/product_service.dart';
import '../services/training_service.dart';
import '../utils/image_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  static const routeName = '/products/detail';

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Map<String, dynamic> _product;
  bool _isLoading = true;
  String? _error;
  final ProductService _productService = ProductService();
  final TrainingService _trainingService = TrainingService();

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

    try {
      final productData = await _productService.fetchProduct(productId);
      setState(() {
        _product = productData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
    final picker = ImagePicker();

    // Mostrar diálogo para elegir fuente
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Selecciona la fuente de la imagen"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: Text("Cámara"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: Text("Galería"),
              ),
            ],
          ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    // Comprimir imagen
    final compressedBytes = await ImageUtils.compressImage(
      pickedFile,
      quality: 70,
      maxWidth: 1080,
    );

    if (_product == null || _product['id'] == null) return;
    final productoId = _product['id'];
    final dispositivo = 'App1';

    try {
      final responseData = await _trainingService.detectAndSaveImage(
        imageBytes: compressedBytes,
        productoId: productoId,
        dispositivo: dispositivo,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagen analizada y guardada exitosamente')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => DetectionResultScreen(
                deteccionId: responseData['deteccion_id'],
                imagenPath: responseData['imagen_path'],
                detallesCount: responseData['detalles_count'],
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
        title: Text(_isLoading ? 'Cargando...' : _product['name']),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del producto
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            _product['image_path'] != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _product['image_path'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Icon(Icons.shopping_basket, size: 50),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Nombre y categoría
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label, color: AppColors.brownMedium),
                        SizedBox(width: 8),
                        Text(
                          _product['name'] ?? '',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brownDark,
                          ),
                        ),
                        SizedBox(width: 16),
                        Chip(
                          label: Text(
                            _product['category'] ?? 'Sin categoría',
                            style: TextStyle(color: AppColors.white),
                          ),
                          backgroundColor: AppColors.brownMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Información con iconos
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoRow(
                              Icons.description,
                              'Descripción',
                              _product['description'] ?? 'N/A',
                            ),
                            Divider(),
                            _infoRow(
                              Icons.qr_code,
                              'Código de barras',
                              _product['barcode'] ?? 'N/A',
                            ),
                            Divider(),
                            _infoRow(
                              Icons.dataset,
                              'Datasets',
                              '${_product['datasets_count'] ?? 0}',
                            ),
                            Divider(),
                            _infoRow(
                              Icons.analytics,
                              'Detecciones',
                              '${_product['detections_count'] ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Grid de acciones
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount;

                        if (constraints.maxWidth >= 500) {
                          crossAxisCount = 5; // pantallas grandes
                        } else if (constraints.maxWidth >= 380) {
                          crossAxisCount = 4; // pantallas medianas
                        } else {
                          crossAxisCount = 3; // pantallas pequeñas
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _actionButton(Icons.dataset, 'Datasets', () {
                              Navigator.pushNamed(
                                context,
                                ProductDatasetsScreen.routeName,
                                arguments: _product['id'],
                              );
                            }),
                            _actionButton(Icons.model_training, 'Models', () {
                              Navigator.pushNamed(
                                context,
                                ProductModelsScreen.routeName,
                                arguments: _product['id'],
                              );
                            }),
                            _actionButton(
                              Icons.camera_alt,
                              'Analizar',
                              _pickAndAnalyzeImage,
                            ),
                            _actionButton(
                              Icons.favorite_border,
                              'Favorito',
                              () {},
                            ),
                            _actionButton(Icons.edit, 'Editar', () {}),
                            _actionButton(Icons.delete, 'Eliminar', () {}),
                            _actionButton(Icons.share, 'Compartir', () {}),
                            _actionButton(Icons.history, 'Historial', () {}),
                            _actionButton(Icons.bar_chart, 'Reporte', () {}),
                            _actionButton(
                              Icons.info_outline,
                              'Detalles',
                              () {},
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brownMedium),
        SizedBox(width: 10),
        Text(
          '$title: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.brownDark,
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: AppColors.blackSoft)),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Ink(
          decoration: ShapeDecoration(
            color: AppColors.brownMedium.withOpacity(0.1),
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon, color: AppColors.brownDark),
            onPressed: onTap,
            iconSize: 28,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.brownDark),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
