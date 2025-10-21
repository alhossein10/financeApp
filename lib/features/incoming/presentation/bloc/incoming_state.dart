import 'package:equatable/equatable.dart';
import '../../domain/entities/incoming.dart';

abstract class IncomingState extends Equatable {
  const IncomingState();

  @override
  List<Object?> get props => [];
}

class IncomingInitial extends IncomingState {
  const IncomingInitial();
}

class IncomingLoading extends IncomingState {
  const IncomingLoading();
}

class IncomingLoaded extends IncomingState {
  final List<Incoming> incomingList;

  const IncomingLoaded(this.incomingList);

  @override
  List<Object?> get props => [incomingList];
}

class IncomingError extends IncomingState {
  final String message;

  const IncomingError(this.message);

  @override
  List<Object?> get props => [message];
}

class IncomingOperationSuccess extends IncomingState {
  final String message;

  const IncomingOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
