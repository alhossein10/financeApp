import 'package:equatable/equatable.dart';
import '../../domain/entities/incoming.dart';

abstract class IncomingEvent extends Equatable {
  const IncomingEvent();

  @override
  List<Object?> get props => [];
}

class LoadIncoming extends IncomingEvent {
  const LoadIncoming();
}

class CreateIncoming extends IncomingEvent {
  final String description;
  final double amountUsd;
  final DateTime? transactionDate;

  const CreateIncoming({
    required this.description,
    required this.amountUsd,
    this.transactionDate,
  });

  @override
  List<Object?> get props => [description, amountUsd, transactionDate];
}

class UpdateIncoming extends IncomingEvent {
  final Incoming incoming;

  const UpdateIncoming(this.incoming);

  @override
  List<Object?> get props => [incoming];
}

class DeleteIncoming extends IncomingEvent {
  final int id;
  final bool refund;

  const DeleteIncoming({
    required this.id,
    this.refund = false,
  });

  @override
  List<Object?> get props => [id, refund];
}

class CheckConnectivityStatus extends IncomingEvent {
  const CheckConnectivityStatus();
}

class ProcessOfflineQueue extends IncomingEvent {
  const ProcessOfflineQueue();
}
