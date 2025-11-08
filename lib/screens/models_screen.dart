import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/model_service.dart';
import '../theme/app_colors.dart';

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> models = [];
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchUserModels();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favString = prefs.getString('favorite_models');
    if (favString != null) {
      final List decoded = jsonDecode(favString);
      setState(() => favorites = decoded.cast<Map<String, dynamic>>());
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_models', jsonEncode(favorites));
  }

  Future<void> _fetchUserModels({String? productName}) async {
    setState(() => isLoading = true);
    try {
      final modelService = ModelService();
      final fetched = await modelService.fetchUserModels(
        productName: productName,
      );
      setState(() => models = fetched);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("💥 Error al obtener modelos: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleFavorite(Map<String, dynamic> model) async {
    setState(() {
      final exists = favorites.any((fav) => fav['id'] == model['id']);
      if (exists) {
        favorites.removeWhere((fav) => fav['id'] == model['id']);
      } else {
        favorites.add({
          'id': model['id'],
          'nombre': model['nombre'],
          'producto': model['producto'],
          'imagen': model['imagen'],
          'version': model['version'],
          'fecha_entrenamiento': model['fecha_entrenamiento'],
          'ruta': model['ruta'],
        });
      }
    });
    await _saveFavorites();
  }

  bool _isFavorite(Map<String, dynamic> model) {
    return favorites.any((fav) => fav['id'] == model['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: const Text("Modelos de Usuario"),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Campo de búsqueda
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      labelText: "Buscar por nombre de producto",
                      labelStyle: TextStyle(color: AppColors.brownDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.brownDark),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _fetchUserModels(
                      productName: _searchController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    "Buscar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ⭐ Favoritos con collapse
            if (favorites.isNotEmpty) ...[
              Text(
                "⭐ Favoritos (${favorites.length})",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brownDark,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final fav = favorites[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              fav['imagen'] != null && fav['imagen'].isNotEmpty
                                  ? Image.network(
                                    fav['imagen'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
                                  )
                                  : const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                        ),
                        title: Text(
                          "${index + 1}. ${fav['nombre']}",
                          style: TextStyle(
                            color: AppColors.brownDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          fav['producto'],
                          style: TextStyle(
                            color: AppColors.brownDark.withOpacity(0.8),
                          ),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Versión: ${fav['version']}",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  "Fecha: ${fav['fecha_entrenamiento']}",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  "Ruta: ${fav['ruta']}",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                setState(() => favorites.removeAt(index));
                                await _saveFavorites();
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                "Eliminar",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 📦 Sección de modelos
            Text(
              "📦 Modelos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              flex: 2,
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.brown),
                      )
                      : models.isEmpty
                      ? const Center(
                        child: Text(
                          "No hay modelos disponibles.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                      : ListView.builder(
                        itemCount: models.length,
                        itemBuilder: (context, index) {
                          final model = models[index];
                          final isFav = _isFavorite(model);
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    model['imagen'] != null &&
                                            model['imagen'].isNotEmpty
                                        ? Image.network(
                                          model['imagen'],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                        )
                                        : const Icon(
                                          Icons.image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                              ),
                              title: Text(
                                model['nombre'],
                                style: TextStyle(
                                  color: AppColors.brownDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Producto: ${model['producto']}",
                                    style: TextStyle(color: Colors.brown[700]),
                                  ),
                                  Text(
                                    "Versión: ${model['version']}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Fecha: ${model['fecha_entrenamiento']}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Ruta: ${model['ruta']}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isFav ? Icons.star : Icons.star_border,
                                  color: isFav ? AppColors.gold : Colors.grey,
                                  size: 28,
                                ),
                                onPressed: () => _toggleFavorite(model),
                              ),
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
