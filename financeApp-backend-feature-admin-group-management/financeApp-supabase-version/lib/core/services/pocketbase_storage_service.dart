import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../error/failures.dart';
import '../utils/image_compression.dart';
import 'storage_service.dart';

/// PocketBase implementation of StorageService
/// Handles invoice image uploads to PocketBase 'invoice_files' collection
class PocketBaseStorageService implements StorageService {
  final PocketBase _pb;
  final Connectivity _connectivity;

  PocketBaseStorageService({
    required PocketBase pb,
    required Connectivity connectivity,
  })  : _pb = pb,
        _connectivity = connectivity;

  @override
  Future<Either<Failure, String>> uploadInvoiceImage({
    required String localPath,
    required int userId,
    required int expenseId,
  }) async {
    try {
      // Check connectivity
      if (!await isOnline()) {
        return const Left(NetworkFailure('No internet connection'));
      }

      // Verify file exists
      final file = File(localPath);
      if (!await file.exists()) {
        return const Left(StorageFailure('File not found'));
      }

      // Compress image before upload
      final compressedFile = await ImageCompression.compressImage(file);

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'invoice_${expenseId}_$timestamp.jpg';

      // Create form data for PocketBase
      final formData = <String, dynamic>{
        'user_id': userId.toString(),
        'expense_id': expenseId.toString(),
        'file': await http.MultipartFile.fromPath(
          'file',
          compressedFile.path,
          filename: filename,
        ),
      };

      // Upload to PocketBase 'invoice_files' collection
      final record = await _pb.collection('invoice_files').create(body: formData);

      // Clean up temporary compressed file
      try {
        await compressedFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      // Return the record ID as the file identifier
      return Right(record.id);
    } on ClientException catch (e) {
      return Left(NetworkFailure('Network error: ${e.toString()}'));
    } catch (e) {
      return Left(StorageFailure('Upload failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> getInvoiceImageUrl(String fileId) async {
    try {
      // Check connectivity
      if (!await isOnline()) {
        return const Left(NetworkFailure('No internet connection'));
      }

      // Fetch the record from PocketBase
      final record = await _pb.collection('invoice_files').getOne(fileId);

      // Get the filename from the record
      final fileName = record.data['file'] as String?;
      if (fileName == null || fileName.isEmpty) {
        return const Left(StorageFailure('File not found in record'));
      }

      // Generate PocketBase file URL
      final url = _pb.files.getUrl(record, fileName);

      return Right(url.toString());
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return const Left(NotFoundFailure('File not found'));
      }
      return Left(NetworkFailure('Network error: ${e.toString()}'));
    } catch (e) {
      return Left(StorageFailure('Failed to get image URL: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, File>> downloadInvoiceImage(String fileId) async {
    try {
      // Check connectivity
      if (!await isOnline()) {
        return const Left(NetworkFailure('No internet connection'));
      }

      // Get the image URL
      final urlResult = await getInvoiceImageUrl(fileId);
      if (urlResult.isLeft()) {
        return Left(urlResult.fold((l) => l, (r) => throw Exception()));
      }

      final url = urlResult.getOrElse(() => throw Exception());

      // Download the image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return Left(NetworkFailure('Download failed with status: ${response.statusCode}'));
      }

      // Save to cache directory
      final cacheDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cachedFile = File('${cacheDir.path}/invoice_${fileId}_$timestamp.jpg');
      await cachedFile.writeAsBytes(response.bodyBytes);

      return Right(cachedFile);
    } on ClientException catch (e) {
      return Left(NetworkFailure('Network error: ${e.toString()}'));
    } catch (e) {
      return Left(StorageFailure('Download failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoiceImage(String fileId) async {
    try {
      // Check connectivity
      if (!await isOnline()) {
        return const Left(NetworkFailure('No internet connection'));
      }

      // Delete the record from PocketBase
      // This will also delete the associated file
      await _pb.collection('invoice_files').delete(fileId);

      return const Right(null);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        // File already deleted or doesn't exist
        return const Right(null);
      }
      return Left(NetworkFailure('Network error: ${e.toString()}'));
    } catch (e) {
      return Left(StorageFailure('Delete failed: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Check if any connectivity is available
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      return true;
    } catch (e) {
      // If connectivity check fails, assume offline
      return false;
    }
  }
}
