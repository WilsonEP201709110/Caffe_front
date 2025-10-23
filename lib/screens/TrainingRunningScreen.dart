import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/training_service.dart';

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

  final List<String> modelOptions = ['yolo11s', 'yolo11m', 'yolov8s'];
  final List<int> epochsOptions = [15, 20, 40, 60, 80, 100];
  final List<int> imgszOptions = [320, 480, 640, 800];
  final List<int> batchOptions = [8, 16, 32];
  final List<double> lrOptions = [0.001, 0.005, 0.01, 0.02];
  final List<String> deviceOptions = ['0', '1', 'cpu'];
  final List<String> projectOptions = ['training_runs', 'custom_project'];

  String? selectedModel;
  int? selectedEpochs;
  int? selectedImgsz;
  int? selectedBatch;
  double? selectedLr;
  String? selectedDevice;
  String? selectedProject;

  final TrainingService _trainingService = TrainingService();

  @override
  void initState() {
    super.initState();
    _loadToken();
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

    final payload = {
      "current_step": "entrenando",
      "model": selectedModel,
      "epochs": selectedEpochs,
      "imgsz": selectedImgsz,
      "batch": selectedBatch,
      "lr": selectedLr,
      "device": selectedDevice,
      "project": selectedProject,
    };

    try {
      final responseData = await _trainingService.advanceStep(
        widget.modelId,
        payload,
        token ?? '',
      );

      if (responseData['success'] == true) {
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
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: AppColors.brownDark),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.beigeLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brownMedium),
              ),
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                underline: SizedBox(),
                items:
                    items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.toString(),
                              style: TextStyle(color: AppColors.brownDark),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
        title: Text(
          'Entrenamiento en Proceso',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.brownMedium.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(20),
              child: Icon(Icons.train, size: 80, color: AppColors.brownDark),
            ),
            SizedBox(height: 20),
            Text(
              'El entrenamiento del modelo ${widget.modelId} está en progreso...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.brownDark,
                fontWeight: FontWeight.w500,
              ),
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
                ? CircularProgressIndicator(color: AppColors.brownDark)
                : ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownDark,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
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
                backgroundColor: AppColors.blueGray,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text('Volver', style: TextStyle(fontSize: 16)),
            ),
            if (message != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      message!.toLowerCase().contains('error')
                          ? AppColors.redAccent.withOpacity(0.2)
                          : AppColors.mintGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        message!.toLowerCase().contains('error')
                            ? AppColors.redAccent
                            : AppColors.brightGreen,
                  ),
                ),
                child: Text(
                  message!,
                  style: TextStyle(
                    color:
                        message!.toLowerCase().contains('error')
                            ? AppColors.redAccent
                            : AppColors.brightGreen,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
