import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';
import '../constants/app_assets.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final AuthService _authService = AuthService();

  String _selectedRole = 'analista';
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        token: _tokenController.text,
        rol: _selectedRole,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Registro exitoso! Ahora inicia sesión.')),
      );
    } catch (e) {
      // Mostrar mensaje de error en popup
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              message.replaceAll(
                'Exception: ',
                '',
              ), // limpiar formato si viene del backend
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(AppAssets.logoPrincipal, height: 100),
                    const SizedBox(height: 20),
                    Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark,
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildInputField(
                      _firstNameController,
                      'Nombre',
                      Icons.person,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      _lastNameController,
                      'Apellido',
                      Icons.person,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      _usernameController,
                      'Usuario',
                      Icons.account_circle,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      _emailController,
                      'Email',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    // Campo teléfono deshabilitado
                    _buildInputField(
                      _phoneController,
                      'Número de celular (deshabilitado)',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: false,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      _passwordController,
                      'Contraseña',
                      Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      _repeatPasswordController,
                      'Repetir Contraseña',
                      Icons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      _tokenController,
                      'Serial / Token',
                      Icons.vpn_key,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items:
                          ['analista', 'inspector']
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => _selectedRole = value!),
                      decoration: InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brownDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator(
                                  color: AppColors.white,
                                )
                                : const Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Botón regresar
            Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.brownDark,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: (value) {
        if (!enabled) return null; // no validar si está deshabilitado
        if (value == null || value.isEmpty) return 'Campo obligatorio';
        if ((label == 'Repetir Contraseña' || label == 'Contraseña') &&
            _passwordController.text != _repeatPasswordController.text &&
            _repeatPasswordController.text.isNotEmpty) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brownDark),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
