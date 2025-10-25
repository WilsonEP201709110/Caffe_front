import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../constants/app_assets.dart'; // <- importa tu clase AppAssets

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final result = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error desconocido'),
          backgroundColor: AppColors.brownDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.beigeLight,
              AppColors.mintGreen.withOpacity(0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo arriba
              Image.asset(AppAssets.logoPrincipal, height: 220),
              SizedBox(height: 30),

              Text(
                'Bienvenido a Caffé 0.6.8',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brownDark,
                ),
              ),
              SizedBox(height: 40),

              // Input Usuario
              _buildInputField(
                controller: _usernameController,
                label: 'Usuario',
                icon: Icons.person,
              ),
              SizedBox(height: 20),

              // Input Contraseña
              _buildInputField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock,
                obscureText: true,
              ),
              SizedBox(height: 30),

              // Botón Ingresar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: AppColors.white)
                          : Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                ),
              ),

              SizedBox(height: 15),

              // Registro
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text(
                  '¿No tienes cuenta? Regístrate',
                  style: TextStyle(
                    color: AppColors.brownMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackSoft.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.brownDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
