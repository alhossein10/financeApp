import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/expense.dart';
import 'expense_model.dart';

/// Data Transfer Object for Expense API communication
/// Handles JSON serialization/deserialization for Laravel API
class ExpenseDto {
  final int? id;
  final int? userId;
  final String? description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final bool hasInvoice;
  final String? invoicePath;
  final String expenseDate; // YYYY-MM-DD format
  final String? syncStatus;
  final DateTime? syncedAt;
  final int? syncRetryCount;
  final String? syncErrorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? user;

  // Fields for create/update requests
  final double? amount;
  final String? category;
  final String? paymentMethod;

  const ExpenseDto({
    this.id,
    this.userId,
    this.description,
    this.priceUsd,
    this.priceSyp,
    this.priceTry,
    this.hasInvoice = false,
    this.invoicePath,
    required this.expenseDate,
    this.syncStatus,
    this.syncedAt,
    this.syncRetryCount,
    this.syncErrorMessage,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.user,
    this.amount,
    this.category,
    this.paymentMethod,
  });

  /// Validate expense data before sending to API
  void validate() {
    // Basic validation - ensure we have required fields
    if (description == null || description!.isEmpty) {
      throw ArgumentError('Description is required');
    }
    
    // Ensure at least one price is provided
    if (priceUsd == null && priceSyp == null && priceTry == null) {
      throw ArgumentError('At least one price (USD, SYP, or TRY) must be provided');
    }
  }

  /// Create DTO from JSON response from Laravel API
  factory ExpenseDto.fromJson(Map<String, dynamic> json) {
    // Parse expense_date - handle both YYYY-MM-DD and ISO 8601 formats
    String expenseDateStr = json['expense_date'] as String? ?? DateFormatter.toApiDate(DateTime.now());
    if (expenseDateStr.contains('T')) {
      // ISO 8601 format - extract just the date part
      expenseDateStr = expenseDateStr.split('T')[0];
    }
    
    return ExpenseDto(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      description: json['description'] as String?,
      priceUsd: _parseDouble(json['price_usd']),
      priceSyp: _parseDouble(json['price_syp']),
      priceTry: _parseDouble(json['price_try']),
      hasInvoice: json['has_invoice'] as bool? ?? false,
      invoicePath: json['invoice_path'] as String?,
      expenseDate: expenseDateStr,
      syncStatus: json['sync_status'] as String?,
      syncedAt: DateFormatter.fromApiTimestampNullable(json['synced_at'] as String?),
      syncRetryCount: json['sync_retry_count'] as int?,
      syncErrorMessage: json['sync_error_message'] as String?,
      createdAt: DateFormatter.fromApiTimestampNullable(json['created_at'] as String?),
      updatedAt: DateFormatter.fromApiTimestampNullable(json['updated_at'] as String?),
      deletedAt: DateFormatter.fromApiTimestampNullable(json['deleted_at'] as String?),
      user: json['user'] as Map<String, dynamic>?,
      amount: _parseDouble(json['amount']),
      category: json['category'] as String?,
      paymentMethod: json['payment_method'] as String?,
    );
  }

  /// Convert DTO to JSON for API requests (create/update)
  /// Note: For photo uploads, use toFormData() instead
  Map<String, dynamic> toJson() {
    // Only send fields that the backend expects
    return {
      if (description != null) 'description': description,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (priceSyp != null) 'price_syp': priceSyp,
      if (priceTry != null) 'price_try': priceTry,
      'expense_date': expenseDate,
    };
  }
  
  /// Convert DTO to form data for API requests with file uploads
  /// Returns Map<String, String> as required by multipart/form-data
  Map<String, String> toFormData() {
    // Only send fields that the backend expects
    return {
      if (description != null) 'description': description!,
      if (priceUsd != null) 'price_usd': priceUsd.toString(),
      if (priceSyp != null) 'price_syp': priceSyp.toString(),
      if (priceTry != null) 'price_try': priceTry.toString(),
      'expense_date': expenseDate,
    };
  }

