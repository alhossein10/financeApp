import 'package:equatable/equatable.dart';
import '../../domain/entities/transfer.dart';

abstract class TransferState extends Equatable {
  const TransferState();

  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {}

class TransferLoading extends TransferState {}

class TransferLoaded extends TransferState {
  final List<Transfer> transfers;
  final bool isOffline;
  final bool isSyncing;

  const TransferLoaded(
    this.transfers, {
    this.isOffline = false,
    this.isSyncing = false,
  });

  @override
  List<Object?> get props => [transfers, isOffline, isSyncing];

  TransferLoaded copyWith({
    List<Transfer>? transfers,
    bool? isOffline,
    bool? isSyncing,
  }) {
    return TransferLoaded(
      transfers ?? this.transfers,
      isOffline: isOffline ?? this.isOffline,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class TransferCreated extends TransferState {
  final Transfer transfer;
  final bool isPending;

  const TransferCreated(
    this.transfer, {
    this.isPending = false,
  });

  @override
  List<Object?> get props => [transfer, isPending];
}

class TransferUpdated extends TransferState {
  final bool isPending;

  const TransferUpdated({this.isPending = false});

  @override
  List<Object?> get props => [isPending];
}

class TransferDeleted extends TransferState {
  final bool isPending;

  const TransferDeleted({this.isPending = false});

  @override
  List<Object?> get props => [isPending];
}

class TransferError extends TransferState {
  final String message;
  final bool isOffline;
  final bool requiresLogout;
  final bool isForbidden;
  final bool isValidationError;
  final bool isRateLimited;
  final int? retryAfterSeconds;

  const TransferError(
    this.message, {
    this.isOffline = false,
    this.requiresLogout = false,
    this.isForbidden = false,
    this.isValidationError = false,
    this.isRateLimited = false,
    this.retryAfterSeconds,
  });

  @override
  List<Object?> get props => [
        message,
        isOffline,
        requiresLogout,
        isForbidden,
        isValidationError,
        isRateLimited,
        retryAfterSeconds,
      ];
}
