import '../../../../core/utils/date_formatter.dart';

/// Data Transfer Object for Exchange entity
/// Used for API communication with Laravel backend
class ExchangeDto {
  final int? id;
  final int? transferId;
  final double convertedAmountSyp;
  final double exchangeRateUsdToSyp;
  final DateTime exchangeDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExchangeDto({
    this.id,
    this.transferId,
    required this.convertedAmountSyp,
    required this.exchangeRateUsdToSyp,
    required this.exchangeDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Create DTO from JSON response
  /// Supports both API response formats:
  /// - New format: amount_usd, exchange_rate, target_currency, amount_syp, amount_try
  /// - Old format: converted_amount_syp, exchange_rate_usd_to_syp
  factory ExchangeDto.fromJson(Map<String, dynamic> json) {
    // Try new API format first (amount_usd, exchange_rate, target_currency, amount_syp, amount_try)
    final amountUsd = _parseDouble(json['amount_usd']);
    final exchangeRate = _parseDouble(json['exchange_rate']);
    final targetCurrency = json['target_currency'] as String?;
    final amountSyp = _parseDouble(json['amount_syp']);
    final amountTry = _parseDouble(json['amount_try']);
    
    // Use new format if available, otherwise fall back to old format
    double convertedAmountSyp = 0.0;
    double exchangeRateUsdToSyp = 0.0;
    
    if (amountUsd != null && exchangeRate != null) {
      // New format
      exchangeRateUsdToSyp = exchangeRate!;
      if (targetCurrency == 'SYP' && amountSyp != null) {
        convertedAmountSyp = amountSyp!;
      } else if (targetCurrency == 'TRY' && amountTry != null) {
        // For TRY, we still use convertedAmountSyp field but it represents TRY amount
        // This is a limitation of the current ExchangeDto structure
        convertedAmountSyp = amountTry!;
      } else {
        // Calculate converted amount from USD amount and rate
        convertedAmountSyp = amountUsd! * exchangeRate!;
      }
    } else {
      // Old format
      convertedAmountSyp = _parseDouble(json['converted_amount_syp']) ?? 0.0;
      exchangeRateUsdToSyp = _parseDouble(json['exchange_rate_usd_to_syp']) ?? 0.0;
    }
    
    return ExchangeDto(
      id: json['id'] as int?,
      transferId: json['transfer_id'] as int?,
      convertedAmountSyp: convertedAmountSyp,
      exchangeRateUsdToSyp: exchangeRateUsdToSyp,
      exchangeDate: DateFormatter.fromApiTimestampNullable(json['exchange_date'] as String?) ?? DateTime.now(),
      createdAt: DateFormatter.fromApiTimestampNullable(json['created_at'] as String?),
      updatedAt: DateFormatter.fromApiTimestampNullable(json['updated_at'] as String?),
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
      if (transferId != null) 'transfer_id': transferId,
      'converted_amount_syp': convertedAmountSyp,
      'exchange_rate_usd_to_syp': exchangeRateUsdToSyp,
      'exchange_date': DateFormatter.toApiTimestamp(exchangeDate),
    };
  }

  ExchangeDto copyWith({
    int? id,
    int? transferId,
    double? convertedAmountSyp,
    double? exchangeRateUsdToSyp,
    DateTime? exchangeDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExchangeDto(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      convertedAmountSyp: convertedAmountSyp ?? this.convertedAmountSyp,
      exchangeRateUsdToSyp: exchangeRateUsdToSyp ?? this.exchangeRateUsdToSyp,
      exchangeDate: exchangeDate ?? this.exchangeDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
