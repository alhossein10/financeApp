import 'package:equatable/equatable.dart';

/// Base class for all FundBox events
abstract class FundBoxEvent extends Equatable {
  const FundBoxEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load fund box for a specific user
class LoadFundBox extends FundBoxEvent {
  final int userId;

  const LoadFundBox(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to update fund box balance
class UpdateFundBalance extends FundBoxEvent {
  final int userId;
  final double newBalance;

  const UpdateFundBalance({
    required this.userId,
    required this.newBalance,
  });

  @override
  List<Object?> get props => [userId, newBalance];
}

/// Event to refresh fund box data
class RefreshFundBox extends FundBoxEvent {
  final int userId;

  const RefreshFundBox(this.userId);

  @override
  List<Object?> get props => [userId];
}
