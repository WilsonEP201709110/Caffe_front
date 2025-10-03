import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Para almacenar el token

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Donde guardaste el token al hacer login
  }

  Future<void> _fetchProducts() async {
    final token = await _getToken();

    if (token == null) {
      setState(() {
        _errorMessage = 'No estás autenticado';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _products = jsonDecode(response.body)['data'];
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Sesión expirada. Por favor inicia sesión nuevamente';
          _isLoading = false;
        });
        // Opcional: redirigir al login
        // Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage = 'Error al cargar productos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: ${e.toString()}';
        print('Error de conexión: ${e.toString()}');
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/products/add'),
        child: Icon(Icons.add),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchProducts,
                        child: Text('Reintentar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Ir al login'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      leading: product['image_path'] != null
                          ? CircleAvatar(backgroundImage: NetworkImage(product['image_path']))
                          : Icon(Icons.shopping_basket),
                      title: Text(product['name']),
                      subtitle: Text('\$${product['price']}'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/products/detail',
                        arguments: product['id'],
                      ),
                    );
                  },
                ),
    );
  }
}