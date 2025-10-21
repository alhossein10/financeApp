import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Utility class for image compression and optimization
class ImageCompression {
  /// Maximum width for resized images (in pixels)
  static const int maxWidth = 1920;

  /// JPEG compression quality (0-100)
  static const int jpegQuality = 85;

  /// Compress an image file
  /// 
  /// This method:
  /// - Decodes the image from various formats (PNG, JPEG, HEIC, etc.)
  /// - Resizes if width exceeds [maxWidth]
  /// - Compresses to JPEG format with [jpegQuality]
  /// - Saves to a temporary file
  /// 
  /// Parameters:
  /// - [file]: The original image file to compress
  /// 
  /// Returns:
  /// - Compressed image file
  /// 
  /// Throws:
  /// - Exception if image cannot be decoded or processed
  static Future<File> compressImage(File file) async {
    try {
      // Read the image bytes
      final bytes = await file.readAsBytes();

      // Decode the image (supports PNG, JPEG, HEIC, etc.)
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if the image is too large
      final resized = image.width > maxWidth
          ? img.copyResize(image, width: maxWidth)
          : image;

      // Compress to JPEG format
      final compressed = img.encodeJpg(resized, quality: jpegQuality);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/compressed_$timestamp.jpg');
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Get the size of a file in bytes
  /// 
  /// Parameters:
  /// - [file]: The file to measure
  /// 
  /// Returns:
  /// - File size in bytes
  static Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Calculate compression ratio
  /// 
  /// Parameters:
  /// - [originalSize]: Original file size in bytes
  /// - [compressedSize]: Compressed file size in bytes
  /// 
  /// Returns:
  /// - Compression ratio as a percentage (e.g., 75.5 means 75.5% reduction)
  static double calculateCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0.0;
    return ((originalSize - compressedSize) / originalSize) * 100;
  }

  /// Check if an image needs compression
  /// 
  /// Parameters:
  /// - [file]: The image file to check
  /// - [maxSizeBytes]: Maximum acceptable size in bytes (default: 2MB)
  /// 
  /// Returns:
  /// - true if the file exceeds the maximum size
  static Future<bool> needsCompression(File file, {int maxSizeBytes = 2 * 1024 * 1024}) async {
    final size = await getFileSize(file);
    return size > maxSizeBytes;
  }
}
