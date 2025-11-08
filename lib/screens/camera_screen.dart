import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../theme/app_colors.dart';
import 'dart:ui' as ui;

class RealTimeDetectionScreen extends StatefulWidget {
  final String wsUrl;

  const RealTimeDetectionScreen({Key? key, required this.wsUrl})
    : super(key: key);

  @override
  _RealTimeDetectionScreenState createState() =>
      _RealTimeDetectionScreenState();
}

class _RealTimeDetectionScreenState extends State<RealTimeDetectionScreen> {
  late CameraController _cameraController;
  WebSocketChannel? _channel;
  bool _isStreaming = false;
  bool _wsConnected = false;

  List<Map<String, dynamic>> _favorites = [];
  Map<String, dynamic>? _selectedFavorite;

  // 🔹 Modo de cámara (photo/live)
  String _mode = "live";

  // 🔸 Modo de análisis (one/full)
  String _analyzeMode = "one";

  List<Detection> _detections = [];
  double _intervalSeconds = 0.5;

  // 🎨 Paleta de colores para distinguir cada modelo favorito
  final List<Color> _palette = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _initCamera().then((_) {
      _connectWebSocket();
      Future.delayed(const Duration(milliseconds: 600), _showModeDialog);
    });
  }

  // 🟤 Popup inicial para seleccionar modo de cámara
  Future<void> _showModeDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Selecciona el modo de detección"),
          content: const Text(
            "¿Deseas analizar una sola captura o usar la cámara en vivo?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _mode = "photo");
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("📸 Modo Captura única")),
                );
              },
              child: const Text("📸 Captura"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brownDark,
              ),
              onPressed: () {
                setState(() => _mode = "live");
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🎥 Modo Cámara en vivo")),
                );
              },
              child: const Text(
                "🎥 Cámara en vivo",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favString = prefs.getString('favorite_models');
    if (favString != null) {
      final List decoded = jsonDecode(favString);
      setState(() {
        _favorites = decoded.cast<Map<String, dynamic>>();
        if (_favorites.isNotEmpty) _selectedFavorite = _favorites.first;
      });
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final channel = WebSocketChannel.connect(Uri.parse(widget.wsUrl));

      channel.stream.listen(
        (message) {
          final data = json.decode(message);
          if (data.containsKey("detections")) {
            List detections = data["detections"];
            setState(() {
              _detections =
                  detections.map((d) => Detection.fromJson(d)).toList();
            });
          }
        },
        onError: (error) {
          debugPrint("❌ Error WebSocket: $error");
          setState(() => _wsConnected = false);
        },
        onDone: () {
          debugPrint("⚠️ WebSocket cerrado.");
          setState(() => _wsConnected = false);
        },
      );

      setState(() {
        _channel = channel;
        _wsConnected = true;
      });
    } catch (e) {
      debugPrint("❌ No se pudo conectar al WebSocket: $e");
      setState(() => _wsConnected = false);
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("❌ Error al inicializar cámara: $e");
    }
  }

  void _startStreaming() {
    if (_favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay modelos favoritos guardados")),
      );
      return;
    }

    if (_analyzeMode == "one" && _selectedFavorite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un modelo primero")),
      );
      return;
    }

    if (_mode == "photo") {
      _takeSinglePhoto();
      return;
    }

    if (_isStreaming || !_wsConnected) return;
    _isStreaming = true;

    Future<void> sendFrame() async {
      if (!_isStreaming ||
          !_cameraController.value.isInitialized ||
          !_wsConnected)
        return;

      final image = await _cameraController.takePicture();
      final compressedBytes = await compressImage(
        image,
        quality: 60,
        maxWidth: 640,
      );

      try {
        if (_analyzeMode == "full") {
          for (var fav in _favorites) {
            _channel?.sink.add(
              json.encode({
                "modelo_id": fav['ruta'],
                "image_bytes": compressedBytes.toList(),
              }),
            );
          }
        } else {
          _channel?.sink.add(
            json.encode({
              "modelo_id": _selectedFavorite!['ruta'],
              "image_bytes": compressedBytes.toList(),
            }),
          );
        }
      } catch (e) {
        debugPrint("❌ Error enviando frame: $e");
      }

      if (_isStreaming && _mode == "live") {
        Future.delayed(
          Duration(milliseconds: (_intervalSeconds * 1000).toInt()),
          sendFrame,
        );
      }
    }

    sendFrame();
  }

  Future<void> _takeSinglePhoto() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      final image = await _cameraController.takePicture();
      final compressedBytes = await compressImage(
        image,
        quality: 70,
        maxWidth: 640,
      );

      if (_analyzeMode == "full") {
        for (var fav in _favorites) {
          _channel?.sink.add(
            json.encode({
              "modelo_id": fav['ruta'],
              "image_bytes": compressedBytes.toList(),
            }),
          );
        }
      } else {
        _channel?.sink.add(
          json.encode({
            "modelo_id": _selectedFavorite!['ruta'],
            "image_bytes": compressedBytes.toList(),
          }),
        );
      }

      setState(() => _isStreaming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📸 Captura enviada para análisis")),
      );
    } catch (e) {
      debugPrint("❌ Error en captura única: $e");
    }
  }

  void _stopStreaming() {
    _isStreaming = false;
  }

  void _toggleCameraMode() {
    setState(() {
      _mode = _mode == "live" ? "photo" : "live";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _mode == "live"
              ? "🎥 Cámara en vivo activada"
              : "📸 Modo captura única activado",
        ),
      ),
    );
  }

  void _toggleAnalyzeMode() {
    setState(() {
      _analyzeMode = _analyzeMode == "one" ? "full" : "one";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _analyzeMode == "full"
              ? "📡 Análisis FULL: todos los modelos"
              : "🎯 Análisis ONE: solo el modelo seleccionado",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopStreaming();
    _cameraController.dispose();
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.beigeLight,
      appBar: AppBar(
        title: const Text("Detección en tiempo real"),
        backgroundColor: AppColors.brownDark,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_favorites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildModelSelector(),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraController),
                  if (_selectedFavorite != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brownDark.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Modo: ${_mode == 'photo' ? '📸 Captura' : '🎥 En vivo'} • ${_analyzeMode == 'one' ? '🎯 One' : '🌈 Full'}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  CustomPaint(
                    painter: DetectionPainter(
                      detections: _detections,
                      cameraPreviewSize: _cameraController.value.previewSize!,
                      palette: _palette,
                      isFull: _analyzeMode == "full",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔹 Botones flotantes
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'analyzeModeBtn',
            backgroundColor: Colors.deepPurple,
            tooltip: 'Cambiar modo análisis',
            onPressed: _toggleAnalyzeMode,
            child: Icon(
              _analyzeMode == "full" ? Icons.grid_view : Icons.adjust,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'cameraModeBtn',
            backgroundColor: Colors.blueAccent,
            tooltip: 'Cambiar modo cámara',
            onPressed: _toggleCameraMode,
            child: Icon(
              _mode == "photo" ? Icons.photo_camera : Icons.videocam,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'intervalBtn',
            backgroundColor: AppColors.brownMedium,
            tooltip: 'Intervalo (${_intervalSeconds.toStringAsFixed(1)}s)',
            onPressed: () async {
              final selected = await showDialog<double>(
                context: context,
                builder: (context) {
                  double temp = _intervalSeconds;
                  return AlertDialog(
                    title: const Text('Seleccionar intervalo'),
                    content: StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Slider(
                              value: temp,
                              min: 0.2,
                              max: 3.0,
                              divisions: 14,
                              label: "${temp.toStringAsFixed(1)} seg",
                              activeColor: AppColors.brownDark,
                              onChanged: (v) => setStateDialog(() => temp = v),
                            ),
                            Text("Cada ${temp.toStringAsFixed(1)} segundos"),
                          ],
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Cancelar"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brownDark,
                        ),
                        onPressed: () => Navigator.pop(context, temp),
                        child: const Text(
                          "Aceptar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
              if (selected != null) setState(() => _intervalSeconds = selected);
            },
            child: const Icon(Icons.timer, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'startBtn',
            backgroundColor:
                _isStreaming ? Colors.redAccent : AppColors.brownMedium,
            onPressed: _isStreaming ? _stopStreaming : _startStreaming,
            tooltip: _isStreaming ? 'Detener' : 'Iniciar',
            child: Icon(
              _isStreaming ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.brownDark,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedFavorite,
          isExpanded: true,
          items:
              _favorites.map((fav) {
                return DropdownMenuItem(
                  value: fav,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                            fav['imagen'] != null && fav['imagen'].isNotEmpty
                                ? Image.network(
                                  fav['imagen'],
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                )
                                : const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fav['nombre'] ?? 'Sin nombre',
                          style: TextStyle(
                            color: AppColors.brownDark,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (v) => setState(() => _selectedFavorite = v),
        ),
      ),
    );
  }

  static Future<Uint8List> compressImage(
    XFile imageFile, {
    int quality = 70,
    int maxWidth = 1080,
  }) async {
    final bytes = await imageFile.readAsBytes();

    if (kIsWeb || imageFile.path.isEmpty) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth,
        format: CompressFormat.jpeg,
      );
      return Uint8List.fromList(compressed);
    } else {
      final file = File(imageFile.path);
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality,
        minWidth: maxWidth,
        format: CompressFormat.jpeg,
      );
      return Uint8List.fromList(compressedBytes!);
    }
  }
}

// Modelo detección
class Detection {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final String label;
  final double confiance;

  Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.label,
    required this.confiance,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
      label: json['nombre_objeto'] ?? "",
      confiance: (json['confianza'] as num).toDouble(),
    );
  }
}

// 🎨 Painter: ahora usa varios colores si es modo "full"
class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size cameraPreviewSize;
  final List<Color> palette;
  final bool isFull;

  DetectionPainter({
    required this.detections,
    required this.cameraPreviewSize,
    this.palette = const [Colors.red],
    this.isFull = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final scaleX = size.width / cameraPreviewSize.height;
    final scaleY = size.height / cameraPreviewSize.width;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    int colorIndex = 0;

    for (var d in detections) {
      final paint =
          Paint()
            ..color = isFull ? palette[colorIndex % palette.length] : Colors.red
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTRB(
        d.x1 * scaleX,
        d.y1 * scaleY,
        d.x2 * scaleX + 26,
        d.y2 * scaleY + 36,
      );

      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: "${d.label} (${d.confiance.toStringAsFixed(2)})",
        style: TextStyle(
          color: paint.color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 16));

      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
