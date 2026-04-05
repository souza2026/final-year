import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  /// Upload from XFile (used by content upload screen).
  /// Stores under 'uploads/' with original extension. Rethrows on error.
  static Future<String> uploadXFile(XFile image) async {
    final String extension = p.extension(image.path).toLowerCase();
    final String safeExtension = extension.isNotEmpty ? extension : '.jpg';
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final String path = 'uploads/$fileName';

    final bytes = await image.readAsBytes();

    try {
      await Supabase.instance.client.storage
          .from('site_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('site_images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint("Storage error: $e");
      rethrow;
    }
  }

  /// Upload from File (used by detailed edit screen).
  /// Stores under 'site_images/' with .jpg extension. Returns null on error.
  static Future<String?> uploadFile(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final path = 'site_images/${DateTime.now().toIso8601String()}.jpg';
      await Supabase.instance.client.storage
          .from('site_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('site_images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint("Storage error: $e");
      return null;
    }
  }
}
