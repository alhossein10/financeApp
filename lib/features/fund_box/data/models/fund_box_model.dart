import '../../domain/entities/fund_box.dart';

/// Data model for FundBox that extends the domain entity
/// Handles serialization/deserialization for database operations
class FundBoxModel extends FundBox {
  const FundBoxModel({
    required super.id,
    required super.userId,
    required super.balanceUsd,
    required super.balanceSyp,
    required super.balanceTry,
    super.lastCalculatedAt,
    required super.updatedAt,
  });

  /// Create a FundBoxModel from a domain entity
  factory FundBoxModel.fromEntity(FundBox fundBox) {
    return FundBoxModel(
      id: fundBox.id,
      userId: fundBox.userId,
      balanceUsd: fundBox.balanceUsd,
      balanceSyp: fundBox.balanceSyp,
      balanceTry: fundBox.balanceTry,
      lastCalculatedAt: fundBox.lastCalculatedAt,
      updatedAt: fundBox.updatedAt,
    );
  }

  /// Create a FundBoxModel from a database map
  factory FundBoxModel.fromMap(Map<String, dynamic> map) {
    return FundBoxModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      balanceUsd: (map['balance_usd'] as num?)?.toDouble() ?? 0.0,
      balanceSyp: (map['balance_syp'] as num?)?.toDouble() ?? 0.0,
      balanceTry: (map['balance_try'] as num?)?.toDouble() ?? 0.0,
      lastCalculatedAt: map['last_calculated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_calculated_at'] as int)
          : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert the model to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'balance_usd': balanceUsd,
      'balance_syp': balanceSyp,
      'balance_try': balanceTry,
      'last_calculated_at': lastCalculatedAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated fields
  @override
  FundBoxModel copyWith({
    int? id,
    int? userId,
    double? balanceUsd,
    double? balanceSyp,
    double? balanceTry,
    DateTime? lastCalculatedAt,
    DateTime? updatedAt,
  }) {
    return FundBoxModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      balanceSyp: balanceSyp ?? this.balanceSyp,
      balanceTry: balanceTry ?? this.balanceTry,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
