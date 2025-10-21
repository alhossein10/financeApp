class ExchangeRecord {
  final int? id;
  final int transferId;
  final double convertedAmountUsd;
  final double? amountSypAtExchange;
  final double? manualUsdToSypRate;
  final DateTime createdAt;

  const ExchangeRecord({
    this.id,
    required this.transferId,
    required this.convertedAmountUsd,
    this.amountSypAtExchange,
    this.manualUsdToSypRate,
    required this.createdAt,
  });

  ExchangeRecord copyWith({
    int? id,
    int? transferId,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? createdAt,
  }) {
    return ExchangeRecord(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      convertedAmountUsd: convertedAmountUsd ?? this.convertedAmountUsd,
      amountSypAtExchange: amountSypAtExchange ?? this.amountSypAtExchange,
      manualUsdToSypRate: manualUsdToSypRate ?? this.manualUsdToSypRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'transfer_id': transferId,
      'converted_amount_usd': convertedAmountUsd,
      'amount_syp_at_exchange': amountSypAtExchange,
      'manual_usd_to_syp_rate': manualUsdToSypRate,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ExchangeRecord.fromMap(Map<String, Object?> map) {
    return ExchangeRecord(
      id: map['id'] as int?,
      transferId: (map['transfer_id'] as int?) ?? 0,
      convertedAmountUsd: (map['converted_amount_usd'] as num?)?.toDouble() ?? 0.0,
      amountSypAtExchange: (map['amount_syp_at_exchange'] as num?)?.toDouble(),
      manualUsdToSypRate: (map['manual_usd_to_syp_rate'] as num?)?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? 0,
      ),
    );
  }
}
