import 'dart:io';
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Abstract interface for cloud storage operations
/// Handles invoice image uploads, downloads, and management
abstract class StorageService {
  /// Upload an invoice image to cloud storage
  /// 
  /// Parameters:
  /// - [localPath]: Local file path of the image to upload
  /// - [userId]: ID of the user uploading the image
  /// - [expenseId]: ID of the expense associated with the image
  /// 
  /// Returns:
  /// - Right(fileId): Unique identifier for the uploaded file
  /// - Left(Failure): Error if upload fails
  Future<Either<Failure, String>> uploadInvoiceImage({
    required String localPath,
    required int userId,
    required int expenseId,
  });

  /// Get the URL for an invoice image
  /// 
  /// Parameters:
  /// - [fileId]: Unique identifier of the file
  /// 
  /// Returns:
  /// - Right(url): Public URL to access the image
  /// - Left(Failure): Error if retrieval fails
  Future<Either<Failure, String>> getInvoiceImageUrl(String fileId);

  /// Download an invoice image from cloud storage
  /// 
  /// Parameters:
  /// - [fileId]: Unique identifier of the file
  /// 
  /// Returns:
  /// - Right(File): Downloaded file object
  /// - Left(Failure): Error if download fails
  Future<Either<Failure, File>> downloadInvoiceImage(String fileId);

  /// Delete an invoice image from cloud storage
  /// 
  /// Parameters:
  /// - [fileId]: Unique identifier of the file to delete
  /// 
  /// Returns:
  /// - Right(void): Success
  /// - Left(Failure): Error if deletion fails
  Future<Either<Failure, void>> deleteInvoiceImage(String fileId);

  /// Check if the device has internet connectivity
  /// 
  /// Returns:
  /// - true if online
  /// - false if offline
  Future<bool> isOnline();
}