  /// Convert DTO to domain entity (ExpenseModel)
  ExpenseModel toEntity() {
    // Determine invoice status
    InvoiceStatus invoiceStatus = hasInvoice 
        ? InvoiceStatus.invoiceAvailable 
        : InvoiceStatus.noInvoice;
    
    // Parse sync status
    SyncStatus parsedSyncStatus = SyncStatus.synced;
    if (syncStatus != null) {
      switch (syncStatus!.toLowerCase()) {
        case 'pending':
          parsedSyncStatus = SyncStatus.pending;
          break;
        case 'synced':
          parsedSyncStatus = SyncStatus.synced;
          break;
        case 'failed':
          parsedSyncStatus = SyncStatus.failed;
          break;
        default:
          parsedSyncStatus = SyncStatus.synced;
      }
    }
    
    // Extract user info if available
    String? creatorUsername;
    String? creatorEmail;
    if (user != null) {
      creatorUsername = user!['name'] as String?;
      creatorEmail = user!['email'] as String?;
    }
    
    // Determine if invoice_path is a server path or local path
    // Server paths start with "public/", "invoices/", or "storage/"
    // Local paths start with "/" or contain device-specific paths
    String? localFilePath;
    String? cloudFileId;
    
    if (invoicePath != null && invoicePath!.isNotEmpty) {
      if (invoicePath!.startsWith('public/') || 
          invoicePath!.startsWith('invoices/') || 
          invoicePath!.startsWith('storage/')) {
        // This is a server path, store as cloud file ID
        cloudFileId = invoicePath;
        localFilePath = null; // Will need to download
      } else {
        // This is a local path
        localFilePath = invoicePath;
        cloudFileId = null;
      }
    }
    
    return ExpenseModel(
      id: id,
      userId: userId ?? 0,
      description: description ?? '',
      priceUsd: priceUsd,
      priceSyp: priceSyp,
      priceTry: priceTry,
      invoiceStatus: invoiceStatus,
      invoiceFilePath: localFilePath,
      invoiceCloudFileId: cloudFileId,
      syncStatus: parsedSyncStatus,
      syncedAt: syncedAt,
      syncRetryCount: syncRetryCount ?? 0,
      syncErrorMessage: syncErrorMessage,
      expenseDate: DateFormatter.fromApiDate(expenseDate),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      creatorUsername: creatorUsername,
      creatorEmail: creatorEmail,
    );
  }

  /// Create DTO from domain entity for create/update requests
  factory ExpenseDto.fromEntity(Expense expense) {
    // Determine amount and category from the expense
    double? amount;
    String category = 'General';
    String paymentMethod = 'cash';
    
    // Prioritize non-null price fields
    if (expense.priceUsd != null && expense.priceUsd! > 0) {
      amount = expense.priceUsd;
      category = 'USD';
      paymentMethod = 'card';
    } else if (expense.priceSyp != null && expense.priceSyp! > 0) {
      amount = expense.priceSyp;
      category = 'SYP';
      paymentMethod = 'cash';
    } else if (expense.priceTry != null && expense.priceTry! > 0) {
      amount = expense.priceTry;
      category = 'TRY';
      paymentMethod = 'cash';
    }
    
    return ExpenseDto(
      id: expense.id,
      userId: expense.userId,
      description: expense.description,
      priceUsd: expense.priceUsd,
      priceSyp: expense.priceSyp,
      priceTry: expense.priceTry,
      expenseDate: DateFormatter.toApiDate(expense.expenseDate),
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }

  /// Helper method to parse double values from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  ExpenseDto copyWith({
    int? id,
    int? userId,
    String? description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    bool? hasInvoice,
    String? invoicePath,
    String? expenseDate,
    String? syncStatus,
    DateTime? syncedAt,
    int? syncRetryCount,
    String? syncErrorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    Map<String, dynamic>? user,
    double? amount,
    String? category,
    String? paymentMethod,
  }) {
    return ExpenseDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      priceUsd: priceUsd ?? this.priceUsd,
      priceSyp: priceSyp ?? this.priceSyp,
      priceTry: priceTry ?? this.priceTry,
      hasInvoice: hasInvoice ?? this.hasInvoice,
      invoicePath: invoicePath ?? this.invoicePath,
      expenseDate: expenseDate ?? this.expenseDate,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      user: user ?? this.user,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

/// Paginated response wrapper for expense list
class ExpenseListResponse {
  final List<ExpenseDto> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const ExpenseListResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>?;
    
    return ExpenseListResponse(
      data: dataList.map((item) => ExpenseDto.fromJson(item as Map<String, dynamic>)).toList(),
      currentPage: meta?['current_page'] as int? ?? json['current_page'] as int? ?? 1,
      lastPage: meta?['last_page'] as int? ?? json['last_page'] as int? ?? 1,
      perPage: meta?['per_page'] as int? ?? json['per_page'] as int? ?? 15,
      total: meta?['total'] as int? ?? json['total'] as int? ?? 0,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
