import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingRunningScreen extends StatefulWidget {
  final int modelId;

  const TrainingRunningScreen({Key? key, required this.modelId})
    : super(key: key);

  @override
  _TrainingRunningScreenState createState() => _TrainingRunningScreenState();
}

class _TrainingRunningScreenState extends State<TrainingRunningScreen> {
  late String? token;
  bool isLoading = false;
  String? message;

  // Opciones de los parámetros
  final List<String> modelOptions = ['yolo11s', 'yolov8s'];
  final List<int> epochsOptions = [15, 20, 40, 60];
  final List<int> imgszOptions = [320, 480, 640, 800];
  final List<int> batchOptions = [8, 16, 32];
  final List<double> lrOptions = [0.001, 0.005, 0.01, 0.02];
  final List<String> deviceOptions = ['0', '1', 'cpu'];
  final List<String> projectOptions = ['training_runs', 'custom_project'];

  // Valores seleccionados
  String? selectedModel;
  int? selectedEpochs;
  int? selectedImgsz;
  int? selectedBatch;
  double? selectedLr;
  String? selectedDevice;
  String? selectedProject;

  @override
  void initState() {
    super.initState();
    _loadToken();
    // Valores por defecto
    selectedModel = modelOptions[0];
    selectedEpochs = epochsOptions[0];
    selectedImgsz = imgszOptions[2];
    selectedBatch = batchOptions[0];
    selectedLr = lrOptions[2];
    selectedDevice = deviceOptions[0];
    selectedProject = projectOptions[0];
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
  }

  Future<void> _startTraining() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    final url = Uri.parse(
      'http://127.0.0.1:5000/api/training/${widget.modelId}/advance-step2',
    );

    final body = jsonEncode({
      "current_step": "entrenando",
      "model": selectedModel,
      "epochs": selectedEpochs,
      "imgsz": selectedImgsz,
      "batch": selectedBatch,
      "lr": selectedLr,
      "device": selectedDevice,
      "project": selectedProject,
    });

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          message =
              responseData['warning'] ??
              'Entrenamiento iniciado correctamente!';
        });
      } else {
        setState(() {
          message = responseData['message'] ?? 'Error al iniciar entrenamiento';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items:
                  items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.toString()),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entrenamiento en Proceso')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.train, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'El entrenamiento del modelo ${widget.modelId} está en progreso...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            _buildDropdown<String>(
              label: 'Modelo',
              value: selectedModel,
              items: modelOptions,
              onChanged: (val) => setState(() => selectedModel = val),
            ),
            _buildDropdown<int>(
              label: 'Epochs',
              value: selectedEpochs,
              items: epochsOptions,
              onChanged: (val) => setState(() => selectedEpochs = val),
            ),
            _buildDropdown<int>(
              label: 'Img Size',
              value: selectedImgsz,
              items: imgszOptions,
              onChanged: (val) => setState(() => selectedImgsz = val),
            ),
            _buildDropdown<int>(
              label: 'Batch',
              value: selectedBatch,
              items: batchOptions,
              onChanged: (val) => setState(() => selectedBatch = val),
            ),
            _buildDropdown<double>(
              label: 'Learning Rate',
              value: selectedLr,
              items: lrOptions,
              onChanged: (val) => setState(() => selectedLr = val),
            ),
            _buildDropdown<String>(
              label: 'Device',
              value: selectedDevice,
              items: deviceOptions,
              onChanged: (val) => setState(() => selectedDevice = val),
            ),
            _buildDropdown<String>(
              label: 'Project',
              value: selectedProject,
              items: projectOptions,
              onChanged: (val) => setState(() => selectedProject = val),
            ),
            SizedBox(height: 24),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Iniciar Entrenamiento',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.grey[400],
              ),
              child: Text(
                'Volver',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color:
                      message!.toLowerCase().contains('error')
                          ? Colors.red
                          : Colors.green,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
