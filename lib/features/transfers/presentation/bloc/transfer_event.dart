import 'package:equatable/equatable.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/entities/transfer_type.dart';

abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

class CreateTransferEvent extends TransferEvent {
  final int userId;
  final String recipientName;
  final int? recipientUserId; // ID of the recipient user (required for SuperAdmin transfers to admins)
  final int? adminGroupId; // Admin group ID for the transfer (should be set from recipient's admin_group_id for SuperAdmin transfers)
  final double amountUsd;
  final double? convertedAmountUsd;
  final double? amountSypAtExchange;
  final double? manualUsdToSypRate;
  final DateTime? transactionDate;

  const CreateTransferEvent({
    required this.userId,
    required this.recipientName,
    this.recipientUserId,
    this.adminGroupId,
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
        recipientUserId,
        adminGroupId,
        amountUsd,
        convertedAmountUsd,
        amountSypAtExchange,
        manualUsdToSypRate,
        transactionDate,
      ];
}

class LoadTransfersEvent extends TransferEvent {
  final int userId;
  final TransferType type;

  const LoadTransfersEvent(this.userId, {this.type = TransferType.all});

  @override
  List<Object?> get props => [userId, type];
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
