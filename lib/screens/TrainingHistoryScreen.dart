import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'TrainingRunningScreen.dart';
import 'TrainingStatusScreen.dart';

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
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:5000/api/training/model-datasets-simple?modelo_base_id=${_modelId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          trainingDetails = responseData['data']['data'] ?? [];
          String? warning;
          String? success;
          // Revisa si algún entrenamiento está en 'validando'
          for (var item in trainingDetails) {
            if (item['estado']?.toString().toLowerCase() == 'validando') {
              warning = 'Validando proceso en curso...';
              break; // Si encuentras uno, ya no necesitas seguir
            }

            if (item['estado']?.toString().toLowerCase() == 'completado') {
              success = 'Modelo IA creado...';
              break; // Si encuentras uno, ya no necesitas seguir
            }
          }

          setState(() {
            trainingDetails = trainingDetails;
            warningMessage = warning; // null si no hay ninguno en validando
            successMessage = success;
          });
        });
      } else {
        throw Exception(responseData['message'] ?? 'Error al cargar detalles');
      }
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
    // 🚀 Si el paso actual es 'entrenando', navegar directamente
    if (currentStep.toLowerCase() == 'entrenando') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainingRunningScreen(modelId: trainingId),
        ),
      );
      return; // Salir de la función, no hacer la llamada PUT
    }

    if (currentStep.toLowerCase() == 'look_entrenar') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrainingStatusScreen(trainingId: trainingId),
        ),
      );
      return; // Salir de la función, no hacer la llamada PUT
    }

    try {
      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:5000/api/training/$trainingId/advance-step2',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_step': currentStep,
          'observations': 'Entrenamiento completado desde la app móvil',
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final newState = responseData['new_state'];

        // Mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paso actualizado a: $newState')),
        );

        setState(() {
          trainingDetails =
              trainingDetails.map((e) {
                if (e['id'] == trainingId) e['estado'] = newState;
                return e;
              }).toList();
        });

        // 🚀 Si el nuevo estado es 'entrenando', ir al nuevo screen
        /*if (newState.toLowerCase() == 'entrenando') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingRunningScreen(modelId: _modelId),
            ),
          );
        }*/

        // 🚀 Si el nuevo estado es 'look_entrenar', ir al nuevo screen
        /*if (newState.toLowerCase() == 'look_entrenar') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingStatusScreen(trainingId: _modelId),
            ),
          );
        }*/

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paso actualizado a: $newState')),
        );

        setState(() {
          trainingDetails =
              trainingDetails.map((e) {
                if (e['id'] == trainingId) e['estado'] = newState;
                return e;
              }).toList();
        });
      } else {
        throw Exception(responseData['message'] ?? 'Error al avanzar paso');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial de Entrenamientos')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $error'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : trainingDetails.isEmpty
              ? Center(child: Text('No hay entrenamientos'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...trainingDetails.map((detail) {
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          leading: Icon(
                            detail['estado'] == 'completado'
                                ? Icons.check_circle
                                : detail['estado'] == 'fallido'
                                ? Icons.error
                                : Icons.autorenew,
                            color:
                                detail['estado'] == 'completado'
                                    ? Colors.green
                                    : detail['estado'] == 'fallido'
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                          title: Text(
                            "ID: ${detail['id']} - Estado: ${detail['estado']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
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
                                  SizedBox(height: 8),
                                  detail['estado'] != 'completado' &&
                                          detail['estado'] != 'cancelado' &&
                                          detail['estado'] != 'fallido'
                                      ? ElevatedButton.icon(
                                        onPressed:
                                            () => _completeTraining(
                                              detail['id'],
                                              detail['estado'],
                                            ),
                                        icon: Icon(Icons.play_arrow),
                                        label: Text('Avanzar'),
                                      )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Aquí mostramos el progress tracker del primer elemento
                    SizedBox(height: 20),
                    if (trainingDetails.isNotEmpty)
                      _buildProgressTracker(trainingDetails.first),
                  ],
                ),
              ),
    );
  }

  // Función helper para mostrar una fila con icono y texto
  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          SizedBox(width: 8),
          Expanded(
            child: Text("$label: $value", style: TextStyle(fontSize: 16)),
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
      'descargar': Colors.orange,
      'ordenar': Colors.purple,
      'etiquetar': Colors.teal,
      'configurar': Colors.brown,
      'validando': Colors.orange,
      'entrenando': Colors.blue,
      'look_entrenar': Colors.indigo,
      'guardar': Colors.green,
      'completado': Colors.green,
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
        SizedBox(height: 8),

        // Cuadro de advertencia
        if (warningMessage != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.yellow[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warningMessage!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (successMessage != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.blue[800]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    successMessage!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                  final isValidando = currentStatus == 'validando';
                  final isCompletedFinal = currentStatus == 'completado';

                  Color bgColor = Colors.transparent;
                  Color textColor = Colors.black;
                  Widget stepIcon = Icon(
                    stepIcons[stepKey],
                    size: 16,
                    color: stepColors[stepKey],
                  );

                  if (isFailed) {
                    bgColor = Colors.red[50]!;
                    textColor = Colors.red[800]!;
                    stepIcon = Icon(Icons.close, size: 16, color: Colors.red);
                  } else if (isCanceled) {
                    bgColor = Colors.grey[200]!;
                    textColor = Colors.grey[700]!;
                    stepIcon = Icon(Icons.block, size: 16, color: Colors.grey);
                  } else if (isCompleted) {
                    stepIcon = Icon(Icons.check, size: 16, color: Colors.green);
                  } else if (isCurrent) {
                    bgColor =
                        isValidando ? Colors.yellow[100]! : Colors.blue[50]!;
                    textColor =
                        isValidando ? Colors.orange[900]! : Colors.black;
                    stepIcon =
                        isValidando
                            ? Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: Colors.orange,
                            )
                            : Icon(
                              stepIcons[stepKey],
                              size: 16,
                              color: stepColors[stepKey],
                            );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            index < steps.length - 1
                                ? BorderSide(color: Colors.grey[300]!)
                                : BorderSide.none,
                      ),
                      color: bgColor,
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
                                isCurrent
                                    ? (isValidando
                                        ? Colors.orange
                                        : Colors.blue)
                                    : isCompleted
                                    ? Colors.green
                                    : Colors.grey[300],
                          ),
                          child: Center(child: stepIcon),
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
                              color: textColor,
                            ),
                          ),
                        ),
                        if (isCurrent &&
                            !isFailed &&
                            !isCanceled &&
                            !isValidando &&
                            !isCompletedFinal)
                          ElevatedButton(
                            onPressed:
                                () => _completeTraining(
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
}
