import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/fund_box.dart';
import 'fund_box_model.dart';

/// Data Transfer Object for FundBox API communication
/// Maps between API JSON and domain FundBox entity
/// Supports multi-currency balances (USD, SYP, TRY)
class FundBoxDto {
  final int id;
  final double? balanceUsd;
  final double? balanceSyp;
  final double? balanceTry;
  final String? currency; // For single currency queries
  final double? balance; // For single currency queries
  final DateTime? lastCalculatedAt;
  final DateTime lastUpdated;

  const FundBoxDto({
    required this.id,
    this.balanceUsd,
    this.balanceSyp,
    this.balanceTry,
    this.currency,
    this.balance,
    this.lastCalculatedAt,
    required this.lastUpdated,
  });
  
  // Legacy field for backward compatibility
  double get totalBalance => balanceUsd ?? 0.0;

  /// Create FundBoxDto from JSON response
  /// API returns either:
  /// 1. Multi-currency: balance_usd, balance_syp, balance_try, last_calculated_at, updated_at
  /// 2. Single currency: currency, balance (when querying ?currency=USD|SYP|TRY)
  factory FundBoxDto.fromJson(Map<String, dynamic> json) {
    // Check if this is a single currency response
    if (json.containsKey('currency') && json.containsKey('balance')) {
      final currency = json['currency'] as String;
      final balance = _parseDouble(json['balance']) ?? 0.0;
      
      return FundBoxDto(
        id: (json['id'] as int?) ?? 1,
        balanceUsd: currency == 'USD' ? balance : null,
        balanceSyp: currency == 'SYP' ? balance : null,
        balanceTry: currency == 'TRY' ? balance : null,
        currency: currency,
        balance: balance,
      lastCalculatedAt: DateFormatter.fromApiTimestampNullable(
        json['last_calculated_at'] as String?,
      ) ?? DateFormatter.fromApiTimestampNullable(
        json['calculated_at'] as String?,
      ),
      lastUpdated: DateFormatter.fromApiTimestampNullable(
        json['updated_at'] as String?,
      ) ?? DateTime.now(),
    );
  }
  
  // Multi-currency response
  return FundBoxDto(
    id: (json['id'] as int?) ?? 1,
    balanceUsd: _parseDouble(json['balance_usd']) ?? 
                _parseDouble(json['total_balance']) ?? 0.0,
    balanceSyp: _parseDouble(json['balance_syp']) ?? 0.0,
    balanceTry: _parseDouble(json['balance_try']) ?? 0.0,
    lastCalculatedAt: DateFormatter.fromApiTimestampNullable(
      json['last_calculated_at'] as String?,
    ) ?? DateFormatter.fromApiTimestampNullable(
      json['calculated_at'] as String?,
    ),
      lastUpdated: DateFormatter.fromApiTimestampNullable(
        json['updated_at'] as String?,
      ) ??
      DateFormatter.fromApiTimestampNullable(
        json['last_updated'] as String?,
      ) ??
      DateTime.now(),
    );
  }

  /// Helper method to parse double from various formats (String, int, double)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Convert FundBoxDto to JSON for API requests
  /// API expects: balance_usd, balance_syp, balance_try (or total_balance for backward compatibility)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'last_updated': DateFormatter.toApiTimestamp(lastUpdated),
    };
    
    if (balanceUsd != null) {
      map['balance_usd'] = balanceUsd;
      map['total_balance'] = balanceUsd; // For backward compatibility
    }
    if (balanceSyp != null) {
      map['balance_syp'] = balanceSyp;
    }
    if (balanceTry != null) {
      map['balance_try'] = balanceTry;
    }
    if (lastCalculatedAt != null) {
      map['last_calculated_at'] = DateFormatter.toApiTimestamp(lastCalculatedAt!);
    }
    
    return map;
  }

  /// Convert FundBoxDto to domain FundBox entity
  /// Note: userId is set to 0 as it's not returned by the API
  /// The fund box is global for admin users
  FundBox toEntity() {
    return FundBox(
      id: id,
      userId: 0, // Global fund box for admin
      balanceUsd: balanceUsd ?? 0.0,
      balanceSyp: balanceSyp ?? 0.0,
      balanceTry: balanceTry ?? 0.0,
      lastCalculatedAt: lastCalculatedAt,
      updatedAt: lastUpdated,
    );
  }

  /// Convert FundBoxDto to FundBoxModel
  FundBoxModel toModel() {
    return FundBoxModel(
      id: id,
      userId: 0, // Global fund box for admin
      balanceUsd: balanceUsd ?? 0.0,
      balanceSyp: balanceSyp ?? 0.0,
      balanceTry: balanceTry ?? 0.0,
      lastCalculatedAt: lastCalculatedAt,
      updatedAt: lastUpdated,
    );
  }

  /// Create FundBoxDto from domain FundBox entity
  factory FundBoxDto.fromEntity(FundBox fundBox) {
    return FundBoxDto(
      id: fundBox.id,
      balanceUsd: fundBox.balanceUsd,
      balanceSyp: fundBox.balanceSyp,
      balanceTry: fundBox.balanceTry,
      lastCalculatedAt: fundBox.lastCalculatedAt,
      lastUpdated: fundBox.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FundBoxDto(id: $id, totalBalance: $totalBalance, lastUpdated: $lastUpdated)';
  }
}
