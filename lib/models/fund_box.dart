class FundBox {
  final int id; // Always 1 for single-row pattern
  final double balanceUsd;
  final DateTime updatedAt;

  const FundBox({
    required this.id,
    required this.balanceUsd,
    required this.updatedAt,
  });

  FundBox copyWith({double? balanceUsd, DateTime? updatedAt}) {
    return FundBox(
      id: id,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'balance_usd': balanceUsd,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory FundBox.fromMap(Map<String, Object?> map) {
    return FundBox(
      id: (map['id'] as int?) ?? 1,
      balanceUsd: (map['balance_usd'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? 0,
      ),
    );
  }
}


