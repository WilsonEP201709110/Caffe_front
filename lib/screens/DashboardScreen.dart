import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Cerrar sesión'),
            content: Text('¿Estás seguro que deseas salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.brownDark),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brownDark,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Salir', style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
    );

    if (result == true) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _DashboardCard(
            icon: Icons.camera_alt,
            title: 'Nueva Detección',
            onTap: () => Navigator.pushNamed(context, '/detections'),
          ),
          _DashboardCard(
            icon: Icons.model_training,
            title: 'Modelos IA',
            onTap: () => Navigator.pushNamed(context, '/models'),
          ),
          _DashboardCard(
            icon: Icons.category,
            title: 'Categoria',
            onTap: () => Navigator.pushNamed(context, '/category'),
          ),
          _DashboardCard(
            icon: Icons.shape_line,
            title: 'Objetos',
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          _DashboardCard(
            icon: Icons.analytics,
            title: 'Reportes',
            onTap: () => Navigator.pushNamed(context, '/products/reports'),
          ),
          _DashboardCard(
            icon: Icons.help_outline,
            title: 'Guía Entrenamiento',
            onTap: () => Navigator.pushNamed(context, '/helper'),
          ),
          _DashboardCard(
            icon: Icons.info_outline,
            title: 'Acerca de',
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          _DashboardCard(
            icon: Icons.settings,
            title: 'Configuraciones',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          color: AppColors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 50, color: AppColors.brownDark),
                  SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brownDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Etiqueta premium en esquina superior izquierda
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            color: AppColors.gold,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Caffé',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ), // 🔹 Espacio extra al final
      ],
    );
  }
}
