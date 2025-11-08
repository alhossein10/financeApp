import 'package:equatable/equatable.dart';

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

class Expense extends Equatable {
  final int? id;
  final int userId;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final InvoiceStatus invoiceStatus;
  final String? invoiceFilePath;
  final String? invoiceCloudFileId;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;
  final int syncRetryCount;
  final String? syncErrorMessage;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? creatorUsername;
  final String? creatorEmail;

  const Expense({
    this.id,
    required this.userId,
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
    this.creatorUsername,
    this.creatorEmail,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        description,
        priceUsd,
        priceSyp,
        priceTry,
        invoiceStatus,
        invoiceFilePath,
        invoiceCloudFileId,
        syncStatus,
        syncedAt,
        syncRetryCount,
        syncErrorMessage,
        expenseDate,
        createdAt,
        updatedAt,
        creatorUsername,
        creatorEmail,
      ];
}
