import '../../domain/entities/fund_box.dart';

/// Data model for FundBox that extends the domain entity
/// Handles serialization/deserialization for database operations
class FundBoxModel extends FundBox {
  const FundBoxModel({
    required super.id,
    required super.userId,
    required super.balanceUsd,
    required super.updatedAt,
  });

  /// Create a FundBoxModel from a domain entity
  factory FundBoxModel.fromEntity(FundBox fundBox) {
    return FundBoxModel(
      id: fundBox.id,
      userId: fundBox.userId,
      balanceUsd: fundBox.balanceUsd,
      updatedAt: fundBox.updatedAt,
    );
  }

  /// Create a FundBoxModel from a database map
  factory FundBoxModel.fromMap(Map<String, dynamic> map) {
    return FundBoxModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      balanceUsd: (map['balance_usd'] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert the model to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'balance_usd': balanceUsd,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated fields
  @override
  FundBoxModel copyWith({
    int? id,
    int? userId,
    double? balanceUsd,
    DateTime? updatedAt,
  }) {
    return FundBoxModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
