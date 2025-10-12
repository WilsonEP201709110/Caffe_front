import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text('Acerca de la App'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoCard(
              icon: Icons.info,
              iconColor: AppColors.blueGray,
              title: 'Nombre',
              subtitle: 'IACaffé - Detección de objetos con IA',
            ),
            _buildInfoCard(
              icon: Icons.important_devices,
              iconColor: AppColors.mintGreen,
              title: 'Versión',
              subtitle: 'v1.0.0',
            ),
            _buildInfoCard(
              icon: Icons.policy,
              iconColor: AppColors.gold,
              title: 'Políticas de Privacidad',
              subtitle:
                  'Se resguarda la información capturada y los datos de usuario.',
            ),
            _buildInfoCard(
              icon: Icons.group,
              iconColor: AppColors.brownMedium,
              title: 'Roles',
              subtitle: '- Analista/Admin\n- Trabajador',
            ),
            _buildInfoCard(
              icon: Icons.update,
              iconColor: AppColors.redAccent,
              title: 'Última actualización',
              subtitle: '11-Oct-2025',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 36),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.brownDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: AppColors.blackSoft),
        ),
      ),
    );
  }
}
