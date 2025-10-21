class IncomingRecord {
  final int? id;
  final int userId;
  final String description;
  final double amountUsd;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const IncomingRecord({
    this.id,
    required this.userId,
    required this.description,
    required this.amountUsd,
    required this.transactionDate,
    required this.createdAt,
    this.updatedAt,
  });

  IncomingRecord copyWith({
    int? id,
    int? userId,
    String? description,
    double? amountUsd,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomingRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amountUsd: amountUsd ?? this.amountUsd,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'user_id': userId,
      'description': description,
      'amount_usd': amountUsd,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory IncomingRecord.fromMap(Map<String, Object?> map) {
    return IncomingRecord(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      description: (map['description'] as String?) ?? '',
      amountUsd: (map['amount_usd'] as num?)?.toDouble() ?? 0.0,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        (map['transaction_date'] as int?) ?? 0,
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
