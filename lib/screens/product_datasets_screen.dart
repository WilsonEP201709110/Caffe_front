import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productId = ModalRoute.of(context)!.settings.arguments as int;
    _fetchDatasets();
  }

  Future<void> _fetchDatasets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/training/datasets?product_id=$_productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          _datasets = responseData['data']['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Error al cargar datasets');
      }
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
      builder: (context) => AlertDialog(
        title: Text('Crear Nuevo Dataset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Dataset*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: dataset-leche-mayo',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: 'Ruta del Dataset*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: /datasets/leche/mayo2023',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  hintText: 'ej: Imágenes de leche mayo 2023',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || pathController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nombre y Ruta son campos obligatorios')),
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
            child: Text('Crear Dataset'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDataset(String name, String path, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/training/datasets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': _productId,
          'name': name,
          'path': path,
          'description': description,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dataset creado exitosamente')),
        );
        await _fetchDatasets(); // Refrescar la lista
      } else {
        throw Exception(responseData['message'] ?? 'Error al crear dataset');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datasets de Producto'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchDatasets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDatasetDialog,
        child: Icon(Icons.add),
        tooltip: 'Agregar nuevo dataset',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _datasets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.dataset, size: 50, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay datasets disponibles'),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: _showAddDatasetDialog,
                            child: Text('Crear primer dataset'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _datasets.length,
                      itemBuilder: (context, index) {
                        final dataset = _datasets[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Icon(Icons.dataset, color: Colors.blue),
                            title: Text(
                              dataset['name'] ?? 'Dataset sin nombre',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dataset['description'] ?? 'Sin descripción'),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('${dataset['image_count'] ?? 0} imágenes'),
                                      backgroundColor: Colors.grey[200],
                                      labelStyle: TextStyle(fontSize: 12),
                                    ),
                                    SizedBox(width: 8),
                                    Chip(
                                      label: Text(_formatStatus(dataset['status'])),
                                      backgroundColor: _getStatusColor(dataset['status']),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(
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