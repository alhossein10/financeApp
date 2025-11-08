import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/file_upload_dto.dart';

/// Service for handling file uploads and downloads
abstract class FileUploadService {
  /// Upload file to API with specified type
  Future<FileUploadDto> uploadFile({
    required File file,
    required FileType type,
    Function(double)? onProgress,
  });

  /// Download file from API using encrypted path
  Future<File> downloadFile(
    String encryptedPath, {
    Function(double)? onProgress,
  });

  /// Delete file from API using path
  Future<void> deleteFile(String path);

  /// Compress image before upload
  Future<File> compressImage(File file, {int quality = 85});

  /// Legacy method for backward compatibility - upload invoice
  @Deprecated('Use uploadFile with FileType.invoice instead')
  Future<String> uploadInvoice(
    File file, {
    int? expenseId,
    Function(double)? onProgress,
  });

  /// Legacy method for backward compatibility - download invoice
  @Deprecated('Use downloadFile instead')
  Future<File> downloadInvoice(
    String invoicePath, {
    Function(double)? onProgress,
  });

  /// Legacy method for backward compatibility - delete invoice
  @Deprecated('Use deleteFile instead')
  Future<void> deleteInvoice(String invoicePath);
}

class FileUploadServiceImpl implements FileUploadService {
  final ApiClient apiClient;
  static const int _maxImageSize = 2 * 1024 * 1024; // 2MB
  static const int _compressionQuality = 85;

  FileUploadServiceImpl({required this.apiClient});

