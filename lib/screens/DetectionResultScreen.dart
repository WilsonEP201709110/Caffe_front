import 'package:flutter/material.dart';

class DetectionResultScreen extends StatelessWidget {
  final int deteccionId;
  final String imagenPath;
  final int detallesCount;

  const DetectionResultScreen({
    Key? key,
    required this.deteccionId,
    required this.imagenPath,
    required this.detallesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resultados de la Detección')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Imagen anotada
            imagenPath.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(imagenPath, fit: BoxFit.cover),
                )
                : Icon(
                  Icons.image_not_supported,
                  size: 150,
                  color: Colors.grey,
                ),

            SizedBox(height: 20),

            // Información de la detección
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.confirmation_number, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'ID de Detección: $deteccionId',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.green),
                        SizedBox(width: 10),
                        Text(
                          'Cantidad de Objetos Detectados: $detallesCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
