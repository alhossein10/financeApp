import '../../../../core/utils/date_formatter.dart';
import '../../../transfers/data/models/transfer_dto.dart';
import '../../../../core/api/models/user_dto.dart';
import '../../domain/entities/exchange.dart';

/// Data Transfer Object for Exchange entity
/// Used for API communication with Laravel backend
/// 
/// Supports balance-based exchanges (optional transferId) and multi-currency (SYP/TRY)
/// API Field Mappings:
/// - id -> id
/// - transfer_id -> transfer_id (optional, can be null)
/// - target_currency -> target_currency ('SYP' or 'TRY')
/// - amount_usd -> amount_usd
/// - exchange_rate -> exchange_rate
/// - amount_syp -> amount_syp (only when targetCurrency is SYP)
/// - amount_try -> amount_try (only when targetCurrency is TRY)
/// - exchange_date -> exchange_date (YYYY-MM-DD format)
/// - notes -> notes
class ExchangeDto {
  final int? id;
  final int? transferId; // Optional - for balance-based exchanges
  final int? userId;
  final int? adminGroupId;
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double exchangeRate;
  final double? amountSyp; // Only set when targetCurrency is SYP
  final double? amountTry; // Only set when targetCurrency is TRY
  final String exchangeDate; // YYYY-MM-DD format
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TransferDto? transfer;
  final UserDto? user;

  const ExchangeDto({
    this.id,
    this.transferId,
    this.userId,
    this.adminGroupId,
    required this.targetCurrency,
    required this.amountUsd,
    required this.exchangeRate,
    this.amountSyp,
    this.amountTry,
    required this.exchangeDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.transfer,
    this.user,
  });