  @override
  Future<FileUploadDto> uploadFile({
    required File file,
    required FileType type,
    Function(double)? onProgress,
  }) async {
    try {
      // Compress image if it's an image file
      final fileToUpload = await _shouldCompress(file) 
          ? await compressImage(file) 
          : file;

      // Prepare form data with type field
      final fields = <String, String>{
        'type': type.value,
      };

      // Upload file to /files/upload endpoint
      final response = await apiClient.uploadFile(
        '/files/upload',
        fileToUpload,
        fields: fields,
        fileFieldName: 'file',
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
          return FileUploadDto.fromJson(data);
        } else {
          throw ApiException(
            message: responseData['message'] as String? ?? 'Upload failed',
            statusCode: response.statusCode ?? 500,
          );
        }
      } else {
        throw ApiException(
          message: 'Failed to upload file',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to upload file: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Check if file should be compressed (only images)
  Future<bool> _shouldCompress(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  @override
  @Deprecated('Use uploadFile with FileType.invoice instead')
  Future<String> uploadInvoice(
    File file, {
    int? expenseId,
    Function(double)? onProgress,
  }) async {
    try {
      // Compress image if needed
      final compressedFile = await compressImage(file);

      // Prepare additional fields
      final fields = <String, String>{};
      if (expenseId != null) {
        fields['expense_id'] = expenseId.toString();
      }

      // Upload file to old endpoint
      final response = await apiClient.uploadFile(
        '/expenses/invoices/upload',
        compressedFile,
        fields: fields,
        fileFieldName: 'invoice',
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final invoicePath = data['invoice_path'] as String?;
        
        if (invoicePath == null) {
          throw ApiException(
            message: 'Invoice path not returned from server',
            statusCode: response.statusCode ?? 500,
          );
        }
        
        return invoicePath;
      } else {
        throw ApiException(
          message: 'Failed to upload invoice',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to upload invoice: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<File> downloadFile(
    String encryptedPath, {
    Function(double)? onProgress,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'download_${DateTime.now().millisecondsSinceEpoch}';
      final savePath = '${tempDir.path}/$fileName';

      // Download file using encrypted path as query parameter
      if (apiClient is DioApiClient) {
        final downloadUrl = '/files/download?path=${Uri.encodeComponent(encryptedPath)}';
        
        await (apiClient as DioApiClient).downloadFile(
          downloadUrl,
          savePath,
          onProgress: (received, total) {
            if (onProgress != null && total > 0) {
              onProgress(received / total);
            }
          },
        );
      } else {
        throw ApiException(
          message: 'Download not supported by current API client',
          statusCode: 500,
        );
      }

      return File(savePath);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to download file: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  @Deprecated('Use downloadFile instead')
  Future<File> downloadInvoice(
    String invoicePath, {
    Function(double)? onProgress,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = invoicePath.split('/').last;
      final savePath = '${tempDir.path}/$fileName';

      // Download file from old endpoint
      if (apiClient is DioApiClient) {
        await (apiClient as DioApiClient).downloadFile(
          '/expenses/invoices/download',
          savePath,
          onProgress: (received, total) {
            if (onProgress != null && total > 0) {
              onProgress(received / total);
            }
          },
        );
      } else {
        throw ApiException(
          message: 'Download not supported by current API client',
          statusCode: 500,
        );
      }

      return File(savePath);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to download invoice: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      // Use DELETE /files with path in request body
      final response = await apiClient.delete(
        '/files',
        queryParams: {'path': path},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final responseData = response.data as Map<String, dynamic>?;
        final message = responseData?['message'] as String? ?? 'Failed to delete file';
        
        throw ApiException(
          message: message,
          statusCode: response.statusCode ?? 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete file: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  @Deprecated('Use deleteFile instead')
  Future<void> deleteInvoice(String invoicePath) async {
    try {
      final response = await apiClient.delete(
        '/expenses/invoices/delete',
        queryParams: {'invoice_path': invoicePath},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          message: 'Failed to delete invoice',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to delete invoice: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<File> compressImage(File file, {int quality = _compressionQuality}) async {
    try {
      // Check file size
      final fileSize = await file.length();
      
      // If file is already small enough, return original
      if (fileSize <= _maxImageSize) {
        return file;
      }

      // Read and decode image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        // If decoding fails, return original
        return file;
      }

      // Get temporary directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress image
      final compressedBytes = img.encodeJpg(image, quality: quality);
      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      // Check if compressed file is still too large
      final compressedSize = await compressedFile.length();
      if (compressedSize > _maxImageSize && quality > 50) {
        // Try again with lower quality
        return compressImage(file, quality: quality - 15);
      }

      return compressedFile;
    } catch (e) {
      // If compression fails, return original file
      return file;
    }
  }

  /// Download file from server using invoice path
  /// Returns local file path where the file was saved
  Future<String?> downloadInvoiceByPath(
    String serverPath, {
    Function(double)? onProgress,
  }) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = serverPath.split('/').last;
      final savePath = '${tempDir.path}/invoices/$fileName';
      
      // Create invoices directory if it doesn't exist
      final invoicesDir = Directory('${tempDir.path}/invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }
      
      // Check if file already exists locally
      final localFile = File(savePath);
      if (await localFile.exists()) {
        print('[FileUploadService] File already exists locally: $savePath');
        return savePath;
      }
      
      // Construct download URL based on server path
      // Handle both old and new path formats:
      // OLD: "invoices/filename.jpg"
      // NEW: "public/invoices/filename.jpg"
      
      String downloadPath = serverPath;
      String filename = serverPath.split('/').last;
      
      // Remove 'public/' prefix if present
      if (downloadPath.startsWith('public/invoices/')) {
        downloadPath = downloadPath.substring(7); // Remove 'public/' → 'invoices/filename.jpg'
      } else if (downloadPath.startsWith('public/')) {
        downloadPath = downloadPath.substring(7); // Remove 'public/'
      }
      
      // Ensure path starts with 'invoices/'
      if (!downloadPath.startsWith('invoices/')) {
        downloadPath = 'invoices/$filename';
      }
      
      // Laravel public storage symlink URL
      // Files accessible at: /storage/invoices/filename.jpg
      final downloadUrl = '/storage/$downloadPath';
      
      print('[FileUploadService] 📥 Server path: $serverPath');
      print('[FileUploadService] 📥 Download URL: $downloadUrl');
      
      if (apiClient is DioApiClient) {
        try {
          await (apiClient as DioApiClient).downloadFile(
            downloadUrl,
            savePath,
            onProgress: (received, total) {
              if (onProgress != null && total > 0) {
                onProgress(received / total);
              }
            },
          );
          
          print('[FileUploadService] ✅ Downloaded invoice to: $savePath');
          return savePath;
        } catch (e) {
          print('[FileUploadService] ⚠️ Strategy 1 failed, trying alternative...');
          
          // Strategy 2: Try authenticated download endpoint
          // If backend has: GET /api/v1/invoices/download/{filename}
          try {
            final filename = serverPath.split('/').last;
            final altUrl = '/invoices/download/$filename';
            
            await (apiClient as DioApiClient).downloadFile(
              altUrl,
              savePath,
              onProgress: (received, total) {
                if (onProgress != null && total > 0) {
                  onProgress(received / total);
                }
              },
            );
            
            print('[FileUploadService] ✅ Downloaded via authenticated endpoint');
            return savePath;
          } catch (e2) {
            print('[FileUploadService] ❌ All download strategies failed');
            rethrow;
          }
        }
      } else {
        throw ApiException(
          message: 'Download not supported by current API client',
          statusCode: 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      print('[FileUploadService] ❌ Failed to download invoice: $e');
      return null;
    }
  }

  /// Get file size in MB
  Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Validate image file
  Future<bool> isValidImage(File file) async {
    try {
      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        return false;
      }

      // Check file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
