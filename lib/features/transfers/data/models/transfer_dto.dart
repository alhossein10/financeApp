import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transfer.dart';
import 'exchange_dto.dart';

/// Data Transfer Object for Transfer entity
/// Used for API communication with Laravel backend
/// 
/// API Field Mappings:
/// - recipientName -> recipient_name
/// - amountUsd -> amount_usd
/// - transferDate -> transfer_date (YYYY-MM-DD format)
/// - notes -> notes
class TransferDto {
  final int? id;
  final int? userId;
  final int? recipientUserId; // ID of the user who receives the transfer
  final int? adminGroupId; // Admin group ID for the transfer (should be set from recipient's admin_group_id for SuperAdmin transfers)
  final String recipientName;
  final double amountUsd;
  final String transferDate; // YYYY-MM-DD format
  final String? notes;
  final ExchangeDto? exchange;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransferDto({
    this.id,
    this.userId,
    this.recipientUserId,
    this.adminGroupId,
    required this.recipientName,
    required this.amountUsd,
    required this.transferDate,
    this.notes,
    this.exchange,
    this.createdAt,
    this.updatedAt,
  });

  /// Create DTO from JSON response
  factory TransferDto.fromJson(Map<String, dynamic> json) {
    // Parse transfer_date - handle both YYYY-MM-DD and timestamp formats
    String transferDateStr = (json['transfer_date'] as String?) ?? DateFormatter.toApiDate(DateTime.now());
    // If it's a timestamp (contains 'T'), extract just the date part
    if (transferDateStr.contains('T')) {
      transferDateStr = transferDateStr.split('T')[0];
    }
    
    return TransferDto(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      recipientUserId: json['recipient_user_id'] as int?,
      adminGroupId: json['admin_group_id'] as int?,
      recipientName: (json['recipient_name'] as String?) ?? '',
      amountUsd: _parseDouble(json['amount_usd']) ?? 0.0,
      transferDate: transferDateStr,
      notes: json['notes'] as String?,
      exchange: json['exchange'] != null
          ? ExchangeDto.fromJson(json['exchange'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateFormatter.fromApiTimestamp(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateFormatter.fromApiTimestamp(json['updated_at'] as String)
          : null,
    );
  }

  /// Helper method to parse double from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Convert DTO to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (recipientUserId != null) 'recipient_user_id': recipientUserId,
      if (adminGroupId != null) 'admin_group_id': adminGroupId, // Send admin_group_id for SuperAdmin transfers
      'recipient_name': recipientName,
      'amount_usd': amountUsd,
      'transfer_date': transferDate, // Already in YYYY-MM-DD format
      if (notes != null) 'notes': notes,
      if (exchange != null) 'exchange': exchange!.toJson(),
    };
  }

  /// Convert DTO to domain entity
  Transfer toEntity() {
    // Parse date string to DateTime
    final parsedDate = DateFormatter.fromApiDate(transferDate);
    
    return Transfer(
      id: id,
      userId: userId ?? 0,
      recipientUserId: recipientUserId,
      recipientName: recipientName,
      amountUsd: amountUsd,
      convertedAmountUsd: exchange?.convertedAmountSyp,
      amountSypAtExchange: exchange?.convertedAmountSyp,
      manualUsdToSypRate: exchange?.exchangeRateUsdToSyp,
      transactionDate: parsedDate,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Create DTO from domain entity
  factory TransferDto.fromEntity(Transfer transfer) {
    ExchangeDto? exchangeDto;
    if (transfer.convertedAmountUsd != null &&
        transfer.manualUsdToSypRate != null) {
      exchangeDto = ExchangeDto(
        id: null,
        transferId: transfer.id,
        convertedAmountSyp: transfer.convertedAmountUsd!,
        exchangeRateUsdToSyp: transfer.manualUsdToSypRate!,
        exchangeDate: transfer.transactionDate,
      );
    }

    return TransferDto(
      id: transfer.id,
      userId: transfer.userId,
      recipientUserId: transfer.recipientUserId,
      recipientName: transfer.recipientName,
      amountUsd: transfer.amountUsd,
      transferDate: DateFormatter.toApiDate(transfer.transactionDate),
      notes: null,
      exchange: exchangeDto,
      createdAt: transfer.createdAt,
      updatedAt: transfer.updatedAt,
    );
  }

  TransferDto copyWith({
    int? id,
    int? userId,
    int? recipientUserId,
    int? adminGroupId,
    String? recipientName,
    double? amountUsd,
    String? transferDate,
    String? notes,
    ExchangeDto? exchange,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      adminGroupId: adminGroupId ?? this.adminGroupId,
      recipientName: recipientName ?? this.recipientName,
      amountUsd: amountUsd ?? this.amountUsd,
      transferDate: transferDate ?? this.transferDate,
      notes: notes ?? this.notes,
      exchange: exchange ?? this.exchange,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Response wrapper for list of transfers with pagination
class TransferListResponse {
  final List<TransferDto> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const TransferListResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory TransferListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final transfers = dataList
        .map((item) => TransferDto.fromJson(item as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return TransferListResponse(
      data: transfers,
      currentPage: (meta['current_page'] as int?) ?? 1,
      lastPage: (meta['last_page'] as int?) ?? 1,
      perPage: (meta['per_page'] as int?) ?? 15,
      total: (meta['total'] as int?) ?? 0,
    );
  }
}
