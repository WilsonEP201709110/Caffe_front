import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text('Configuraciones'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingCard(
              icon: Icons.person,
              iconColor: AppColors.blueGray,
              title: 'Perfil',
              subtitle: 'Actualizar información de usuario',
              onTap: () {
                // Acción para ir a perfil
              },
            ),
            _buildSettingCard(
              icon: Icons.lock,
              iconColor: AppColors.mintGreen,
              title: 'Seguridad',
              subtitle: 'Cambiar contraseña y opciones de seguridad',
              onTap: () {
                // Acción para ir a seguridad
              },
            ),
            _buildSettingCard(
              icon: Icons.notifications,
              iconColor: AppColors.gold,
              title: 'Notificaciones',
              subtitle: 'Configurar alertas y notificaciones',
              onTap: () {
                // Acción para notificaciones
              },
            ),
            _buildSettingCard(
              icon: Icons.palette,
              iconColor: AppColors.brownMedium,
              title: 'Apariencia',
              subtitle: 'Personalizar tema y colores',
              onTap: () {
                // Acción para apariencia
              },
            ),
            _buildSettingCard(
              icon: Icons.info_outline,
              iconColor: AppColors.redAccent,
              title: 'Acerca de',
              subtitle: 'Información de la app',
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
        onTap: onTap,
      ),
    );
  }
}
