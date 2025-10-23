import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    try {
      final data = await _productService.fetchProducts();
      setState(() {
        _products = data;
        _filteredProducts = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts =
          _products
              .where(
                (product) => product['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: Text('Productos'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/products/add'),
        backgroundColor: AppColors.brownDark,
        child: Icon(Icons.add, color: AppColors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Buscador
            TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search, color: AppColors.brownDark),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brownDark,
                        ),
                      )
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _fetchProducts,
                              child: Text('Reintentar'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  () => Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  ),
                              child: Text('Ir al login'),
                            ),
                          ],
                        ),
                      )
                      : _filteredProducts.isEmpty
                      ? Center(
                        child: Text(
                          'No se encontraron productos',
                          style: TextStyle(color: AppColors.brownDark),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.coffee_sharp, // taza de café
                                color: AppColors.brownDark,
                                size: 36,
                              ),
                              title: Text(
                                product['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brownDark,
                                ),
                              ),
                              //subtitle: Text(
                              //  '\$${product['price']}',
                              //  style: TextStyle(color: AppColors.blackSoft),
                              //),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: AppColors.redAccent,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Eliminar producto: ${product['name']}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/products/detail',
                                    arguments: product['id'],
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
