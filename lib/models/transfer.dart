class TransferRecord {
  final int? id;
  final int userId;
  final String recipientName;
  final double amountUsd;
  final double? convertedAmountUsd; // amount converted to SYP
  final double? amountSypAtExchange; // optional, editable later
  final double? manualUsdToSypRate; // snapshot of rate used if recorded
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TransferRecord({
    this.id,
    required this.userId,
    required this.recipientName,
    required this.amountUsd,
    this.convertedAmountUsd,
    this.amountSypAtExchange,
    this.manualUsdToSypRate,
    required this.transactionDate,
    required this.createdAt,
    this.updatedAt,
  });

  TransferRecord copyWith({
    int? id,
    int? userId,
    String? recipientName,
    double? amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      amountUsd: amountUsd ?? this.amountUsd,
      convertedAmountUsd: convertedAmountUsd ?? this.convertedAmountUsd,
      amountSypAtExchange: amountSypAtExchange ?? this.amountSypAtExchange,
      manualUsdToSypRate: manualUsdToSypRate ?? this.manualUsdToSypRate,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'user_id': userId,
      'recipient_name': recipientName,
      'amount_usd': amountUsd,
      'converted_amount_usd': convertedAmountUsd,
      'amount_syp_at_exchange': amountSypAtExchange,
      'manual_usd_to_syp_rate': manualUsdToSypRate,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory TransferRecord.fromMap(Map<String, Object?> map) {
    return TransferRecord(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      recipientName: (map['recipient_name'] as String?) ?? '',
      amountUsd: (map['amount_usd'] as num?)?.toDouble() ?? 0.0,
      convertedAmountUsd: (map['converted_amount_usd'] as num?)?.toDouble(),
      amountSypAtExchange:
          (map['amount_syp_at_exchange'] as num?)?.toDouble(),
      manualUsdToSypRate:
          (map['manual_usd_to_syp_rate'] as num?)?.toDouble(),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        (map['transaction_date'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
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


