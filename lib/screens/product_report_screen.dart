import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProductSearchScreen extends StatefulWidget {
  @override
  _ProductSearchScreenState createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'name';
  List<dynamic> _products = [];
  bool _isLoading = false;
  dynamic _selectedProduct;
  List<dynamic> _detections = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_debounceSearch);
  }

  void _debounceSearch() {
    if (_searchController.text.length > 2) {
      _searchProducts();
    }
  }

  Future<void> _searchProducts() async {
    setState(() {
      _isLoading = true;
      _selectedProduct = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/products/search?q=${_searchController.text}&by=$_searchType'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _products = data['data'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar productos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getProductDetections(int productId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/detections?product_id=$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _detections = data['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener detecciones')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Producto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar producto',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _searchType,
                  items: [
                    DropdownMenuItem(value: 'name', child: Text('Nombre')),
                    DropdownMenuItem(value: 'barcode', child: Text('Código')),
                    DropdownMenuItem(value: 'id', child: Text('ID')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _searchType = value!;
                      if (_searchController.text.isNotEmpty) {
                        _searchProducts();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_selectedProduct != null)
            Expanded(
              child: _buildProductDetails(),
            )
          else
            Expanded(
              child: _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_products.isEmpty && _searchController.text.isNotEmpty) {
      return Center(child: Text('No se encontraron productos'));
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ListTile(
          leading: product['image_path'] != null
              ? Image.network(
                  'https://picsum.photos/150/150',//http://tu-api.com${product['image_path']}',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.abc_sharp),
                )
              : Icon(Icons.abc),
          title: Text(product['name']),
          subtitle: Text(product['barcode'] ?? 'Sin código'),
          trailing: Text('\$${product['price']?.toStringAsFixed(2) ?? 'N/A'}'),
          onTap: () {
            setState(() {
              _selectedProduct = product;
            });
            _getProductDetections(product['id']);
          },
        );
      },
    );
  }

Widget buildProductImage(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return Icon(Icons.image, size: 100);
  }
  
  return Image.network(
    'http://tu-api.com$imagePath',
    width: 100,
    height: 100,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 100),
  );
}

  Widget _buildProductDetails() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _selectedProduct['image_path'] != null
                  ? Container(
                      width: 100,
                      height: 100,
                      child: Image.network(
                        'https://picsum.photos/150/150',//'http://tu-api.com${_selectedProduct['image_path']}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 100),
                      ),
                    )
                  : Icon(Icons.image, size: 100),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProduct['name'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    if (_selectedProduct['barcode'] != null)
                      Text('Código: ${_selectedProduct['barcode']}'),
                    Text('Precio: \$${_selectedProduct['price']?.toStringAsFixed(2) ?? 'N/A'}'),
                    Text('Estado: ${_selectedProduct['status'] == 1 ? 'Activo' : 'Inactivo'}'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Descripción:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(_selectedProduct['description'] ?? 'Sin descripción'),
          SizedBox(height: 24),
          Text(
            'Detecciones recientes:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (_detections.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No hay detecciones recientes para este producto'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _detections.length,
              itemBuilder: (context, index) {
                final detection = _detections[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.image, size: 40),
                      onPressed: () {
                        // Mostrar la imagen en un dialog/modal
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.7,
                                child: detection['image_path'] != null
                                    ? Image.network(
                                        'https://picsum.photos/150/150',//'http://tu-api.com${detection['image_path']}',
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / 
                                                    loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => 
                                          Center(child: Icon(Icons.broken_image, size: 60)),
                                      )
                                    : Center(child: Text('Imagen no disponible')),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    title: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(detection['date']))),
                    subtitle: Text('Cantidad: ${detection['quantity']}'),
                    trailing: Text('Conf: ${(detection['confidence'] * 100).toStringAsFixed(1)}%'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}