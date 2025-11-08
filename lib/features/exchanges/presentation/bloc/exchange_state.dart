import 'package:equatable/equatable.dart';
import '../../domain/entities/exchange.dart';

abstract class ExchangeState extends Equatable {
  const ExchangeState();

  @override
  List<Object?> get props => [];
}

class ExchangeInitial extends ExchangeState {
  const ExchangeInitial();
}

class ExchangeLoading extends ExchangeState {
  const ExchangeLoading();
}

class ExchangeCreated extends ExchangeState {
  final Exchange exchange;

  const ExchangeCreated(this.exchange);

  @override
  List<Object?> get props => [exchange];
}

class ExchangesLoaded extends ExchangeState {
  final List<Exchange> exchanges;

  const ExchangesLoaded(this.exchanges);

  @override
  List<Object?> get props => [exchanges];
}

class TransferBalanceLoaded extends ExchangeState {
  final TransferBalance balance;

  const TransferBalanceLoaded(this.balance);

  @override
  List<Object?> get props => [balance];
}

class ExchangeError extends ExchangeState {
  final String message;

  const ExchangeError(this.message);

  @override
  List<Object?> get props => [message];
}
