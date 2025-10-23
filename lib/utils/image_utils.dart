// lib/utils/image_utils.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// Comprime la imagen seleccionada
  /// [imageFile]: XFile obtenido de ImagePicker
  /// [quality]: porcentaje de compresión (0-100), default 70
  /// [maxWidth]: ancho máximo de la imagen, manteniendo la proporción, default 1080
  static Future<Uint8List> compressImage(
    XFile imageFile, {
    int quality = 70,
    int maxWidth = 1080,
  }) async {
    final bytes = await imageFile.readAsBytes();

    if (kIsWeb || imageFile.path.isEmpty) {
      // Web o XFile creado desde bytes (sin path real)
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth,
        format: CompressFormat.jpeg,
      );
      return Uint8List.fromList(compressed);
    } else {
      // Móvil con path real
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
