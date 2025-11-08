import 'package:equatable/equatable.dart';

/// Exchange domain entity
/// Supports balance-based exchanges (optional transferId) and multi-currency (SYP/TRY)
class Exchange extends Equatable {
  final int? id;
  final int? transferId; // Optional - for balance-based exchanges
  final int? userId;
  final int? adminGroupId;
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double exchangeRate;
  final double? amountSyp; // Only set when targetCurrency is SYP
  final double? amountTry; // Only set when targetCurrency is TRY
  final DateTime exchangeDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? recipientName;
  final String? userName;

  const Exchange({
    this.id,
    this.transferId,
    this.userId,
    this.adminGroupId,
    required this.targetCurrency,
    required this.amountUsd,
    required this.exchangeRate,
    this.amountSyp,
    this.amountTry,
    required this.exchangeDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.recipientName,
    this.userName,
  });

  @override
  List<Object?> get props => [
        id,
        transferId,
        userId,
        adminGroupId,
        targetCurrency,
        amountUsd,
        exchangeRate,
        amountSyp,
        amountTry,
        exchangeDate,
        notes,
        createdAt,
        updatedAt,
        recipientName,
        userName,
      ];

  Exchange copyWith({
    int? id,
    int? transferId,
    int? userId,
    int? adminGroupId,
    String? targetCurrency,
    double? amountUsd,
    double? exchangeRate,
    double? amountSyp,
    double? amountTry,
    DateTime? exchangeDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? recipientName,
    String? userName,
  }) {
    return Exchange(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      userId: userId ?? this.userId,
      adminGroupId: adminGroupId ?? this.adminGroupId,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      amountUsd: amountUsd ?? this.amountUsd,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      amountSyp: amountSyp ?? this.amountSyp,
      amountTry: amountTry ?? this.amountTry,
      exchangeDate: exchangeDate ?? this.exchangeDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recipientName: recipientName ?? this.recipientName,
      userName: userName ?? this.userName,
    );
  }
}

/// Transfer Balance entity
class TransferBalance extends Equatable {
  final int transferId;
  final double originalAmount;
  final double totalExchanged;
  final double remainingBalance;
  final String recipientName;
  final DateTime transferDate;

  const TransferBalance({
    required this.transferId,
    required this.originalAmount,
    required this.totalExchanged,
    required this.remainingBalance,
    required this.recipientName,
    required this.transferDate,
  });

  @override
  List<Object?> get props => [
        transferId,
        originalAmount,
        totalExchanged,
        remainingBalance,
        recipientName,
        transferDate,
      ];
}
