import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:ui' as ui;

class RealTimeDetectionScreen extends StatefulWidget {
  final String wsUrl;
  final String modeloId;

  const RealTimeDetectionScreen({
    Key? key,
    required this.wsUrl,
    required this.modeloId,
  }) : super(key: key);

  @override
  _RealTimeDetectionScreenState createState() =>
      _RealTimeDetectionScreenState();
}

class _RealTimeDetectionScreenState extends State<RealTimeDetectionScreen> {
  late CameraController _cameraController;
  WebSocketChannel? _channel;
  bool _isStreaming = false;
  bool _wsConnected = false; // ✅ bandera de conexión

  List<Detection> _detections = [];
  double _intervalSeconds = 0.5;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _connectWebSocket();
  }

  // ✅ Conexión segura al WebSocket
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
        _channel?.sink.add(
          json.encode({
            "modelo_id": widget.modeloId,
            "image_bytes": compressedBytes.toList(),
          }),
        );
      } catch (e) {
        debugPrint("❌ Error enviando frame: $e");
      }

      if (_isStreaming) {
        Future.delayed(
          Duration(milliseconds: (_intervalSeconds * 1000).toInt()),
          sendFrame,
        );
      }
    }

    sendFrame();
  }

  void _stopStreaming() {
    _isStreaming = false;
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

    // ✅ Si no hay conexión al WebSocket, mostramos mensaje
    if (!_wsConnected) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detección en tiempo real")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              const Text(
                "❌ No hay conexión con el servidor WebSocket",
                style: TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _connectWebSocket,
                child: const Text("Reintentar conexión"),
              ),
            ],
          ),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final cameraAspectRatio = _cameraController.value.aspectRatio;
    double previewHeight = screenSize.height * 0.7;
    double previewWidth = previewHeight * cameraAspectRatio;

    if (previewWidth > screenSize.width) {
      previewWidth = screenSize.width;
      //previewHeight = previewWidth / cameraAspectRatio;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Detección en tiempo real")),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: previewWidth,
              height: previewHeight,
              alignment: Alignment.topCenter,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraController),
                  CustomPaint(
                    painter: DetectionPainter(
                      detections: _detections,
                      cameraPreviewSize: _cameraController.value.previewSize!,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isStreaming ? _stopStreaming : _startStreaming,
                  child: Text(_isStreaming ? "Detener" : "Iniciar"),
                ),
                DropdownButton<double>(
                  value: _intervalSeconds,
                  items:
                      [0.2, 0.5, 1.0, 1.5, 2.0, 3.0]
                          .map(
                            (e) => DropdownMenuItem<double>(
                              value: e,
                              child: Text("$e segundos"),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _intervalSeconds = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🔹 Compresión
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

// Painter con escalado correcto
class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size cameraPreviewSize;

  DetectionPainter({required this.detections, required this.cameraPreviewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final scaleX = size.width / cameraPreviewSize.height;
    final scaleY = size.height / cameraPreviewSize.width;

    final paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var d in detections) {
      final rect = Rect.fromLTRB(
        d.x1 * scaleX,
        d.y1 * scaleY,
        d.x2 * scaleX,
        d.y2 * scaleY,
      );

      canvas.drawRect(rect, paint);

      final textSpan = TextSpan(
        text: "${d.label} c:${d.confiance.toStringAsFixed(2)}",
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
