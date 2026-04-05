// ============================================================
// image_upload_service.dart — Image upload to Supabase Storage
// ============================================================
// Provides two static methods for uploading images to the
// Supabase Storage bucket named `site_images`:
//
//   1. [uploadXFile] — Accepts an [XFile] (from image_picker),
//      used by the content upload screen.
//   2. [uploadFile] — Accepts a [File] (dart:io), used by the
//      detailed edit screen.
//
// Both methods:
//   - Generate a unique filename using the current timestamp
//   - Preserve the original file extension (defaulting to .jpg)
//   - Upload to the `uploads/` folder within the bucket
//   - Return the public URL of the uploaded image
//
// The `upsert: true` option ensures that if a file with the same
// name already exists, it will be overwritten rather than causing
// an error (though timestamp-based naming makes collisions unlikely).
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// A utility service for uploading images to Supabase Storage.
/// All methods are static, so no instance is needed.
class ImageUploadService {
  /// Upload an image from an [XFile] (returned by the image_picker package).
  ///
  /// Used by the content upload screen when the admin picks a new image.
  /// Stores the file under `uploads/<timestamp>.<ext>` in the `site_images`
  /// bucket. Returns the public URL of the uploaded image.
  ///
  /// Throws on error (rethrows the original exception).
  static Future<String> uploadXFile(XFile image) async {
    // Step 1: Extract the file extension, defaulting to .jpg if none
    final String extension = p.extension(image.path).toLowerCase();
    final String safeExtension = extension.isNotEmpty ? extension : '.jpg';

    // Step 2: Generate a unique filename using the current timestamp
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final String path = 'uploads/$fileName';

    // Step 3: Read the file bytes
    final bytes = await image.readAsBytes();

    try {
      // Step 4: Upload the binary data to Supabase Storage
      await Supabase.instance.client.storage
          .from('site_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Step 5: Return the public URL for the uploaded file
      return Supabase.instance.client.storage
          .from('site_images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint("Storage error: $e");
      rethrow;
    }
  }

  /// Upload an image from a [File] (dart:io).
  ///
  /// Used by the detailed edit screen when the admin updates an
  /// existing location's image. Same upload logic as [uploadXFile]
  /// but returns null on error instead of throwing.
  static Future<String?> uploadFile(File image) async {
    try {
      // Step 1: Read the file bytes
      final bytes = await image.readAsBytes();

      // Step 2: Extract the file extension, defaulting to .jpg if none
      final String extension = p.extension(image.path).toLowerCase();
      final String safeExtension = extension.isNotEmpty ? extension : '.jpg';

      // Step 3: Generate a unique filename using the current timestamp
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
      final String path = 'uploads/$fileName';

      // Step 4: Upload the binary data to Supabase Storage
      await Supabase.instance.client.storage
          .from('site_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Step 5: Return the public URL for the uploaded file
      return Supabase.instance.client.storage
          .from('site_images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint("Storage error: $e");
      return null; // Return null on error instead of throwing
    }
  }
}
