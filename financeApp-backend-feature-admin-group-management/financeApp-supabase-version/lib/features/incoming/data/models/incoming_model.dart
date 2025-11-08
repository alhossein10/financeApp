import '../../domain/entities/incoming.dart';

class IncomingModel extends Incoming {
  const IncomingModel({
    super.id,
    required super.userId,
    required super.description,
    required super.amountUsd,
    required super.transactionDate,
    required super.createdAt,
    super.updatedAt,
  });

  factory IncomingModel.fromMap(Map<String, dynamic> map) {
    return IncomingModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'amount_usd': amountUsd,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory IncomingModel.fromEntity(Incoming incoming) {
    return IncomingModel(
      id: incoming.id,
      userId: incoming.userId,
      description: incoming.description,
      amountUsd: incoming.amountUsd,
      transactionDate: incoming.transactionDate,
      createdAt: incoming.createdAt,
      updatedAt: incoming.updatedAt,
    );
  }

  IncomingModel copyWith({
    int? id,
    int? userId,
    String? description,
    double? amountUsd,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amountUsd: amountUsd ?? this.amountUsd,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
