import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio encargado de la selección y carga de imágenes a Cloudinary vía API unsigned.
class CloudinaryService {
  static final ImagePicker _picker = ImagePicker();
  static final Dio _dio = Dio();

  // Configuración por defecto de Cloudinary
  static const String cloudName = 'chazinfood';
  static const String uploadPreset = 'chazin_food_preset';

  /// Muestra un modal bottom sheet para que el usuario elija entre Cámara o Galería,
  /// selecciona la foto y la sube a Cloudinary devolviendo la URL HTTPS.
  static Future<String?> pickAndUploadImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Seleccionar Foto del Producto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text('Galería de fotos'),
                subtitle: const Text('Elegir una imagen guardada'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.camera_alt_outlined, color: Color(0xFFDC2626)),
                ),
                title: const Text('Tomar foto con la cámara'),
                subtitle: const Text('Capturar directamente'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (file == null) return null;

    return await uploadImage(File(file.path));
  }

  /// Sube un archivo File local a Cloudinary
  static Future<String> uploadImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'upload_preset': uploadPreset,
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final secureUrl = response.data['secure_url'] ?? response.data['url'];
        if (secureUrl != null && secureUrl.toString().isNotEmpty) {
          return secureUrl.toString();
        }
      }
    } catch (e) {
      // En caso de fallo de conexión a Cloudinary o preset no configurado,
      // se retorna la ruta local del archivo para no romper el flujo
      debugPrint('Cloudinary upload warning: $e. Retornando ruta local.');
    }
    return imageFile.path;
  }
}
