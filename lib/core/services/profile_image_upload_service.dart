import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

/// Service for handling profile image uploads
/// Provides image picking, compression, and upload functionality
class ProfileImageUploadService {
  final ApiClient apiClient;
  final ImagePicker _imagePicker;
  
  static const int _maxImageSizeBytes = 1024 * 1024; // 1MB
  static const int _compressionQuality = 85;
  static const int _maxImageDimension = 512; // Max width/height in pixels

  ProfileImageUploadService({
    required this.apiClient,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageDimension.toDouble(),
        maxHeight: _maxImageDimension.toDouble(),
        imageQuality: _compressionQuality,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw Exception('Failed to pick image from gallery: ${e.toString()}');
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: _maxImageDimension.toDouble(),
        maxHeight: _maxImageDimension.toDouble(),
        imageQuality: _compressionQuality,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw Exception('Failed to take photo: ${e.toString()}');
    }
  }

  /// Compress image to meet size requirements (max 1MB)
  Future<File> compressImage(File imageFile) async {
    try {
      // Check current file size
      final fileSize = await imageFile.length();
      
      // If already under 1MB, return as is
      if (fileSize <= _maxImageSizeBytes) {
        return imageFile;
      }

      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed (maintain aspect ratio)
      img.Image resizedImage = image;
      if (image.width > _maxImageDimension || image.height > _maxImageDimension) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? _maxImageDimension : null,
          height: image.height > image.width ? _maxImageDimension : null,
        );
      }

      // Get temporary directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Start with initial quality
      int quality = _compressionQuality;
      File compressedFile;
      
      // Compress with decreasing quality until under 1MB
      do {
        final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        compressedFile = File(targetPath);
        await compressedFile.writeAsBytes(compressedBytes);
        
        final compressedSize = await compressedFile.length();
        
        // If under 1MB, we're done
        if (compressedSize <= _maxImageSizeBytes) {
          break;
        }
        
        // Reduce quality for next iteration
        quality -= 10;
        
        // Don't go below 50% quality
        if (quality < 50) {
          break;
        }
      } while (true);

      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: ${e.toString()}');
    }
  }

  /// Upload profile image to API
  /// Returns the URL of the uploaded image
  Future<String> uploadProfileImage(
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    try {
      // Compress image first
      final compressedFile = await compressImage(imageFile);

      // Upload to profile image endpoint
      final response = await apiClient.uploadFile(
        '/profile/upload-image',
        compressedFile,
        fileFieldName: 'profile_image',
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Check for success field
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          final imageUrl = data['profile_image_url'] as String?;
          
          if (imageUrl == null) {
            throw ApiException(
              message: 'Profile image URL not returned from server',
              statusCode: response.statusCode ?? 500,
            );
          }
          
          return imageUrl;
        } else {
          throw ApiException(
            message: responseData['message'] as String? ?? 'Upload failed',
            statusCode: response.statusCode ?? 500,
          );
        }
      } else {
        throw ApiException(
          message: 'Failed to upload profile image',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to upload profile image: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get file size in MB
  Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Validate that file is an image
  bool isValidImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }
}
