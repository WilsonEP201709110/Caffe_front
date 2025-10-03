import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _DashboardCard(
            icon: Icons.camera_alt,
            title: 'Nueva Detección',
            onTap: () => Navigator.pushNamed(context, '/detection'),
          ),
          _DashboardCard(
            icon: Icons.shopping_basket,
            title: 'Productos',
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          _DashboardCard(
            icon: Icons.model_training,
            title: 'Modelos IA',
            onTap: () => Navigator.pushNamed(context, '/models'),
          ),
          _DashboardCard(
            icon: Icons.analytics,
            title: 'Reportes',
            onTap: () => Navigator.pushNamed(context, '/products/reports'),
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
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}