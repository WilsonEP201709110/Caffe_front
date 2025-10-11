import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingStatusScreen extends StatefulWidget {
  final int trainingId;

  const TrainingStatusScreen({Key? key, required this.trainingId})
    : super(key: key);

  @override
  _TrainingStatusScreenState createState() => _TrainingStatusScreenState();
}

class _TrainingStatusScreenState extends State<TrainingStatusScreen> {
  Map<String, dynamic>? trainingData;
  bool isLoading = false;
  String? errorMessage;
  String? token;

  @override
  void initState() {
    super.initState();
    print("Entró a mi componente");
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    _fetchTrainingStatus();
  }

  Future<void> _fetchTrainingStatus() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(
      'http://127.0.0.1:5000/api/training/${widget.trainingId}/advance-step2',
    );

    final body = jsonEncode({"current_step": "look_entrenar"});

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

      if (response.statusCode == 200) {
        if (responseData['status'] == 'error') {
          setState(() {
            errorMessage = 'Error en el entrenamiento. Revisa los logs.';
            trainingData = responseData;
          });
        } else {
          setState(() {
            trainingData = responseData;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error al consultar el estado del entrenamiento.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'running':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estado de Entrenamiento'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : trainingData == null
              ? Center(child: Text(errorMessage ?? 'No hay datos disponibles'))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Si hay error en status, mostramos mensaje arriba con icono de advertencia
                    if (trainingData!['status'] == 'error')
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Error en el entrenamiento. Revisa los logs.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Icon(
                      Icons.train,
                      size: 80,
                      color: _getStatusColor(trainingData!['status']),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Estado del entrenamiento del modelo ${widget.trainingId}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.info,
                      label: 'Job ID',
                      value: trainingData!['job_id']?.toString() ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.computer,
                      label: 'PID',
                      value: trainingData!['pid']?.toString() ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.timelapse,
                      label: 'Estado',
                      value: trainingData!['status'] ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.access_time,
                      label: 'Tiempo transcurrido',
                      value: trainingData!['elapsed_time_hms'] ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.bar_chart,
                      label: 'Progreso',
                      value:
                          trainingData!['progress_pct'] != null
                              ? '${trainingData!['progress_pct']} %'
                              : '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.timelapse_outlined,
                      label: 'Tiempo estimado restante',
                      value: trainingData!['estimated_left_hms'] ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.folder,
                      label: 'Ruta de logs',
                      value: trainingData!['log_path'] ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.code,
                      label: 'Epoch actual',
                      value: trainingData!['current_epoch']?.toString() ?? '-',
                    ),
                    _buildInfoCard(
                      icon: Icons.format_list_numbered,
                      label: 'Total epochs',
                      value: trainingData!['total_epochs']?.toString() ?? '-',
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchTrainingStatus,
                      icon: Icon(Icons.refresh),
                      label: Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    if (trainingData!['status'] == 'completed')
                      Text(
                        'Entrenamiento completado ✅',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    if (trainingData!['status'] == 'error')
                      Text(
                        'Entrenamiento fallido ❌',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
