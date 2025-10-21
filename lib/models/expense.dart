enum InvoiceStatus { invoiceAvailable, noInvoice }

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;

  bool get isPending => this == SyncStatus.pending;
  bool get isSyncing => this == SyncStatus.syncing;
  bool get isSynced => this == SyncStatus.synced;
  bool get isFailed => this == SyncStatus.failed;
}

class ExpenseRecord {
  final int? id;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final InvoiceStatus invoiceStatus;
  final String? invoiceFilePath; // optional local file path
  final String? invoiceCloudFileId; // Supabase file record ID
  final SyncStatus syncStatus;
  final DateTime? syncedAt;
  final int syncRetryCount;
  final String? syncErrorMessage;
  final DateTime expenseDate; // the date of the expense
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExpenseRecord({
    this.id,
    required this.description,
    this.priceUsd,
    this.priceSyp,
    this.priceTry,
    required this.invoiceStatus,
    this.invoiceFilePath,
    this.invoiceCloudFileId,
    this.syncStatus = SyncStatus.pending,
    this.syncedAt,
    this.syncRetryCount = 0,
    this.syncErrorMessage,
    required this.expenseDate,
    required this.createdAt,
    this.updatedAt,
  });

  ExpenseRecord copyWith({
    int? id,
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
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
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
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
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
    };
  }

  factory ExpenseRecord.fromMap(Map<String, Object?> map) {
    return ExpenseRecord(
      id: map['id'] as int?,
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
    );
  }
}


