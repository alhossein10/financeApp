import 'package:equatable/equatable.dart';

abstract class ExchangeEvent extends Equatable {
  const ExchangeEvent();

  @override
  List<Object?> get props => [];
}

class CreateExchangeEvent extends ExchangeEvent {
  final int? transferId; // Optional - for balance-based exchanges
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double? exchangeRate; // Optional if convertedAmount is provided
  final double? convertedAmount; // Optional if exchangeRate is provided (Backend v3.1+)
  final DateTime exchangeDate;
  final String? notes;

  const CreateExchangeEvent({
    this.transferId,
    required this.targetCurrency,
    required this.amountUsd,
    this.exchangeRate,
    this.convertedAmount,
    required this.exchangeDate,
    this.notes,
  });

  @override
  List<Object?> get props => [transferId, targetCurrency, amountUsd, exchangeRate, convertedAmount, exchangeDate, notes];
}

class LoadAllExchangesEvent extends ExchangeEvent {
  final String? currency; // Optional filter: 'all', 'SYP', or 'TRY'

  const LoadAllExchangesEvent({this.currency});

  @override
  List<Object?> get props => [currency];
}

class LoadExchangesByTransferEvent extends ExchangeEvent {
  final int transferId;

  const LoadExchangesByTransferEvent(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class LoadTransferBalanceEvent extends ExchangeEvent {
  final int transferId;

  const LoadTransferBalanceEvent(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

class ResetExchangeStateEvent extends ExchangeEvent {
  const ResetExchangeStateEvent();
}
