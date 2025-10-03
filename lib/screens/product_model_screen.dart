import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductModelsScreen extends StatefulWidget {
  static const routeName = '/products/models';

  @override
  _ProductModelsScreenState createState() => _ProductModelsScreenState();
}

class _ProductModelsScreenState extends State<ProductModelsScreen> {
  List<dynamic> _models = [];
  List<dynamic> _datasets = [];
  bool _isLoading = true;
  bool _isLoadingDatasets = false;
  String? _error;
  late int _productId;
  String? _productName;
  int? _selectedModelId;
  int? _selectedDatasetId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productId = ModalRoute.of(context)!.settings.arguments as int;
    _fetchModels();
    _fetchDatasets();
  }

  Future<void> _fetchModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/models/product/$_productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          _models = responseData['data']['models'] ?? [];
          _productName = responseData['data']['product'];
          _isLoading = false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Error al cargar modelos');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDatasets() async {
    setState(() {
      _isLoadingDatasets = true;
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
          _isLoadingDatasets = false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Error al cargar datasets');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingDatasets = false;
      });
    }
  }

  Future<void> _startTraining(int modelId, int datasetId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/training/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': _productId,
          'dataset_id': datasetId,
          'base_model_id': modelId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrenamiento iniciado exitosamente')),
        );
        await _fetchModels();
      } else {
        throw Exception(responseData['message'] ?? 'Error al iniciar entrenamiento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showTrainingDialog(int modelId) async {
    _selectedModelId = modelId;
    _selectedDatasetId = null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Entrenar Modelo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selecciona un dataset para entrenar:', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _isLoadingDatasets
                      ? Center(child: CircularProgressIndicator())
                      : _datasets.isEmpty
                          ? Text('No hay datasets disponibles')
                          : DropdownButtonFormField<int>(
                              value: _selectedDatasetId,
                              hint: Text('Selecciona un dataset'),
                              items: _datasets.map((dataset) {
                                return DropdownMenuItem<int>(
                                  value: dataset['id'],
                                  child: Text(dataset['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDatasetId = value;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                              ),
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
                onPressed: _selectedDatasetId == null
                    ? null
                    : () async {
                        await _startTraining(modelId, _selectedDatasetId!);
                        Navigator.pop(context);
                      },
                child: Text('Iniciar Entrenamiento'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddModelDialog() async {
    final nameController = TextEditingController();
    final versionController = TextEditingController();
    final frameworkController = TextEditingController();
    final routePathController = TextEditingController();
    final routeTypeController = TextEditingController();
    final routeFormatController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Nuevo Modelo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Modelo*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: modelo-leche-v2',
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
                controller: versionController,
                decoration: InputDecoration(
                  labelText: 'Versión*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: 2.0',
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
                controller: frameworkController,
                decoration: InputDecoration(
                  labelText: 'Framework*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: PyTorch, TensorFlow',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Primera Ruta del Modelo', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: routeTypeController,
                decoration: InputDecoration(
                  labelText: 'Tipo de Ruta*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: inferencia, pesos',
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: routePathController,
                decoration: InputDecoration(
                  labelText: 'Ruta*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: /models/leche/v2.pt',
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: routeFormatController,
                decoration: InputDecoration(
                  labelText: 'Formato*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: pt, h5',
                ),
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
              if (nameController.text.isEmpty || 
                  versionController.text.isEmpty || 
                  frameworkController.text.isEmpty ||
                  routeTypeController.text.isEmpty ||
                  routePathController.text.isEmpty ||
                  routeFormatController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Todos los campos son obligatorios')),
                );
                return;
              }

              await _createModel(
                nameController.text,
                versionController.text,
                frameworkController.text,
                routeTypeController.text,
                routePathController.text,
                routeFormatController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Crear Modelo'),
          ),
        ],
      ),
    );
  }

  Future<void> _createModel(
    String name, 
    String version, 
    String framework,
    String routeType,
    String routePath,
    String routeFormat,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/models'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': _productId,
          'name': name,
          'version': version,
          'framework': framework,
          'routes': [
            {
              'type': routeType,
              'path': routePath,
              'format': routeFormat
            }
          ]
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modelo creado exitosamente')),
        );
        await _fetchModels();
      } else {
        throw Exception(responseData['message'] ?? 'Error al crear modelo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddRouteDialog(int modelId) async {
    final pathController = TextEditingController();
    final typeController = TextEditingController();
    final formatController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Ruta al Modelo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Tipo*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: inferencia, pesos',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: 'Ruta*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: /models/leche/v2-weights.pt',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: formatController,
                decoration: InputDecoration(
                  labelText: 'Formato*',
                  border: OutlineInputBorder(),
                  hintText: 'ej: pt, h5',
                ),
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
              if (pathController.text.isEmpty || 
                  typeController.text.isEmpty || 
                  formatController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Todos los campos son obligatorios')),
                );
                return;
              }

              await _addRouteToModel(
                modelId,
                typeController.text,
                pathController.text,
                formatController.text,
              );
              Navigator.pop(context);
            },
            child: Text('Agregar Ruta'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRouteToModel(
    int modelId, 
    String type, 
    String path, 
    String format,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/models/$modelId/routes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'path': path,
          'format': format
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruta agregada exitosamente')),
        );
        await _fetchModels();
      } else {
        throw Exception(responseData['message'] ?? 'Error al agregar ruta');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _setModelActive(int modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:5000/api/models/$modelId/set-active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modelo activado exitosamente')),
        );
        await _fetchModels();
      } else {
        throw Exception(responseData['message'] ?? 'Error al activar modelo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

Future<void> _showModelTrainingDetails(int modelId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  List<dynamic> trainingDetails = [];
  String? error;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> loadData() async {
            try {
              final response = await http.get(
                Uri.parse('http://127.0.0.1:5000/api/training/model-datasets-simple?modelo_base_id=$modelId'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              final responseData = jsonDecode(response.body);

              if (response.statusCode == 200 && responseData['success']) {
                setState(() {
                  trainingDetails = responseData['data']['data'] ?? [];
                });
              } else {
                throw Exception(responseData['message'] ?? 'Error al cargar detalles');
              }
            } catch (e) {
              setState(() {
                error = e.toString();
              });
            }
          }

          Future<void> completeTraining(int trainingId, String currentStep) async {
            try {
              final response = await http.put(
                Uri.parse('http://127.0.0.1:5000/api/training/$trainingId/advance-step'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'current_step': currentStep,
                  'observations': 'Entrenamiento completado desde la app móvil'
                }),
              );

              final responseData = jsonDecode(response.body);

              if (response.statusCode == 200 && responseData['success']) {
                final newState = responseData['new_state'];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Paso actualizado a: $newState')),
                );

                setState(() {
                  trainingDetails = trainingDetails.map((e) {
                    if (e['id'] == trainingId) {
                      e['estado'] = newState;
                    }
                    return e;
                  }).toList();
                });
              } else {
                throw Exception(responseData['message'] ?? 'Error al avanzar paso');
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }

          if (trainingDetails.isEmpty && error == null) {
            loadData();
          }

          return AlertDialog(
            title: Text('Historial de Entrenamientos'),
            content: Container(
              width: double.maxFinite,
              child: error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: $error'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadData,
                          child: Text('Reintentar'),
                        ),
                      ],
                    )
                  : trainingDetails.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Dataset')),
                                  DataColumn(label: Text('Descripción')),
                                  DataColumn(label: Text('Validación %')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: trainingDetails.map((detail) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(detail['estado'])),
                                      DataCell(Text(detail['nombre_dataset'] ?? 'N/A')),
                                      DataCell(Text(detail['descripcion_dataset'] ?? 'N/A')),
                                      DataCell(Text(detail['porcentaje_validacion']?.toStringAsFixed(2) ?? 'N/A')),
                                      DataCell(
                                        detail['estado'] != 'completado' && detail['estado'] != 'cancelado' && detail['estado'] != 'fallido'
                                            ? ElevatedButton(
                                                onPressed: () => completeTraining(detail['id'], detail['estado']),
                                                child: Text('Avanzar'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                ),
                                              )
                                            : Text('No actions'),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildProgressTracker(trainingDetails.first),
                          ],
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );
    },
  );
}



Widget _buildProgressTracker(Map<String, dynamic> trainingDetail) {
    final steps = {
      'pendiente': 'Pendiente',
      'certificar': 'certificar',
      'descargar': 'Descargar imagenes',
      'ordenar': 'Ordenar dataset',
      'etiquetar': 'Etiquetar',
      'configurar': 'Configurar file yaml',
      'entrenando': 'Iniciar entrenamiento',
      'look_entrenar': 'Verificar estatus',
      'guardar': 'Guardar modelo',
      'completado': 'Completado'
    };

    final currentStatus = trainingDetail['estado']?.toString().toLowerCase() ?? 'pendiente';
    final stepKeys = steps.keys.toList();
    final currentIndex = stepKeys.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progreso del Entrenamiento:', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        )),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: stepKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final stepKey = entry.value;
              final stepDescription = steps[stepKey]!;
              final isCompleted = index < currentIndex;
              final isCurrent = index == currentIndex;
              final isFailed = currentStatus == 'fallido';
              final isCanceled = currentStatus == 'cancelado';

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: index < steps.length - 1 
                        ? BorderSide(color: Colors.grey[300]!) 
                        : BorderSide.none,
                  ),
                  color: isCurrent 
                      ? Colors.blue[50]
                      : isFailed
                          ? Colors.red[50]
                          : isCanceled
                              ? Colors.grey[200]
                              : Colors.transparent,
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFailed
                            ? Colors.red
                            : isCanceled
                                ? Colors.grey
                                : isCompleted
                                    ? Colors.green
                                    : isCurrent
                                        ? Colors.blue
                                        : Colors.grey[300],
                      ),
                      child: Center(
                        child: isFailed
                            ? Icon(Icons.close, size: 14, color: Colors.white)
                            : isCanceled
                                ? Icon(Icons.block, size: 14, color: Colors.white)
                                : isCompleted
                                    ? Icon(Icons.check, size: 14, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isCurrent ? Colors.white : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        stepDescription.toUpperCase(),
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isFailed
                              ? Colors.red[800]
                              : isCanceled
                                  ? Colors.grey[700]
                                  : Colors.black,
                        ),
                      ),
                    ),
                    if (isCurrent && !isFailed && !isCanceled)
                      ElevatedButton(
                        onPressed: () => _advanceTrainingStep(trainingDetail['id'], stepKey),
                        child: Text('COMPLETAR PASO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Future<void> _advanceTrainingStep(int trainingId, String currentStep) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:5000/api/training/$trainingId/advance-step2'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_step': currentStep,
          'observations': 'Iniciando fase de entrenamiento'
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paso completado exitosamente')),
        );
        _fetchModels();
      } else {
        throw Exception(responseData['message'] ?? 'Error al avanzar paso');
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
        title: Text(_productName != null ? 'Modelos de $_productName' : 'Modelos de Producto'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _fetchModels();
              _fetchDatasets();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModelDialog,
        child: Icon(Icons.add),
        tooltip: 'Agregar nuevo modelo',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _models.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.model_training, size: 50, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No hay modelos disponibles'),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: _showAddModelDialog,
                            child: Text('Crear primer modelo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _models.length,
                      itemBuilder: (context, index) {
                        final model = _models[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: Icon(Icons.model_training, color: _getStatusColor(model['status'])),
                            title: Text(
                              model['name'] ?? 'Modelo sin nombre',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Versión: ${model['version']}'),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(model['framework']),
                                      backgroundColor: Colors.grey[200],
                                      labelStyle: TextStyle(fontSize: 12),
                                    ),
                                    SizedBox(width: 8),
                                    Chip(
                                      label: Text(_formatStatus(model['status'])),
                                      backgroundColor: _getStatusColor(model['status']),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rutas:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...(model['routes'] as List).map((route) => ListTile(
                                      leading: Icon(Icons.route, size: 20),
                                      title: Text(route['path']),
                                      subtitle: Text('${route['type']} (${route['format']})'),
                                      trailing: route['is_current'] 
                                          ? Icon(Icons.check_circle, color: Colors.green)
                                          : null,
                                    )).toList(),
                                    SizedBox(height: 16),
                                    Text('Entrenamiento:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _showTrainingDialog(model['id']),
                                      child: Text('Entrenar con Dataset'),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showAddRouteDialog(model['id']),
                                          child: Text('Agregar Ruta'),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: model['status'] != 'activo' 
                                              ? () => _setModelActive(model['id'])
                                              : null,
                                          child: Text('Activar'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.green,
                                            disabledBackgroundColor: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _showModelTrainingDetails(model['id']),
                                child: Text('Ver Entrenamientos'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'entrenando':
        return 'Entrenando';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'activo':
        return Colors.green;
      case 'inactivo':
        return Colors.grey;
      case 'entrenando':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

String _formatTrainingStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pendiente': return 'Pendiente';
    case 'procesando': return 'Procesando';
    case 'completado': return 'Completado';
    case 'fallido': return 'Fallido';
    case 'cancelado': return 'Cancelado';
    case 'validando': return 'Validando';
    case 'ordenar': return 'Ordenando';
    case 'entrenando': return 'Entrenando';
    case 'guardar': return 'Guardando';
    default: return status;
  }
  }

  Color _getTrainingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.blue;
      case 'procesando':
        return Colors.orange;
      case 'completado':
        return Colors.green;
      case 'fallido':
        return Colors.red;
      case 'cancelado':
        return Colors.grey;
      default:
        return Colors.grey[300]!;
    }
  }
}