  /// Create DTO from JSON response
  /// Backend v3.1+ includes converted_amount in response
  factory ExchangeDto.fromJson(Map<String, dynamic> json) {
    // Parse exchange_date - handle both YYYY-MM-DD and timestamp formats
    String exchangeDateStr = (json['exchange_date'] as String?) ?? 
        DateFormatter.toApiDate(DateTime.now());
    // If it's a timestamp (contains 'T'), extract just the date part
    if (exchangeDateStr.contains('T')) {
      exchangeDateStr = exchangeDateStr.split('T')[0];
    }

    final targetCurrency = (json['target_currency'] as String?) ?? 'SYP'; // Default to SYP for backward compatibility
    final amountUsd = _parseDouble(json['amount_usd']) ?? 0.0;
    final exchangeRate = _parseDouble(json['exchange_rate']) ?? 0.0;
    
    // Backend v3.1+ sends converted_amount and amount_syp/amount_try
    // Prefer amount_syp/amount_try if available, otherwise use converted_amount
    // If neither is available, calculate from amount_usd * exchange_rate
    final convertedAmount = _parseDouble(json['converted_amount']);
    final amountSypRaw = _parseDouble(json['amount_syp']);
    final amountTryRaw = _parseDouble(json['amount_try']);
    
    double? amountSyp;
    double? amountTry;
    
    if (targetCurrency == 'SYP') {
      // For SYP: prefer amount_syp, then converted_amount, then calculate
      amountSyp = amountSypRaw ?? convertedAmount ?? (amountUsd * exchangeRate);
      amountTry = null;
    } else if (targetCurrency == 'TRY') {
      // For TRY: prefer amount_try, then converted_amount, then calculate
      amountTry = amountTryRaw ?? convertedAmount ?? (amountUsd * exchangeRate);
      amountSyp = null;
    }
    
    return ExchangeDto(
      id: json['id'] as int?,
      transferId: json['transfer_id'] as int?, // Can be null for balance-based exchanges
      userId: json['user_id'] as int?,
      adminGroupId: json['admin_group_id'] as int?,
      targetCurrency: targetCurrency,
      amountUsd: amountUsd,
      exchangeRate: exchangeRate,
      amountSyp: amountSyp,
      amountTry: amountTry,
      exchangeDate: exchangeDateStr,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateFormatter.fromApiTimestamp(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateFormatter.fromApiTimestamp(json['updated_at'] as String)
          : null,
      transfer: json['transfer'] != null
          ? TransferDto.fromJson(json['transfer'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
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
      if (transferId != null) 'transfer_id': transferId, // Optional
      'target_currency': targetCurrency,
      'amount_usd': amountUsd,
      'exchange_rate': exchangeRate,
      'exchange_date': exchangeDate, // Already in YYYY-MM-DD format
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  /// Convert DTO to domain entity
  Exchange toEntity() {
    return Exchange(
      id: id,
      transferId: transferId,
      userId: userId,
      adminGroupId: adminGroupId,
      targetCurrency: targetCurrency,
      amountUsd: amountUsd,
      exchangeRate: exchangeRate,
      amountSyp: amountSyp,
      amountTry: amountTry,
      exchangeDate: DateFormatter.fromApiDate(exchangeDate),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      recipientName: transfer?.recipientName,
      userName: user?.name,
    );
  }

  /// Create DTO from domain entity
  factory ExchangeDto.fromEntity(Exchange entity) {
    return ExchangeDto(
      id: entity.id,
      transferId: entity.transferId,
      userId: entity.userId,
      adminGroupId: entity.adminGroupId,
      targetCurrency: entity.targetCurrency,
      amountUsd: entity.amountUsd,
      exchangeRate: entity.exchangeRate,
      amountSyp: entity.amountSyp,
      amountTry: entity.amountTry,
      exchangeDate: DateFormatter.toApiDate(entity.exchangeDate),
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ExchangeDto copyWith({
    int? id,
    int? transferId,
    int? userId,
    int? adminGroupId,
    String? targetCurrency,
    double? amountUsd,
    double? exchangeRate,
    double? amountSyp,
    double? amountTry,
    String? exchangeDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    TransferDto? transfer,
    UserDto? user,
  }) {
    return ExchangeDto(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      userId: userId ?? this.userId,
      adminGroupId: adminGroupId ?? this.adminGroupId,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      amountUsd: amountUsd ?? this.amountUsd,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      amountSyp: amountSyp ?? this.amountSyp,
      amountTry: amountTry ?? this.amountTry,
      exchangeDate: exchangeDate ?? this.exchangeDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transfer: transfer ?? this.transfer,
      user: user ?? this.user,
    );
  }
}

/// Transfer Balance DTO
class TransferBalanceDto {
  final int transferId;
  final double originalAmount;
  final double totalExchanged;
  final double remainingBalance;
  final String recipientName;
  final String transferDate;

  const TransferBalanceDto({
    required this.transferId,
    required this.originalAmount,
    required this.totalExchanged,
    required this.remainingBalance,
    required this.recipientName,
    required this.transferDate,
  });

  factory TransferBalanceDto.fromJson(Map<String, dynamic> json) {
    return TransferBalanceDto(
      transferId: json['transfer_id'] as int? ?? 0,
      originalAmount: _parseDouble(json['original_amount']) ?? 0.0,
      totalExchanged: _parseDouble(json['total_exchanged']) ?? 0.0,
      remainingBalance: _parseDouble(json['remaining_balance']) ?? 0.0,
      recipientName: json['recipient_name'] as String? ?? '',
      transferDate: json['transfer_date'] as String? ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Convert DTO to domain entity
  TransferBalance toEntity() {
    return TransferBalance(
      transferId: transferId,
      originalAmount: originalAmount,
      totalExchanged: totalExchanged,
      remainingBalance: remainingBalance,
      recipientName: recipientName,
      transferDate: DateFormatter.fromApiDate(transferDate),
    );
  }
}

/// Response wrapper for list of exchanges
class ExchangeListResponse {
  final List<ExchangeDto> data;

  const ExchangeListResponse({required this.data});

  factory ExchangeListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final exchanges = dataList
        .map((item) => ExchangeDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return ExchangeListResponse(data: exchanges);
  }
}
