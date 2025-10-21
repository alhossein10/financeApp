import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    super.id,
    required super.userId,
    required super.description,
    super.priceUsd,
    super.priceSyp,
    super.priceTry,
    required super.invoiceStatus,
    super.invoiceFilePath,
    super.invoiceCloudFileId,
    super.syncStatus = SyncStatus.pending,
    super.syncedAt,
    super.syncRetryCount = 0,
    super.syncErrorMessage,
    required super.expenseDate,
    required super.createdAt,
    super.updatedAt,
    super.creatorUsername,
    super.creatorEmail,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      description: (map['description'] as String?) ?? '',
      priceUsd: (map['price_usd'] as num?)?.toDouble(),
      priceSyp: (map['price_syp'] as num?)?.toDouble(),
      priceTry: (map['price_try'] as num?)?.toDouble(),
      invoiceStatus: InvoiceStatus.values[(map['invoice_status'] as int?) ?? 1],
      invoiceFilePath: map['invoice_file_path'] as String?,
      invoiceCloudFileId: map['invoice_cloud_file_id'] as String?,
      syncStatus: SyncStatus.values[(map['sync_status'] as int?) ?? 0],
      syncedAt: (map['synced_at'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(map['synced_at'] as int)
          : null,
      syncRetryCount: (map['sync_retry_count'] as int?) ?? 0,
      syncErrorMessage: map['sync_error_message'] as String?,
      expenseDate: DateTime.fromMillisecondsSinceEpoch(
        (map['expense_date'] as int?) ?? (map['created_at'] as int?) ?? 0,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? 0,
      ),
      updatedAt: (map['updated_at'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      creatorUsername: map['creator_username'] as String?,
      creatorEmail: map['creator_email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'price_usd': priceUsd,
      'price_syp': priceSyp,
      'price_try': priceTry,
      'invoice_status': invoiceStatus.index,
      'invoice_file_path': invoiceFilePath,
      'invoice_cloud_file_id': invoiceCloudFileId,
      'sync_status': syncStatus.index,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
      'sync_retry_count': syncRetryCount,
      'sync_error_message': syncErrorMessage,
      'expense_date': expenseDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'creator_username': creatorUsername,
      'creator_email': creatorEmail,
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      description: expense.description,
      priceUsd: expense.priceUsd,
      priceSyp: expense.priceSyp,
      priceTry: expense.priceTry,
      invoiceStatus: expense.invoiceStatus,
      invoiceFilePath: expense.invoiceFilePath,
      invoiceCloudFileId: expense.invoiceCloudFileId,
      syncStatus: expense.syncStatus,
      syncedAt: expense.syncedAt,
      syncRetryCount: expense.syncRetryCount,
      syncErrorMessage: expense.syncErrorMessage,
      expenseDate: expense.expenseDate,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      creatorUsername: expense.creatorUsername,
      creatorEmail: expense.creatorEmail,
    );
  }

  ExpenseModel copyWith({
    int? id,
    int? userId,
    String? description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    InvoiceStatus? invoiceStatus,
    String? invoiceFilePath,
    String? invoiceCloudFileId,
    SyncStatus? syncStatus,
    DateTime? syncedAt,
    int? syncRetryCount,
    String? syncErrorMessage,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorUsername,
    String? creatorEmail,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      priceUsd: priceUsd ?? this.priceUsd,
      priceSyp: priceSyp ?? this.priceSyp,
      priceTry: priceTry ?? this.priceTry,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      invoiceFilePath: invoiceFilePath ?? this.invoiceFilePath,
      invoiceCloudFileId: invoiceCloudFileId ?? this.invoiceCloudFileId,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorEmail: creatorEmail ?? this.creatorEmail,
    );
  }
}
