import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({Key? key}) : super(key: key);

  @override
  _ProductSearchScreenState createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchType = 'name';
  List<dynamic> _products = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selectedProduct;
  List<dynamic> _detections = [];
  bool _isLoadingDetections = false;

  // Ajusta si tu API base es diferente
  final String apiBase = dotenv.env['API_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (_searchController.text.trim().length > 2) {
        _searchProducts();
      } else {
        setState(() {
          _products = [];
          _selectedProduct = null;
          _detections = [];
        });
      }
    });
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _searchProducts() async {
    setState(() {
      _isLoading = true;
      _selectedProduct = null;
      _detections = [];
    });

    try {
      final token = await _getToken();
      final uri = Uri.parse(
        '$apiBase/api/products/search?q=${Uri.encodeComponent(_searchController.text.trim())}&by=$_searchType',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _products = decoded['data'] is List ? decoded['data'] as List : [];
        });
      } else {
        _showSnack('Error al buscar objetos (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Error de conexión al buscar objetos');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getProductDetections(int productId) async {
    setState(() {
      _isLoadingDetections = true;
      _detections = [];
    });

    try {
      final token = await _getToken();
      final uri = Uri.parse(
        '$apiBase/api/detections/full?product_id=$productId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // asume estructura: { message:..., data: [...] } o directamente lista
        final List<dynamic> data =
            decoded is Map && decoded['data'] != null
                ? decoded['data'] as List
                : (decoded as List? ?? []);
        setState(() {
          _detections = data;
        });
      } else {
        _showSnack('Error al obtener detecciones (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Error de conexión al obtener detecciones');
    } finally {
      setState(() {
        _isLoadingDetections = false;
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // Si el backend devuelve rutas relativas, las concatenamos
    return apiBase + (trimmed.startsWith('/') ? '' : '/') + trimmed;
  }

  Widget _productTile(dynamic product) {
    final imagePath =
        product['image_path'] ??
        product['imagen_path'] ??
        product['image'] ??
        product['imagen'];
    final imageUrl = _buildImageUrl(imagePath as String?);
    final name = product['name'] ?? product['nombre'] ?? 'Objeto';
    final barcode = product['barcode'] ?? product['codigo'] ?? '';
    final price = product['price'] ?? product['precio'];
    final status = product['status']; // asumimos 1 = activo

    return Card(
      color: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedProduct = Map<String, dynamic>.from(product);
          });
          _getProductDetections(product['id'] as int);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 84,
                  height: 84,
                  color: AppColors.beigeLight,
                  child:
                      imageUrl != null
                          ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 84,
                            height: 84,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(child: CircularProgressIndicator());
                            },
                            errorBuilder:
                                (context, err, stack) => Icon(
                                  Icons.broken_image,
                                  color: AppColors.brownDark,
                                ),
                          )
                          : Icon(
                            Icons.image,
                            size: 48,
                            color: AppColors.brownDark,
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      barcode != null && barcode != ''
                          ? 'Código: $barcode'
                          : 'Sin código',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brownDark.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Precio: ${price != null ? '\$${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}' : 'N/A'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brownDark.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Caffé',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: AppColors.brownDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detectionCard(dynamic detection) {
    final imgPath =
        detection['image_path'] ??
        detection['imagen_path'] ??
        detection['image'] ??
        detection['imagen'];
    final imageUrl = _buildImageUrl(imgPath as String?);
    final dateStr = detection['date'] ?? detection['fecha'];

    DateTime? dateTime;
    try {
      if (dateStr != null) dateTime = DateTime.parse(dateStr);
    } catch (_) {
      dateTime = null;
    }

    final formattedDate =
        dateTime != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(dateTime.toLocal())
            : (dateStr ?? '');

    final quantity = detection['quantity'] ?? detection['cantidad'] ?? 0;
    double? confRaw;
    try {
      confRaw =
          detection['confidence'] != null
              ? double.parse(detection['confidence'].toString())
              : null;
    } catch (_) {
      confRaw = null;
    }
    final confPercent = confRaw != null ? (confRaw * 100.0) : null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: IntrinsicHeight(
        // ✅ asegura que leading, subtitle y trailing se alineen sin overflow
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: GestureDetector(
            onTap: () {
              if (imageUrl != null) _openImageDialog(imageUrl);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.beigeLight,
                child:
                    imageUrl != null
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder:
                              (context, err, stack) => Icon(
                                Icons.broken_image,
                                color: AppColors.brownDark,
                              ),
                        )
                        : Icon(Icons.image, color: AppColors.brownDark),
              ),
            ),
          ),
          title: Text(
            formattedDate,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.brownDark,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                'Cantidad: $quantity',
                style: TextStyle(color: AppColors.brownDark.withOpacity(0.8)),
              ),
              const SizedBox(height: 4),
              if (detection['user'] != null)
                Text(
                  'Usuario: ${detection['user']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brownDark.withOpacity(0.7),
                  ),
                ),
              if (detection['model_version'] != null)
                Text(
                  'Modelo: ${detection['model_version']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brownDark.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween, // ✅ distribuye verticalmente sin overflow
            mainAxisSize: MainAxisSize.min,
            children: [
              confPercent != null
                  ? Text(
                    '${confPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brownDark,
                    ),
                  )
                  : Text(
                    'N/A',
                    style: TextStyle(
                      color: AppColors.brownDark.withOpacity(0.7),
                    ),
                  ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.open_in_full,
                  color: AppColors.brownDark,
                  size: 20,
                ),
                onPressed: () {
                  if (imageUrl != null) _openImageDialog(imageUrl);
                },
              ),
            ],
          ),
          onTap: () => _showDetectionDetails(detection),
        ),
      ),
    );
  }

  void _showDetectionDetails(dynamic detection) {
    final details = detection['details'] ?? detection['detalles'] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.66,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.beigeLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Detalles de detección',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      details.isEmpty
                          ? Center(
                            child: Text(
                              'No hay objetos detectados',
                              style: TextStyle(color: AppColors.brownDark),
                            ),
                          )
                          : ListView.separated(
                            itemCount: details.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final d = details[idx];
                              final objId =
                                  d['objeto_id'] ??
                                  d['object_id'] ??
                                  d['objeto'] ??
                                  'obj_${idx + 1}';
                              final conf = d['confianza'] ?? d['confidence'];
                              final coords =
                                  d['coordenadas'] ??
                                  [d['x1'], d['y1'], d['x2'], d['y2']];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    objId.toString(),
                                    style: TextStyle(
                                      color: AppColors.brownDark,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (conf != null)
                                        Text(
                                          'Confianza: ${(double.tryParse(conf.toString()) ?? 0) * 100}%',
                                        ),
                                      if (coords != null)
                                        Text(
                                          'Coordenadas: ${coords.map((e) => e.toString()).join(', ')}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                    ],
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
      },
    );
  }

  void _openImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.white,
            insetPadding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.brownDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.7,
                    color: AppColors.beigeLight,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder:
                          (context, err, stack) => Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 80,
                              color: AppColors.brownDark,
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  Widget _buildSearchArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.brownDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                hintText: 'Buscar objeto...',
                prefixIcon: Icon(Icons.search, color: AppColors.brownDark),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _searchType,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Nombre')),
                DropdownMenuItem(value: 'barcode', child: Text('Código')),
                DropdownMenuItem(value: 'id', child: Text('ID')),
              ],
              onChanged: (value) {
                setState(() {
                  _searchType = value ?? 'name';
                });
                if (_searchController.text.trim().length > 2) {
                  _searchProducts();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedProduct != null) {
      return _buildProductDetails();
    }

    // No seleccionado -> lista de productos
    return RefreshIndicator(
      onRefresh: _searchProducts,
      color: AppColors.brownDark,
      backgroundColor: AppColors.white,
      child:
          _products.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'Busca un objeto para empezar',
                      style: TextStyle(color: AppColors.brownDark),
                    ),
                  ),
                ],
              )
              : ListView.builder(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  return _productTile(_products[index]);
                },
              ),
    );
  }

  Widget _buildProductDetails() {
    final product = _selectedProduct!;
    final productImage =
        product['image_path'] ??
        product['imagen_path'] ??
        product['image'] ??
        product['imagen'];
    final productImageUrl = _buildImageUrl(productImage as String?);
    final name = product['name'] ?? product['nombre'] ?? 'Objeto';
    final barcode = product['barcode'] ?? product['codigo'] ?? '';
    final price = product['price'] ?? product['precio'];
    final desc = product['description'] ?? product['descripcion'] ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        if (product['id'] != null)
          await _getProductDetections(product['id'] as int);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 110,
                        height: 110,
                        color: AppColors.beigeLight,
                        child:
                            productImageUrl != null
                                ? Image.network(
                                  productImageUrl,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder:
                                      (context, err, stack) => Icon(
                                        Icons.broken_image,
                                        color: AppColors.brownDark,
                                      ),
                                )
                                : Icon(
                                  Icons.image,
                                  size: 64,
                                  color: AppColors.brownDark,
                                ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brownDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            barcode != '' ? 'Código: $barcode' : 'Sin código',
                            style: TextStyle(
                              color: AppColors.brownDark.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Precio: ${price != null ? '\$${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}' : 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brownDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc ?? 'Sin descripción',
              style: TextStyle(color: AppColors.brownDark.withOpacity(0.85)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detecciones recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
                if (_isLoadingDetections)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _detections.isEmpty
                ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _isLoadingDetections
                        ? 'Cargando detecciones...'
                        : 'No hay detecciones recientes para este objeto',
                    style: TextStyle(
                      color: AppColors.brownDark.withOpacity(0.8),
                    ),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _detections.length,
                  itemBuilder: (context, index) {
                    return _detectionCard(_detections[index]);
                  },
                ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brownDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // Volver a la lista de productos
                setState(() {
                  _selectedProduct = null;
                  _detections = [];
                });
              },
              child: const Center(
                child: Text(
                  'Volver',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: const Text('Buscar Objeto'),
        backgroundColor: AppColors.brownDark,
        foregroundColor: AppColors.white,
      ),
      resizeToAvoidBottomInset: true, // ✅ evita overflow si aparece el teclado
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12), // ✅ margen extra inferior
          child: Column(
            children: [_buildSearchArea(), Expanded(child: _buildBody())],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
