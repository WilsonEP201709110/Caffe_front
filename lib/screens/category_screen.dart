import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories();
      setState(() => _categories = categories);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _showCreateOrEditDialog({Map<String, dynamic>? category}) {
    final nombreController = TextEditingController(
      text: category != null ? category['nombre'] : '',
    );
    final descController = TextEditingController(
      text: category != null ? category['descripcion'] ?? '' : '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              category != null ? 'Editar Categoría' : 'Nueva Categoría',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brownDark,
                ),
                onPressed: () async {
                  final nombre = nombreController.text.trim();
                  final descripcion = descController.text.trim();
                  if (nombre.isEmpty)
                    return _showError('El nombre es obligatorio');

                  try {
                    if (category != null) {
                      await _categoryService.updateCategory(
                        category['id'],
                        nombre,
                        descripcion,
                      );
                    } else {
                      await _categoryService.createCategory(
                        nombre,
                        descripcion,
                      );
                    }
                    Navigator.pop(context);
                    await _loadCategories();
                  } catch (e) {
                    _showError(e.toString());
                  }
                },
                child: Text(
                  category != null ? 'Actualizar' : 'Crear',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Categoría'),
            content: const Text('¿Deseas eliminar esta categoría?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brownDark,
                ),
                onPressed: () async {
                  try {
                    await _categoryService.deleteCategory(category['id']);
                    Navigator.pop(context);
                    await _loadCategories();
                  } catch (e) {
                    Navigator.pop(context);
                    _showError(e.toString());
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.white),
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
        title: const Text('Categorías'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brownDark,
        child: const Icon(Icons.add, color: AppColors.white),
        onPressed: () => _showCreateOrEditDialog(),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
              ? const Center(child: Text('No hay categorías'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return Card(
                    color: AppColors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        cat['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(cat['descripcion'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.brownDark,
                            ),
                            onPressed:
                                () => _showCreateOrEditDialog(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _confirmDelete(cat),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
