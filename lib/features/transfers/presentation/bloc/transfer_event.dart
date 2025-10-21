import 'package:equatable/equatable.dart';
import '../../domain/entities/transfer.dart';

abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

class CreateTransferEvent extends TransferEvent {
  final int userId;
  final String recipientName;
  final double amountUsd;
  final double? convertedAmountUsd;
  final double? amountSypAtExchange;
  final double? manualUsdToSypRate;
  final DateTime? transactionDate;

  const CreateTransferEvent({
    required this.userId,
    required this.recipientName,
    required this.amountUsd,
    this.convertedAmountUsd,
    this.amountSypAtExchange,
    this.manualUsdToSypRate,
    this.transactionDate,
  });

  @override
  List<Object?> get props => [
        userId,
        recipientName,
        amountUsd,
        convertedAmountUsd,
        amountSypAtExchange,
        manualUsdToSypRate,
        transactionDate,
      ];
}

class LoadTransfersEvent extends TransferEvent {
  final int userId;

  const LoadTransfersEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateTransferEvent extends TransferEvent {
  final Transfer transfer;

  const UpdateTransferEvent(this.transfer);

  @override
  List<Object?> get props => [transfer];
}

class DeleteTransferEvent extends TransferEvent {
  final int transferId;
  final int userId;
  final bool refund;

  const DeleteTransferEvent({
    required this.transferId,
    required this.userId,
    this.refund = false,
  });

  @override
  List<Object?> get props => [transferId, userId, refund];
}
