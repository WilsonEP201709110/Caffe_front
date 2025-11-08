import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/dataset_service.dart';
import '../services/settings_service.dart';

class ProductDatasetsScreen extends StatefulWidget {
  static const routeName = '/products/datasets';

  @override
  _ProductDatasetsScreenState createState() => _ProductDatasetsScreenState();
}

class _ProductDatasetsScreenState extends State<ProductDatasetsScreen> {
  List<dynamic> _datasets = [];
  bool _isLoading = true;
  String? _error;
  late int _productId;
  int _minImagesRequired = 0;
  final DatasetService _datasetService = DatasetService();
  final SettingsService _settingsService = SettingsService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productId = ModalRoute.of(context)!.settings.arguments as int;
    _fetchMinImagesRequired().then((_) => _fetchDatasets());
  }

  Future<void> _fetchDatasets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _datasetService.fetchDatasets(_productId);
      setState(() {
        _datasets = data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDatasetDialog() async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.beigeLight,
            title: Text(
              'Crear Nuevo Dataset',
              style: TextStyle(color: AppColors.brownDark),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    nameController,
                    'Nombre del Dataset*',
                    'ej: dataset-leche-mayo',
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    pathController,
                    'Ruta del Dataset*',
                    'ej: /datasets/leche/mayo2023',
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    descriptionController,
                    'Descripción',
                    'ej: Imágenes de leche mayo 2023',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.brownDark),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brownDark,
                ),
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      pathController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nombre y Ruta son campos obligatorios'),
                      ),
                    );
                    return;
                  }

                  await _createDataset(
                    nameController.text,
                    pathController.text,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  'Crear Dataset',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _createDataset(
    String name,
    String path,
    String description,
  ) async {
    try {
      await _datasetService.createDataset(
        productId: _productId,
        name: name,
        path: path,
        description: description,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dataset creado exitosamente')));

      await _fetchDatasets(); // refrescar lista
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _fetchMinImagesRequired() async {
    try {
      final minImages = await _settingsService.getMinImagesRequired();
      setState(() {
        _minImagesRequired = minImages;
      });
    } catch (e) {
      print('Error al obtener configuración: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
        title: Text('Datasets de Producto'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchDatasets),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brownMedium,
        onPressed: _showAddDatasetDialog,
        child: Icon(Icons.add, color: AppColors.white),
        tooltip: 'Agregar nuevo dataset',
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.brownDark),
              )
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.redAccent),
                ),
              )
              : _datasets.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dataset, size: 60, color: AppColors.brownMedium),
                    SizedBox(height: 16),
                    Text(
                      'No hay datasets disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.blackSoft,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _showAddDatasetDialog,
                      child: Text(
                        'Crear primer dataset',
                        style: TextStyle(color: AppColors.brownDark),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _datasets.length,
                itemBuilder: (context, index) {
                  final dataset = _datasets[index];
                  final imageCount = dataset['image_count'] ?? 0;
                  final progreso =
                      (_minImagesRequired > 0)
                          ? (imageCount / _minImagesRequired).clamp(0.0, 1.0)
                          : 0.0;
                  final yaCumple = imageCount >= _minImagesRequired;

                  return Card(
                    color: AppColors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brownMedium.withOpacity(0.2),
                        child: Icon(Icons.dataset, color: AppColors.brownDark),
                      ),
                      title: Text(
                        dataset['name'] ?? 'Dataset sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brownDark,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            dataset['description'] ?? 'Sin descripción',
                            style: TextStyle(color: AppColors.blackSoft),
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: AppColors.beigeLight,
                            color: yaCumple ? Colors.green : Colors.orange,
                            minHeight: 8,
                          ),
                          SizedBox(height: 4),
                          Text(
                            yaCumple
                                ? 'Listo ($imageCount imágenes, mínimo $_minImagesRequired)'
                                : '${(progreso * 100).toStringAsFixed(0)}% completado (mínimo $_minImagesRequired)',
                            style: TextStyle(
                              fontSize: 12,
                              color: yaCumple ? Colors.green : Colors.orange,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text('$imageCount imágenes'),
                                backgroundColor: AppColors.beigeLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brownDark,
                                ),
                              ),
                              SizedBox(width: 2),
                              Chip(
                                label: Text(_formatStatus(dataset['status'])),
                                backgroundColor: _getStatusColor(
                                  dataset['status'],
                                ),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppColors.brownMedium,
                      ),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/datasets/images',
                            arguments: {
                              'datasetId': dataset['id'],
                              'datasetName': dataset['name'],
                            },
                          ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'en_proceso':
        return 'En Proceso';
      case 'completado':
        return 'Completado';
      case 'pendiente':
        return 'Pendiente';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_proceso':
        return Colors.orange;
      case 'completado':
        return Colors.green;
      case 'pendiente':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
