import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';
import '../config/pocketbase_config.dart';

/// Service for syncing expenses to PocketBase
class PocketBaseSyncService {
  final PocketBaseService _pbService = PocketBaseService();
  
  /// Sync expense to PocketBase
  /// Returns the PocketBase record ID if successful, null otherwise
  Future<String?> syncExpense({
    required int expenseId,
    required String description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    required int invoiceStatus,
    required DateTime expenseDate,
    File? invoiceImage,
  }) async {
    try {
      final pb = _pbService.pb;
      
      if (!_pbService.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      // Prepare expense data
      final body = {
        'user_id': _pbService.currentUserId!,
        'expense_id': expenseId,
        'description': description,
        'price_usd': priceUsd,
        'price_syp': priceSyp,
        'price_try': priceTry,
        'invoice_status': invoiceStatus,
        'expense_date': expenseDate.toIso8601String(),
        'sync_status': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
      };
      
      // Create expense record
      final record = await pb
          .collection(PocketBaseConfig.expensesCollection)
          .create(body: body);
      
      // Upload invoice image if provided
      if (invoiceImage != null && await invoiceImage.exists()) {
        await _uploadInvoiceImage(record.id, invoiceImage);
      }
      
      return record.id;
    } catch (e) {
      print('Sync error: $e');
      return null;
    }
  }
  
  /// Upload invoice image to existing expense record
  Future<void> _uploadInvoiceImage(String recordId, File imageFile) async {
    try {
      final pb = _pbService.pb;
      final bytes = await imageFile.readAsBytes();
      
      final formData = http.MultipartFile.fromBytes(
        'invoice_image',
        bytes,
        filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      await pb
          .collection(PocketBaseConfig.expensesCollection)
          .update(recordId, body: {}, files: [formData]);
    } catch (e) {
      print('Image upload error: $e');
      rethrow;
    }
  }
  
  /// Fetch all expenses (admin only)
  Future<List<RecordModel>> fetchAllExpenses() async {
    try {
      if (!_pbService.isAdmin) {
        throw Exception('Only admins can fetch all expenses');
      }
      
      final records = await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .getFullList(
            sort: '-created',
            expand: 'user_id',
          );
      
      return records;
    } catch (e) {
      print('Fetch all expenses error: $e');
      return [];
    }
  }
  
  /// Fetch current user's expenses
  Future<List<RecordModel>> fetchMyExpenses() async {
    try {
      if (!_pbService.isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      final records = await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .getFullList(
            filter: 'user_id = "${_pbService.currentUserId}"',
            sort: '-created',
          );
      
      return records;
    } catch (e) {
      print('Fetch my expenses error: $e');
      return [];
    }
  }
  
  /// Get expense by ID
  Future<RecordModel?> getExpenseById(String recordId) async {
    try {
      return await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .getOne(recordId, expand: 'user_id');
    } catch (e) {
      print('Get expense error: $e');
      return null;
    }
  }
  
  /// Get invoice image URL from record
  String getImageUrl(RecordModel record) {
    final imageField = record.data['invoice_image'];
    
    if (imageField == null || imageField == '') {
      return '';
    }
    
    return _pbService.pb.files.getUrl(record, imageField).toString();
  }
  
  /// Check if expense has an image
  bool hasImage(RecordModel record) {
    final imageField = record.data['invoice_image'];
    return imageField != null && imageField != '';
  }
  
  /// Subscribe to real-time expense updates (optional feature)
  Future<void> subscribeToExpenses(
    Function(RecordSubscriptionEvent) callback,
  ) async {
    try {
      await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .subscribe('*', callback);
    } catch (e) {
      print('Subscribe error: $e');
    }
  }
  
  /// Unsubscribe from real-time updates
  Future<void> unsubscribeFromExpenses() async {
    try {
      await _pbService.pb
          .collection(PocketBaseConfig.expensesCollection)
          .unsubscribe();
    } catch (e) {
      print('Unsubscribe error: $e');
    }
  }
}
