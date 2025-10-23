import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/model_service.dart';
import '../services/dataset_service.dart';

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
  final ModelService _modelService = ModelService();
  final DatasetService _datasetService = DatasetService();

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

    try {
      final data = await _modelService.fetchModels(_productId);
      setState(() {
        _models = data['models'] ?? [];
        _productName = data['product'];
        _isLoading = false;
      });
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

    try {
      final data = await _datasetService.fetchAllDatasets(_productId);
      setState(() {
        _datasets = data['data'] ?? [];
        _isLoadingDatasets = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingDatasets = false;
      });
    }
  }

  // -------- Estilo personalizado para Cards y Chips --------
  Color _statusColor(String status) {
    switch (status) {
      case 'activo':
        return AppColors.brightGreen;
      case 'inactivo':
        return AppColors.brownMedium;
      case 'entrenando':
        return AppColors.gold;
      case 'error':
        return AppColors.redAccent;
      default:
        return AppColors.blueGray;
    }
  }

  Future<void> _startTraining(int modelId, int datasetId) async {
    try {
      await _datasetService.startTraining(
        productId: _productId,
        datasetId: datasetId,
        baseModelId: modelId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entrenamiento iniciado exitosamente')),
      );

      await _fetchModels();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _showTrainingDialog(int modelId) async {
    _selectedModelId = modelId;
    _selectedDatasetId = null;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Entrenar Modelo'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selecciona un dataset para entrenar:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _isLoadingDatasets
                          ? Center(child: CircularProgressIndicator())
                          : _datasets.isEmpty
                          ? Text('No hay datasets disponibles')
                          : DropdownButtonFormField<int>(
                            value: _selectedDatasetId,
                            hint: Text('Selecciona un dataset'),
                            items:
                                _datasets.map((dataset) {
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
                    onPressed:
                        _selectedDatasetId == null
                            ? null
                            : () async {
                              await _startTraining(
                                modelId,
                                _selectedDatasetId!,
                              );
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
    final routePathController = TextEditingController();

    String? selectedFramework;
    String? selectedRouteType;
    String? selectedRouteFormat;

    final frameworks = ['PyTorch', 'TensorFlow', 'Keras', 'ONNX'];
    final routeTypes = ['inferencia', 'pesos'];
    final routeFormats = ['pt', 'h5', 'onnx'];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Crear Nuevo Modelo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    nameController,
                    'Nombre del Modelo*',
                    'ej: modelo-leche-v2',
                  ),
                  SizedBox(height: 16),
                  _buildTextField(versionController, 'Versión*', 'ej: 2.0'),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedFramework,
                    decoration: InputDecoration(
                      labelText: 'Framework*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: Text('ej: PyTorch, TensorFlow'),
                    items:
                        frameworks
                            .map(
                              (fw) =>
                                  DropdownMenuItem(value: fw, child: Text(fw)),
                            )
                            .toList(),
                    onChanged: (value) => selectedFramework = value,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Este campo es obligatorio'
                                : null,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Primera Ruta del Modelo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRouteType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Ruta*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: Text('ej: inferencia, pesos'),
                    items:
                        routeTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedRouteType = value,
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    routePathController,
                    'Ruta*',
                    'ej: /models/leche/v2.pt',
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRouteFormat,
                    decoration: InputDecoration(
                      labelText: 'Formato*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: Text('ej: pt, h5'),
                    items:
                        routeFormats
                            .map(
                              (fmt) => DropdownMenuItem(
                                value: fmt,
                                child: Text(fmt),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedRouteFormat = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      versionController.text.isEmpty ||
                      selectedFramework == null ||
                      selectedRouteType == null ||
                      routePathController.text.isEmpty ||
                      selectedRouteFormat == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Todos los campos son obligatorios'),
                      ),
                    );
                    return;
                  }

                  await _createModel(
                    nameController.text,
                    versionController.text,
                    selectedFramework!,
                    selectedRouteType!,
                    routePathController.text,
                    selectedRouteFormat!,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Crear Modelo'),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
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
    try {
      await _modelService.createModel(
        productId: _productId,
        name: name,
        version: version,
        framework: framework,
        routeType: routeType,
        routePath: routePath,
        routeFormat: routeFormat,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Modelo creado exitosamente')));

      await _fetchModels();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _showAddRouteDialog(int modelId) async {
    final pathController = TextEditingController();
    String? selectedRouteType;
    String? selectedRouteFormat;

    final routeTypes = ['inferencia', 'pesos'];
    final routeFormats = ['pt', 'h5', 'onnx'];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Agregar Ruta al Modelo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRouteType,
                    decoration: InputDecoration(
                      labelText: 'Tipo*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: Text('ej: inferencia, pesos'),
                    items:
                        routeTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedRouteType = value,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    pathController,
                    'Ruta*',
                    'ej: /models/leche/v2-weights.pt',
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRouteFormat,
                    decoration: InputDecoration(
                      labelText: 'Formato*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    hint: Text('ej: pt, h5'),
                    items:
                        routeFormats
                            .map(
                              (fmt) => DropdownMenuItem(
                                value: fmt,
                                child: Text(fmt),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedRouteFormat = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (pathController.text.isEmpty ||
                      selectedRouteType == null ||
                      selectedRouteFormat == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Todos los campos son obligatorios'),
                      ),
                    );
                    return;
                  }

                  await _addRouteToModel(
                    modelId,
                    selectedRouteType!,
                    pathController.text,
                    selectedRouteFormat!,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
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
    try {
      await _modelService.addRouteToModel(
        modelId: modelId,
        type: type,
        path: path,
        format: format,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ruta agregada exitosamente')));

      await _fetchModels();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _setModelActive(int modelId) async {
    try {
      await _modelService.setModelActive(modelId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Modelo activado exitosamente')));

      await _fetchModels();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
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
      'completado': 'Completado',
    };

    final currentStatus =
        trainingDetail['estado']?.toString().toLowerCase() ?? 'pendiente';
    final stepKeys = steps.keys.toList();
    final currentIndex = stepKeys.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso del Entrenamiento:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                stepKeys.asMap().entries.map((entry) {
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
                        bottom:
                            index < steps.length - 1
                                ? BorderSide(color: Colors.grey[300]!)
                                : BorderSide.none,
                      ),
                      color:
                          isCurrent
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
                            color:
                                isFailed
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
                            child:
                                isFailed
                                    ? Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                    : isCanceled
                                    ? Icon(
                                      Icons.block,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                    : isCompleted
                                    ? Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                    : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color:
                                            isCurrent
                                                ? Colors.white
                                                : Colors.black54,
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
                              fontWeight:
                                  isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isFailed
                                      ? Colors.red[800]
                                      : isCanceled
                                      ? Colors.grey[700]
                                      : Colors.black,
                            ),
                          ),
                        ),
                        if (isCurrent && !isFailed && !isCanceled)
                          ElevatedButton(
                            onPressed:
                                () => _advanceTrainingStep(
                                  trainingDetail['id'],
                                  stepKey,
                                ),
                            child: Text('COMPLETAR PASO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
    try {
      await _datasetService.advanceTrainingStep(
        trainingId: trainingId,
        currentStep: currentStep,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Paso completado exitosamente')));

      _fetchModels();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // -------- Construcción del Screen --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
        title: Text(
          _productName != null
              ? 'Modelos de $_productName'
              : 'Modelos de Producto',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.white),
            onPressed: () {
              _fetchModels();
              _fetchDatasets();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModelDialog,
        backgroundColor: AppColors.mintGreen,
        child: Icon(Icons.add, color: AppColors.white),
        tooltip: 'Agregar nuevo modelo',
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
                  style: TextStyle(color: AppColors.redAccent, fontSize: 16),
                ),
              )
              : _models.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.model_training,
                      size: 50,
                      color: AppColors.blueGray,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay modelos disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.brownDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _showAddModelDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.mintGreen,
                      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.brownMedium.withOpacity(0.3),
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.model_training,
                        color: _statusColor(model['status']),
                      ),
                      title: Text(
                        model['name'] ?? 'Modelo sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brownDark,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Versión: ${model['version']}',
                            style: TextStyle(color: AppColors.brownMedium),
                          ),
                          SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text(model['framework']),
                                backgroundColor: AppColors.beigeLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brownDark,
                                ),
                              ),
                              Chip(
                                label: Text(_formatStatus(model['status'])),
                                backgroundColor: _statusColor(model['status']),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rutas
                              Text(
                                'Rutas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brownDark,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              if (model['routes'] != null)
                                ...List<Widget>.from(
                                  (model['routes'] as List).map(
                                    (route) => ListTile(
                                      leading: Icon(
                                        Icons.alt_route,
                                        size: 22,
                                        color: Colors.deepPurpleAccent,
                                      ),
                                      title: Text(
                                        route['path'] ?? '',
                                        style: TextStyle(
                                          color: AppColors.brownDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${route['type'] ?? ''} (${route['format'] ?? ''})',
                                        style: TextStyle(
                                          color: AppColors.brownMedium,
                                        ),
                                      ),
                                      trailing:
                                          route['is_current'] == true
                                              ? Icon(
                                                Icons.check_circle,
                                                color: Colors.greenAccent,
                                              )
                                              : null,
                                    ),
                                  ),
                                ),

                              SizedBox(height: 24),

                              // Entrenamiento
                              Text(
                                'Entrenamiento:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brownDark,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed:
                                    model['has_training']
                                        ? null
                                        : () =>
                                            _showTrainingDialog(model['id']),
                                icon: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                label: Text('Entrenar con Dataset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrangeAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Botones finales
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed:
                                        model['status'] == 'inactivo' ||
                                                model['status'] == 'activo'
                                            ? () =>
                                                _showAddRouteDialog(model['id'])
                                            : null,
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.teal,
                                    ),
                                    label: Text('Agregar Ruta'),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed:
                                        model['status'] == 'inactivo'
                                            ? () => _setModelActive(model['id'])
                                            : null,
                                    icon: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    label: Text('Activar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 14,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/products/models/history',
                                        arguments: model['id'],
                                      );
                                    },
                                    icon: Icon(
                                      Icons.history,
                                      color: Colors.white,
                                    ),
                                    label: Text('Ver Entrenamiento'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
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
      case 'error':
        return 'Error';
      default:
        return status;
    }
  }
}
