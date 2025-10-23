import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/detection_service.dart';

class NewDetectionScreen extends StatefulWidget {
  static const routeName = '/detections/new';

  @override
  _NewDetectionScreenState createState() => _NewDetectionScreenState();
}

class _NewDetectionScreenState extends State<NewDetectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _productId;
  final _modelIdController = TextEditingController(text: '1');
  final _quantityController = TextEditingController(text: '1');
  final _imagePathController = TextEditingController();
  final _confidenceController = TextEditingController(text: '0.9');
  final _locationController = TextEditingController();
  final _deviceController = TextEditingController();
  final DetectionService _detectionService = DetectionService();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productId = ModalRoute.of(context)!.settings.arguments as int;
  }

  Future<void> _submitDetection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _detectionService.submitDetection(
        productId: _productId,
        modelId: int.parse(_modelIdController.text),
        quantity: int.parse(_quantityController.text),
        imagePath: _imagePathController.text,
        confidence: double.parse(_confidenceController.text),
        location: _locationController.text,
        device: _deviceController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detección registrada exitosamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar detección: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva Detección')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _modelIdController,
                decoration: InputDecoration(
                  labelText: 'ID del Modelo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el ID del modelo';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cantidad';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _imagePathController,
                decoration: InputDecoration(
                  labelText: 'Ruta de la imagen',
                  border: OutlineInputBorder(),
                  hintText: 'ej: uploads/detections/leche-1.jpg',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la ruta de la imagen';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confidenceController,
                decoration: InputDecoration(
                  labelText: 'Confianza (0-1)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el valor de confianza';
                  }
                  final conf = double.tryParse(value);
                  if (conf == null || conf < 0 || conf > 1) {
                    return 'Debe ser un número entre 0 y 1';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(),
                  hintText: 'ej: Pasillo 3, Estante 2',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la ubicación';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _deviceController,
                decoration: InputDecoration(
                  labelText: 'Dispositivo',
                  border: OutlineInputBorder(),
                  hintText: 'ej: Cámara IP 1',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el dispositivo';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDetection,
                child:
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Registrar Detección'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _modelIdController.dispose();
    _quantityController.dispose();
    _imagePathController.dispose();
    _confidenceController.dispose();
    _locationController.dispose();
    _deviceController.dispose();
    super.dispose();
  }
}
