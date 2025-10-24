import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  List<FileSystemEntity> localModels = [];
  final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalModels();
  }

  Future<void> _loadLocalModels() async {
    final dir = await _getModelsDir();
    setState(() {
      localModels = dir.listSync();
    });
  }

  Future<Directory> _getModelsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/models');

    if (!modelsDir.existsSync()) modelsDir.createSync();
    return modelsDir;
  }

  Future<void> _downloadModel(int modeloId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (localModels.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solo se permiten 10 modelos guardados")),
      );
      return;
    }

    final url = Uri.parse(
      "http://192.168.0.18:5000/api/models/get_model/$modeloId",
    );

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No estás autenticado")));
      return;
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dir = await _getModelsDir();
        final filePath = '${dir.path}/modelo_$modeloId.tflite';
        File(filePath).writeAsBytesSync(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Modelo $modeloId descargado correctamente")),
        );

        _loadLocalModels();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al descargar el modelo")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteModel(FileSystemEntity file) async {
    await file.delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Modelo eliminado")));
    _loadLocalModels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modelos guardados")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "ID del modelo",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final idText = _idController.text.trim();
                    if (idText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ingresa un ID válido")),
                      );
                      return;
                    }
                    final modeloId = int.tryParse(idText);
                    if (modeloId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("ID debe ser un número")),
                      );
                      return;
                    }
                    _downloadModel(modeloId);
                  },
                  child: const Text("Descargar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: localModels.length,
                itemBuilder: (context, index) {
                  final file = localModels[index];
                  return ListTile(
                    title: Text(file.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteModel(file),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
