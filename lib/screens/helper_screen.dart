import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HelperScreen extends StatelessWidget {
  const HelperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text('Guía Entrenamiento'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildExpansionTile(
                icon: Icons.dataset,
                iconColor: AppColors.blueGray,
                title: 'Dataset Requerido',
                children: [
                  '- Imágenes con colores variados',
                  '- Diferentes ángulos y luz',
                  '- Tamaño consistente',
                  '- Carpetas por clase',
                ],
              ),
              _buildExpansionTile(
                icon: Icons.label,
                iconColor: AppColors.mintGreen,
                title: 'Etiquetado',
                children: [
                  '- Etiquetado automático',
                  '- Verificar clases',
                  '- Evitar errores visuales',
                ],
              ),
              _buildExpansionTile(
                icon: Icons.file_copy,
                iconColor: AppColors.gold,
                title: 'Archivos YAML',
                children: [
                  '- Rutas correctas train/val/test',
                  '- Número de clases',
                  '- Configurar batch size',
                ],
              ),
              _buildExpansionTile(
                icon: Icons.security,
                iconColor: AppColors.brownMedium,
                title: 'Roles y permisos',
                children: [
                  '- Analista/Admin: entrena y valida',
                  '- Trabajador: captura imágenes',
                ],
              ),
              _buildExpansionTile(
                icon: Icons.lightbulb_outline,
                iconColor: AppColors.blueGray,
                title: 'Recomendaciones',
                children: [
                  '- Mínimo 100 imágenes por clase',
                  '- Iluminación estable',
                  '- Validaciones frecuentes',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.brownDark,
          ),
        ),
        children:
            children
                .map(
                  (text) => ListTile(
                    title: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.blackSoft,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
