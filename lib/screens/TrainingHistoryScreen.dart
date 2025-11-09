import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'TrainingRunningScreen.dart';
import 'TrainingStatusScreen.dart';
import '../theme/app_colors.dart';
import '../services/training_service.dart';

class TrainingHistoryScreen extends StatefulWidget {
  static const routeName = '/products/models/history';

  @override
  _TrainingHistoryScreenState createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  List<dynamic> trainingDetails = [];
  String? error;
  bool isLoading = true;
  late String? token;
  late int _modelId;
  String? warningMessage;
  String? successMessage;
  final TrainingService _trainingService = TrainingService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _modelId = ModalRoute.of(context)!.settings.arguments as int;
  }

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _trainingService.getModelDatasetsSimple(_modelId);

      setState(() {
        trainingDetails = data['data'] ?? [];

        warningMessage =
            trainingDetails.any(
                  (item) =>
                      item['estado']?.toString().toLowerCase() == 'validando',
                )
                ? 'Validando proceso en curso...'
                : null;

        successMessage =
            trainingDetails.any(
                  (item) =>
                      item['estado']?.toString().toLowerCase() == 'completado',
                )
                ? 'Modelo IA creado con éxito'
                : null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _completeTraining(int trainingId, String currentStep) async {
    if (currentStep.toLowerCase() == 'entrenando') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainingRunningScreen(modelId: trainingId),
        ),
      );
      return;
    }

    if (currentStep.toLowerCase() == 'look_entrenar') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainingStatusScreen(trainingId: trainingId),
        ),
      );
      return;
    }

    try {
      final responseData = await _trainingService.advanceStep2(
        trainingId,
        currentStep,
        'Entrenamiento completado desde la app móvil',
      );

      final newState = responseData['new_state'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paso actualizado a: $newState'),
          backgroundColor: AppColors.mintGreen,
        ),
      );

      setState(() {
        trainingDetails =
            trainingDetails.map((e) {
              if (e['id'] == trainingId) e['estado'] = newState;
              return e;
            }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.redAccent,
        ),
      );
    }
  }

  Future<void> _updateTrainingStatus(int trainingId) async {
    final TextEditingController estadoController = TextEditingController();

    // Opciones de estados posibles (ajusta según tu lógica del backend)
    final estados = [
      'pendiente',
      'certificar',
      'validando',
      'entrenando',
      'completado',
      'descargar',
      'ordenar',
      'configurar',
      'guardar',
    ];

    String? selectedEstado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar estado del entrenamiento'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nuevo estado',
                  border: OutlineInputBorder(),
                ),
                value: selectedEstado,
                items:
                    estados
                        .map(
                          (estado) => DropdownMenuItem(
                            value: estado,
                            child: Text(estado.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => selectedEstado = value),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedEstado == null) return;

                Navigator.pop(context);
                try {
                  final result = await _trainingService.updateTrainingStatus(
                    trainingId: trainingId,
                    estado: selectedEstado!,
                    observaciones:
                        'Estado actualizado manualmente desde app móvil',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Estado actualizado'),
                      backgroundColor: AppColors.mintGreen,
                    ),
                  );

                  // Actualizar la lista local
                  setState(() {
                    trainingDetails =
                        trainingDetails.map((e) {
                          if (e['id'] == trainingId)
                            e['estado'] = selectedEstado;
                          return e;
                        }).toList();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brownDark,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text('Historial de Entrenamientos'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.brownMedium),
              )
              : error != null
              ? _buildError()
              : trainingDetails.isEmpty
              ? Center(
                child: Text(
                  'No hay entrenamientos',
                  style: TextStyle(fontSize: 16, color: AppColors.brownDark),
                ),
              )
              : _buildTrainingList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $error', style: TextStyle(color: AppColors.redAccent)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brownMedium,
            ),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingList() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ), // 👈 espacio extra inferior
        child: Column(
          children: [
            if (warningMessage != null)
              _buildMessageContainer(
                warningMessage!,
                AppColors.gold,
                AppColors.brownDark,
                Icons.warning_amber_rounded,
              ),
            if (successMessage != null)
              _buildMessageContainer(
                successMessage!,
                AppColors.mintGreen,
                AppColors.brownDark,
                Icons.check_circle_rounded,
              ),
            ...trainingDetails
                .map((detail) => _buildTrainingCard(detail))
                .toList(),
            const SizedBox(height: 20),
            if (trainingDetails.isNotEmpty)
              _buildProgressTracker(trainingDetails.first),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContainer(
    String message,
    Color bgColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: bgColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(dynamic detail) {
    Color iconColor;
    IconData iconData;

    switch (detail['estado']) {
      case 'completado':
        iconColor = AppColors.brightGreen;
        iconData = Icons.check_circle;
        break;
      case 'fallido':
        iconColor = AppColors.redAccent;
        iconData = Icons.error;
        break;
      default:
        iconColor = AppColors.mintGreen;
        iconData = Icons.autorenew;
    }

    return Card(
      elevation: 4,
      shadowColor: AppColors.brownMedium.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(iconData, color: iconColor, size: 28),
        title: Text(
          "ID: ${detail['id']} - Estado: ${detail['estado']}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.brownDark,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildRow(
                  Icons.storage,
                  "Dataset",
                  detail['nombre_dataset'] ?? 'N/A',
                ),
                _buildRow(
                  Icons.description,
                  "Descripción",
                  detail['descripcion_dataset'] ?? 'N/A',
                ),
                _buildRow(
                  Icons.percent,
                  "Validación %",
                  detail['porcentaje_validacion'] != null
                      ? "${detail['porcentaje_validacion'].toStringAsFixed(2)}%"
                      : 'N/A',
                ),
                SizedBox(height: 12),
                if (detail['estado'] != 'completado' &&
                    detail['estado'] != 'cancelado' &&
                    detail['estado'] != 'fallido')
                  ElevatedButton.icon(
                    onPressed:
                        () => _completeTraining(detail['id'], detail['estado']),
                    icon: Icon(Icons.play_arrow),
                    label: Text('Avanzar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brownMedium,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (detail['estado'] == 'fallido') ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateTrainingStatus(detail['id']),
                    icon: const Icon(Icons.sync),
                    label: const Text('Cambiar estado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.brownDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.blueGray),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(fontSize: 16, color: AppColors.blackSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(Map<String, dynamic> trainingDetail) {
    final steps = {
      'pendiente': 'Pendiente',
      'certificar': 'Certificar',
      'descargar': 'Descargar imágenes',
      'validando': 'Validando dataset',
      'ordenar': 'Ordenar dataset',
      'etiquetar': 'Etiquetar',
      'configurar': 'Configurar file yaml',
      'entrenando': 'Iniciar entrenamiento',
      'look_entrenar': 'Verificar estatus',
      'guardar': 'Guardar modelo',
      'completado': 'Completado',
    };

    final stepIcons = {
      'pendiente': Icons.schedule,
      'certificar': Icons.verified,
      'descargar': Icons.download,
      'ordenar': Icons.format_list_bulleted,
      'etiquetar': Icons.label,
      'configurar': Icons.settings,
      'validando': Icons.warning_amber_rounded,
      'entrenando': Icons.autorenew,
      'look_entrenar': Icons.visibility,
      'guardar': Icons.save,
      'completado': Icons.check_circle,
    };

    final stepColors = {
      'pendiente': Colors.grey,
      'certificar': Colors.blue,
      'descargar': Colors.pink,
      'ordenar': Colors.purple,
      'etiquetar': Colors.teal,
      'configurar': Colors.brown,
      'validando': Colors.orange,
      'entrenando': Colors.blue,
      'look_entrenar': Colors.indigo,
      'guardar': Colors.green,
      'completado': Colors.green,
    };

    final stepKeys = steps.keys.toList();
    final currentStatus =
        trainingDetail['estado']?.toString().toLowerCase() ?? 'pendiente';
    final currentIndex = stepKeys.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso del Entrenamiento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.brownDark,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white,
            border: Border.all(color: AppColors.brightGreen, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.beigeLight,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children:
                stepKeys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stepKey = entry.value;
                  final stepDesc = steps[stepKey]!;

                  bool isCompleted = index < currentIndex;
                  bool isCurrent = index == currentIndex;

                  Color bgColor =
                      isCurrent
                          ? stepColors[stepKey]!.withOpacity(0.5)
                          : isCompleted
                          ? stepColors[stepKey]!.withOpacity(0.6)
                          : AppColors.white;

                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isCurrent || isCompleted
                                    ? stepColors[stepKey]
                                    : Colors.grey[300],
                          ),
                          child: Center(
                            child: Icon(
                              stepIcons[stepKey],
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            stepDesc.toUpperCase(),
                            style: TextStyle(
                              fontWeight:
                                  isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: AppColors.brownDark,
                            ),
                          ),
                        ),
                        if (isCurrent &&
                            stepKey != 'completado' &&
                            stepKey != 'validando')
                          ElevatedButton(
                            onPressed:
                                () => _completeTraining(
                                  trainingDetail['id'],
                                  stepKey,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brightGreen,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: TextStyle(fontSize: 12),
                            ),
                            child: Text('COMPLETAR PASO'),
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
}
