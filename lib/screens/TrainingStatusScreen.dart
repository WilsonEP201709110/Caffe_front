import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'TrainingLogScreen.dart';
import '../services/training_service.dart';

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
  final TrainingService _trainingService = TrainingService();

  @override
  void initState() {
    super.initState();
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

    try {
      final trainingService = TrainingService();
      final response = await trainingService.fetchTrainingStatus(
        widget.trainingId,
      );

      final statusCode = response['statusCode'];
      final responseData = response['body'];

      if (statusCode == 200) {
        setState(() {
          trainingData = responseData;
          if (responseData['status'] == 'error') {
            errorMessage = 'Error en el entrenamiento. Revisa los logs.';
          }
        });
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
    Color? iconColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  iconColor?.withOpacity(0.2) ?? Colors.grey.shade200,
              child: Icon(icon, color: iconColor ?? Colors.blue, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brownDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.brownMedium,
                      fontSize: 15,
                    ),
                  ),
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
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text(
          'Estado de Entrenamiento',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.brownDark),
              )
              : trainingData == null
              ? Center(
                child: Text(
                  errorMessage ?? 'No hay datos disponibles',
                  style: TextStyle(color: AppColors.redAccent, fontSize: 16),
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (trainingData!['status'] == 'error')
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Error en el entrenamiento. Revisa los logs.',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.brownMedium.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        Icons.train,
                        size: 80,
                        color: _getStatusColor(trainingData!['status']),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Estado del entrenamiento del modelo ${widget.trainingId}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.info,
                      label: 'Job ID',
                      value: trainingData!['job_id']?.toString() ?? '-',
                      iconColor: Colors.teal,
                    ),
                    _buildInfoCard(
                      icon: Icons.computer,
                      label: 'PID',
                      value: trainingData!['pid']?.toString() ?? '-',
                      iconColor: Colors.purple,
                    ),
                    _buildInfoCard(
                      icon: Icons.timelapse,
                      label: 'Estado',
                      value: trainingData!['status'] ?? '-',
                      iconColor: _getStatusColor(trainingData!['status']),
                    ),
                    _buildInfoCard(
                      icon: Icons.access_time,
                      label: 'Tiempo transcurrido',
                      value: trainingData!['elapsed_time_hms'] ?? '-',
                      iconColor: Colors.orange,
                    ),
                    _buildInfoCard(
                      icon: Icons.bar_chart,
                      label: 'Progreso',
                      value:
                          trainingData!['progress_pct'] != null
                              ? '${trainingData!['progress_pct']} %'
                              : '-',
                      iconColor: Colors.blue,
                    ),
                    _buildInfoCard(
                      icon: Icons.timelapse_outlined,
                      label: 'Tiempo estimado restante',
                      value: trainingData!['estimated_left_hms'] ?? '-',
                      iconColor: Colors.indigo,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => TrainingLogScreen(
                                  trainingId: widget.trainingId,
                                ),
                          ),
                        );
                      },
                      child: _buildInfoCard(
                        icon: Icons.folder,
                        label: 'Ruta de logs',
                        value: trainingData!['log_path'] ?? '-',
                        iconColor: AppColors.brownDark,
                      ),
                    ),
                    _buildInfoCard(
                      icon: Icons.code,
                      label: 'Epoch actual',
                      value: trainingData!['current_epoch']?.toString() ?? '-',
                      iconColor: Colors.green,
                    ),
                    _buildInfoCard(
                      icon: Icons.format_list_numbered,
                      label: 'Total epochs',
                      value: trainingData!['total_epochs']?.toString() ?? '-',
                      iconColor: Colors.green,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchTrainingStatus,
                      icon: Icon(Icons.refresh),
                      label: Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brownDark,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
