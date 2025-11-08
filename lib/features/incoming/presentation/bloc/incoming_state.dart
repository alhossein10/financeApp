import 'package:equatable/equatable.dart';
import '../../domain/entities/incoming.dart';

abstract class IncomingState extends Equatable {
  final bool isOnline;
  final int pendingQueueCount;

  const IncomingState({
    this.isOnline = true,
    this.pendingQueueCount = 0,
  });

  @override
  List<Object?> get props => [isOnline, pendingQueueCount];
}

class IncomingInitial extends IncomingState {
  const IncomingInitial({
    super.isOnline,
    super.pendingQueueCount,
  });
}

class IncomingLoading extends IncomingState {
  const IncomingLoading({
    super.isOnline,
    super.pendingQueueCount,
  });
}

class IncomingLoaded extends IncomingState {
  final List<Incoming> incomingList;
  final double totalAmountUsd;

  const IncomingLoaded(
    this.incomingList, {
    this.totalAmountUsd = 0.0,
    super.isOnline,
    super.pendingQueueCount,
  });

  @override
  List<Object?> get props => [
        incomingList,
        totalAmountUsd,
        isOnline,
        pendingQueueCount,
      ];
}

class IncomingError extends IncomingState {
  final String message;
  final bool requiresLogout;
  final bool isForbidden;
  final bool isValidationError;
  final bool isRateLimited;
  final int? retryAfterSeconds;

  const IncomingError(
    this.message, {
    super.isOnline,
    super.pendingQueueCount,
    this.requiresLogout = false,
    this.isForbidden = false,
    this.isValidationError = false,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [
        message,
        isOnline,
        pendingQueueCount,
        requiresLogout,
        isForbidden,
        isValidationError,
        isRateLimited,
        retryAfterSeconds,
      ];
}

@Deprecated('Use IncomingError with enhanced error handling instead')
class IncomingApiError extends IncomingState {
  final String message;
  final int statusCode;

  const IncomingApiError(
    this.message, {
    required this.statusCode,
    super.isOnline,
    super.pendingQueueCount,
  });

  @override
  List<Object?> get props => [
        message,
        statusCode,
        isOnline,
        pendingQueueCount,
      ];
}

class IncomingOperationSuccess extends IncomingState {
  final String message;

  const IncomingOperationSuccess(
    this.message, {
    super.isOnline,
    super.pendingQueueCount,
  });

  @override
  List<Object?> get props => [message, isOnline, pendingQueueCount];
}
