import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class TrainingLogScreen extends StatefulWidget {
  final int trainingId;

  const TrainingLogScreen({Key? key, required this.trainingId})
    : super(key: key);

  @override
  _TrainingLogScreenState createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  String? logContent;
  String? logPath;
  bool isLoading = true;
  String? errorMessage;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    await _fetchLogFile();
  }

  Future<void> _fetchLogFile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse(
      'http://127.0.0.1:5000/api/training/${widget.trainingId}/log-file',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final base64File = responseData['base64_file'] as String?;
        final decodedContent =
            base64File != null ? utf8.decode(base64.decode(base64File)) : null;

        setState(() {
          logContent = decodedContent;
          logPath = responseData['log_path'];
        });
      } else {
        setState(() {
          errorMessage =
              'Error al obtener el log. Código: ${response.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text(
          'Log de Entrenamiento',
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
              : errorMessage != null
              ? Center(
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: AppColors.redAccent, fontSize: 8),
                ),
              )
              : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    color: AppColors.brownDark.withOpacity(0.1),
                    child: Text(
                      logPath ?? 'Archivo de log',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        logContent ?? 'No hay contenido en el log.',
                        style: TextStyle(
                          fontSize: 6,
                          color: AppColors.brownMedium,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
