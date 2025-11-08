import 'package:equatable/equatable.dart';

class Transfer extends Equatable {
  final int? id;
  final int userId;
  final int? recipientUserId; // ID of the user who receives the transfer
  final String recipientName;
  final double amountUsd;
  final double? convertedAmountUsd;
  final double? amountSypAtExchange;
  final double? manualUsdToSypRate;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Transfer({
    this.id,
    required this.userId,
    this.recipientUserId,
    required this.recipientName,
    required this.amountUsd,
    this.convertedAmountUsd,
    this.amountSypAtExchange,
    this.manualUsdToSypRate,
    required this.transactionDate,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        recipientUserId,
        recipientName,
        amountUsd,
        convertedAmountUsd,
        amountSypAtExchange,
        manualUsdToSypRate,
        transactionDate,
        createdAt,
        updatedAt,
      ];
}
