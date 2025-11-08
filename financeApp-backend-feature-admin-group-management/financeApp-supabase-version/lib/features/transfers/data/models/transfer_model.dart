import '../../domain/entities/transfer.dart';

class TransferModel extends Transfer {
  const TransferModel({
    super.id,
    required super.userId,
    required super.recipientName,
    required super.amountUsd,
    super.convertedAmountUsd,
    super.amountSypAtExchange,
    super.manualUsdToSypRate,
    required super.transactionDate,
    required super.createdAt,
    super.updatedAt,
  });

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      recipientName: map['recipient_name'] as String,
      amountUsd: (map['amount_usd'] as num).toDouble(),
      convertedAmountUsd: map['converted_amount_usd'] != null
          ? (map['converted_amount_usd'] as num).toDouble()
          : null,
      amountSypAtExchange: map['amount_syp_at_exchange'] != null
          ? (map['amount_syp_at_exchange'] as num).toDouble()
          : null,
      manualUsdToSypRate: map['manual_usd_to_syp_rate'] != null
          ? (map['manual_usd_to_syp_rate'] as num).toDouble()
          : null,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transaction_date'] as int,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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

  factory TransferModel.fromEntity(Transfer transfer) {
    return TransferModel(
      id: transfer.id,
      userId: transfer.userId,
      recipientName: transfer.recipientName,
      amountUsd: transfer.amountUsd,
      convertedAmountUsd: transfer.convertedAmountUsd,
      amountSypAtExchange: transfer.amountSypAtExchange,
      manualUsdToSypRate: transfer.manualUsdToSypRate,
      transactionDate: transfer.transactionDate,
      createdAt: transfer.createdAt,
      updatedAt: transfer.updatedAt,
    );
  }

  TransferModel copyWith({
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
    return TransferModel(
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
}
